/**
 * 국세청 상태조회 공통 서비스의 핵심 응답 해석을 검증합니다.
 * Lead 단계 검증 화면은 제거되었고, Lead에는 사업자번호 정규화만 남습니다.
 */
@IsTest
private class BusinessStatusServiceTest {
    private static final String VALID_BUSINESS_NUMBER = '2208162517';

    @IsTest
    static void lookupNormalizesAndParsesActiveBusiness() {
        Test.setMock(HttpCalloutMock.class, new NtsBusinessStatusMock(true, 200));

        Test.startTest();
        BusinessStatusService.BusinessStatusResult result =
            BusinessStatusService.lookup('220-81-62517');
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(true, result.isVerified);
        System.assertEquals(VALID_BUSINESS_NUMBER, result.normalizedBusinessNumber);
        System.assertEquals('계속사업자', result.businessStatus);
        System.assertEquals('부가가치세 일반과세자', result.taxType);
        System.assertEquals(Date.newInstance(2024, 12, 31), result.closureDate);
    }

    @IsTest
    static void lookupRejectsInvalidBusinessNumberBeforeCallout() {
        BusinessStatusService.BusinessStatusResult result =
            BusinessStatusService.lookup('12345');

        System.assertEquals(false, result.success);
        System.assertEquals(false, result.isVerified);
        System.assertEquals('유효한 사업자번호 형식이 아닙니다.', result.message);
    }

    private class NtsBusinessStatusMock implements HttpCalloutMock {
        private final Boolean activeBusiness;
        private final Integer statusCode;

        NtsBusinessStatusMock(Boolean activeBusiness, Integer statusCode) {
            this.activeBusiness = activeBusiness;
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod());
            System.assertEquals('callout:NtsBusinessStatus', request.getEndpoint());
            System.assert(request.getBody().contains(VALID_BUSINESS_NUMBER));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);

            if (statusCode != 200) {
                response.setBody('{"message":"temporary error"}');
                return response;
            }

            String businessStatus = activeBusiness ? '계속사업자' : '폐업자';
            String businessStatusCode = activeBusiness ? '01' : '03';
            String body =
                '{"status_code":"OK","data":[{"b_no":"' + VALID_BUSINESS_NUMBER +
                '","b_stt":"' + businessStatus +
                '","b_stt_cd":"' + businessStatusCode +
                '","tax_type":"부가가치세 일반과세자","tax_type_cd":"01","end_dt":"20241231"}]}';
            response.setBody(body);
            return response;
        }
    }
}
