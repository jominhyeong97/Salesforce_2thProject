@IsTest
private class QuoteStatusGuardHandlerTest {
    @IsTest
    static void blocksEnteringPresentedWithoutApprovedRequest() {
        Opportunity opportunityRecord = createOpportunity(null);
        Quote quoteRecord = createQuote(opportunityRecord.Id, QuoteApprovalService.QUOTE_STATUS_REQUEST);

        Test.startTest();
        quoteRecord.Status = QuoteApprovalService.QUOTE_STATUS_PRESENTED;
        try {
            update quoteRecord;
            System.assert(false, '승인 없는 견적서 송부 단계 진입은 차단되어야 합니다.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('승인 완료된 견적서'));
        }
        Test.stopTest();
    }

    @IsTest
    static void blocksEnteringAcceptedWhenQuoteIsNotSynced() {
        User approver = createUser('qtguard1');
        Opportunity opportunityRecord = createOpportunity(approver.Id);
        Quote syncedQuote = createQuote(opportunityRecord.Id, QuoteApprovalService.QUOTE_STATUS_REQUEST);
        update new Opportunity(Id = opportunityRecord.Id, SyncedQuoteId = syncedQuote.Id);

        Quote unsyncedQuote = createQuote(
            opportunityRecord.Id,
            QuoteApprovalService.QUOTE_STATUS_REQUEST
        );
        attachPdf(unsyncedQuote.Id, 'unsynced-accepted.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequestByQuote(
                unsyncedQuote.Id,
                '비동기 견적 승인 요청'
            );

        System.runAs(approver) {
            QuoteApprovalService.processDecision(
                submitResult.approvalRequestId,
                QuoteApprovalService.STATUS_APPROVED,
                '승인'
            );
        }

        Test.startTest();
        unsyncedQuote = [SELECT Id, Status FROM Quote WHERE Id = :unsyncedQuote.Id];
        unsyncedQuote.Status = QuoteApprovalService.QUOTE_STATUS_ACCEPTED;
        try {
            update unsyncedQuote;
            System.assert(false, '동기화되지 않은 견적 확정은 차단되어야 합니다.');
        } catch (DmlException ex) {
            System.assert(ex.getMessage().contains('제품 동기화'));
        }
        Test.stopTest();
    }

    @IsTest
    static void allowsEnteringAcceptedWhenQuoteIsApprovedAndSynced() {
        User approver = createUser('qtguard2');
        Opportunity opportunityRecord = createOpportunity(approver.Id);
        Quote quoteRecord = createQuote(opportunityRecord.Id, QuoteApprovalService.QUOTE_STATUS_REQUEST);
        update new Opportunity(Id = opportunityRecord.Id, SyncedQuoteId = quoteRecord.Id);
        attachPdf(quoteRecord.Id, 'synced-accepted.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequestByQuote(
                quoteRecord.Id,
                '동기화 견적 승인 요청'
            );

        System.runAs(approver) {
            QuoteApprovalService.processDecision(
                submitResult.approvalRequestId,
                QuoteApprovalService.STATUS_APPROVED,
                '승인'
            );
        }

        Test.startTest();
        quoteRecord = [SELECT Id, Status FROM Quote WHERE Id = :quoteRecord.Id];
        quoteRecord.Status = QuoteApprovalService.QUOTE_STATUS_ACCEPTED;
        update quoteRecord;
        Test.stopTest();

        Quote verifiedQuote = [SELECT Status FROM Quote WHERE Id = :quoteRecord.Id];
        System.assertEquals(QuoteApprovalService.QUOTE_STATUS_ACCEPTED, verifiedQuote.Status);
    }

    private static Opportunity createOpportunity(Id approverId) {
        Account accountRecord = new Account(Name = 'Quote Guard 거래처');
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(Name = 'Quote Guard 가격표', IsActive = true);
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Quote Guard 기회',
            AccountId = accountRecord.Id,
            StageName = getOpenStageName(),
            CloseDate = Date.today().addDays(10),
            Pricebook2Id = pricebookRecord.Id,
            Quote_Approver__c = approverId,
            Business_Verified__c = true,
            Business_Number__c = '123-45-67890'
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static Quote createQuote(Id opportunityId, String statusValue) {
        Quote quoteRecord = new Quote(
            Name = 'Quote Guard 견적',
            OpportunityId = opportunityId,
            Status = statusValue,
            ExpirationDate = Date.today().addDays(20)
        );
        insert quoteRecord;
        return quoteRecord;
    }

    private static void attachPdf(Id quoteId, String fileName) {
        insert new ContentVersion(
            Title = fileName.replace('.pdf', ''),
            PathOnClient = fileName,
            VersionData = Blob.valueOf('pdf'),
            FirstPublishLocationId = quoteId
        );
    }

    private static User createUser(String aliasSeed) {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId()];
        String uniqueToken = String.valueOf(DateTime.now().getTime());
        User userRecord = new User(
            Alias = aliasSeed.length() > 8 ? aliasSeed.substring(0, 8) : aliasSeed,
            Email = aliasSeed + '.' + uniqueToken + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = '승인자',
            LanguageLocaleKey = 'ko',
            LocaleSidKey = 'ko_KR',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'Asia/Seoul',
            Username = aliasSeed + '.' + uniqueToken + '@example.com'
        );
        insert userRecord;
        return userRecord;
    }

    private static String getOpenStageName() {
        for (Schema.PicklistEntry entry :
            Schema.SObjectType.Opportunity.fields.StageName.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return '기회 발굴';
    }
}
