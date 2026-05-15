trigger QuoteLineItemTrigger on QuoteLineItem (
    after insert,
    after update,
    after delete,
    after undelete
) {
    Set<Id> quoteIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (QuoteLineItem lineItem : Trigger.new) {
            if (lineItem.QuoteId != null) {
                quoteIds.add(lineItem.QuoteId);
            }
        }
    }

    if (Trigger.isDelete || Trigger.isUpdate) {
        for (QuoteLineItem lineItem : Trigger.old) {
            if (lineItem.QuoteId != null) {
                quoteIds.add(lineItem.QuoteId);
            }
        }
    }

    AquaPricingSupport.recalculateQuotes(quoteIds);
}
