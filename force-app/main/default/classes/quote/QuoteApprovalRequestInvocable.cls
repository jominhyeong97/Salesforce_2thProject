public with sharing class QuoteApprovalRequestInvocable {
    public class Request {
        @InvocableVariable(label='Opportunity Id')
        public Id opportunityId;

        @InvocableVariable(label='Quote Id')
        public Id quoteId;

        @InvocableVariable(label='Request Detail' required=true)
        public String requestDetail;
    }

    public class Response {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Approval Request Id')
        public Id approvalRequestId;

        @InvocableVariable(label='Message')
        public String message;

        @InvocableVariable(label='Approver Id')
        public Id approverId;

        @InvocableVariable(label='Quote Id')
        public Id quoteId;

        @InvocableVariable(label='PDF Document Id')
        public Id pdfDocumentId;

        @InvocableVariable(label='PDF Version Id')
        public Id pdfVersionId;
    }

    @InvocableMethod(
        label='Submit Quote Approval Request'
        description='Creates a quote approval request, validates the PDF attachment, and notifies the approver.'
    )
    public static List<Response> submit(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        for (Request requestRecord : requests) {
            QuoteApprovalService.SubmitResult serviceResult;
            if (requestRecord.quoteId != null) {
                serviceResult = QuoteApprovalService.submitApprovalRequestByQuote(
                    requestRecord.quoteId,
                    requestRecord.requestDetail
                );
            } else {
                serviceResult = QuoteApprovalService.submitApprovalRequest(
                    requestRecord.opportunityId,
                    requestRecord.requestDetail
                );
            }

            Response response = new Response();
            response.success = serviceResult.success;
            response.approvalRequestId = serviceResult.approvalRequestId;
            response.message = serviceResult.message;
            response.approverId = serviceResult.approverId;
            response.quoteId = serviceResult.quoteId;
            response.pdfDocumentId = serviceResult.pdfDocumentId;
            response.pdfVersionId = serviceResult.pdfVersionId;
            responses.add(response);
        }

        return responses;
    }
}
