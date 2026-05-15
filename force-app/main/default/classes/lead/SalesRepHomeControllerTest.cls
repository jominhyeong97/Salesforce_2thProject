@IsTest
private class SalesRepHomeControllerTest {
    @IsTest
    static void returnsExpandedSalesSummaryForCurrentRep() {
        Lead hotLead = new Lead(
            OwnerId = UserInfo.getUserId(),
            LastName = '핫홈',
            Company = '핫홈 주식회사',
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
            LastName = '갱신홈',
            Company = '갱신홈 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '렌탈 유지 검토',
            Inquiry_Intent__c = '제품 문의',
            Purchase_Timeline__c = '6개월 이후',
            Current_Contract_End_Date__c = Date.today().addDays(70),
            Geo_Region__c = '서울'
        );
        Lead quoteLead = new Lead(
            OwnerId = UserInfo.getUserId(),
            LastName = '견적홈',
            Company = '견적홈 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '비교 후 결정',
            Customer_Scenario__c = '신규 도입',
            Inquiry_Intent__c = '견적 요청',
            Desired_Rental_Budget__c = '10만-20만원',
            Purchase_Timeline__c = '3개월 이내',
            Geo_Region__c = '경기'
        );
        insert new List<Lead>{ hotLead, renewalLead, quoteLead };

        List<Lead> ownedLeads = [
            SELECT Id, OwnerId
            FROM Lead
            WHERE Id IN :new Set<Id>{ hotLead.Id, renewalLead.Id, quoteLead.Id }
        ];
        for (Lead leadRecord : ownedLeads) {
            leadRecord.OwnerId = UserInfo.getUserId();
        }
        update ownedLeads;

        List<Task> leadTasks = [
            SELECT Id, OwnerId
            FROM Task
            WHERE WhoId IN :new Set<Id>{ hotLead.Id, renewalLead.Id, quoteLead.Id }
        ];
        for (Task taskRecord : leadTasks) {
            taskRecord.OwnerId = UserInfo.getUserId();
        }
        if (!leadTasks.isEmpty()) {
            update leadTasks;
        }

        Account contractAccount = new Account(Name = '계약 종료 거래처');
        insert contractAccount;

        Contract expiringContract = new Contract(
            AccountId = contractAccount.Id,
            StartDate = Date.today().addDays(-345),
            ContractTerm = 12,
            Status = 'Draft'
        );
        insert expiringContract;

        User approver = createUser('homeappr');
        Opportunity approvalOpportunity = createOpportunity('홈 승인 대기', approver.Id);
        Quote approvalQuote = createQuote(
            approvalOpportunity.Id,
            QuoteApprovalService.QUOTE_STATUS_REQUEST
        );
        insert new Quote_Approval_Request__c(
            OpporTunity__c = approvalOpportunity.Id,
            Quote__c = approvalQuote.Id,
            Requester__c = UserInfo.getUserId(),
            Approver__c = approver.Id,
            Status__c = QuoteApprovalService.STATUS_PENDING,
            Request_Detail__c = '이번 달 견적 결재 대기',
            Requested_At__c = System.now()
        );

        Opportunity reengagementOpportunity = createOpportunity('홈 재공략', approver.Id);
        reengagementOpportunity.StageName = '수주 실패';
        reengagementOpportunity.Lost_Reason_Primary__c = '가격';
        reengagementOpportunity.Lost_Reason_Secondary__c = '경쟁사 선택';
        reengagementOpportunity.Lost_To_Competitor__c = '청호나이스';
        reengagementOpportunity.Lost_Reason_Detail__c = '재공략으로 다시 제안할 여지가 있습니다.';
        reengagementOpportunity.Reopen_Potential__c = '높음';
        update reengagementOpportunity;

        Test.startTest();
        SalesRepHomeController.DashboardData data = SalesRepHomeController.getDashboardData();
        SalesRepHomeController.LeadManagementData leadManagementData =
            SalesRepHomeController.getLeadManagementData();
        SalesRepHomeController.TaskManagementData taskManagementData =
            SalesRepHomeController.getTaskManagementData();
        SalesRepHomeController.ContractManagementData contractManagementData =
            SalesRepHomeController.getContractManagementData();
        Test.stopTest();

        System.assertEquals(6, data.metrics.size());
        System.assertEquals(1, findMetricValue(data.metrics, '오늘 처리할 Hot Lead'));
        System.assertEquals(1, findMetricValue(data.metrics, 'SLA 임박 Task'));
        System.assertEquals(1, findMetricValue(data.metrics, '계약 종료 30일'));
        System.assertEquals(1, findMetricValue(data.metrics, '이번 달 승인 대기'));
        System.assertEquals(1, findMetricValue(data.metrics, '재공략 예정'));
        System.assertEquals(3, findMetricValue(data.metrics, '이번 달 리드 유입'));

        System.assertEquals(1, data.hotLeads.size());
        System.assertEquals('전략 영업', data.hotLeads[0].routingGroup);

        System.assert(data.slaTasks.size() >= 1, '7일 이내 미완료 Task가 1건 이상이어야 합니다.');
        Boolean hotLeadTaskFound = false;
        for (SalesRepHomeController.TaskRow taskRow : data.slaTasks) {
            if (taskRow.relatedName == '핫홈') {
                hotLeadTaskFound = true;
                break;
            }
        }
        System.assert(hotLeadTaskFound, '핫홈 리드의 Task가 slaTasks에 포함되어야 합니다.');

        System.assertEquals(1, data.expiringContracts.size());
        System.assertNotEquals(null, data.expiringContracts[0].endDate);
        System.assert(data.expiringContracts[0].endDate >= Date.today());
        System.assert(data.expiringContracts[0].endDate <= Date.today().addDays(60));

        System.assertEquals(1, data.pendingApprovals.size());
        System.assertEquals('홈 승인 대기', data.pendingApprovals[0].opportunityName);

        System.assertEquals(1, data.reengagementTasks.size());
        System.assertEquals('재공략', data.reengagementTasks[0].salesTaskType);

        System.assertEquals(2, data.regionalInflows.size());
        System.assertEquals('서울', data.regionalInflows[0].region);
        System.assertEquals(2, data.regionalInflows[0].leadCount);

        System.assertEquals(4, leadManagementData.metrics.size());
        System.assertEquals(1, findMetricValue(leadManagementData.metrics, 'Hot Lead'));
        System.assertEquals(1, leadManagementData.hotLeads.size());
        System.assertEquals(1, leadManagementData.quoteFollowUps.size());
        System.assertEquals(2, leadManagementData.regionalInflows.size());

        System.assertEquals(2, taskManagementData.metrics.size());
        System.assert(
            findMetricValue(taskManagementData.metrics, '7일 이내 마감') >= 1,
            '7일 이내 마감 Task KPI가 1 이상이어야 합니다.'
        );
        System.assert(taskManagementData.slaTasks.size() >= 1, '7일 이내 Task가 1건 이상이어야 합니다.');
        System.assertEquals(1, taskManagementData.reengagementTasks.size());

        System.assertEquals(2, contractManagementData.metrics.size());
        System.assertEquals(1, findMetricValue(contractManagementData.metrics, '종료 60일'));
        System.assertEquals(1, contractManagementData.expiringContracts.size());
        System.assertEquals(1, contractManagementData.pendingApprovals.size());
        System.assertEquals('Renewals Next 60 Days', contractManagementData.renewalListViewLabel);
    }

    private static Integer findMetricValue(
        List<SalesRepHomeController.KpiCard> metrics,
        String targetLabel
    ) {
        for (SalesRepHomeController.KpiCard metric : metrics) {
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

    private static Quote createQuote(Id opportunityId, String statusValue) {
        Quote quoteRecord = new Quote(
            Name = '홈 대시보드 견적',
            OpportunityId = opportunityId,
            Status = statusValue,
            ExpirationDate = Date.today().addDays(30)
        );
        insert quoteRecord;
        return quoteRecord;
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
            LastName = '홈결재자',
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
