/**
 * 국세청 사업자 상태조회 API 호출과 응답 해석을 전담하는 서비스 클래스.
 * Flow나 Trigger에서는 이 클래스를 통해 "검증 결과"만 받아서 사용합니다.
 */
public with sharing class BusinessStatusService {
    private static final String NAMED_CREDENTIAL = 'callout:NtsBusinessStatus';
    private static final String ACTIVE_STATUS_CODE = '01';

    public class BusinessStatusException extends Exception {}

    public class BusinessStatusResult {
        public Boolean success { get; set; }
        public Boolean isVerified { get; set; }
        public String normalizedBusinessNumber { get; set; }
        public String businessStatus { get; set; }
        public String businessStatusCode { get; set; }
        public String taxType { get; set; }
        public String taxTypeCode { get; set; }
        public Date closureDate { get; set; }
        public String message { get; set; }
    }

    public static BusinessStatusResult lookup(String businessNumber) {
        List<BusinessStatusResult> results = lookup(new List<String>{ businessNumber });
        return results.isEmpty() ? new BusinessStatusResult() : results[0];
    }

    // Flow/Batch 확장까지 고려해 여러 사업자번호를 한 번에 조회할 수 있게 구성했습니다.
    public static List<BusinessStatusResult> lookup(List<String> businessNumbers) {
        List<BusinessStatusResult> results = new List<BusinessStatusResult>();
        if (businessNumbers == null || businessNumbers.isEmpty()) {
            return results;
        }

        List<String> numbersForLookup = new List<String>();
        Set<String> seenNumbers = new Set<String>();

        for (String rawBusinessNumber : businessNumbers) {
            BusinessStatusResult result = new BusinessStatusResult();
            result.success = false;
            result.isVerified = false;
            result.normalizedBusinessNumber = normalizeBusinessNumber(rawBusinessNumber);

            if (String.isBlank(result.normalizedBusinessNumber)) {
                result.message = '사업자번호를 입력하세요.';
            } else if (!isValidBusinessNumber(result.normalizedBusinessNumber)) {
                result.message = '유효한 사업자번호 형식이 아닙니다.';
            } else if (!seenNumbers.contains(result.normalizedBusinessNumber)) {
                seenNumbers.add(result.normalizedBusinessNumber);
                numbersForLookup.add(result.normalizedBusinessNumber);
            }

            results.add(result);
        }

        if (numbersForLookup.isEmpty()) {
            return results;
        }

        Map<String, Map<String, Object>> responseByBusinessNumber = callStatusApi(numbersForLookup);

        for (BusinessStatusResult result : results) {
            if (!String.isBlank(result.message)) {
                continue;
            }

            Map<String, Object> row = responseByBusinessNumber.get(result.normalizedBusinessNumber);
            if (row == null) {
                result.message = '사업자 상태조회 결과가 없습니다. 번호를 다시 확인하세요.';
                continue;
            }

            populateResult(result, row);
        }

        return results;
    }

    // Named Credential을 통해 실제 외부 API를 호출합니다.
    private static Map<String, Map<String, Object>> callStatusApi(List<String> businessNumbers) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(NAMED_CREDENTIAL);
        request.setMethod('POST');
        request.setTimeout(10000);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(new Map<String, Object>{
            'b_no' => businessNumbers
        }));

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
            throw new BusinessStatusException(
                '사업자 상태조회 API 호출에 실패했습니다. HTTP ' + response.getStatusCode()
            );
        }

        Map<String, Object> payload =
            (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String apiStatusCode = asString(payload.get('status_code'));
        if (!String.isBlank(apiStatusCode) && apiStatusCode != 'OK') {
            throw new BusinessStatusException(
                '사업자 상태조회 API가 오류를 반환했습니다. ' + extractMessage(payload)
            );
        }

        Map<String, Map<String, Object>> dataByBusinessNumber =
            new Map<String, Map<String, Object>>();
        List<Object> rows = (List<Object>) payload.get('data');
        if (rows == null) {
            return dataByBusinessNumber;
        }

        for (Object item : rows) {
            Map<String, Object> row = (Map<String, Object>) item;
            String businessNumber = asString(row.get('b_no'));
            if (!String.isBlank(businessNumber)) {
                dataByBusinessNumber.put(businessNumber, row);
            }
        }

        return dataByBusinessNumber;
    }

    // 외부 API 응답의 핵심 값만 우리가 쓰는 결과 객체에 옮겨 담습니다.
    private static void populateResult(BusinessStatusResult result, Map<String, Object> row) {
        result.success = true;
        result.businessStatus = asString(row.get('b_stt'));
        result.businessStatusCode = asString(row.get('b_stt_cd'));
        result.taxType = asString(row.get('tax_type'));
        result.taxTypeCode = asString(row.get('tax_type_cd'));
        result.closureDate = parseYyyyMmDd(asString(row.get('end_dt')));
        result.isVerified = isActiveBusiness(result.businessStatus, result.businessStatusCode);
        result.message = buildMessage(result);
    }

    // 국세청 상태 코드가 있으면 그 값을 우선 신뢰하고, 없으면 텍스트로 한 번 더 보정합니다.
    private static Boolean isActiveBusiness(String businessStatus, String businessStatusCode) {
        if (!String.isBlank(businessStatusCode)) {
            return businessStatusCode == ACTIVE_STATUS_CODE;
        }

        return !String.isBlank(businessStatus) && businessStatus.contains('계속');
    }

    private static String buildMessage(BusinessStatusResult result) {
        if (result.isVerified) {
            return '사업자 상태가 계속사업자로 확인되었습니다.';
        }

        if (!String.isBlank(result.businessStatus)) {
            return '사업자 상태가 "' + result.businessStatus + '"로 조회되어 전환이 제한됩니다.';
        }

        return '사업자 상태를 확인했지만 계속사업자로 판정되지 않았습니다.';
    }

    // 하이픈이 섞여 들어와도 같은 번호로 취급할 수 있게 숫자만 남깁니다.
    public static String normalizeBusinessNumber(String businessNumber) {
        if (String.isBlank(businessNumber)) {
            return null;
        }

        String normalized = businessNumber.replaceAll('[^0-9]', '');
        return String.isBlank(normalized) ? null : normalized;
    }

    // 사업자번호 체크섬 검증으로 API 호출 전에 명백한 오입력을 걸러냅니다.
    public static Boolean isValidBusinessNumber(String businessNumber) {
        if (String.isBlank(businessNumber) || businessNumber.length() != 10) {
            return false;
        }

        List<Integer> weights = new List<Integer>{ 1, 3, 7, 1, 3, 7, 1, 3, 5 };
        Integer sum = 0;

        for (Integer index = 0; index < 9; index++) {
            Integer digit = Integer.valueOf(businessNumber.substring(index, index + 1));
            sum += digit * weights[index];
        }

        Integer ninthDigit = Integer.valueOf(businessNumber.substring(8, 9));
        sum += (ninthDigit * 5) / 10;

        Integer remainder = sum - ((sum / 10) * 10);
        Integer checkDigit = (10 - remainder) == 10
            ? 0
            : 10 - remainder;

        return checkDigit == Integer.valueOf(businessNumber.substring(9, 10));
    }

    private static Date parseYyyyMmDd(String value) {
        if (String.isBlank(value) || value.length() != 8) {
            return null;
        }

        return Date.newInstance(
            Integer.valueOf(value.substring(0, 4)),
            Integer.valueOf(value.substring(4, 6)),
            Integer.valueOf(value.substring(6, 8))
        );
    }

    private static String extractMessage(Map<String, Object> payload) {
        List<String> keys = new List<String>{ 'message', 'msg', 'error' };
        for (String key : keys) {
            String value = asString(payload.get(key));
            if (!String.isBlank(value)) {
                return value;
            }
        }

        return '응답 본문을 확인하세요.';
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}
