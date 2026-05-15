/**
 * Opportunity 저장 시 사업자등록번호를 정규화하고, 번호 변경 시 기존 검증 결과를 초기화합니다.
 * 검증 결과의 기준 데이터는 Opportunity에 저장합니다.
 */
public class OpportunityBusinessVerificationHandler {
    public static void beforeInsert(List<Opportunity> newRecords) {
        for (Opportunity newOpportunity : newRecords) {
            normalizeBusinessNumber(newOpportunity);
        }
    }

    public static void beforeUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        for (Opportunity newOpportunity : newRecords) {
            Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
            if (oldOpportunity == null) {
                continue;
            }

            String oldBusinessNumber =
                BusinessStatusService.normalizeBusinessNumber(oldOpportunity.Business_Number__c);
            normalizeBusinessNumber(newOpportunity);

            if (oldBusinessNumber != newOpportunity.Business_Number__c &&
                !isVerificationRefresh(newOpportunity, oldOpportunity)) {
                clearVerificationState(newOpportunity);
            }
        }
    }

    private static void normalizeBusinessNumber(Opportunity opportunityRecord) {
        opportunityRecord.Business_Number__c =
            BusinessStatusService.normalizeBusinessNumber(opportunityRecord.Business_Number__c);
    }

    private static Boolean isVerificationRefresh(
        Opportunity newOpportunity,
        Opportunity oldOpportunity
    ) {
        return newOpportunity.Business_Verified__c != oldOpportunity.Business_Verified__c
            || newOpportunity.Business_Verified_At__c != oldOpportunity.Business_Verified_At__c
            || newOpportunity.Business_Status__c != oldOpportunity.Business_Status__c
            || newOpportunity.Business_Tax_Type__c != oldOpportunity.Business_Tax_Type__c
            || newOpportunity.Business_Closure_Date__c != oldOpportunity.Business_Closure_Date__c
            || newOpportunity.Business_Verification_Notes__c != oldOpportunity.Business_Verification_Notes__c;
    }

    private static void clearVerificationState(Opportunity opportunityRecord) {
        opportunityRecord.Business_Verified__c = false;
        opportunityRecord.Business_Verified_At__c = null;
        opportunityRecord.Business_Status__c = null;
        opportunityRecord.Business_Tax_Type__c = null;
        opportunityRecord.Business_Closure_Date__c = null;
        opportunityRecord.Business_Verification_Notes__c = null;
    }
}
