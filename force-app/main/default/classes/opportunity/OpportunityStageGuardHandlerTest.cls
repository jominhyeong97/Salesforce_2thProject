@IsTest
private class OpportunityStageGuardHandlerTest {
    @IsTest
    static void blocksEnteringClosedStageWhenBusinessNotVerified() {
        Opportunity opportunityRecord = createOpportunity(false);

        Test.startTest();
        opportunityRecord.StageName = '수주 완료';
        try {
            update opportunityRecord;
            System.assert(false, '사업자 검증 없는 수주 완료 진입은 차단되어야 합니다.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('사업자등록번호 검증이 완료된 기회만'));
        }
        Test.stopTest();
    }

    @IsTest
    static void allowsEnteringClosedStageWhenBusinessVerified() {
        Opportunity opportunityRecord = createOpportunity(true);

        Test.startTest();
        opportunityRecord.StageName = '수주 완료';
        update opportunityRecord;
        Test.stopTest();

        Opportunity verifiedOpportunity = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        System.assertEquals('수주 완료', verifiedOpportunity.StageName);
    }

    @IsTest
    static void allowsEnteringClosedStageForPersonalOpportunityWithoutBusinessVerification() {
        Opportunity opportunityRecord = createOpportunity(false, '(개인) 홍길동');

        Test.startTest();
        opportunityRecord.StageName = '수주 완료';
        update opportunityRecord;
        Test.stopTest();

        Opportunity verifiedOpportunity = [
            SELECT StageName
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        System.assertEquals('수주 완료', verifiedOpportunity.StageName);
    }

    private static Opportunity createOpportunity(Boolean businessVerified) {
        return createOpportunity(businessVerified, 'Stage Guard 거래처');
    }

    private static Opportunity createOpportunity(Boolean businessVerified, String accountName) {
        Account accountRecord = new Account(Name = accountName);
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Stage Guard 가격표', IsActive = true);
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Stage Guard 기회',
            AccountId = accountRecord.Id,
            StageName = getOpenStageName(),
            CloseDate = Date.today().addDays(10),
            Pricebook2Id = pricebookRecord.Id,
            Business_Verified__c = businessVerified,
            Business_Number__c = '123-45-67890'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static String getOpenStageName() {
        for (Schema.PicklistEntry entry :
            Schema.SObjectType.Opportunity.fields.StageName.getPicklistValues()) {
            if (entry.isActive() && entry.getValue() != '수주 완료') {
                return entry.getValue();
            }
        }

        return '기회 발굴';
    }
}
