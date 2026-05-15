trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        LeadSalesAutomationHandler.beforeInsertOrUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter) {
        LeadSalesAutomationHandler.afterInsertOrUpdate(Trigger.new, Trigger.oldMap);
    }
}
