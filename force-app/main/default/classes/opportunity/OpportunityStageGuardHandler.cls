/**
 * Opportunity가 수주 완료 단계로 넘어갈 때 Opportunity 자체의 사업자번호 검증 여부를 확인합니다.
 * 검증이 완료되지 않았다면 Opportunity 저장을 차단합니다.
 */
public class OpportunityStageGuardHandler {
    private static final String CLOSED_STAGE = '수주 완료';
    private static final String VALIDATION_ERROR =
        '사업자등록번호 검증이 완료된 기회만 수주 완료 단계로 변경할 수 있습니다.';

    public static void beforeUpdate(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        Map<Id, Account> accountById = loadAccountsForClosingOpportunities(newRecords, oldMap);

        for (Opportunity newOpportunity : newRecords) {
            Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
            if (oldOpportunity == null) {
                continue;
            }

            if (isEnteringClosedStage(newOpportunity, oldOpportunity) &&
                !isPersonalOpportunity(newOpportunity, accountById) &&
                newOpportunity.Business_Verified__c != true) {
                String errorMessage = VALIDATION_ERROR;
                if (String.isBlank(newOpportunity.Business_Number__c)) {
                    errorMessage += ' 기회에 사업자등록번호를 먼저 입력하세요.';
                } else if (!String.isBlank(newOpportunity.Business_Verification_Notes__c)) {
                    errorMessage += ' 최근 확인 결과: ' + newOpportunity.Business_Verification_Notes__c;
                }

                newOpportunity.StageName.addError(errorMessage);
            }
        }
    }

    private static Boolean isEnteringClosedStage(
        Opportunity newOpportunity,
        Opportunity oldOpportunity
    ) {
        return newOpportunity.StageName == CLOSED_STAGE &&
            oldOpportunity.StageName != CLOSED_STAGE;
    }

    private static Map<Id, Account> loadAccountsForClosingOpportunities(
        List<Opportunity> newRecords,
        Map<Id, Opportunity> oldMap
    ) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity newOpportunity : newRecords) {
            Opportunity oldOpportunity = oldMap.get(newOpportunity.Id);
            if (oldOpportunity != null &&
                isEnteringClosedStage(newOpportunity, oldOpportunity) &&
                newOpportunity.AccountId != null) {
                accountIds.add(newOpportunity.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return new Map<Id, Account>();
        }

        return new Map<Id, Account>([
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ]);
    }

    private static Boolean isPersonalOpportunity(
        Opportunity opportunityRecord,
        Map<Id, Account> accountById
    ) {
        if (opportunityRecord.AccountId == null || !accountById.containsKey(opportunityRecord.AccountId)) {
            return false;
        }

        Account relatedAccount = accountById.get(opportunityRecord.AccountId);
        return relatedAccount != null &&
            CustomerIdentitySupport.isPersonalCompanyName(relatedAccount.Name);
    }
}
