@IsTest
private class OpportunityBusinessVerificationTest {
    private static final String VALID_BUSINESS_NUMBER = '2208162517';
    private static final String OPEN_STAGE = '기회 발굴';
    private static final String CLOSED_STAGE = '수주 완료';

    @IsTest
    static void invocableUpdatesOpportunityWhenVerificationSucceeds() {
        Opportunity opportunityRecord = createOpportunity('검증 성공', null, false);

        OpportunityBusinessStatusInvocable.Request request =
            new OpportunityBusinessStatusInvocable.Request();
        request.opportunityId = opportunityRecord.Id;
        request.businessNumber = VALID_BUSINESS_NUMBER;
        request.updateOpportunity = true;

        Test.setMock(HttpCalloutMock.class, new OpportunityBusinessStatusMock(true, 200));

        Test.startTest();
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>{ request }
            );
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT
                Business_Number__c,
                Business_Verified__c,
                Business_Verified_At__c,
                Business_Status__c,
                Business_Tax_Type__c,
                Business_Closure_Date__c,
                Business_Verification_Notes__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals(true, updatedOpportunity.Business_Verified__c);
        System.assertEquals(VALID_BUSINESS_NUMBER, updatedOpportunity.Business_Number__c);
        System.assertNotEquals(null, updatedOpportunity.Business_Verified_At__c);
        System.assertEquals('계속사업자', updatedOpportunity.Business_Status__c);
        System.assertEquals('부가가치세 일반과세자', updatedOpportunity.Business_Tax_Type__c);
        System.assertEquals(
            Date.newInstance(2024, 12, 31),
            updatedOpportunity.Business_Closure_Date__c
        );
    }

    @IsTest
    static void invocableReturnsEmptyListWhenNoRequestsAreProvided() {
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>()
            );

        System.assertEquals(0, responses.size());
    }

    @IsTest
    static void invocableCanSkipOpportunityUpdate() {
        Opportunity opportunityRecord = createOpportunity('업데이트 건너뜀', null, false);

        OpportunityBusinessStatusInvocable.Request request =
            new OpportunityBusinessStatusInvocable.Request();
        request.opportunityId = opportunityRecord.Id;
        request.businessNumber = VALID_BUSINESS_NUMBER;
        request.updateOpportunity = false;

        Test.setMock(HttpCalloutMock.class, new OpportunityBusinessStatusMock(true, 200));

        Test.startTest();
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>{ request }
            );
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT Business_Verified__c, Business_Status__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(true, responses[0].success);
        System.assertEquals(false, updatedOpportunity.Business_Verified__c);
        System.assertEquals(null, updatedOpportunity.Business_Status__c);
    }

    @IsTest
    static void invocableMarksOpportunityAsNotVerifiedForInvalidBusinessNumber() {
        Opportunity opportunityRecord = createOpportunity(
            '잘못된 번호',
            VALID_BUSINESS_NUMBER,
            true
        );

        OpportunityBusinessStatusInvocable.Request request =
            new OpportunityBusinessStatusInvocable.Request();
        request.opportunityId = opportunityRecord.Id;
        request.businessNumber = '12345';
        request.updateOpportunity = true;

        Test.startTest();
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>{ request }
            );
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT
                Business_Number__c,
                Business_Verified__c,
                Business_Status__c,
                Business_Verification_Notes__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(false, responses[0].success);
        System.assertEquals(false, updatedOpportunity.Business_Verified__c);
        System.assertEquals(null, updatedOpportunity.Business_Status__c);
        System.assertEquals('12345', updatedOpportunity.Business_Number__c);
        System.assertEquals(
            '유효한 사업자번호 형식이 아닙니다.',
            updatedOpportunity.Business_Verification_Notes__c
        );
    }

    @IsTest
    static void invocableStoresMessageOnlyWhenCalloutThrows() {
        Opportunity opportunityRecord = createOpportunity(
            '콜아웃 실패',
            VALID_BUSINESS_NUMBER,
            true
        );

        OpportunityBusinessStatusInvocable.Request request =
            new OpportunityBusinessStatusInvocable.Request();
        request.opportunityId = opportunityRecord.Id;
        request.businessNumber = VALID_BUSINESS_NUMBER;
        request.updateOpportunity = true;

        Test.setMock(HttpCalloutMock.class, new OpportunityBusinessStatusMock(true, 500));

        Test.startTest();
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>{ request }
            );
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT Business_Verified__c, Business_Verification_Notes__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(false, responses[0].success);
        System.assertEquals(true, updatedOpportunity.Business_Verified__c);
        System.assert(
            updatedOpportunity.Business_Verification_Notes__c.contains(
                '사업자 상태조회 서비스 호출에 실패했습니다.'
            )
        );
    }

    @IsTest
    static void invocableReturnsDmlErrorWhenOpportunityUpdateFails() {
        Opportunity opportunityRecord = createOpportunity('삭제된 기회', null, false);
        delete opportunityRecord;

        OpportunityBusinessStatusInvocable.Request request =
            new OpportunityBusinessStatusInvocable.Request();
        request.opportunityId = opportunityRecord.Id;
        request.businessNumber = VALID_BUSINESS_NUMBER;
        request.updateOpportunity = true;

        Test.setMock(HttpCalloutMock.class, new OpportunityBusinessStatusMock(true, 200));

        Test.startTest();
        List<OpportunityBusinessStatusInvocable.Response> responses =
            OpportunityBusinessStatusInvocable.verify(
                new List<OpportunityBusinessStatusInvocable.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(false, responses[0].success);
        System.assert(
            responses[0].message.contains('deleted') ||
            responses[0].message.contains('삭제') ||
            responses[0].message.contains('entity')
        );
    }

    @IsTest
    static void clearsOpportunityVerificationStateWhenBusinessNumberChanges() {
        Opportunity opportunityRecord = createOpportunity(
            '번호 변경',
            '220-81-62517',
            true
        );

        opportunityRecord.Business_Number__c = '123-45-67890';
        update opportunityRecord;

        Opportunity updatedOpportunity = [
            SELECT
                Business_Number__c,
                Business_Verified__c,
                Business_Verified_At__c,
                Business_Status__c,
                Business_Tax_Type__c,
                Business_Verification_Notes__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals('1234567890', updatedOpportunity.Business_Number__c);
        System.assertEquals(false, updatedOpportunity.Business_Verified__c);
        System.assertEquals(null, updatedOpportunity.Business_Verified_At__c);
        System.assertEquals(null, updatedOpportunity.Business_Status__c);
        System.assertEquals(null, updatedOpportunity.Business_Tax_Type__c);
        System.assertEquals(null, updatedOpportunity.Business_Verification_Notes__c);
    }

    @IsTest
    static void blocksOpportunityWhenBusinessNumberIsNotVerified() {
        Opportunity opportunityRecord = createOpportunity(
            '미검증 마감',
            VALID_BUSINESS_NUMBER,
            false
        );
        syncQuote(opportunityRecord.Id);

        opportunityRecord.StageName = CLOSED_STAGE;

        Test.startTest();
        Database.SaveResult result = Database.update(opportunityRecord, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(
            result.getErrors()[0].getMessage().contains(
                '사업자등록번호 검증이 완료된 기회만 수주 완료 단계로 변경할 수 있습니다.'
            )
        );
    }

    @IsTest
    static void allowsOpportunityWhenBusinessNumberIsVerified() {
        Opportunity opportunityRecord = createOpportunity(
            '검증 후 마감',
            VALID_BUSINESS_NUMBER,
            true
        );
        syncQuote(opportunityRecord.Id);

        opportunityRecord.StageName = CLOSED_STAGE;

        Test.startTest();
        update opportunityRecord;
        Test.stopTest();

        Opportunity updatedOpportunity = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(CLOSED_STAGE, updatedOpportunity.StageName);
    }

    @IsTest
    static void blocksOpportunityWhenBusinessNumberIsMissing() {
        Opportunity opportunityRecord = createOpportunity('번호 없음', null, false);
        syncQuote(opportunityRecord.Id);

        opportunityRecord.StageName = CLOSED_STAGE;

        Test.startTest();
        Database.SaveResult result = Database.update(opportunityRecord, false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(result.getErrors()[0].getMessage().contains('사업자등록번호를 먼저 입력하세요'));
    }

    private static Opportunity createOpportunity(
        String name,
        String businessNumber,
        Boolean isVerified
    ) {
        Account accountRecord = new Account(Name = name + ' 거래처');
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(
            Name = name + ' 가격표',
            IsActive = true
        );
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = name,
            AccountId = accountRecord.Id,
            StageName = OPEN_STAGE,
            CloseDate = Date.today(),
            Pricebook2Id = pricebookRecord.Id,
            Business_Number__c = businessNumber,
            Business_Verified__c = isVerified,
            Business_Verified_At__c = isVerified ? System.now() : null,
            Business_Status__c = isVerified ? '계속사업자' : null,
            Business_Tax_Type__c = isVerified ? '부가가치세 일반과세자' : null,
            Business_Verification_Notes__c = isVerified ? '기존 검증 완료' : '최근 검증 기록 없음'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static void syncQuote(Id opportunityId) {
        Quote quoteRecord = new Quote(
            Name = '동기화 견적',
            OpportunityId = opportunityId,
            Status = 'Accepted',
            ExpirationDate = Date.today().addDays(30)
        );
        insert quoteRecord;

        update new Opportunity(
            Id = opportunityId,
            SyncedQuoteId = quoteRecord.Id
        );
    }

    private class OpportunityBusinessStatusMock implements HttpCalloutMock {
        private final Boolean activeBusiness;
        private final Integer statusCode;

        OpportunityBusinessStatusMock(Boolean activeBusiness, Integer statusCode) {
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
