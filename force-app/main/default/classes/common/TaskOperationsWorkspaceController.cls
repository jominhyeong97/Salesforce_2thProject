public with sharing class TaskOperationsWorkspaceController {
    private static final Integer WORKSPACE_ROW_LIMIT = 25;

    public class WorkspaceData {
        @AuraEnabled public List<KpiCard> metrics { get; set; }
        @AuraEnabled public List<TaskRow> openTasks { get; set; }
        @AuraEnabled public List<TaskRow> slaTasks { get; set; }
        @AuraEnabled public List<TaskRow> overdueTasks { get; set; }
        @AuraEnabled public List<TaskRow> renewalTasks { get; set; }
        @AuraEnabled public List<TaskRow> reengagementTasks { get; set; }
    }

    public class KpiCard {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer value { get; set; }
        @AuraEnabled public String helperText { get; set; }

        public KpiCard(String label, Integer value, String helperText) {
            this.label = label;
            this.value = value;
            this.helperText = helperText;
        }
    }

    public class TaskRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String subject { get; set; }
        @AuraEnabled public Date activityDate { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String salesTaskType { get; set; }
        @AuraEnabled public String description { get; set; }
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
            this.description = taskRecord.Description;
            this.relatedName = relatedName;
            this.company = company;
            this.recordUrl = buildRecordUrl('Task', taskRecord.Id);
            this.relatedRecordUrl = relatedRecordUrl;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WorkspaceData getWorkspaceData() {
        Id currentUserId = UserInfo.getUserId();

        WorkspaceData data = new WorkspaceData();
        data.metrics = buildMetrics(currentUserId);
        data.openTasks = buildTaskRows(queryOpenTasks(currentUserId));
        data.slaTasks = buildTaskRows(querySlaTasks(currentUserId));
        data.overdueTasks = buildTaskRows(queryOverdueTasks(currentUserId));
        data.renewalTasks = buildTaskRows(queryRenewalTasks(currentUserId));
        data.reengagementTasks = buildTaskRows(queryReengagementTasks(currentUserId));
        return data;
    }

    private static List<KpiCard> buildMetrics(Id currentUserId) {
        return new List<KpiCard>{
            new KpiCard(
                '내 미완료 Task',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                ],
                '현재 직접 처리 중인 전체 Task'
            ),
            new KpiCard(
                'SLA 임박',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND ActivityDate <= :Date.today().addDays(1)
                ],
                '오늘 또는 내일 마감'
            ),
            new KpiCard(
                '연체 Task',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND ActivityDate < :Date.today()
                ],
                '이미 기한이 지난 Task'
            ),
            new KpiCard(
                '계약 갱신',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND Sales_Task_Type__c = '계약 갱신'
                ],
                '갱신 대응이 필요한 Task'
            ),
            new KpiCard(
                '재공략',
                [
                    SELECT COUNT()
                    FROM Task
                    WHERE OwnerId = :currentUserId
                    AND IsClosed = false
                    AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
                ],
                'Closed Lost 후속 재공략'
            )
        };
    }

    private static List<Task> queryOpenTasks(Id currentUserId) {
        return [
            SELECT
                Id,
                Subject,
                ActivityDate,
                Priority,
                Status,
                Description,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
            LIMIT :WORKSPACE_ROW_LIMIT
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
                Description,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND ActivityDate <= :Date.today().addDays(1)
            ORDER BY ActivityDate ASC, CreatedDate DESC
            LIMIT :WORKSPACE_ROW_LIMIT
        ];
    }

    private static List<Task> queryOverdueTasks(Id currentUserId) {
        return [
            SELECT
                Id,
                Subject,
                ActivityDate,
                Priority,
                Status,
                Description,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND ActivityDate < :Date.today()
            ORDER BY ActivityDate ASC, CreatedDate DESC
            LIMIT :WORKSPACE_ROW_LIMIT
        ];
    }

    private static List<Task> queryRenewalTasks(Id currentUserId) {
        return [
            SELECT
                Id,
                Subject,
                ActivityDate,
                Priority,
                Status,
                Description,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND Sales_Task_Type__c = '계약 갱신'
            ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
            LIMIT :WORKSPACE_ROW_LIMIT
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
                Description,
                WhoId,
                WhatId,
                Sales_Task_Type__c
            FROM Task
            WHERE OwnerId = :currentUserId
            AND IsClosed = false
            AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
            ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
            LIMIT :WORKSPACE_ROW_LIMIT
        ];
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
