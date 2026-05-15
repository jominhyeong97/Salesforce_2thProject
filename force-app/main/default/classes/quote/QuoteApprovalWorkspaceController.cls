public with sharing class QuoteApprovalWorkspaceController {
    @AuraEnabled(cacheable=true)
    public static QuoteApprovalService.WorkspaceData getWorkspaceData(Id approvalRequestId) {
        return QuoteApprovalService.getWorkspaceData(approvalRequestId);
    }

    @AuraEnabled
    public static QuoteApprovalService.ActionResult approveRequest(
        Id approvalRequestId,
        String decisionComment
    ) {
        return QuoteApprovalService.processDecision(
            approvalRequestId,
            QuoteApprovalService.STATUS_APPROVED,
            decisionComment
        );
    }

    @AuraEnabled
    public static QuoteApprovalService.ActionResult rejectRequest(
        Id approvalRequestId,
        String decisionComment
    ) {
        return QuoteApprovalService.processDecision(
            approvalRequestId,
            QuoteApprovalService.STATUS_REJECTED,
            decisionComment
        );
    }
}
