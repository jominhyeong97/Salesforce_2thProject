trigger QuoteTrigger on Quote (before insert, before update, after update) {
    if (Trigger.isBefore) {
        AquaPricingSupport.prepareQuotes(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        QuoteStatusGuardHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AquaPricingSupport.afterQuotes(Trigger.new, Trigger.oldMap);
    }
}
