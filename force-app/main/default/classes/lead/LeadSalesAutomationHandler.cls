public class LeadSalesAutomationHandler {
    @TestVisible
    private static final String PRIORITY_HOT = 'Hot';
    @TestVisible
    private static final String PRIORITY_WARM = 'Warm';
    @TestVisible
    private static final String PRIORITY_COLD = 'Cold';

    @TestVisible
    private static final String CONTRACT_WINDOW_UNKNOWN = '미입력';
    @TestVisible
    private static final String CONTRACT_WINDOW_EXPIRED = '종료 지남';
    @TestVisible
    private static final String CONTRACT_WINDOW_30 = '30일 이내';
    @TestVisible
    private static final String CONTRACT_WINDOW_60 = '31-60일';
    @TestVisible
    private static final String CONTRACT_WINDOW_90 = '61-90일';
    @TestVisible
    private static final String CONTRACT_WINDOW_OVER_90 = '90일 초과';

    @TestVisible
    private static final String ACTION_INITIAL = '초기 상담';
    @TestVisible
    private static final String ACTION_COMPETITOR = '경쟁사 교체 제안';
    @TestVisible
    private static final String ACTION_RENEWAL = '렌탈 갱신';
    @TestVisible
    private static final String ACTION_CONVERSION = '구매 전환';
    @TestVisible
    private static final String ACTION_LARGE_SITE = '대형 설치 검토';
    @TestVisible
    private static final String ACTION_QUOTE_FOLLOW_UP = '견적 후속';

    @TestVisible
    private static final String CONSULT_INITIAL = '초기 상담';
    @TestVisible
    private static final String CONSULT_QUOTE = '견적 상담';
    @TestVisible
    private static final String CONSULT_DEMO = '데모 상담';
    @TestVisible
    private static final String CONSULT_TECHNICAL = '기술 상담';
    @TestVisible
    private static final String CONSULT_PARTNER = '파트너 상담';
    @TestVisible
    private static final String CONSULT_COMPETITOR = '경쟁사 교체 상담';
    @TestVisible
    private static final String CONSULT_RENEWAL = '렌탈 갱신 상담';
    @TestVisible
    private static final String CONSULT_CONVERSION = '구매 전환 상담';
    @TestVisible
    private static final String CONSULT_LARGE_SITE = '대형 설치 상담';

    @TestVisible
    private static final String ROUTING_INBOUND = '인바운드';
    @TestVisible
    private static final String ROUTING_INSIDE_SALES = '인사이드 세일즈';
    @TestVisible
    private static final String ROUTING_RETENTION = '리텐션';
    @TestVisible
    private static final String ROUTING_STRATEGIC = '전략 영업';
    @TestVisible
    private static final String ROUTING_ENTERPRISE = '엔터프라이즈';
    @TestVisible
    private static final String ROUTING_PARTNER = '파트너';

    private static final String HOT_NOTIFICATION_DEVELOPER_NAME = 'Hot_Lead_Notification';
    private static final Integer HOT_SCORE_THRESHOLD = 80;
    private static final Integer WARM_SCORE_THRESHOLD = 55;
    private static final Integer HOT_TASK_DAYS = 1;
    private static final Integer WARM_TASK_DAYS = 3;
    private static final Integer RENEWAL_WATCH_TASK_DAYS = 7;

    public static void beforeInsertOrUpdate(List<Lead> newRecords) {
        beforeInsertOrUpdate(newRecords, null);
    }

    public static void beforeInsertOrUpdate(List<Lead> newRecords, Map<Id, Lead> oldMap) {
        applyPersonalCompanyNames(newRecords, oldMap);
        AquaPricingSupport.prepareLeads(newRecords);
        List<User> assignableUsers = loadAssignableUsers();

        for (Lead leadRecord : newRecords) {
            Integer leadScore = determineLeadScore(leadRecord);
            String contractWindow =
                determineContractEndWindow(leadRecord.Current_Contract_End_Date__c);

            leadRecord.Lead_Score__c = leadScore;
            leadRecord.Sales_Priority__c = determineSalesPriority(leadScore);
            leadRecord.Contract_End_Window__c = contractWindow;
            leadRecord.Consultation_Type__c = determineConsultationType(leadRecord, contractWindow);
            leadRecord.Sales_Routing_Group__c = determineRoutingGroup(leadRecord, contractWindow);
            leadRecord.Sales_Action_Summary__c = buildLeadActionSummary(
                leadRecord,
                contractWindow
            );

            if (shouldAssignOwner(leadRecord)) {
                Id assignedOwnerId = determineOwnerId(leadRecord, assignableUsers);
                if (assignedOwnerId != null) {
                    leadRecord.OwnerId = assignedOwnerId;
                }
            }
        }
    }

    private static void applyPersonalCompanyNames(
        List<Lead> newRecords,
        Map<Id, Lead> oldMap
    ) {
        for (Lead leadRecord : newRecords) {
            Lead oldLead = oldMap == null ? null : oldMap.get(leadRecord.Id);
            if (!shouldMaintainPersonalCompanyName(leadRecord, oldLead)) {
                continue;
            }

            String leadName = buildLeadDisplayName(leadRecord);
            if (!String.isBlank(leadName)) {
                leadRecord.Company = CustomerIdentitySupport.buildPersonalCompanyName(leadName);
            }
        }
    }

    private static Boolean shouldMaintainPersonalCompanyName(Lead leadRecord, Lead oldLead) {
        if (CustomerIdentitySupport.isPersonalCompanyName(leadRecord.Company)) {
            return true;
        }

        if (oldLead == null || !CustomerIdentitySupport.isPersonalCompanyName(oldLead.Company)) {
            return false;
        }

        String normalizedNewCompany = normalizeCompanyName(leadRecord.Company);
        String normalizedOldCompany = normalizeCompanyName(oldLead.Company);
        return String.isBlank(normalizedNewCompany) || normalizedNewCompany == normalizedOldCompany;
    }

    private static String buildLeadDisplayName(Lead leadRecord) {
        List<String> nameSegments = new List<String>();
        if (!String.isBlank(leadRecord.FirstName)) {
            nameSegments.add(leadRecord.FirstName.trim());
        }
        if (!String.isBlank(leadRecord.LastName)) {
            nameSegments.add(leadRecord.LastName.trim());
        }

        String resolvedName = String.join(nameSegments, ' ').trim();
        if (String.isBlank(resolvedName) && !String.isBlank(leadRecord.Name)) {
            resolvedName = leadRecord.Name.trim();
        }
        return resolvedName;
    }

    private static String normalizeCompanyName(String companyName) {
        return String.isBlank(companyName) ? null : companyName.trim();
    }

    public static void afterInsertOrUpdate(List<Lead> newRecords, Map<Id, Lead> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        List<Lead> hotLeads = new List<Lead>();

        for (Lead leadRecord : newRecords) {
            if (shouldCreateSalesTask(leadRecord, oldMap) &&
                SalesTaskSupport.isUserId(leadRecord.OwnerId)) {
                tasksToInsert.add(buildSalesTask(leadRecord));
            }

            if (isTransitioningToHot(leadRecord, oldMap)) {
                hotLeads.add(leadRecord);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }

        sendHotLeadNotifications(hotLeads);
    }

    @TestVisible
    private static Integer determineLeadScore(Lead leadRecord) {
        Integer score = 0;
        score += getIntentScore(leadRecord.Inquiry_Intent__c);
        score += getTimelineScore(leadRecord.Purchase_Timeline__c);
        score += getBudgetScore(leadRecord);
        score += getScenarioScore(leadRecord.Customer_Scenario__c);
        score += getContractScore(leadRecord.Current_Contract_End_Date__c);
        score += getScaleScore(leadRecord);
        return Math.min(score, 100);
    }

    @TestVisible
    private static String determineSalesPriority(Integer leadScore) {
        if (leadScore >= HOT_SCORE_THRESHOLD) {
            return PRIORITY_HOT;
        }
        if (leadScore >= WARM_SCORE_THRESHOLD) {
            return PRIORITY_WARM;
        }
        return PRIORITY_COLD;
    }

    @TestVisible
    private static String determineContractEndWindow(Date contractEndDate) {
        if (contractEndDate == null) {
            return CONTRACT_WINDOW_UNKNOWN;
        }

        Integer daysUntilContractEnd = Date.today().daysBetween(contractEndDate);
        if (daysUntilContractEnd < 0) {
            return CONTRACT_WINDOW_EXPIRED;
        }
        if (daysUntilContractEnd <= 30) {
            return CONTRACT_WINDOW_30;
        }
        if (daysUntilContractEnd <= 60) {
            return CONTRACT_WINDOW_60;
        }
        if (daysUntilContractEnd <= 90) {
            return CONTRACT_WINDOW_90;
        }
        return CONTRACT_WINDOW_OVER_90;
    }

    @TestVisible
    private static String determineActionType(Lead leadRecord) {
        String contractWindow = coalesce(
            leadRecord.Contract_End_Window__c,
            determineContractEndWindow(leadRecord.Current_Contract_End_Date__c)
        );
        String consultationType = determineConsultationType(leadRecord, contractWindow);

        if (consultationType == CONSULT_CONVERSION) {
            return ACTION_CONVERSION;
        }
        if (consultationType == CONSULT_COMPETITOR) {
            return ACTION_COMPETITOR;
        }
        if (consultationType == CONSULT_RENEWAL) {
            return ACTION_RENEWAL;
        }
        if (consultationType == CONSULT_LARGE_SITE) {
            return ACTION_LARGE_SITE;
        }
        if (leadRecord.Inquiry_Intent__c == '견적 요청') {
            return ACTION_QUOTE_FOLLOW_UP;
        }
        return ACTION_INITIAL;
    }

    @TestVisible
    private static String determineConsultationType(Lead leadRecord, String contractWindow) {
        if (leadRecord.Inquiry_Intent__c == '파트너 문의') {
            return CONSULT_PARTNER;
        }
        if (leadRecord.Customer_Scenario__c == '렌탈→구매 전환') {
            return CONSULT_CONVERSION;
        }
        if (leadRecord.Customer_Scenario__c == '경쟁사 교체') {
            return CONSULT_COMPETITOR;
        }
        if (leadRecord.Sales_Model__c == '렌탈' &&
            isRenewalWindow(contractWindow)) {
            return CONSULT_RENEWAL;
        }
        if (isLargeSiteLead(leadRecord)) {
            return CONSULT_LARGE_SITE;
        }
        if (leadRecord.Inquiry_Intent__c == '견적 요청') {
            return CONSULT_QUOTE;
        }
        if (leadRecord.Inquiry_Intent__c == '데모 요청') {
            return CONSULT_DEMO;
        }
        if (leadRecord.Inquiry_Intent__c == '기술 문의') {
            return CONSULT_TECHNICAL;
        }
        return CONSULT_INITIAL;
    }

    @TestVisible
    private static String determineRoutingGroup(Lead leadRecord, String contractWindow) {
        if (leadRecord.Inquiry_Intent__c == '파트너 문의') {
            return ROUTING_PARTNER;
        }
        if (leadRecord.Customer_Scenario__c == '렌탈→구매 전환' ||
            leadRecord.Customer_Scenario__c == '경쟁사 교체') {
            return ROUTING_STRATEGIC;
        }
        if (isLargeSiteLead(leadRecord)) {
            return ROUTING_ENTERPRISE;
        }
        if (leadRecord.Sales_Model__c == '렌탈' &&
            isRenewalWindow(contractWindow)) {
            return ROUTING_RETENTION;
        }
        if (leadRecord.Inquiry_Intent__c == '견적 요청' ||
            leadRecord.Inquiry_Intent__c == '데모 요청' ||
            leadRecord.Sales_Priority__c == PRIORITY_HOT) {
            return ROUTING_INSIDE_SALES;
        }
        return ROUTING_INBOUND;
    }

    @TestVisible
    private static String buildLeadActionSummary(Lead leadRecord, String contractWindow) {
        List<String> segments = new List<String>();
        String consultationType = determineConsultationType(leadRecord, contractWindow);
        String routingGroup = determineRoutingGroup(leadRecord, contractWindow);

        addSummarySegment(segments, consultationType);
        addSummarySegment(segments, routingGroup + ' 배정');
        addSummarySegment(segments, leadRecord.Inquiry_Intent__c);
        addSummarySegment(segments, leadRecord.Customer_Scenario__c);
        addSummarySegment(segments, buildBudgetSnapshot(leadRecord));

        if (isKnownValue(leadRecord.Purchase_Timeline__c)) {
            segments.add(leadRecord.Purchase_Timeline__c + ' 도입 희망');
        }
        if (contractWindow != CONTRACT_WINDOW_UNKNOWN) {
            segments.add('계약 ' + contractWindow);
        }
        if (!String.isBlank(leadRecord.Competitor_In_Use__c)) {
            segments.add('경쟁사 ' + leadRecord.Competitor_In_Use__c);
        }
        if (!String.isBlank(leadRecord.Pain_Points__c)) {
            segments.add('이슈 ' + SalesTaskSupport.truncateValue(leadRecord.Pain_Points__c, 60));
        }
        return SalesTaskSupport.truncateValue(String.join(segments, ' / '), 1000);
    }

    private static Integer getIntentScore(String inquiryIntent) {
        if (inquiryIntent == '견적 요청') {
            return 35;
        }
        if (inquiryIntent == '데모 요청') {
            return 25;
        }
        if (inquiryIntent == '제품 문의') {
            return 18;
        }
        if (inquiryIntent == '기술 문의' || inquiryIntent == '파트너 문의') {
            return 12;
        }
        return 5;
    }

    private static Integer getTimelineScore(String purchaseTimeline) {
        if (purchaseTimeline == '즉시') {
            return 30;
        }
        if (purchaseTimeline == '1개월 이내') {
            return 25;
        }
        if (purchaseTimeline == '3개월 이내') {
            return 15;
        }
        if (purchaseTimeline == '6개월 이내') {
            return 8;
        }
        if (purchaseTimeline == '6개월 이후') {
            return 3;
        }
        return 0;
    }

    private static Integer getBudgetScore(Lead leadRecord) {
        if (isHighBudgetLead(leadRecord)) {
            return 15;
        }
        if (hasKnownBudget(leadRecord)) {
            return 8;
        }
        return 0;
    }

    private static Integer getScenarioScore(String customerScenario) {
        if (customerScenario == '경쟁사 교체' || customerScenario == '렌탈→구매 전환') {
            return 15;
        }
        if (customerScenario == '렌탈 유지 검토') {
            return 10;
        }
        if (customerScenario == '추가 설치') {
            return 10;
        }
        if (customerScenario == '신규 도입') {
            return 8;
        }
        return 0;
    }

    private static Integer getContractScore(Date contractEndDate) {
        String contractWindow = determineContractEndWindow(contractEndDate);
        if (contractWindow == CONTRACT_WINDOW_EXPIRED ||
            contractWindow == CONTRACT_WINDOW_30) {
            return 20;
        }
        if (contractWindow == CONTRACT_WINDOW_60) {
            return 12;
        }
        if (contractWindow == CONTRACT_WINDOW_90) {
            return 6;
        }
        return 0;
    }

    private static Integer getScaleScore(Lead leadRecord) {
        if (isEnterpriseLead(leadRecord)) {
            return 10;
        }
        if (leadRecord.Estimated_Unit_Count__c != null && leadRecord.Estimated_Unit_Count__c >= 2) {
            return 5;
        }
        return 0;
    }

    private static Boolean hasKnownBudget(Lead leadRecord) {
        return isKnownValue(leadRecord.Desired_Rental_Budget__c) ||
            isKnownValue(leadRecord.Desired_Purchase_Budget__c) ||
            isKnownValue(leadRecord.Budget_Range__c);
    }

    private static Boolean isHighBudgetLead(Lead leadRecord) {
        return leadRecord.Desired_Rental_Budget__c == '10만-20만원' ||
            leadRecord.Desired_Rental_Budget__c == '20만원 이상' ||
            leadRecord.Desired_Purchase_Budget__c == '100만-300만원' ||
            leadRecord.Desired_Purchase_Budget__c == '300만원 이상' ||
            leadRecord.Budget_Range__c == '1천만-5천만원' ||
            leadRecord.Budget_Range__c == '5천만-1억원' ||
            leadRecord.Budget_Range__c == '1억원 이상';
    }

    private static Boolean isKnownValue(String value) {
        return !String.isBlank(value) && value != '미정';
    }

    private static Boolean isEnterpriseLead(Lead leadRecord) {
        return leadRecord.Customer_Scenario__c == '렌탈→구매 전환' ||
            isLargeSiteLead(leadRecord);
    }

    private static Boolean isLargeSiteLead(Lead leadRecord) {
        return leadRecord.Sales_Model__c == '구매' ||
            leadRecord.Desired_Product_Type__c == '대용량' ||
            (leadRecord.Estimated_Unit_Count__c != null && leadRecord.Estimated_Unit_Count__c >= 3);
    }

    private static Boolean shouldAssignOwner(Lead leadRecord) {
        return !SalesTaskSupport.isUserId(leadRecord.OwnerId);
    }

    private static Id determineOwnerId(Lead leadRecord, List<User> assignableUsers) {
        if (assignableUsers.isEmpty()) {
            return leadRecord.OwnerId;
        }

        Integer ownerIndex = determineOwnerIndex(
            coalesce(
                leadRecord.Sales_Routing_Group__c,
                determineRoutingGroup(leadRecord, leadRecord.Contract_End_Window__c)
            ),
            assignableUsers.size()
        );
        return assignableUsers[ownerIndex].Id;
    }

    @TestVisible
    private static Integer determineOwnerIndex(String routingGroup, Integer userCount) {
        if (userCount == null || userCount <= 1) {
            return 0;
        }
        if (routingGroup == ROUTING_INSIDE_SALES) {
            return Math.min(1, userCount - 1);
        }
        if (routingGroup == ROUTING_STRATEGIC) {
            return Math.min(2, userCount - 1);
        }
        if (routingGroup == ROUTING_ENTERPRISE || routingGroup == ROUTING_PARTNER) {
            return userCount - 1;
        }
        return 0;
    }

    private static List<User> loadAssignableUsers() {
        List<User> filteredUsers = new List<User>();
        for (User userRecord : [
            SELECT Id, Name
            FROM User
            WHERE IsActive = true
            ORDER BY Name
        ]) {
            if (isBusinessUser(userRecord.Name)) {
                filteredUsers.add(userRecord);
            }
        }

        if (filteredUsers.isEmpty()) {
            filteredUsers.add([
                SELECT Id, Name
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ]);
        }
        return filteredUsers;
    }

    private static Boolean isBusinessUser(String userName) {
        if (String.isBlank(userName)) {
            return false;
        }

        String normalizedUserName = userName.toLowerCase();
        return !normalizedUserName.contains('chatter') &&
            !normalizedUserName.contains('data.com') &&
            !normalizedUserName.contains('integration') &&
            !normalizedUserName.contains('process') &&
            !normalizedUserName.contains('security');
    }

    private static Boolean isTransitioningToActionablePriority(
        Lead leadRecord,
        Map<Id, Lead> oldMap
    ) {
        if (!isActionablePriority(leadRecord.Sales_Priority__c)) {
            return false;
        }

        if (oldMap == null || !oldMap.containsKey(leadRecord.Id)) {
            return true;
        }

        Lead oldLead = oldMap.get(leadRecord.Id);
        return oldLead == null || oldLead.Sales_Priority__c != leadRecord.Sales_Priority__c;
    }

    private static Boolean shouldCreateSalesTask(Lead leadRecord, Map<Id, Lead> oldMap) {
        if (isActionablePriority(leadRecord.Sales_Priority__c)) {
            return isTransitioningToActionablePriority(leadRecord, oldMap);
        }
        if (isRenewalWatchLead(leadRecord)) {
            return isTransitioningToRenewalWatch(leadRecord, oldMap);
        }
        return false;
    }

    private static Boolean isTransitioningToRenewalWatch(Lead leadRecord, Map<Id, Lead> oldMap) {
        if (!isRenewalWatchLead(leadRecord)) {
            return false;
        }

        if (oldMap == null || !oldMap.containsKey(leadRecord.Id)) {
            return true;
        }

        Lead oldLead = oldMap.get(leadRecord.Id);
        return oldLead == null ||
            !isRenewalWatchLead(oldLead) ||
            oldLead.Contract_End_Window__c != leadRecord.Contract_End_Window__c ||
            oldLead.Sales_Model__c != leadRecord.Sales_Model__c;
    }

    private static Boolean isTransitioningToHot(Lead leadRecord, Map<Id, Lead> oldMap) {
        if (leadRecord.Sales_Priority__c != PRIORITY_HOT) {
            return false;
        }

        if (oldMap == null || !oldMap.containsKey(leadRecord.Id)) {
            return true;
        }

        Lead oldLead = oldMap.get(leadRecord.Id);
        return oldLead == null || oldLead.Sales_Priority__c != PRIORITY_HOT;
    }

    private static Boolean isActionablePriority(String salesPriority) {
        return salesPriority == PRIORITY_HOT || salesPriority == PRIORITY_WARM;
    }

    private static Boolean isRenewalWatchLead(Lead leadRecord) {
        if (leadRecord == null ||
            isActionablePriority(leadRecord.Sales_Priority__c) ||
            leadRecord.Sales_Model__c != '렌탈') {
            return false;
        }

        return leadRecord.Contract_End_Window__c == CONTRACT_WINDOW_60 ||
            leadRecord.Contract_End_Window__c == CONTRACT_WINDOW_90;
    }

    private static Boolean isRenewalWindow(String contractWindow) {
        return contractWindow == CONTRACT_WINDOW_EXPIRED ||
            contractWindow == CONTRACT_WINDOW_30 ||
            contractWindow == CONTRACT_WINDOW_60 ||
            contractWindow == CONTRACT_WINDOW_90;
    }

    private static Task buildSalesTask(Lead leadRecord) {
        String actionType = determineActionType(leadRecord);
        String salesTaskType = determineSalesTaskType(leadRecord);
        Integer slaDays = determineSlaDays(leadRecord);

        Task taskRecord = new Task();
        taskRecord.OwnerId = leadRecord.OwnerId;
        taskRecord.WhoId = leadRecord.Id;
        taskRecord.Subject = SalesTaskSupport.truncateValue(
            salesTaskType + ' - ' + coalesce(leadRecord.Company, leadRecord.LastName),
            255
        );
        taskRecord.Priority = SalesTaskSupport.resolveTaskPriority(
            leadRecord.Sales_Priority__c == PRIORITY_HOT ? 'High' : 'Normal'
        );
        taskRecord.Status = SalesTaskSupport.resolveTaskStatus();
        taskRecord.ActivityDate = Date.today().addDays(slaDays);
        SalesTaskSupport.applyTaskTypes(taskRecord, salesTaskType);
        taskRecord.Description = buildTaskDescription(leadRecord, salesTaskType, actionType, slaDays);
        return taskRecord;
    }

    @TestVisible
    private static String determineSalesTaskType(Lead leadRecord) {
        String contractWindow = coalesce(
            leadRecord.Contract_End_Window__c,
            determineContractEndWindow(leadRecord.Current_Contract_End_Date__c)
        );
        String consultationType = determineConsultationType(leadRecord, contractWindow);

        if (consultationType == CONSULT_CONVERSION) {
            return SalesTaskSupport.TASK_TYPE_PURCHASE_CONVERSION;
        }
        if (consultationType == CONSULT_RENEWAL) {
            return SalesTaskSupport.TASK_TYPE_CONTRACT_RENEWAL;
        }
        if (leadRecord.Inquiry_Intent__c == '견적 요청') {
            return SalesTaskSupport.TASK_TYPE_QUOTE_FOLLOW_UP;
        }
        return SalesTaskSupport.TASK_TYPE_INITIAL;
    }

    private static Integer determineSlaDays(Lead leadRecord) {
        if (leadRecord.Sales_Priority__c == PRIORITY_HOT) {
            return HOT_TASK_DAYS;
        }
        if (leadRecord.Sales_Priority__c == PRIORITY_WARM) {
            return WARM_TASK_DAYS;
        }
        if (isRenewalWatchLead(leadRecord)) {
            return RENEWAL_WATCH_TASK_DAYS;
        }
        return WARM_TASK_DAYS;
    }

    private static String buildTaskDescription(
        Lead leadRecord,
        String salesTaskType,
        String actionType,
        Integer slaDays
    ) {
        List<String> lines = new List<String>();
        SalesTaskSupport.addLine(lines, 'Task 유형', salesTaskType);
        SalesTaskSupport.addLine(lines, '액션 유형', actionType);
        SalesTaskSupport.addLine(lines, '상담 유형', leadRecord.Consultation_Type__c);
        SalesTaskSupport.addLine(lines, '라우팅 그룹', leadRecord.Sales_Routing_Group__c);
        SalesTaskSupport.addLine(lines, 'SLA(일)', String.valueOf(slaDays));
        SalesTaskSupport.addLine(lines, '리드 점수', String.valueOf(leadRecord.Lead_Score__c));
        SalesTaskSupport.addLine(lines, '영업 우선순위', leadRecord.Sales_Priority__c);
        SalesTaskSupport.addLine(lines, '계약 종료 윈도우', leadRecord.Contract_End_Window__c);
        SalesTaskSupport.addLine(lines, '영업 액션 요약', leadRecord.Sales_Action_Summary__c);
        SalesTaskSupport.addLine(lines, '리드', leadRecord.Name);
        SalesTaskSupport.addLine(lines, '회사', leadRecord.Company);
        SalesTaskSupport.addLine(lines, '상담 방식', leadRecord.Sales_Model__c);
        SalesTaskSupport.addLine(lines, '고객 상황', leadRecord.Customer_Scenario__c);
        SalesTaskSupport.addLine(lines, '문의 목적', leadRecord.Inquiry_Intent__c);
        SalesTaskSupport.addLine(lines, '희망 제품 유형', leadRecord.Desired_Product_Type__c);
        SalesTaskSupport.addLine(
            lines,
            '예상 설치 대수',
            String.valueOf(leadRecord.Estimated_Unit_Count__c)
        );
        SalesTaskSupport.addLine(lines, '희망 렌탈 예산', leadRecord.Desired_Rental_Budget__c);
        SalesTaskSupport.addLine(lines, '희망 구매 예산', leadRecord.Desired_Purchase_Budget__c);
        SalesTaskSupport.addLine(lines, '기존 예산 범위', leadRecord.Budget_Range__c);
        SalesTaskSupport.addLine(
            lines,
            '예상 계약기간(개월)',
            stringifyDecimal(leadRecord.Expected_Rental_Term_Months__c)
        );
        SalesTaskSupport.addLine(
            lines,
            '예상 월 렌탈료',
            stringifyCurrency(leadRecord.Estimated_Monthly_Rental_Fee__c)
        );
        SalesTaskSupport.addLine(
            lines,
            '예상 구매금액',
            stringifyCurrency(leadRecord.Estimated_Purchase_Amount__c)
        );
        SalesTaskSupport.addLine(
            lines,
            '예상 총액',
            stringifyCurrency(leadRecord.Estimated_Total_Amount__c)
        );
        SalesTaskSupport.addLine(lines, '도입 희망 시점', leadRecord.Purchase_Timeline__c);
        SalesTaskSupport.addLine(
            lines,
            '현재 계약 종료일',
            SalesTaskSupport.stringifyDate(leadRecord.Current_Contract_End_Date__c)
        );
        SalesTaskSupport.addLine(lines, '현재 경쟁사', leadRecord.Competitor_In_Use__c);
        SalesTaskSupport.addLine(lines, '고객 문제점', leadRecord.Pain_Points__c);
        SalesTaskSupport.addLine(lines, '유입 채널', leadRecord.UTM_Source__c);
        SalesTaskSupport.addLine(lines, '유입 매체', leadRecord.UTM_Medium__c);
        SalesTaskSupport.addLine(lines, '캠페인', leadRecord.UTM_Campaign__c);
        SalesTaskSupport.addLine(lines, '랜딩 페이지', leadRecord.Landing_Page_URL__c);
        return String.join(lines, '\n');
    }

    private static void sendHotLeadNotifications(List<Lead> hotLeads) {
        if (hotLeads.isEmpty() || Test.isRunningTest()) {
            return;
        }

        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :HOT_NOTIFICATION_DEVELOPER_NAME
            LIMIT 1
        ];
        if (notificationTypes.isEmpty()) {
            return;
        }

        for (Lead leadRecord : hotLeads) {
            if (!SalesTaskSupport.isUserId(leadRecord.OwnerId)) {
                continue;
            }

            try {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('핫 리드 즉시 확인');
                notification.setBody(buildNotificationBody(leadRecord));
                notification.setNotificationTypeId(notificationTypes[0].Id);
                notification.setTargetId(leadRecord.Id);
                notification.send(new Set<String>{ String.valueOf(leadRecord.OwnerId) });
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.WARN,
                    'Hot lead notification was not sent: ' + ex.getMessage()
                );
            }
        }
    }

    private static String buildNotificationBody(Lead leadRecord) {
        List<String> segments = new List<String>();
        addSummarySegment(segments, leadRecord.Company);
        addSummarySegment(segments, leadRecord.Consultation_Type__c);
        addSummarySegment(segments, determineActionType(leadRecord));
        addSummarySegment(segments, leadRecord.Purchase_Timeline__c);
        addSummarySegment(segments, '점수 ' + String.valueOf(leadRecord.Lead_Score__c));

        String summary = String.join(segments, ' / ');
        if (String.isBlank(summary)) {
            summary = coalesce(leadRecord.Name, '새 핫 리드');
        }
        return SalesTaskSupport.truncateValue(summary + ' 리드가 Hot으로 분류되었습니다.', 255);
    }

    private static void addSummarySegment(List<String> segments, String value) {
        if (!String.isBlank(value) && value != 'null') {
            segments.add(value);
        }
    }

    private static String buildBudgetSnapshot(Lead leadRecord) {
        if (isKnownValue(leadRecord.Desired_Rental_Budget__c)) {
            return '렌탈 예산 ' + leadRecord.Desired_Rental_Budget__c;
        }
        if (isKnownValue(leadRecord.Desired_Purchase_Budget__c)) {
            return '구매 예산 ' + leadRecord.Desired_Purchase_Budget__c;
        }
        if (isKnownValue(leadRecord.Budget_Range__c)) {
            return '예산 ' + leadRecord.Budget_Range__c;
        }
        return null;
    }

    private static String coalesce(String primaryValue, String fallbackValue) {
        return String.isBlank(primaryValue) ? fallbackValue : primaryValue;
    }

    private static String stringifyDecimal(Decimal rawValue) {
        if (rawValue == null) {
            return null;
        }
        return rawValue.stripTrailingZeros().format();
    }

    private static String stringifyCurrency(Decimal rawValue) {
        if (rawValue == null) {
            return null;
        }
        return rawValue.setScale(0).format() + '원';
    }
}
