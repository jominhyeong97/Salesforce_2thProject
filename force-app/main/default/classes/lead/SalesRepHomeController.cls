public with sharing class SalesRepHomeController {
    private static final Integer ROW_LIMIT = 10;

    public class DashboardData {
        @AuraEnabled public List<KpiCard> metrics { get; set; }
        @AuraEnabled public List<LeadRow> hotLeads { get; set; }
        @AuraEnabled public List<LeadRow> quoteFollowUps { get; set; }
        @AuraEnabled public List<TaskRow> slaTasks { get; set; }
        @AuraEnabled public List<ContractRow> expiringContracts { get; set; }
        @AuraEnabled public List<ApprovalRow> pendingApprovals { get; set; }
        @AuraEnabled public List<TaskRow> reengagementTasks { get; set; }
        @AuraEnabled public List<RegionRow> regionalInflows { get; set; }
    }

    public class LeadManagementData {
        @AuraEnabled public List<KpiCard> metrics { get; set; }
        @AuraEnabled public List<LeadRow> hotLeads { get; set; }
        @AuraEnabled public List<LeadRow> warmLeads { get; set; }
        @AuraEnabled public List<LeadRow> quoteFollowUps { get; set; }
        @AuraEnabled public List<RegionRow> regionalInflows { get; set; }
    }

    public class TaskManagementData {
        @AuraEnabled public List<KpiCard> metrics { get; set; }
        @AuraEnabled public List<TaskRow> slaTasks { get; set; }
        @AuraEnabled public List<TaskRow> reengagementTasks { get; set; }
    }

    public class ContractManagementData {
        @AuraEnabled public List<KpiCard> metrics { get; set; }
        @AuraEnabled public List<ContractRow> expiringContracts { get; set; }
        @AuraEnabled public List<ApprovalRow> pendingApprovals { get; set; }
        @AuraEnabled public String renewalListViewLabel { get; set; }
    }

    public class OpportunityContractKpiData {
        @AuraEnabled public List<KpiCard> opportunityMetrics { get; set; }
        @AuraEnabled public List<KpiCard> contractMetrics { get; set; }
    }

    public class KpiCard {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer value { get; set; }
        @AuraEnabled public String helperText { get; set; }
        @AuraEnabled public String theme { get; set; }

        public KpiCard(String label, Integer value, String helperText, String theme) {
            this.label = label;
            this.value = value;
            this.helperText = helperText;
            this.theme = theme;
        }
    }

    public class LeadRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String company { get; set; }
        @AuraEnabled public Integer leadScore { get; set; }
        @AuraEnabled public String salesPriority { get; set; }
        @AuraEnabled public String consultationType { get; set; }
        @AuraEnabled public String routingGroup { get; set; }
        @AuraEnabled public String contractEndWindow { get; set; }
        @AuraEnabled public Date contractEndDate { get; set; }
        @AuraEnabled public String salesActionSummary { get; set; }
        @AuraEnabled public String recordUrl { get; set; }

        public LeadRow(Lead leadRecord) {
            this.id = leadRecord.Id;
            this.name = leadRecord.Name;
            this.company = leadRecord.Company;
            this.leadScore = leadRecord.Lead_Score__c == null
                ? null
                : leadRecord.Lead_Score__c.intValue();
            this.salesPriority = leadRecord.Sales_Priority__c;
            this.consultationType = leadRecord.Consultation_Type__c;
            this.routingGroup = leadRecord.Sales_Routing_Group__c;
            this.contractEndWindow = leadRecord.Contract_End_Window__c;
            this.contractEndDate = leadRecord.Current_Contract_End_Date__c;
            this.salesActionSummary = leadRecord.Sales_Action_Summary__c;
            this.recordUrl = buildRecordUrl('Lead', leadRecord.Id);
        }
    }

    public class TaskRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String salesTaskType { get; set; }
        @AuraEnabled public String relatedName { get; set; }
        @AuraEnabled public String company { get; set; }
        @AuraEnabled public String recordUrl { get; set; }
        @AuraEnabled public String relatedRecordUrl { get; set; }

        public TaskRow(
            Task taskRecord,
            String relatedName,
            String company,
            String relatedRecordUrl
        ) {
            this.id = taskRecord.Id;
            this.subject = taskRecord.Subject;
            this.activityDate = taskRecord.ActivityDate;
            this.priority = taskRecord.Priority;
            this.status = taskRecord.Status;
            this.salesTaskType = taskRecord.Sales_Task_Type__c;
            this.relatedName = relatedName;
            this.company = company;
            this.recordUrl = buildRecordUrl('Task', taskRecord.Id);
            this.relatedRecordUrl = relatedRecordUrl;
        }
    }

    public class ContractRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String contractNumber { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date endDate { get; set; }
        @AuraEnabled public String recordUrl { get; set; }

        public ContractRow(Contract contractRecord) {
            this.id = contractRecord.Id;
            this.contractNumber = contractRecord.ContractNumber;
            this.name = contractRecord.ContractNumber;
            this.accountName = contractRecord.Account == null ? null : contractRecord.Account.Name;
            this.status = contractRecord.Status;
            this.endDate = contractRecord.EndDate;
            this.recordUrl = buildRecordUrl('Contract', contractRecord.Id);
        }
    }

    public class ApprovalRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String approvalRequestName { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public String quoteName { get; set; }
        @AuraEnabled public String approverName { get; set; }
        @AuraEnabled public Datetime requestedAt { get; set; }
        @AuraEnabled public String recordUrl { get; set; }

        public ApprovalRow(Quote_Approval_Request__c approvalRequest) {
            this.id = approvalRequest.Id;
            this.approvalRequestName = approvalRequest.Name;
            this.opportunityName = approvalRequest.OpporTunity__r == null
                ? null
                : approvalRequest.OpporTunity__r.Name;
            this.quoteName = approvalRequest.Quote__r == null ? null : approvalRequest.Quote__r.Name;
            this.approverName = approvalRequest.Approver__r == null
                ? null
                : approvalRequest.Approver__r.Name;
            this.requestedAt = approvalRequest.Requested_At__c;
            this.recordUrl = buildRecordUrl('Quote_Approval_Request__c', approvalRequest.Id);
        }
    }

    public class RegionRow {
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public Integer leadCount { get; set; }

        public RegionRow(String region, Integer leadCount) {
            this.region = String.isBlank(region) ? '미분류' : region;
            this.leadCount = leadCount;
        }
    }

    @AuraEnabled(cacheable=true)
    public static DashboardData getDashboardData() {
        Id currentUserId = UserInfo.getUserId();
        DashboardData data = new DashboardData();

        data.metrics = buildMetrics(currentUserId);
        data.hotLeads = buildLeadRows(queryHotLeads(currentUserId));
        data.quoteFollowUps = buildLeadRows(queryQuoteFollowUps(currentUserId));
        data.slaTasks = buildTaskRows(querySlaTasks(currentUserId));
        data.expiringContracts = buildContractRows(queryExpiringContracts(currentUserId));
        data.pendingApprovals = buildApprovalRows(queryPendingApprovals(currentUserId));
        data.reengagementTasks = buildTaskRows(queryReengagementTasks(currentUserId));
        data.regionalInflows = buildRegionRows(queryRegionalInflows());

        return data;
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityContractKpiData getOpportunityContractKpiData() {
        Id currentUserId = UserInfo.getUserId();
        Date today = Date.today();

        OpportunityContractKpiData data = new OpportunityContractKpiData();
        data.opportunityMetrics = new List<KpiCard>{
            new KpiCard(
                '진행 중 기회',
                [
                    SELECT COUNT()
                    FROM Opportunity
                    WHERE IsClosed = false
                    AND OwnerId = :currentUserId
                ],
                '활성 영업 파이프라인',
                'active'
            ),
            new KpiCard(
                '이번 달 수주',
                [
                    SELECT COUNT()
                    FROM Opportunity
                    WHERE IsWon = true
                    AND CloseDate = THIS_MONTH
                    AND OwnerId = :currentUserId
                ],
                '이번 달 성사된 기회',
                'success'
            ),
            new KpiCard(
                '이번 달 실패',
                [
                    SELECT COUNT()
                    FROM Opportunity
                    WHERE StageName = '수주 실패'
                    AND CloseDate = THIS_MONTH
                    AND OwnerId = :currentUserId
                ],
                '이번 달 수주 실패 건',
                'fail'
            ),
            new KpiCard(
                '견적 승인 대기',
                [
                    SELECT COUNT()
                    FROM Quote_Approval_Request__c
                    WHERE Status__c = '승인대기'
                    AND OpporTunity__r.OwnerId = :currentUserId
                ],
                '처리 필요한 승인 요청',
                'pending'
            )
        };
        data.contractMetrics = new List<KpiCard>{
            new KpiCard(
                '활성 계약',
                [
                    SELECT COUNT()
                    FROM Contract
                    WHERE Status = 'Activated'
                    AND OwnerId = :currentUserId
                ],
                '현재 유효한 담당 계약',
                'active'
            ),
            new KpiCard(
                '60일 만료 예정',
                [
                    SELECT COUNT()
                    FROM Contract
                    WHERE OwnerId = :currentUserId
                    AND EndDate >= :today
                    AND EndDate <= :today.addDays(60)
                ],
                '60일 이내 만료 계약',
                'expiring'
            ),
            new KpiCard(
                '이번 달 신규',
                [
                    SELECT COUNT()
                    FROM Contract
                    WHERE OwnerId = :currentUserId
                    AND StartDate = THIS_MONTH
                ],
                '이번 달 시작된 계약',
                'new'
            )
        };
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static LeadManagementData getLeadManagementData() {
        Id currentUserId = UserInfo.getUserId();

        LeadManagementData data = new LeadManagementData();
        data.metrics = new List<KpiCard>{
            new KpiCard(
                'Hot Lead',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE IsConverted = false
                    AND OwnerId = :currentUserId
                    AND Sales_Priority__c = 'Hot'
                ],
                '즉시 응답 대상',
                'hot'
            ),
            new KpiCard(
                'Warm Lead',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE IsConverted = false
                    AND OwnerId = :currentUserId
                    AND Sales_Priority__c = 'Warm'
                ],
                '관심 유지 필요',
                'warm'
            ),
            new KpiCard(
                '견적 후속',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE IsConverted = false
                    AND OwnerId = :currentUserId
                    AND Inquiry_Intent__c = '견적 요청'
                    AND Sales_Priority__c != 'Cold'
                ],
                '우선 후속이 필요한 견적 요청',
                'quote'
            ),
            new KpiCard(
                '이번 달 유입',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE CreatedDate = THIS_MONTH
                ],
                '지역별 리드 유입 현황',
                'region'
            )
        };
        data.hotLeads = buildLeadRows(queryHotLeads(currentUserId));
        data.warmLeads = buildLeadRows(queryWarmLeads(currentUserId));
        data.quoteFollowUps = buildLeadRows(queryQuoteFollowUps(currentUserId));
        data.regionalInflows = buildRegionRows(queryRegionalInflows());
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static TaskManagementData getTaskManagementData() {
        Id currentUserId = UserInfo.getUserId();

        TaskManagementData data = new TaskManagementData();
        data.metrics = new List<KpiCard>{
            new KpiCard(
                '7일 이내 마감',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND ActivityDate <= :Date.today().addDays(7)
                ],
                '이번 주 안에 마감되는 Task',
                'task'
            ),
            new KpiCard(
                '재공략 예정',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
                ],
                'Closed Lost 후속 일정',
                'reengagement'
            )
        };
        data.slaTasks = buildTaskRows(querySlaTasks(currentUserId));
        data.reengagementTasks = buildTaskRows(queryReengagementTasks(currentUserId));
        return data;
    }

    @AuraEnabled(cacheable=true)
    public static ContractManagementData getContractManagementData() {
        Id currentUserId = UserInfo.getUserId();

        ContractManagementData data = new ContractManagementData();
        data.metrics = new List<KpiCard>{
            new KpiCard(
                '종료 60일',
                [
                    SELECT COUNT()
                    FROM Contract
                    WHERE OwnerId = :currentUserId
                    AND EndDate >= :Date.today()
                    AND EndDate <= :Date.today().addDays(60)
                ],
                '60일 이내 만료 예정 계약',
                'contract'
            ),
            new KpiCard(
                '승인 대기',
                [
                    SELECT COUNT()
                    FROM Quote_Approval_Request__c
                    WHERE Status__c = '승인대기'
                    AND OpporTunity__r.OwnerId = :currentUserId
                ],
                '처리 필요한 견적 승인 요청',
                'quote'
            )
        };
        data.expiringContracts = buildContractRows(queryExpiringContracts(currentUserId));
        data.pendingApprovals = buildApprovalRows(queryPendingApprovals(currentUserId));
        data.renewalListViewLabel = 'Renewals Next 60 Days';
        return data;
    }

    private static List<KpiCard> buildMetrics(Id currentUserId) {
        return new List<KpiCard>{
            new KpiCard(
                '오늘 처리할 Hot Lead',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE IsConverted = false
                    AND OwnerId = :currentUserId
                    AND Sales_Priority__c = 'Hot'
                ],
                '즉시 응답이 필요한 내 Hot 리드',
                'hot'
            ),
            new KpiCard(
                'SLA 임박 Task',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND ActivityDate <= :Date.today().addDays(1)
                ],
                '오늘 또는 내일까지 마감되는 Task',
                'task'
            ),
            new KpiCard(
                '계약 종료 30일',
                [
                    SELECT COUNT()
                    FROM Contract
                    WHERE OwnerId = :currentUserId
                    AND EndDate >= :Date.today()
                    AND EndDate <= :Date.today().addDays(30)
                ],
                '30일 안에 종료되는 담당 계약',
                'contract'
            ),
            new KpiCard(
                '이번 달 승인 대기',
                [
                    SELECT COUNT()
                    FROM Quote_Approval_Request__c
                    WHERE Status__c = '승인대기'
                    AND Requested_At__c = THIS_MONTH
                    AND OpporTunity__r.OwnerId = :currentUserId
                ],
                '이번 달 요청된 견적 승인 대기 건',
                'quote'
            ),
            new KpiCard(
                '재공략 예정',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
                ],
                'Closed Lost 후속 재공략 일정',
                'reengagement'
            ),
            new KpiCard(
                '이번 달 리드 유입',
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE CreatedDate = THIS_MONTH
                ],
                '이번 달 접수된 전체 리드 수',
                'region'
            )
        };
    }

    private static List<Lead> queryHotLeads(Id currentUserId) {
        return [
            SELECT
                Id,
                Name,
                Company,
                Lead_Score__c,
                Sales_Priority__c,
                Consultation_Type__c,
                Sales_Routing_Group__c,
                Contract_End_Window__c,
                Current_Contract_End_Date__c,
                Sales_Action_Summary__c
            FROM Lead
            WHERE IsConverted = false
            AND OwnerId = :currentUserId
            AND Sales_Priority__c = 'Hot'
            ORDER BY Lead_Score__c DESC, LastModifiedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Lead> queryWarmLeads(Id currentUserId) {
        return [
            SELECT
                Id,
                Name,
                Company,
                Lead_Score__c,
                Sales_Priority__c,
                Consultation_Type__c,
                Sales_Routing_Group__c,
                Contract_End_Window__c,
                Current_Contract_End_Date__c,
                Sales_Action_Summary__c
            FROM Lead
            WHERE IsConverted = false
            AND OwnerId = :currentUserId
            AND Sales_Priority__c = 'Warm'
            ORDER BY Lead_Score__c DESC, LastModifiedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Lead> queryQuoteFollowUps(Id currentUserId) {
        return [
            SELECT
                Id,
                Name,
                Company,
                Lead_Score__c,
                Sales_Priority__c,
                Consultation_Type__c,
                Sales_Routing_Group__c,
                Contract_End_Window__c,
                Current_Contract_End_Date__c,
                Sales_Action_Summary__c
            FROM Lead
            WHERE IsConverted = false
            AND OwnerId = :currentUserId
            AND Inquiry_Intent__c = '견적 요청'
            AND Sales_Priority__c != 'Cold'
            ORDER BY Lead_Score__c DESC, LastModifiedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Task> querySlaTasks(Id currentUserId) {
        return [
            SELECT
                Id,
                Subject,
                ActivityDate,
                Priority,
                Status,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND ActivityDate <= :Date.today().addDays(7)
            ORDER BY ActivityDate ASC, CreatedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Contract> queryExpiringContracts(Id currentUserId) {
        return [
            SELECT Id, ContractNumber, Account.Name, Status, EndDate
            FROM Contract
            WHERE OwnerId = :currentUserId
            AND EndDate >= :Date.today()
            AND EndDate <= :Date.today().addDays(60)
            ORDER BY EndDate ASC, LastModifiedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Quote_Approval_Request__c> queryPendingApprovals(Id currentUserId) {
        return [
            SELECT
                Id,
                Name,
                Requested_At__c,
                Approver__r.Name,
                OpporTunity__r.Name,
                Quote__r.Name
            FROM Quote_Approval_Request__c
            WHERE Status__c = '승인대기'
            AND OpporTunity__r.OwnerId = :currentUserId
            ORDER BY Requested_At__c DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<Task> queryReengagementTasks(Id currentUserId) {
        return [
            SELECT
                Id,
                Subject,
                ActivityDate,
                Priority,
                Status,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
            ORDER BY ActivityDate ASC, CreatedDate DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<AggregateResult> queryRegionalInflows() {
        return [
            SELECT Geo_Region__c region, COUNT(Id) totalLeads
            FROM Lead
            WHERE CreatedDate = THIS_MONTH
            GROUP BY Geo_Region__c
            ORDER BY COUNT(Id) DESC
            LIMIT :ROW_LIMIT
        ];
    }

    private static List<LeadRow> buildLeadRows(List<Lead> leadRecords) {
        List<LeadRow> rows = new List<LeadRow>();
        for (Lead leadRecord : leadRecords) {
            rows.add(new LeadRow(leadRecord));
        }
        return rows;
    }

    private static List<TaskRow> buildTaskRows(List<Task> taskRecords) {
        Set<Id> leadIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();

        for (Task taskRecord : taskRecords) {
            if (isLeadId(taskRecord.WhoId)) {
                leadIds.add(taskRecord.WhoId);
            }
            if (isOpportunityId(taskRecord.WhatId)) {
                opportunityIds.add(taskRecord.WhatId);
            }
            if (isContractId(taskRecord.WhatId)) {
                contractIds.add(taskRecord.WhatId);
            }
        }

        Map<Id, Lead> leadById = leadIds.isEmpty()
            ? new Map<Id, Lead>()
            : new Map<Id, Lead>([
                SELECT Id, Name, Company
                FROM Lead
                WHERE Id IN :leadIds
            ]);
        Map<Id, Opportunity> opportunityById = opportunityIds.isEmpty()
            ? new Map<Id, Opportunity>()
            : new Map<Id, Opportunity>([
                SELECT Id, Name, Account.Name
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ]);
        Map<Id, Contract> contractById = contractIds.isEmpty()
            ? new Map<Id, Contract>()
            : new Map<Id, Contract>([
                SELECT Id, ContractNumber, Account.Name
                FROM Contract
                WHERE Id IN :contractIds
            ]);

        List<TaskRow> rows = new List<TaskRow>();
        for (Task taskRecord : taskRecords) {
            String relatedName;
            String company;
            String relatedRecordUrl;

            if (isLeadId(taskRecord.WhoId)) {
                Lead relatedLead = leadById.get(taskRecord.WhoId);
                relatedName = relatedLead == null ? null : relatedLead.Name;
                company = relatedLead == null ? null : relatedLead.Company;
                relatedRecordUrl = buildRecordUrl('Lead', taskRecord.WhoId);
            } else if (isOpportunityId(taskRecord.WhatId)) {
                Opportunity relatedOpportunity = opportunityById.get(taskRecord.WhatId);
                relatedName = relatedOpportunity == null ? null : relatedOpportunity.Name;
                company = relatedOpportunity == null || relatedOpportunity.Account == null
                    ? null
                    : relatedOpportunity.Account.Name;
                relatedRecordUrl = buildRecordUrl('Opportunity', taskRecord.WhatId);
            } else if (isContractId(taskRecord.WhatId)) {
                Contract relatedContract = contractById.get(taskRecord.WhatId);
                relatedName = relatedContract == null ? null : relatedContract.ContractNumber;
                company = relatedContract == null || relatedContract.Account == null
                    ? null
                    : relatedContract.Account.Name;
                relatedRecordUrl = buildRecordUrl('Contract', taskRecord.WhatId);
            }

            rows.add(new TaskRow(taskRecord, relatedName, company, relatedRecordUrl));
        }
        return rows;
    }

    private static List<ContractRow> buildContractRows(List<Contract> contractRecords) {
        List<ContractRow> rows = new List<ContractRow>();
        for (Contract contractRecord : contractRecords) {
            rows.add(new ContractRow(contractRecord));
        }
        return rows;
    }

    private static List<ApprovalRow> buildApprovalRows(
        List<Quote_Approval_Request__c> approvalRequests
    ) {
        List<ApprovalRow> rows = new List<ApprovalRow>();
        for (Quote_Approval_Request__c approvalRequest : approvalRequests) {
            rows.add(new ApprovalRow(approvalRequest));
        }
        return rows;
    }

    private static List<RegionRow> buildRegionRows(List<AggregateResult> aggregates) {
        List<RegionRow> rows = new List<RegionRow>();
        for (AggregateResult aggregateRow : aggregates) {
            rows.add(
                new RegionRow(
                    (String) aggregateRow.get('region'),
                    Integer.valueOf(String.valueOf(aggregateRow.get('totalLeads')))
                )
            );
        }
        return rows;
    }

    private static String buildRecordUrl(String objectApiName, Id recordId) {
        return recordId == null ? null : '/lightning/r/' + objectApiName + '/' + recordId + '/view';
    }

    private static Boolean isLeadId(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Lead.SObjectType;
    }

    private static Boolean isOpportunityId(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Opportunity.SObjectType;
    }

    private static Boolean isContractId(Id recordId) {
        return recordId != null && recordId.getSObjectType() == Contract.SObjectType;
    }
}
