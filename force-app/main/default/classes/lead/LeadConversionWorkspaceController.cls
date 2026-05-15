public with sharing class LeadConversionWorkspaceController {
    private static final Integer SUGGESTION_LIMIT = 5;

    public class WorkspaceData {
        @AuraEnabled public LeadSummary lead { get; set; }
        @AuraEnabled public List<PicklistOption> convertedStatuses { get; set; }
        @AuraEnabled public List<AccountSuggestion> accountSuggestions { get; set; }
        @AuraEnabled public List<ContactSuggestion> contactSuggestions { get; set; }
        @AuraEnabled public Id recommendedAccountId { get; set; }
        @AuraEnabled public Id recommendedContactId { get; set; }
        @AuraEnabled public String recommendedAccountMode { get; set; }
        @AuraEnabled public String recommendedContactMode { get; set; }
        @AuraEnabled public String recommendedOpportunityName { get; set; }
    }

    public class LeadSummary {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String company { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public String phone { get; set; }
        @AuraEnabled public String salesPriority { get; set; }
        @AuraEnabled public Integer leadScore { get; set; }
        @AuraEnabled public String consultationType { get; set; }
        @AuraEnabled public String routingGroup { get; set; }
        @AuraEnabled public String contractEndWindow { get; set; }
        @AuraEnabled public String salesActionSummary { get; set; }
        @AuraEnabled public Boolean isConverted { get; set; }
        @AuraEnabled public Id convertedAccountId { get; set; }
        @AuraEnabled public Id convertedContactId { get; set; }
        @AuraEnabled public Id convertedOpportunityId { get; set; }
    }

    public class PicklistOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class AccountSuggestion {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String industry { get; set; }
        @AuraEnabled public String ownerName { get; set; }
        @AuraEnabled public Boolean isExactMatch { get; set; }
    }

    public class ContactSuggestion {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String email { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public String accountName { get; set; }
        @AuraEnabled public Boolean isExactMatch { get; set; }
    }

    public class ConvertResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String accountUrl { get; set; }
        @AuraEnabled public String contactUrl { get; set; }
        @AuraEnabled public String opportunityUrl { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static WorkspaceData getWorkspaceData(Id leadId) {
        if (leadId == null) {
            throw new AuraHandledException('리드 레코드를 찾을 수 없습니다.');
        }

        Lead leadRecord = [
            SELECT
                Id,
                Name,
                Company,
                Status,
                Email,
                Phone,
                Sales_Priority__c,
                Lead_Score__c,
                Consultation_Type__c,
                Sales_Routing_Group__c,
                Contract_End_Window__c,
                Sales_Action_Summary__c,
                IsConverted,
                ConvertedAccountId,
                ConvertedContactId,
                ConvertedOpportunityId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        WorkspaceData workspace = new WorkspaceData();
        workspace.lead = buildLeadSummary(leadRecord);
        workspace.convertedStatuses = buildConvertedStatuses();
        workspace.accountSuggestions = new List<AccountSuggestion>();
        workspace.contactSuggestions = new List<ContactSuggestion>();
        workspace.recommendedOpportunityName = buildOpportunityName(leadRecord, null);
        workspace.recommendedAccountMode = 'new';
        workspace.recommendedContactMode = 'new';

        if (leadRecord.IsConverted) {
            return workspace;
        }

        Map<Id, AccountSuggestion> accountSuggestionsById = new Map<Id, AccountSuggestion>();
        for (AccountSuggestion accountSuggestion : buildAccountSuggestions(leadRecord)) {
            workspace.accountSuggestions.add(accountSuggestion);
            accountSuggestionsById.put(accountSuggestion.id, accountSuggestion);
            if (workspace.recommendedAccountId == null && accountSuggestion.isExactMatch) {
                workspace.recommendedAccountId = accountSuggestion.id;
            }
        }

        for (ContactSuggestion contactSuggestion : buildContactSuggestions(leadRecord)) {
            workspace.contactSuggestions.add(contactSuggestion);
            if (workspace.recommendedContactId == null && contactSuggestion.isExactMatch) {
                workspace.recommendedContactId = contactSuggestion.id;
                if (contactSuggestion.accountId != null) {
                    workspace.recommendedAccountId = contactSuggestion.accountId;
                }
            }

            if (contactSuggestion.accountId != null &&
                !accountSuggestionsById.containsKey(contactSuggestion.accountId)) {
                AccountSuggestion contactAccountSuggestion = new AccountSuggestion();
                contactAccountSuggestion.id = contactSuggestion.accountId;
                contactAccountSuggestion.name = contactSuggestion.accountName;
                contactAccountSuggestion.label =
                    contactSuggestion.accountName + ' · 연락처 연결';
                contactAccountSuggestion.isExactMatch = false;
                workspace.accountSuggestions.add(contactAccountSuggestion);
                accountSuggestionsById.put(contactAccountSuggestion.id, contactAccountSuggestion);
            }
        }

        workspace.recommendedAccountMode = workspace.recommendedAccountId == null
            ? 'new'
            : 'existing';
        workspace.recommendedContactMode = workspace.recommendedContactId == null
            ? 'new'
            : 'existing';
        return workspace;
    }

    @AuraEnabled
    public static ConvertResult convertLeadRecord(
        Id leadId,
        String convertedStatus,
        Id existingAccountId,
        Id existingContactId,
        String accountName,
        Boolean createOpportunity,
        String opportunityName
    ) {
        ConvertResult result = new ConvertResult();
        result.success = false;

        if (leadId == null) {
            result.message = '리드 레코드를 찾을 수 없습니다.';
            return result;
        }

        Lead leadRecord = [
            SELECT
                Id,
                Name,
                Company,
                Consultation_Type__c,
                IsConverted,
                ConvertedAccountId,
                ConvertedContactId,
                ConvertedOpportunityId
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        if (leadRecord.IsConverted) {
            result.message = '이미 전환된 리드입니다.';
            result.accountId = leadRecord.ConvertedAccountId;
            result.contactId = leadRecord.ConvertedContactId;
            result.opportunityId = leadRecord.ConvertedOpportunityId;
            populateUrls(result);
            return result;
        }

        String resolvedStatus = resolveConvertedStatus(convertedStatus);
        if (String.isBlank(resolvedStatus)) {
            result.message = '전환 완료 상태를 찾지 못했습니다.';
            return result;
        }

        Contact existingContact;
        if (existingContactId != null) {
            List<Contact> contacts = [
                SELECT Id, AccountId
                FROM Contact
                WHERE Id = :existingContactId
                LIMIT 1
            ];
            if (contacts.isEmpty()) {
                result.message = '선택한 기존 연락처를 찾을 수 없습니다.';
                return result;
            }
            existingContact = contacts[0];
            if (existingContact.AccountId != null && existingAccountId == null) {
                existingAccountId = existingContact.AccountId;
            }
        }

        if (existingContact != null &&
            existingAccountId != null &&
            existingContact.AccountId != null &&
            existingContact.AccountId != existingAccountId) {
            result.message = '기존 연락처와 기존 거래처가 서로 다른 계정에 연결되어 있습니다.';
            return result;
        }

        String resolvedAccountName = String.isBlank(accountName) ? leadRecord.Company : accountName;
        if (existingAccountId == null && String.isBlank(resolvedAccountName)) {
            result.message = '새 거래처 이름을 입력하세요.';
            return result;
        }

        if (existingAccountId == null &&
            !String.isBlank(resolvedAccountName) &&
            resolvedAccountName != leadRecord.Company) {
            leadRecord.Company = truncateValue(resolvedAccountName, 255);
            update leadRecord;
        }

        Boolean shouldCreateOpportunity = createOpportunity == null ? true : createOpportunity;
        String resolvedOpportunityName = buildOpportunityName(leadRecord, opportunityName);
        if (shouldCreateOpportunity && String.isBlank(resolvedOpportunityName)) {
            result.message = '기회 이름을 입력하세요.';
            return result;
        }

        Database.LeadConvert convertRequest = new Database.LeadConvert();
        convertRequest.setLeadId(leadRecord.Id);
        convertRequest.setConvertedStatus(resolvedStatus);
        convertRequest.setDoNotCreateOpportunity(!shouldCreateOpportunity);

        if (existingAccountId != null) {
            convertRequest.setAccountId(existingAccountId);
        }

        if (existingContact != null) {
            convertRequest.setContactId(existingContact.Id);
        }

        if (shouldCreateOpportunity) {
            convertRequest.setOpportunityName(truncateValue(resolvedOpportunityName, 120));
        }

        Database.LeadConvertResult conversionResult = Database.convertLead(convertRequest);
        if (!conversionResult.isSuccess()) {
            result.message = buildConversionErrorMessage(conversionResult);
            return result;
        }

        result.success = true;
        result.accountId = conversionResult.getAccountId();
        result.contactId = conversionResult.getContactId();
        result.opportunityId = conversionResult.getOpportunityId();
        result.message = shouldCreateOpportunity
            ? '리드를 전환하고 기회를 생성했습니다.'
            : '리드를 전환하고 거래처/연락처를 생성했습니다.';
        populateUrls(result);
        return result;
    }

    private static LeadSummary buildLeadSummary(Lead leadRecord) {
        LeadSummary summary = new LeadSummary();
        summary.id = leadRecord.Id;
        summary.name = leadRecord.Name;
        summary.company = leadRecord.Company;
        summary.status = leadRecord.Status;
        summary.email = leadRecord.Email;
        summary.phone = leadRecord.Phone;
        summary.salesPriority = leadRecord.Sales_Priority__c;
        summary.leadScore = leadRecord.Lead_Score__c == null
            ? null
            : leadRecord.Lead_Score__c.intValue();
        summary.consultationType = leadRecord.Consultation_Type__c;
        summary.routingGroup = leadRecord.Sales_Routing_Group__c;
        summary.contractEndWindow = leadRecord.Contract_End_Window__c;
        summary.salesActionSummary = leadRecord.Sales_Action_Summary__c;
        summary.isConverted = leadRecord.IsConverted;
        summary.convertedAccountId = leadRecord.ConvertedAccountId;
        summary.convertedContactId = leadRecord.ConvertedContactId;
        summary.convertedOpportunityId = leadRecord.ConvertedOpportunityId;
        return summary;
    }

    private static List<PicklistOption> buildConvertedStatuses() {
        List<PicklistOption> options = new List<PicklistOption>();
        for (LeadStatus statusRecord : [
            SELECT MasterLabel, ApiName
            FROM LeadStatus
            WHERE IsConverted = true
            ORDER BY SortOrder ASC
        ]) {
            options.add(
                new PicklistOption(
                    statusRecord.MasterLabel,
                    coalesceStatusValue(statusRecord)
                )
            );
        }
        return options;
    }

    private static List<AccountSuggestion> buildAccountSuggestions(Lead leadRecord) {
        List<AccountSuggestion> suggestions = new List<AccountSuggestion>();
        if (String.isBlank(leadRecord.Company)) {
            return suggestions;
        }

        String exactCompanyName = leadRecord.Company.trim();
        String companyPrefix = exactCompanyName + '%';
        for (Account accountRecord : [
            SELECT Id, Name, Industry, Owner.Name
            FROM Account
            WHERE Name = :exactCompanyName OR Name LIKE :companyPrefix
            ORDER BY Name ASC
            LIMIT :SUGGESTION_LIMIT
        ]) {
            AccountSuggestion suggestion = new AccountSuggestion();
            suggestion.id = accountRecord.Id;
            suggestion.name = accountRecord.Name;
            suggestion.industry = accountRecord.Industry;
            suggestion.ownerName = accountRecord.Owner == null ? null : accountRecord.Owner.Name;
            suggestion.isExactMatch = accountRecord.Name != null &&
                accountRecord.Name.toLowerCase() == exactCompanyName.toLowerCase();
            suggestion.label = buildAccountLabel(suggestion);
            suggestions.add(suggestion);
        }
        return suggestions;
    }

    private static List<ContactSuggestion> buildContactSuggestions(Lead leadRecord) {
        List<ContactSuggestion> suggestions = new List<ContactSuggestion>();
        if (String.isBlank(leadRecord.Email)) {
            return suggestions;
        }

        String email = leadRecord.Email.trim();
        for (Contact contactRecord : [
            SELECT Id, Name, Email, AccountId, Account.Name
            FROM Contact
            WHERE Email = :email
            ORDER BY LastModifiedDate DESC
            LIMIT :SUGGESTION_LIMIT
        ]) {
            ContactSuggestion suggestion = new ContactSuggestion();
            suggestion.id = contactRecord.Id;
            suggestion.name = contactRecord.Name;
            suggestion.email = contactRecord.Email;
            suggestion.accountId = contactRecord.AccountId;
            suggestion.accountName = contactRecord.Account == null ? null : contactRecord.Account.Name;
            suggestion.isExactMatch = contactRecord.Email != null &&
                contactRecord.Email.toLowerCase() == email.toLowerCase();
            suggestion.label = buildContactLabel(suggestion);
            suggestions.add(suggestion);
        }
        return suggestions;
    }

    private static String buildAccountLabel(AccountSuggestion suggestion) {
        List<String> segments = new List<String>();
        addSegment(segments, suggestion.name);
        addSegment(segments, suggestion.industry);
        addSegment(segments, suggestion.ownerName);
        return String.join(segments, ' · ');
    }

    private static String buildContactLabel(ContactSuggestion suggestion) {
        List<String> segments = new List<String>();
        addSegment(segments, suggestion.name);
        addSegment(segments, suggestion.email);
        addSegment(segments, suggestion.accountName);
        return String.join(segments, ' · ');
    }

    private static void addSegment(List<String> segments, String value) {
        if (!String.isBlank(value)) {
            segments.add(value);
        }
    }

    private static String resolveConvertedStatus(String providedStatus) {
        List<LeadStatus> statuses = [
            SELECT MasterLabel, ApiName
            FROM LeadStatus
            WHERE IsConverted = true
            ORDER BY SortOrder ASC
        ];
        if (statuses.isEmpty()) {
            return null;
        }

        if (String.isBlank(providedStatus)) {
            return coalesceStatusValue(statuses[0]);
        }

        for (LeadStatus statusRecord : statuses) {
            if (providedStatus == statusRecord.MasterLabel ||
                providedStatus == statusRecord.ApiName) {
                return coalesceStatusValue(statusRecord);
            }
        }

        return providedStatus;
    }

    private static String coalesceStatusValue(LeadStatus statusRecord) {
        if (statusRecord == null) {
            return null;
        }
        return String.isBlank(statusRecord.ApiName)
            ? statusRecord.MasterLabel
            : statusRecord.ApiName;
    }

    private static String buildOpportunityName(Lead leadRecord, String customOpportunityName) {
        if (!String.isBlank(customOpportunityName)) {
            return customOpportunityName.trim();
        }

        List<String> segments = new List<String>();
        addSegment(segments, leadRecord.Company);
        addSegment(segments, leadRecord.Consultation_Type__c);
        String generatedName = String.join(segments, ' - ');
        return String.isBlank(generatedName) ? leadRecord.Name : generatedName;
    }

    private static String buildConversionErrorMessage(Database.LeadConvertResult conversionResult) {
        List<String> messages = new List<String>();
        for (Database.Error errorRecord : conversionResult.getErrors()) {
            messages.add(errorRecord.getMessage());
        }
        return messages.isEmpty()
            ? '리드 전환에 실패했습니다.'
            : String.join(messages, ' ');
    }

    private static void populateUrls(ConvertResult result) {
        result.accountUrl = buildRecordUrl('Account', result.accountId);
        result.contactUrl = buildRecordUrl('Contact', result.contactId);
        result.opportunityUrl = buildRecordUrl('Opportunity', result.opportunityId);
    }

    private static String buildRecordUrl(String objectApiName, Id recordId) {
        return recordId == null ? null : '/lightning/r/' + objectApiName + '/' + recordId + '/view';
    }

    private static String truncateValue(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}
