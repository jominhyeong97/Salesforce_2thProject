trigger OpportunityLineItemTrigger on OpportunityLineItem (
    after insert,
    after update,
    after delete,
    after undelete
) {
    Set<Id> opportunityIds = new Set<Id>();

    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (OpportunityLineItem lineItem : Trigger.new) {
            if (lineItem.OpportunityId != null) {
                opportunityIds.add(lineItem.OpportunityId);
            }
        }
    }

    if (Trigger.isDelete || Trigger.isUpdate) {
        for (OpportunityLineItem lineItem : Trigger.old) {
            if (lineItem.OpportunityId != null) {
                opportunityIds.add(lineItem.OpportunityId);
            }
        }
    }

    AquaPricingSupport.enqueueOpportunityRecalculation(opportunityIds);
}
