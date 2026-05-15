public class SalesTaskSupport {
    public static final String TASK_TYPE_INITIAL = '초기 상담';
    public static final String TASK_TYPE_QUOTE_FOLLOW_UP = '견적 후속';
    public static final String TASK_TYPE_CONTRACT_RENEWAL = '계약 갱신';
    public static final String TASK_TYPE_PURCHASE_CONVERSION = '구매 전환';
    public static final String TASK_TYPE_REENGAGEMENT = '재공략';

    public static void applyTaskTypes(Task taskRecord, String salesTaskType) {
        if (taskRecord == null || String.isBlank(salesTaskType)) {
            return;
        }

        taskRecord.Sales_Task_Type__c = resolvePreferredOrFirstActivePicklistValue(
            Task.Sales_Task_Type__c.getDescribe().getPicklistValues(),
            salesTaskType
        );

        String standardTaskType = resolvePreferredActivePicklistValue(
            Task.Type.getDescribe().getPicklistValues(),
            salesTaskType
        );
        if (!String.isBlank(standardTaskType)) {
            taskRecord.Type = standardTaskType;
        }
    }

    public static String resolveTaskStatus() {
        return resolvePreferredOrFirstActivePicklistValue(
            Task.Status.getDescribe().getPicklistValues(),
            'Not Started'
        );
    }

    public static String resolveTaskPriority(String preferredValue) {
        return resolvePreferredOrFirstActivePicklistValue(
            Task.Priority.getDescribe().getPicklistValues(),
            preferredValue
        );
    }

    public static void addLine(List<String> lines, String label, String value) {
        if (!String.isBlank(value) && value != 'null') {
            lines.add(label + ': ' + value);
        }
    }

    public static String stringifyDate(Date value) {
        return value == null ? null : String.valueOf(value);
    }

    public static Boolean isUserId(Id ownerId) {
        return ownerId != null && String.valueOf(ownerId).startsWith('005');
    }

    public static String truncateValue(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }

    @TestVisible
    private static String resolvePreferredActivePicklistValue(
        List<Schema.PicklistEntry> entries,
        String preferredValue
    ) {
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive() && entry.getValue() == preferredValue) {
                return entry.getValue();
            }
        }
        return null;
    }

    @TestVisible
    private static String resolvePreferredOrFirstActivePicklistValue(
        List<Schema.PicklistEntry> entries,
        String preferredValue
    ) {
        String matchedValue = resolvePreferredActivePicklistValue(entries, preferredValue);
        if (!String.isBlank(matchedValue)) {
            return matchedValue;
        }

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return preferredValue;
    }
}
