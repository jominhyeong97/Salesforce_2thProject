@IsTest
private class LeadSalesAutomationHandlerTest {
    @IsTest
    static void setsHotPriorityAndCreatesOneDayTaskOnInsert() {
        Lead leadRecord = new Lead(
            LastName = '핫리드',
            Company = '핫리드 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '경쟁사 교체',
            Inquiry_Intent__c = '견적 요청',
            Desired_Product_Type__c = '얼음정수기',
            Desired_Rental_Budget__c = '10만-20만원',
            Purchase_Timeline__c = '1개월 이내',
            Current_Contract_End_Date__c = Date.today().addDays(20),
            Competitor_In_Use__c = '코웨이',
            Pain_Points__c = '렌탈 비용이 높아서 대체안을 찾고 있습니다.'
        );

        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ leadRecord });
        System.assertEquals('Hot', leadRecord.Sales_Priority__c);
        System.assert(leadRecord.Lead_Score__c >= 80);
        System.assertEquals('30일 이내', leadRecord.Contract_End_Window__c);
        System.assertEquals('경쟁사 교체 상담', leadRecord.Consultation_Type__c);
        System.assertEquals('전략 영업', leadRecord.Sales_Routing_Group__c);
        System.assert(leadRecord.Sales_Action_Summary__c.contains('경쟁사 교체 상담'));
        System.assertNotEquals(null, leadRecord.OwnerId);

        Test.startTest();
        insert leadRecord;
        LeadSalesAutomationHandler.afterInsertOrUpdate(new List<Lead>{ leadRecord }, null);
        Test.stopTest();

        Task aquaTask = findAquaTask(leadRecord.Id);
        System.assertNotEquals(null, aquaTask, 'Hot 리드는 Aqua 대응 Task가 생성되어야 합니다.');
        System.assertNotEquals(null, aquaTask.Subject);
        System.assertEquals(Date.today().addDays(1), aquaTask.ActivityDate);
        System.assertEquals('견적 후속', aquaTask.Sales_Task_Type__c);
        System.assert(aquaTask.Subject.startsWith('견적 후속 - '));
        System.assert(aquaTask.Description.contains('Task 유형: 견적 후속'));
        System.assert(aquaTask.Description.contains('SLA(일): 1'));
        System.assert(aquaTask.Description.contains('영업 우선순위: Hot'));
        System.assert(aquaTask.Description.contains('상담 유형: 경쟁사 교체 상담'));
        System.assert(aquaTask.Description.contains('라우팅 그룹: 전략 영업'));
    }

    @IsTest
    static void setsWarmPriorityAndCreatesThreeDayTaskOnInsert() {
        Lead leadRecord = new Lead(
            LastName = '웜리드',
            Company = '웜리드 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '비교 후 결정',
            Customer_Scenario__c = '렌탈→구매 전환',
            Inquiry_Intent__c = '제품 문의',
            Desired_Purchase_Budget__c = '50만-100만원',
            Purchase_Timeline__c = '3개월 이내',
            Current_Contract_End_Date__c = Date.today().addDays(45)
        );

        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ leadRecord });
        System.assertEquals('Warm', leadRecord.Sales_Priority__c);
        System.assert(leadRecord.Lead_Score__c >= 55 && leadRecord.Lead_Score__c < 80);
        System.assertEquals('31-60일', leadRecord.Contract_End_Window__c);
        System.assertEquals('구매 전환 상담', leadRecord.Consultation_Type__c);
        System.assertEquals('전략 영업', leadRecord.Sales_Routing_Group__c);

        Test.startTest();
        insert leadRecord;
        LeadSalesAutomationHandler.afterInsertOrUpdate(new List<Lead>{ leadRecord }, null);
        Test.stopTest();

        Task createdTask = findAquaTask(leadRecord.Id);
        System.assertNotEquals(null, createdTask);
        System.assertNotEquals(null, createdTask.Subject);
        System.assertEquals(Date.today().addDays(3), createdTask.ActivityDate);
        System.assertEquals('구매 전환', createdTask.Sales_Task_Type__c);
        System.assert(createdTask.Description.contains('SLA(일): 3'));
        System.assert(createdTask.Description.contains('영업 우선순위: Warm'));
        System.assert(createdTask.Description.contains('상담 유형: 구매 전환 상담'));
    }

    @IsTest
    static void createsTaskWhenExistingLeadBecomesHot() {
        Lead leadRecord = new Lead(
            LastName = '콜드리드',
            Company = '콜드리드 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '신규 도입',
            Inquiry_Intent__c = '기술 문의',
            Desired_Rental_Budget__c = '미정',
            Purchase_Timeline__c = '미정'
        );
        insert leadRecord;

        leadRecord.Customer_Scenario__c = '경쟁사 교체';
        leadRecord.Inquiry_Intent__c = '견적 요청';
        leadRecord.Desired_Rental_Budget__c = '20만원 이상';
        leadRecord.Purchase_Timeline__c = '즉시';
        leadRecord.Current_Contract_End_Date__c = Date.today().addDays(10);
        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ leadRecord });

        System.assertEquals('Hot', leadRecord.Sales_Priority__c);
        System.assert(leadRecord.Lead_Score__c >= 80);
        System.assertEquals('30일 이내', leadRecord.Contract_End_Window__c);

        Test.startTest();
        update leadRecord;
        Test.stopTest();

        System.assertNotEquals(
            null,
            findAquaTask(leadRecord.Id),
            'Hot 전환 시 Aqua 대응 Task가 생성되어야 합니다.'
        );
    }

    @IsTest
    static void createsSevenDayRenewalWatchTaskForColdLead() {
        Lead leadRecord = new Lead(
            LastName = '갱신리드',
            Company = '갱신리드 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '렌탈 유지 검토',
            Inquiry_Intent__c = '제품 문의',
            Purchase_Timeline__c = '6개월 이후',
            Current_Contract_End_Date__c = Date.today().addDays(75),
            Pain_Points__c = '현재 계약이 3개월 안에 종료되어 비교 검토 예정입니다.'
        );

        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ leadRecord });
        System.assertEquals('Cold', leadRecord.Sales_Priority__c);
        System.assertEquals('61-90일', leadRecord.Contract_End_Window__c);
        System.assertEquals('렌탈 갱신 상담', leadRecord.Consultation_Type__c);
        System.assertEquals('리텐션', leadRecord.Sales_Routing_Group__c);

        Test.startTest();
        insert leadRecord;
        LeadSalesAutomationHandler.afterInsertOrUpdate(new List<Lead>{ leadRecord }, null);
        Test.stopTest();

        Task renewalTask = findAquaTask(leadRecord.Id);
        System.assertNotEquals(null, renewalTask, '갱신 관찰 리드는 Task가 생성되어야 합니다.');
        System.assertEquals(Date.today().addDays(7), renewalTask.ActivityDate);
        System.assertEquals('계약 갱신', renewalTask.Sales_Task_Type__c);
        System.assert(renewalTask.Subject.startsWith('계약 갱신 - '));
        System.assert(renewalTask.Description.contains('액션 유형: 렌탈 갱신'));
        System.assert(renewalTask.Description.contains('SLA(일): 7'));
    }

    @IsTest
    static void evaluatesDirectAquaScoringRules() {
        Lead renewalLead = new Lead(
            Sales_Model__c = '렌탈',
            Customer_Scenario__c = '렌탈 유지 검토',
            Inquiry_Intent__c = '견적 요청',
            Desired_Rental_Budget__c = '20만원 이상',
            Purchase_Timeline__c = '즉시',
            Current_Contract_End_Date__c = Date.today().addDays(5)
        );
        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ renewalLead });
        Integer renewalScore = LeadSalesAutomationHandler.determineLeadScore(renewalLead);
        System.assertEquals('Hot', LeadSalesAutomationHandler.determineSalesPriority(renewalScore));
        System.assertEquals(
            '30일 이내',
            LeadSalesAutomationHandler.determineContractEndWindow(
                renewalLead.Current_Contract_End_Date__c
            )
        );
        System.assertEquals('렌탈 갱신', LeadSalesAutomationHandler.determineActionType(renewalLead));
        System.assertEquals(
            '렌탈 갱신 상담',
            LeadSalesAutomationHandler.determineConsultationType(
                renewalLead,
                renewalLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '리텐션',
            LeadSalesAutomationHandler.determineRoutingGroup(
                renewalLead,
                renewalLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '계약 갱신',
            LeadSalesAutomationHandler.determineSalesTaskType(renewalLead)
        );

        Lead conversionLead = new Lead(
            Sales_Model__c = '비교 후 결정',
            Customer_Scenario__c = '렌탈→구매 전환',
            Inquiry_Intent__c = '제품 문의',
            Desired_Purchase_Budget__c = '50만-100만원',
            Purchase_Timeline__c = '3개월 이내',
            Current_Contract_End_Date__c = Date.today().addDays(45)
        );
        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ conversionLead });
        Integer conversionScore = LeadSalesAutomationHandler.determineLeadScore(conversionLead);
        System.assertEquals('Warm', LeadSalesAutomationHandler.determineSalesPriority(conversionScore));
        System.assertEquals('구매 전환', LeadSalesAutomationHandler.determineActionType(conversionLead));
        System.assertEquals(
            '구매 전환 상담',
            LeadSalesAutomationHandler.determineConsultationType(
                conversionLead,
                conversionLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '전략 영업',
            LeadSalesAutomationHandler.determineRoutingGroup(
                conversionLead,
                conversionLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '구매 전환',
            LeadSalesAutomationHandler.determineSalesTaskType(conversionLead)
        );

        Lead largeSiteLead = new Lead(
            Sales_Model__c = '구매',
            Customer_Scenario__c = '신규 도입',
            Inquiry_Intent__c = '제품 문의',
            Desired_Product_Type__c = '대용량',
            Desired_Purchase_Budget__c = '300만원 이상',
            Estimated_Unit_Count__c = 4,
            Purchase_Timeline__c = '6개월 이내'
        );
        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ largeSiteLead });
        System.assertEquals('대형 설치 검토', LeadSalesAutomationHandler.determineActionType(largeSiteLead));
        System.assertEquals(
            '대형 설치 상담',
            LeadSalesAutomationHandler.determineConsultationType(
                largeSiteLead,
                largeSiteLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '엔터프라이즈',
            LeadSalesAutomationHandler.determineRoutingGroup(
                largeSiteLead,
                largeSiteLead.Contract_End_Window__c
            )
        );
        System.assertEquals(
            '초기 상담',
            LeadSalesAutomationHandler.determineSalesTaskType(largeSiteLead)
        );
        System.assertEquals(
            '종료 지남',
            LeadSalesAutomationHandler.determineContractEndWindow(Date.today().addDays(-1))
        );
        System.assertEquals(
            '90일 초과',
            LeadSalesAutomationHandler.determineContractEndWindow(Date.today().addDays(120))
        );
        System.assertEquals(
            '미입력',
            LeadSalesAutomationHandler.determineContractEndWindow(null)
        );
    }

    @IsTest
    static void normalizesPersonalLeadCompanyNameOnInsert() {
        Lead leadRecord = new Lead(
            LastName = '홍길동',
            Company = '(개인) 임시값',
            Status = 'Inbound_Received',
            LeadSource = 'Web'
        );

        LeadSalesAutomationHandler.beforeInsertOrUpdate(new List<Lead>{ leadRecord });
        System.assertEquals('(개인) 홍길동', leadRecord.Company);
    }

    @IsTest
    static void refreshesPersonalLeadCompanyNameWhenLeadNameChanges() {
        Lead leadRecord = new Lead(
            LastName = '기존이름',
            Company = '(개인) 기존이름',
            Status = 'Inbound_Received',
            LeadSource = 'Web'
        );
        insert leadRecord;

        leadRecord.LastName = '변경이름';

        Test.startTest();
        update leadRecord;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Company
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];
        System.assertEquals('(개인) 변경이름', updatedLead.Company);
    }

    private static Task findAquaTask(Id leadId) {
        for (Task taskRecord : [
            SELECT Subject, ActivityDate, Description, Sales_Task_Type__c
            FROM Task
            WHERE WhoId = :leadId
            ORDER BY CreatedDate DESC
        ]) {
            if (taskRecord.Description != null &&
                taskRecord.Description.contains('액션 유형:') &&
                taskRecord.Description.contains('SLA(일):')) {
                return taskRecord;
            }
        }
        return null;
    }
}
