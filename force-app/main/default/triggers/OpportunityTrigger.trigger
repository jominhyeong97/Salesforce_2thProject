// Opportunity 저장 시 사업자번호 검증, 가격 집계, 수주 실패 재공략 후속 생성을 함께 처리합니다.
trigger OpportunityTrigger on Opportunity (before insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AquaPricingSupport.prepareOpportunities(Trigger.new, null);
            OpportunityBusinessVerificationHandler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            AquaPricingSupport.prepareOpportunities(Trigger.new, Trigger.oldMap);
            OpportunityBusinessVerificationHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
            OpportunityStageGuardHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AquaPricingSupport.afterOpportunities(Trigger.new, Trigger.oldMap);
        OpportunityReengagementHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
