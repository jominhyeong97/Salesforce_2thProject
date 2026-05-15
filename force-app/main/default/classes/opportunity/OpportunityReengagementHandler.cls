public class OpportunityReengagementHandler {
    @TestVisible
    private static final String CLOSED_LOST_STAGE = '수주 실패';
    @TestVisible
    private static final String REOPEN_HIGH = '높음';
    @TestVisible
    private static final String REOPEN_NORMAL = '보통';

    private static final Integer HIGH_POTENTIAL_FOLLOW_UP_DAYS = 14;
    private static final Integer NORMAL_POTENTIAL_FOLLOW_UP_DAYS = 30;

    public static void afterUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opportunityRecord : newRecords) {
            if (shouldCreateReengagementTask(opportunityRecord, oldMap) &&
                SalesTaskSupport.isUserId(opportunityRecord.OwnerId)) {
                opportunityIds.add(opportunityRecord.Id);
            }
        }

        if (opportunityIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> opportunityById = new Map<Id, Opportunity>([
            SELECT
                Id,
                Name,
                Account.Name,
                OwnerId,
                CloseDate,
                Reopen_Potential__c,
                Lost_Reason_Primary__c,
                Lost_Reason_Secondary__c,
                Lost_To_Competitor__c,
                Lost_Reason_Detail__c,
                Description,
                NextStep
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);

        Set<Id> opportunitiesWithOpenTask = new Set<Id>();
        for (Task taskRecord : [
            SELECT WhatId
            FROM Task
            WHERE WhatId IN :opportunityIds
            AND IsClosed = false
            AND Sales_Task_Type__c = :SalesTaskSupport.TASK_TYPE_REENGAGEMENT
        ]) {
            if (taskRecord.WhatId != null) {
                opportunitiesWithOpenTask.add(taskRecord.WhatId);
            }
        }

        List<Task> tasksToInsert = new List<Task>();
        for (Id opportunityId : opportunityIds) {
            if (opportunitiesWithOpenTask.contains(opportunityId)) {
                continue;
            }

            Opportunity opportunityRecord = opportunityById.get(opportunityId);
            if (opportunityRecord != null) {
                tasksToInsert.add(buildReengagementTask(opportunityRecord));
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    @TestVisible
    private static Boolean shouldCreateReengagementTask(
        Opportunity newOpportunity,
        Map<Id, Opportunity> oldMap
    ) {
        if (newOpportunity == null ||
            newOpportunity.StageName != CLOSED_LOST_STAGE ||
            !isActionableReopenPotential(newOpportunity.Reopen_Potential__c)) {
            return false;
        }

        if (oldMap == null || !oldMap.containsKey(newOpportunity.Id)) {
            return true;
        }

        Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
        return oldOpportunity == null ||
            oldOpportunity.StageName != CLOSED_LOST_STAGE ||
            !isActionableReopenPotential(oldOpportunity.Reopen_Potential__c);
    }

    private static Task buildReengagementTask(Opportunity opportunityRecord) {
        Integer followUpDays = determineFollowUpDays(opportunityRecord.Reopen_Potential__c);

        Task taskRecord = new Task();
        taskRecord.OwnerId = opportunityRecord.OwnerId;
        taskRecord.WhatId = opportunityRecord.Id;
        taskRecord.Subject = SalesTaskSupport.truncateValue(
            SalesTaskSupport.TASK_TYPE_REENGAGEMENT + ' - ' + opportunityRecord.Name,
            255
        );
        taskRecord.Priority = SalesTaskSupport.resolveTaskPriority(
            opportunityRecord.Reopen_Potential__c == REOPEN_HIGH ? 'High' : 'Normal'
        );
        taskRecord.Status = SalesTaskSupport.resolveTaskStatus();
        taskRecord.ActivityDate = Date.today().addDays(followUpDays);
        SalesTaskSupport.applyTaskTypes(taskRecord, SalesTaskSupport.TASK_TYPE_REENGAGEMENT);
        taskRecord.Description = buildTaskDescription(opportunityRecord, followUpDays);
        return taskRecord;
    }

    private static String buildTaskDescription(
        Opportunity opportunityRecord,
        Integer followUpDays
    ) {
        List<String> lines = new List<String>();
        SalesTaskSupport.addLine(lines, 'Task 유형', SalesTaskSupport.TASK_TYPE_REENGAGEMENT);
        SalesTaskSupport.addLine(lines, '재공략 가능성', opportunityRecord.Reopen_Potential__c);
        SalesTaskSupport.addLine(lines, '후속 예정일(일)', String.valueOf(followUpDays));
        SalesTaskSupport.addLine(lines, '기회', opportunityRecord.Name);
        SalesTaskSupport.addLine(
            lines,
            '거래처',
            opportunityRecord.Account == null ? null : opportunityRecord.Account.Name
        );
        SalesTaskSupport.addLine(
            lines,
            '기회 종료일',
            SalesTaskSupport.stringifyDate(opportunityRecord.CloseDate)
        );
        SalesTaskSupport.addLine(lines, '1차 실패 사유', opportunityRecord.Lost_Reason_Primary__c);
        SalesTaskSupport.addLine(lines, '2차 실패 사유', opportunityRecord.Lost_Reason_Secondary__c);
        SalesTaskSupport.addLine(lines, '경쟁사', opportunityRecord.Lost_To_Competitor__c);
        SalesTaskSupport.addLine(lines, '실패 상세', opportunityRecord.Lost_Reason_Detail__c);
        SalesTaskSupport.addLine(lines, '다음 액션 메모', opportunityRecord.NextStep);
        SalesTaskSupport.addLine(lines, '추가 설명', opportunityRecord.Description);
        return String.join(lines, '\n');
    }

    @TestVisible
    private static Integer determineFollowUpDays(String reopenPotential) {
        return reopenPotential == REOPEN_HIGH
            ? HIGH_POTENTIAL_FOLLOW_UP_DAYS
            : NORMAL_POTENTIAL_FOLLOW_UP_DAYS;
    }

    private static Boolean isActionableReopenPotential(String reopenPotential) {
        return reopenPotential == REOPEN_HIGH || reopenPotential == REOPEN_NORMAL;
    }
}
