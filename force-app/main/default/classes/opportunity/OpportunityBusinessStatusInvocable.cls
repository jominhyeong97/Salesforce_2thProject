/**
 * Flow에서 직접 호출할 수 있게 사업자 상태조회 서비스를 감싼 Opportunity용 Invocable 클래스.
 * 조회 결과를 Flow 반환값으로 넘기고, 원하면 Opportunity 필드도 함께 업데이트합니다.
 */
public with sharing class OpportunityBusinessStatusInvocable {
    public class Request {
        @InvocableVariable(label='Opportunity Id')
        public Id opportunityId;

        @InvocableVariable(label='Business Number' required=true)
        public String businessNumber;

        @InvocableVariable(label='Update Opportunity')
        public Boolean updateOpportunity;
    }

    public class Response {
        @InvocableVariable(label='Opportunity Id')
        public Id opportunityId;

        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Verified')
        public Boolean isVerified;

        @InvocableVariable(label='Normalized Business Number')
        public String normalizedBusinessNumber;

        @InvocableVariable(label='Business Status')
        public String businessStatus;

        @InvocableVariable(label='Tax Type')
        public String taxType;

        @InvocableVariable(label='Closure Date')
        public String closureDate;

        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(
        label='Verify Opportunity Business Status'
        description='Calls the NTS business status API and optionally updates the Opportunity with the result.'
    )
    public static List<Response> verify(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        List<String> businessNumbers = new List<String>();
        for (Request request : requests) {
            businessNumbers.add(request.businessNumber);
        }

        List<BusinessStatusService.BusinessStatusResult> results;
        try {
            results = BusinessStatusService.lookup(businessNumbers);
        } catch (Exception ex) {
            for (Request request : requests) {
                Response response = new Response();
                response.opportunityId = request.opportunityId;
                response.success = false;
                response.isVerified = false;
                response.message = '사업자 상태조회 서비스 호출에 실패했습니다. ' + ex.getMessage();
                responses.add(response);
            }

            upsertOpportunityMessagesOnly(requests, responses);
            return responses;
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Integer index = 0; index < requests.size(); index++) {
            Request request = requests[index];
            BusinessStatusService.BusinessStatusResult result = results[index];

            Response response = new Response();
            response.opportunityId = request.opportunityId;
            response.success = result.success;
            response.isVerified = result.isVerified;
            response.normalizedBusinessNumber = result.normalizedBusinessNumber;
            response.businessStatus = result.businessStatus;
            response.taxType = result.taxType;
            response.closureDate = result.closureDate == null
                ? null
                : String.valueOf(result.closureDate);
            response.message = result.message;
            responses.add(response);

            if (request.opportunityId != null && shouldUpdateOpportunity(request)) {
                opportunitiesToUpdate.add(buildOpportunityUpdate(request.opportunityId, result));
            }
        }

        applyOpportunityUpdates(opportunitiesToUpdate, responses);
        return responses;
    }

    private static Boolean shouldUpdateOpportunity(Request request) {
        return request.updateOpportunity == null || request.updateOpportunity;
    }

    private static Opportunity buildOpportunityUpdate(
        Id opportunityId,
        BusinessStatusService.BusinessStatusResult result
    ) {
        Opportunity opportunityUpdate = new Opportunity(Id = opportunityId);
        opportunityUpdate.Business_Number__c = result.normalizedBusinessNumber;

        if (result.success) {
            opportunityUpdate.Business_Verified__c = result.isVerified;
            opportunityUpdate.Business_Verified_At__c = System.now();
            opportunityUpdate.Business_Status__c = result.businessStatus;
            opportunityUpdate.Business_Tax_Type__c = result.taxType;
            opportunityUpdate.Business_Closure_Date__c = result.closureDate;
            opportunityUpdate.Business_Verification_Notes__c = result.message;
            return opportunityUpdate;
        }

        opportunityUpdate.Business_Verified__c = false;
        opportunityUpdate.Business_Verified_At__c = null;
        opportunityUpdate.Business_Status__c = null;
        opportunityUpdate.Business_Tax_Type__c = null;
        opportunityUpdate.Business_Closure_Date__c = null;
        opportunityUpdate.Business_Verification_Notes__c = result.message;
        return opportunityUpdate;
    }

    private static void applyOpportunityUpdates(
        List<Opportunity> opportunitiesToUpdate,
        List<Response> responses
    ) {
        if (opportunitiesToUpdate.isEmpty()) {
            return;
        }

        Map<Id, Response> responseByOpportunityId = new Map<Id, Response>();
        for (Response response : responses) {
            if (response.opportunityId != null) {
                responseByOpportunityId.put(response.opportunityId, response);
            }
        }

        Database.SaveResult[] saveResults = Database.update(opportunitiesToUpdate, false);
        for (Integer index = 0; index < saveResults.size(); index++) {
            if (saveResults[index].isSuccess()) {
                continue;
            }

            Response response = responseByOpportunityId.get(opportunitiesToUpdate[index].Id);
            if (response == null) {
                continue;
            }

            response.success = false;
            response.isVerified = false;
            response.message = buildDmlErrorMessage(saveResults[index]);
        }
    }

    private static void upsertOpportunityMessagesOnly(List<Request> requests, List<Response> responses) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Integer index = 0; index < requests.size(); index++) {
            if (requests[index].opportunityId == null || !shouldUpdateOpportunity(requests[index])) {
                continue;
            }

            opportunitiesToUpdate.add(new Opportunity(
                Id = requests[index].opportunityId,
                Business_Verification_Notes__c = responses[index].message
            ));
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            Database.update(opportunitiesToUpdate, false);
        }
    }

    private static String buildDmlErrorMessage(Database.SaveResult saveResult) {
        List<String> messages = new List<String>();
        for (Database.Error error : saveResult.getErrors()) {
            messages.add(error.getMessage());
        }

        return String.join(messages, ' ');
    }
}
