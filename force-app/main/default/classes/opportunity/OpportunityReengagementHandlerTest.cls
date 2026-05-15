@IsTest
private class OpportunityReengagementHandlerTest {
    @IsTest
    static void createsReengagementTaskWhenOpportunityBecomesClosedLost() {
        Opportunity opportunityRecord = createOpportunity('재공략 생성');

        opportunityRecord.StageName = '수주 실패';
        opportunityRecord.Lost_Reason_Primary__c = '가격';
        opportunityRecord.Lost_Reason_Secondary__c = '경쟁사 선택';
        opportunityRecord.Lost_To_Competitor__c = '코웨이';
        opportunityRecord.Lost_Reason_Detail__c = '가격 경쟁에서 밀려 다음 분기 재접촉이 필요합니다.';
        opportunityRecord.Reopen_Potential__c = '높음';
        opportunityRecord.NextStep = '2주 뒤 재제안';

        Test.startTest();
        update opportunityRecord;
        Test.stopTest();

        Task reengagementTask = [
            SELECT Subject, ActivityDate, Priority, Sales_Task_Type__c, Description
            FROM Task
            WHERE WhatId = :opportunityRecord.Id
            AND Sales_Task_Type__c = '재공략'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('재공략', reengagementTask.Sales_Task_Type__c);
        System.assert(reengagementTask.Subject.startsWith('재공략 - '));
        System.assertEquals(Date.today().addDays(14), reengagementTask.ActivityDate);
        System.assertEquals(
            resolveFirstActivePicklistValue(
                Task.Priority.getDescribe().getPicklistValues(),
                'High'
            ),
            reengagementTask.Priority
        );
        System.assert(reengagementTask.Description.contains('재공략 가능성: 높음'));
        System.assert(reengagementTask.Description.contains('경쟁사: 코웨이'));
    }

    @IsTest
    static void doesNotCreateReengagementTaskForLowPotentialLoss() {
        Opportunity opportunityRecord = createOpportunity('재공략 미생성');

        opportunityRecord.StageName = '수주 실패';
        opportunityRecord.Lost_Reason_Primary__c = '가격';
        opportunityRecord.Lost_Reason_Detail__c = '이번에는 보류되었지만 재공략 우선순위는 낮습니다.';
        opportunityRecord.Reopen_Potential__c = '낮음';

        Test.startTest();
        update opportunityRecord;
        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Task
                WHERE WhatId = :opportunityRecord.Id
                AND Sales_Task_Type__c = '재공략'
            ]
        );
    }

    private static Opportunity createOpportunity(String name) {
        Account accountRecord = new Account(Name = name + ' 거래처');
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(Name = name + ' 가격표', IsActive = true);
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = name,
            AccountId = accountRecord.Id,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(10),
            Pricebook2Id = pricebookRecord.Id,
            Business_Verified__c = true,
            Business_Number__c = '123-45-67890'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static String resolveFirstActivePicklistValue(
        List<Schema.PicklistEntry> entries,
        String preferredValue
    ) {
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive() && entry.getValue() == preferredValue) {
                return entry.getValue();
            }
        }

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return preferredValue;
    }
}
