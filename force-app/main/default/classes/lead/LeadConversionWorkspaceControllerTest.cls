@IsTest
private class LeadConversionWorkspaceControllerTest {
    @IsTest
    static void returnsRecommendedExistingAccountAndContact() {
        Account accountRecord = new Account(Name = 'Aqua 추천 거래처');
        insert accountRecord;

        Contact contactRecord = new Contact(
            LastName = '추천 연락처',
            Email = 'lead-convert@example.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        Lead leadRecord = new Lead(
            LastName = '추천리드',
            Company = accountRecord.Name,
            Status = findOpenLeadStatus(),
            Email = contactRecord.Email
        );
        insert leadRecord;

        Test.startTest();
        LeadConversionWorkspaceController.WorkspaceData workspace =
            LeadConversionWorkspaceController.getWorkspaceData(leadRecord.Id);
        Test.stopTest();

        System.assertEquals(leadRecord.Id, workspace.lead.id);
        System.assertEquals(accountRecord.Id, workspace.recommendedAccountId);
        System.assertEquals(contactRecord.Id, workspace.recommendedContactId);
        System.assertEquals('existing', workspace.recommendedAccountMode);
        System.assertEquals('existing', workspace.recommendedContactMode);
        System.assert(!workspace.convertedStatuses.isEmpty());
        System.assertEquals(1, workspace.accountSuggestions.size());
        System.assertEquals(1, workspace.contactSuggestions.size());
    }

    @IsTest
    static void convertsLeadUsingExistingAccountAndContact() {
        Account accountRecord = new Account(Name = 'Aqua 전환 거래처');
        insert accountRecord;

        Contact contactRecord = new Contact(
            LastName = '전환 연락처',
            Email = 'convert-existing@example.com',
            AccountId = accountRecord.Id
        );
        insert contactRecord;

        Lead leadRecord = new Lead(
            LastName = '전환리드',
            Company = accountRecord.Name,
            Status = findOpenLeadStatus(),
            Email = contactRecord.Email,
            Consultation_Type__c = '견적 상담'
        );
        insert leadRecord;

        Test.startTest();
        LeadConversionWorkspaceController.ConvertResult conversion =
            LeadConversionWorkspaceController.convertLeadRecord(
                leadRecord.Id,
                findConvertedLeadStatus(),
                accountRecord.Id,
                contactRecord.Id,
                null,
                true,
                'Aqua 전환 기회'
            );
        Test.stopTest();

        System.assertEquals(true, conversion.success);
        System.assertEquals(accountRecord.Id, conversion.accountId);
        System.assertEquals(contactRecord.Id, conversion.contactId);
        System.assertNotEquals(null, conversion.opportunityId);

        Lead convertedLead = [
            SELECT IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];
        System.assertEquals(true, convertedLead.IsConverted);
        System.assertEquals(accountRecord.Id, convertedLead.ConvertedAccountId);
        System.assertEquals(contactRecord.Id, convertedLead.ConvertedContactId);
        System.assertEquals(conversion.opportunityId, convertedLead.ConvertedOpportunityId);
    }

    @IsTest
    static void convertsLeadToNewAccountWithoutOpportunity() {
        Lead leadRecord = new Lead(
            LastName = '신규전환',
            Company = 'Aqua 신규 거래처',
            Status = findOpenLeadStatus(),
            Consultation_Type__c = '초기 상담'
        );
        insert leadRecord;

        Test.startTest();
        LeadConversionWorkspaceController.ConvertResult conversion =
            LeadConversionWorkspaceController.convertLeadRecord(
                leadRecord.Id,
                findConvertedLeadStatus(),
                null,
                null,
                'Aqua 신규 거래처',
                false,
                null
            );
        Test.stopTest();

        System.assertEquals(true, conversion.success);
        System.assertNotEquals(null, conversion.accountId);
        System.assertNotEquals(null, conversion.contactId);
        System.assertEquals(null, conversion.opportunityId);
    }

    @IsTest
    static void updatesLeadCompanyWhenCustomAccountNameIsProvided() {
        Lead leadRecord = new Lead(
            LastName = '회사명수정',
            Company = '기존 회사명',
            Status = findOpenLeadStatus(),
            Consultation_Type__c = '초기 상담'
        );
        insert leadRecord;

        Test.startTest();
        LeadConversionWorkspaceController.ConvertResult conversion =
            LeadConversionWorkspaceController.convertLeadRecord(
                leadRecord.Id,
                findConvertedLeadStatus(),
                null,
                null,
                '변경된 거래처명',
                false,
                null
            );
        Test.stopTest();

        System.assertEquals(true, conversion.success);

        Account convertedAccount = [
            SELECT Name
            FROM Account
            WHERE Id = :conversion.accountId
        ];
        System.assertEquals('변경된 거래처명', convertedAccount.Name);
    }

    private static String findOpenLeadStatus() {
        return [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = false
            ORDER BY SortOrder ASC
            LIMIT 1
        ].MasterLabel;
    }

    private static String findConvertedLeadStatus() {
        LeadStatus convertedStatus = [
            SELECT MasterLabel, ApiName
            FROM LeadStatus
            WHERE IsConverted = true
            ORDER BY SortOrder ASC
            LIMIT 1
        ];
        return String.isBlank(convertedStatus.ApiName)
            ? convertedStatus.MasterLabel
            : convertedStatus.ApiName;
    }
}
