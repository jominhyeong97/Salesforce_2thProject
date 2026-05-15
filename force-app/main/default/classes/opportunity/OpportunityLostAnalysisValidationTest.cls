@IsTest
private class OpportunityLostAnalysisValidationTest {
    @IsTest
    static void blocksClosedLostWithoutRequiredAnalysis() {
        Opportunity opportunityRecord = createOpportunity();

        Test.startTest();
        opportunityRecord.StageName = '수주 실패';
        try {
            update opportunityRecord;
            System.assert(false, '수주 실패 분석 필수값이 없으면 저장이 차단되어야 합니다.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('1차 실패 사유'));
        }
        Test.stopTest();
    }

    @IsTest
    static void blocksCompetitorLossWithoutCompetitorName() {
        Opportunity opportunityRecord = createOpportunity();
        opportunityRecord.StageName = '수주 실패';
        opportunityRecord.Lost_Reason_Primary__c = '경쟁사 선택';
        opportunityRecord.Lost_Reason_Detail__c = '가격과 유지관리 조건을 비교하다가 경쟁사로 이동했습니다.';
        opportunityRecord.Reopen_Potential__c = '보통';

        Test.startTest();
        try {
            update opportunityRecord;
            System.assert(false, '경쟁사명을 입력하지 않으면 저장이 차단되어야 합니다.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('경쟁사명'));
        }
        Test.stopTest();
    }

    @IsTest
    static void allowsClosedLostWhenAnalysisIsComplete() {
        Opportunity opportunityRecord = createOpportunity();
        opportunityRecord.StageName = '수주 실패';
        opportunityRecord.Lost_Reason_Primary__c = '가격';
        opportunityRecord.Lost_Reason_Secondary__c = '경쟁사 선택';
        opportunityRecord.Lost_Reason_Detail__c = '예산과 경쟁사 조건을 비교한 뒤 이번에는 보류되었습니다.';
        opportunityRecord.Lost_To_Competitor__c = '코웨이';
        opportunityRecord.Reopen_Potential__c = '높음';

        Test.startTest();
        update opportunityRecord;
        Test.stopTest();

        Opportunity savedOpportunity = [
            SELECT StageName, Lost_Reason_Primary__c, Lost_To_Competitor__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        System.assertEquals('수주 실패', savedOpportunity.StageName);
        System.assertEquals('가격', savedOpportunity.Lost_Reason_Primary__c);
        System.assertEquals('코웨이', savedOpportunity.Lost_To_Competitor__c);
    }

    private static Opportunity createOpportunity() {
        Account accountRecord = new Account(Name = '수주 실패 검증 거래처');
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(Name = '수주 실패 검증 가격표', IsActive = true);
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = '수주 실패 검증 기회',
            AccountId = accountRecord.Id,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(14),
            Pricebook2Id = pricebookRecord.Id,
            Business_Verified__c = true,
            Business_Number__c = '123-45-67890'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }
}
