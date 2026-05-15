public class QuoteStatusGuardHandler {
    private static final String APPROVAL_REQUIRED_ERROR =
        '승인 완료된 견적서가 있어야 "' +
        QuoteApprovalService.QUOTE_STATUS_PRESENTED_LABEL +
        '" 이상 단계로 변경할 수 있습니다.';
    private static final String SYNC_REQUIRED_ERROR =
        '제품 동기화가 완료된 견적서만 "' +
        QuoteApprovalService.QUOTE_STATUS_ACCEPTED_LABEL +
        '" 단계로 변경할 수 있습니다. 먼저 이 견적을 동기화해 주세요.';

    public static void beforeUpdate(List<Quote> newRecords, Map<Id, Quote> oldMap) {
        Set<Id> approvalQuoteIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();

        for (Quote newQuote : newRecords) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            if (oldQuote == null) {
                continue;
            }

            if (isEnteringPresentedOrLater(newQuote, oldQuote)) {
                approvalQuoteIds.add(newQuote.Id);
            }
            if (isEnteringAccepted(newQuote, oldQuote) && newQuote.OpportunityId != null) {
                opportunityIds.add(newQuote.OpportunityId);
            }
        }

        Map<Id, Quote_Approval_Request__c> latestApprovalRequestByQuoteId =
            loadLatestApprovalRequests(approvalQuoteIds);
        Map<Id, Opportunity> opportunityById = loadOpportunities(opportunityIds);

        for (Quote newQuote : newRecords) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            if (oldQuote == null) {
                continue;
            }

            if (isEnteringPresentedOrLater(newQuote, oldQuote) &&
                !hasApprovedRequest(newQuote.Id, latestApprovalRequestByQuoteId)) {
                newQuote.Status.addError(APPROVAL_REQUIRED_ERROR);
            }

            if (isEnteringAccepted(newQuote, oldQuote) &&
                !isSyncedQuote(newQuote, opportunityById)) {
                newQuote.Status.addError(SYNC_REQUIRED_ERROR);
            }
        }
    }

    @TestVisible
    private static Boolean isEnteringPresentedOrLater(Quote newQuote, Quote oldQuote) {
        if (String.isBlank(newQuote.Status) || newQuote.Status == oldQuote.Status) {
            return false;
        }

        Integer thresholdIndex = getQuoteStatusIndex(QuoteApprovalService.QUOTE_STATUS_PRESENTED);
        Integer newStatusIndex = getQuoteStatusIndex(newQuote.Status);
        Integer oldStatusIndex = getQuoteStatusIndex(oldQuote.Status);

        if (thresholdIndex == null || newStatusIndex == null || newStatusIndex < thresholdIndex) {
            return false;
        }

        return oldStatusIndex == null || oldStatusIndex < thresholdIndex;
    }

    private static Boolean isEnteringAccepted(Quote newQuote, Quote oldQuote) {
        return newQuote.Status == QuoteApprovalService.QUOTE_STATUS_ACCEPTED &&
            oldQuote.Status != QuoteApprovalService.QUOTE_STATUS_ACCEPTED;
    }

    private static Boolean hasApprovedRequest(
        Id quoteId,
        Map<Id, Quote_Approval_Request__c> latestApprovalRequestByQuoteId
    ) {
        Quote_Approval_Request__c latestRequest = latestApprovalRequestByQuoteId.get(quoteId);
        return latestRequest != null &&
            latestRequest.Status__c == QuoteApprovalService.STATUS_APPROVED;
    }

    private static Boolean isSyncedQuote(Quote quoteRecord, Map<Id, Opportunity> opportunityById) {
        Opportunity relatedOpportunity = opportunityById.get(quoteRecord.OpportunityId);
        return relatedOpportunity != null && relatedOpportunity.SyncedQuoteId == quoteRecord.Id;
    }

    private static Map<Id, Quote_Approval_Request__c> loadLatestApprovalRequests(Set<Id> quoteIds) {
        Map<Id, Quote_Approval_Request__c> latestByQuoteId = new Map<Id, Quote_Approval_Request__c>();
        if (quoteIds.isEmpty()) {
            return latestByQuoteId;
        }

        for (Quote_Approval_Request__c approvalRequest : [
            SELECT Id, Quote__c, Status__c
            FROM Quote_Approval_Request__c
            WHERE Quote__c IN :quoteIds
            ORDER BY CreatedDate DESC
        ]) {
            if (approvalRequest.Quote__c != null &&
                !latestByQuoteId.containsKey(approvalRequest.Quote__c)) {
                latestByQuoteId.put(approvalRequest.Quote__c, approvalRequest);
            }
        }
        return latestByQuoteId;
    }

    private static Map<Id, Opportunity> loadOpportunities(Set<Id> opportunityIds) {
        if (opportunityIds.isEmpty()) {
            return new Map<Id, Opportunity>();
        }

        return new Map<Id, Opportunity>([
            SELECT Id, SyncedQuoteId
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    private static Integer getQuoteStatusIndex(String statusValue) {
        Integer currentIndex = 0;
        for (Schema.PicklistEntry entry :
            Schema.SObjectType.Quote.fields.Status.getPicklistValues()) {
            if (entry.isActive()) {
                if (entry.getValue() == statusValue) {
                    return currentIndex;
                }
                currentIndex++;
            }
        }
        return null;
    }
}
