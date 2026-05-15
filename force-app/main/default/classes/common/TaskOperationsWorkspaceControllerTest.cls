@IsTest
private class TaskOperationsWorkspaceControllerTest {
    @IsTest
    static void returnsTaskWorkspaceDataForCurrentRep() {
        Lead hotLead = new Lead(
            OwnerId = UserInfo.getUserId(),
            LastName = '워크스페이스핫',
            Company = '워크스페이스 핫 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '경쟁사 교체',
            Inquiry_Intent__c = '데모 요청',
            Desired_Rental_Budget__c = '20만원 이상',
            Purchase_Timeline__c = '즉시',
            Current_Contract_End_Date__c = Date.today().addDays(15),
            Geo_Region__c = '서울'
        );
        Lead renewalLead = new Lead(
            OwnerId = UserInfo.getUserId(),
            LastName = '워크스페이스갱신',
            Company = '워크스페이스 갱신 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '렌탈 유지 검토',
            Inquiry_Intent__c = '제품 문의',
            Purchase_Timeline__c = '6개월 이후',
            Current_Contract_End_Date__c = Date.today().addDays(70),
            Geo_Region__c = '서울'
        );
        insert new List<Lead>{ hotLead, renewalLead };

        List<Lead> ownedLeads = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id IN :new Set<Id>{ hotLead.Id, renewalLead.Id }
        ];
        for (Lead leadRecord : ownedLeads) {
            leadRecord.OwnerId = UserInfo.getUserId();
        }
        update ownedLeads;

        List<Task> leadTasks = [
            SELECT Id, OwnerId
            FROM Task
            WHERE WhoId IN :new Set<Id>{ hotLead.Id, renewalLead.Id }
        ];
        for (Task taskRecord : leadTasks) {
            taskRecord.OwnerId = UserInfo.getUserId();
        }
        if (!leadTasks.isEmpty()) {
            update leadTasks;
        }

        insert new Task(
            OwnerId = UserInfo.getUserId(),
            Subject = '연체 확인 Task',
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today().addDays(-2),
            WhoId = hotLead.Id,
            Description = '이미 기한이 지난 실무 처리용 Task',
            Sales_Task_Type__c = '초기 상담'
        );

        User approver = createUser('taskops');
        Opportunity reengagementOpportunity = createOpportunity('워크스페이스 재공략', approver.Id);
        reengagementOpportunity.StageName = '수주 실패';
        reengagementOpportunity.Lost_Reason_Primary__c = '가격';
        reengagementOpportunity.Lost_Reason_Secondary__c = '경쟁사 선택';
        reengagementOpportunity.Lost_To_Competitor__c = '코웨이';
        reengagementOpportunity.Lost_Reason_Detail__c = '재공략 필요';
        reengagementOpportunity.Reopen_Potential__c = '높음';
        update reengagementOpportunity;

        Test.startTest();
        TaskOperationsWorkspaceController.WorkspaceData data =
            TaskOperationsWorkspaceController.getWorkspaceData();
        Test.stopTest();

        Integer openMetric = findMetricValue(data.metrics, '내 미완료 Task');
        Integer slaMetric = findMetricValue(data.metrics, 'SLA 임박');
        Integer overdueMetric = findMetricValue(data.metrics, '연체 Task');
        Integer renewalMetric = findMetricValue(data.metrics, '계약 갱신');
        Integer reengagementMetric = findMetricValue(data.metrics, '재공략');

        System.assertEquals(5, data.metrics.size());
        System.assert(openMetric >= 4);
        System.assert(slaMetric >= 2);
        System.assertEquals(1, overdueMetric);
        System.assert(renewalMetric >= 1);
        System.assertEquals(1, reengagementMetric);

        System.assertEquals(openMetric, data.openTasks.size());
        System.assertEquals(slaMetric, data.slaTasks.size());
        System.assertEquals(overdueMetric, data.overdueTasks.size());
        System.assertEquals(renewalMetric, data.renewalTasks.size());
        System.assertEquals(reengagementMetric, data.reengagementTasks.size());

        System.assertEquals('워크스페이스핫', data.slaTasks[0].relatedName);
        System.assertEquals('계약 갱신', data.renewalTasks[0].salesTaskType);
        System.assertEquals('재공략', data.reengagementTasks[0].salesTaskType);
        System.assert(data.reengagementTasks[0].description.contains('재공략 가능성: 높음'));
    }

    private static Integer findMetricValue(
        List<TaskOperationsWorkspaceController.KpiCard> metrics,
        String targetLabel
    ) {
        for (TaskOperationsWorkspaceController.KpiCard metric : metrics) {
            if (metric.label == targetLabel) {
                return metric.value;
            }
        }
        return -1;
    }

    private static Opportunity createOpportunity(String name, Id approverId) {
        Account accountRecord = new Account(Name = name + ' 거래처');
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(Name = name + ' 가격표', IsActive = true);
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = name,
            AccountId = accountRecord.Id,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(14),
            Pricebook2Id = pricebookRecord.Id,
            Quote_Approver__c = approverId,
            Business_Verified__c = true,
            Business_Number__c = '123-45-67890'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static User createUser(String aliasSeed) {
        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
        ];

        String uniqueToken = String.valueOf(DateTime.now().getTime());
        User userRecord = new User(
            Alias = aliasSeed.length() > 8 ? aliasSeed.substring(0, 8) : aliasSeed,
            Email = aliasSeed + '.' + uniqueToken + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = '업무담당자',
            LanguageLocaleKey = 'ko',
            LocaleSidKey = 'ko_KR',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'Asia/Seoul',
            Username = aliasSeed + '.' + uniqueToken + '@example.com'
        );
        insert userRecord;
        return userRecord;
    }
}
