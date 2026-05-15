@IsTest
private class QuoteApprovalServiceTest {
    @IsTest
    static void submitApprovalRequestCreatesRequestAndUpdatesOpportunity() {
        User approver = createUser('approver1');
        Opportunity opportunityRecord = createOpportunity('승인 요청 생성', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-request.pdf');

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequest(
                opportunityRecord.Id,
                '결재 검토를 위해 상세한 견적 배경과 조건을 공유합니다.'
            );
        Test.stopTest();

        Quote_Approval_Request__c approvalRequest = [
            SELECT
                OpporTunity__c,
                Quote__c,
                Requester__c,
                Approver__c,
                Status__c,
                Request_Detail__c,
                Submitted_Pdf_Document_Id__c,
                Submitted_Pdf_Version_Id__c,
                Snapshot_Json__c
            FROM Quote_Approval_Request__c
            WHERE Id = :result.approvalRequestId
        ];

        Opportunity updatedOpportunity = [
            SELECT Quote_Approval_Status__c, Current_Approval_Request__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];

        System.assertEquals(true, result.success);
        System.assertEquals(QuoteApprovalService.STATUS_PENDING, approvalRequest.Status__c);
        System.assertEquals(opportunityRecord.Id, approvalRequest.OpporTunity__c);
        System.assertEquals(quoteRecord.Id, approvalRequest.Quote__c);
        System.assertEquals(UserInfo.getUserId(), approvalRequest.Requester__c);
        System.assertEquals(approver.Id, approvalRequest.Approver__c);
        System.assertNotEquals(null, approvalRequest.Submitted_Pdf_Document_Id__c);
        System.assertNotEquals(null, approvalRequest.Submitted_Pdf_Version_Id__c);
        System.assert(approvalRequest.Snapshot_Json__c.contains('결재 검토를 위해'));
        System.assertEquals(
            QuoteApprovalService.STATUS_PENDING,
            updatedOpportunity.Quote_Approval_Status__c
        );
        System.assertEquals(approvalRequest.Id, updatedOpportunity.Current_Approval_Request__c);
    }

    @IsTest
    static void submitApprovalRequestByQuoteSupportsQuoteRecordPage() {
        User approver = createUser('approverq1');
        Opportunity opportunityRecord = createOpportunity('Quote 버튼 요청', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-page.pdf');

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequestByQuote(
                quoteRecord.Id,
                'Quote 페이지에서 보낸 요청'
            );
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(quoteRecord.Id, result.quoteId);
    }

    @IsTest
    static void submitApprovalRequestByQuoteAllowsUnsyncedQuote() {
        User approver = createUser('approverq2');
        Opportunity opportunityRecord = createOpportunity('비동기 견적 허용', approver.Id);
        createSyncedQuote(opportunityRecord.Id);

        Quote anotherQuote = createQuote(
            opportunityRecord.Id,
            QuoteApprovalService.QUOTE_STATUS_REQUEST
        );
        attachPdf(anotherQuote.Id, 'quote-unsynced.pdf');

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequestByQuote(
                anotherQuote.Id,
                '동기화되지 않은 견적 요청'
            );
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(anotherQuote.Id, result.quoteId);
    }

    @IsTest
    static void submitApprovalRequestRequiresQuoteRequestStatus() {
        User approver = createUser('approverq3');
        Opportunity opportunityRecord = createOpportunity('상태 제한', approver.Id);
        Quote quoteRecord = createQuote(
            opportunityRecord.Id,
            QuoteApprovalService.QUOTE_STATUS_DRAFT
        );
        attachPdf(quoteRecord.Id, 'quote-draft.pdf');

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequestByQuote(
                quoteRecord.Id,
                '초안 상태에서 요청'
            );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('승인 요청'));
    }

    @IsTest
    static void submitApprovalRequestRejectsSelfApproval() {
        Opportunity opportunityRecord = createOpportunity('자기 결재 방지', UserInfo.getUserId());
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-self.pdf');

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '자기 결재 테스트');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('요청자와 결재자'));
    }

    @IsTest
    static void submitApprovalRequestRequiresPdfAttachment() {
        User approver = createUser('approver2');
        Opportunity opportunityRecord = createOpportunity('PDF 필수', approver.Id);
        createSyncedQuote(opportunityRecord.Id);

        Test.startTest();
        QuoteApprovalService.SubmitResult result =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, 'PDF 없는 요청');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('견적 PDF가 없습니다'));
    }

    @IsTest
    static void approverCanApproveAndUpdateOpportunityStatus() {
        User approver = createUser('approver3');
        Opportunity opportunityRecord = createOpportunity('승인 처리', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-approve.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '승인 테스트 상세');

        Test.startTest();
        System.runAs(approver) {
            QuoteApprovalService.ActionResult actionResult =
                QuoteApprovalService.processDecision(
                    submitResult.approvalRequestId,
                    QuoteApprovalService.STATUS_APPROVED,
                    '승인합니다.'
                );

            System.assertEquals(true, actionResult.success);
        }
        Test.stopTest();

        Quote_Approval_Request__c approvalRequest = [
            SELECT Status__c, Decision_By__c, Decision_Comment__c, Responded_At__c
            FROM Quote_Approval_Request__c
            WHERE Id = :submitResult.approvalRequestId
        ];
        Opportunity updatedOpportunity = [
            SELECT Quote_Approval_Status__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        Quote updatedQuote = [
            SELECT Status
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];

        System.assertEquals(QuoteApprovalService.STATUS_APPROVED, approvalRequest.Status__c);
        System.assertEquals(approver.Id, approvalRequest.Decision_By__c);
        System.assertEquals('승인합니다.', approvalRequest.Decision_Comment__c);
        System.assertNotEquals(null, approvalRequest.Responded_At__c);
        System.assertEquals(QuoteApprovalService.STATUS_APPROVED, updatedOpportunity.Quote_Approval_Status__c);
        System.assertEquals(QuoteApprovalService.QUOTE_STATUS_PRESENTED, updatedQuote.Status);
    }

    @IsTest
    static void approverCanRejectAndUpdateOpportunityStatus() {
        User approver = createUser('approver4');
        Opportunity opportunityRecord = createOpportunity('반려 처리', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-reject.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '반려 테스트 상세');

        Test.startTest();
        System.runAs(approver) {
            QuoteApprovalService.ActionResult actionResult =
                QuoteApprovalService.processDecision(
                    submitResult.approvalRequestId,
                    QuoteApprovalService.STATUS_REJECTED,
                    '수정 후 재상신이 필요합니다.'
                );

            System.assertEquals(true, actionResult.success);
        }
        Test.stopTest();

        Quote_Approval_Request__c approvalRequest = [
            SELECT Status__c, Decision_By__c, Decision_Comment__c
            FROM Quote_Approval_Request__c
            WHERE Id = :submitResult.approvalRequestId
        ];
        Opportunity updatedOpportunity = [
            SELECT Quote_Approval_Status__c
            FROM Opportunity
            WHERE Id = :opportunityRecord.Id
        ];
        Quote updatedQuote = [
            SELECT Status
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];

        System.assertEquals(QuoteApprovalService.STATUS_REJECTED, approvalRequest.Status__c);
        System.assertEquals(approver.Id, approvalRequest.Decision_By__c);
        System.assertEquals('수정 후 재상신이 필요합니다.', approvalRequest.Decision_Comment__c);
        System.assertEquals(QuoteApprovalService.STATUS_REJECTED, updatedOpportunity.Quote_Approval_Status__c);
        System.assertEquals(QuoteApprovalService.QUOTE_STATUS_DRAFT, updatedQuote.Status);
    }

    @IsTest
    static void workspaceDataReturnsSnapshotAndPermissionFlags() {
        User approver = createUser('approver5');
        Opportunity opportunityRecord = createOpportunity('워크스페이스 조회', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-workspace.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '워크스페이스 상세');

        Test.startTest();
        System.runAs(approver) {
            QuoteApprovalService.WorkspaceData workspace =
                QuoteApprovalService.getWorkspaceData(submitResult.approvalRequestId);
            System.assertEquals(true, workspace.canApprove);
            System.assertEquals(true, workspace.canReject);
            System.assertNotEquals(null, workspace.snapshotJson);
            System.assertNotEquals(null, workspace.quotePdfPreviewUrl);
        }
        Test.stopTest();
    }

    @IsTest
    static void submitApprovalRequestRejectsDuplicatePendingRequest() {
        User approver = createUser('approver6');
        Opportunity opportunityRecord = createOpportunity('중복 요청 방지', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-duplicate.pdf');

        QuoteApprovalService.SubmitResult firstResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '첫 번째 요청');

        Test.startTest();
        QuoteApprovalService.SubmitResult secondResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '두 번째 요청');
        Test.stopTest();

        System.assertEquals(true, firstResult.success);
        System.assertEquals(false, secondResult.success);
        System.assert(secondResult.message.contains('이미 승인 대기 중인 요청이 있습니다'));
    }

    @IsTest
    static void processDecisionRejectsInvalidAndUnauthorizedActions() {
        User approver = createUser('approver7');
        User outsider = createUser('outsider1');
        Opportunity opportunityRecord = createOpportunity('결재 권한 검증', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-guard.pdf');

        QuoteApprovalService.SubmitResult submitResult =
            QuoteApprovalService.submitApprovalRequest(opportunityRecord.Id, '권한 검증용 요청');

        Test.startTest();
        QuoteApprovalService.ActionResult invalidStatusResult =
            QuoteApprovalService.processDecision(
                submitResult.approvalRequestId,
                '보류',
                '유효하지 않은 상태'
            );
        System.assertEquals(false, invalidStatusResult.success);
        System.assert(invalidStatusResult.message.contains('지원하지 않는 결재 처리 상태'));

        System.runAs(outsider) {
            QuoteApprovalService.ActionResult unauthorizedResult =
                QuoteApprovalService.processDecision(
                    submitResult.approvalRequestId,
                    QuoteApprovalService.STATUS_APPROVED,
                    '승인 시도'
                );
            System.assertEquals(false, unauthorizedResult.success);
            System.assert(unauthorizedResult.message.contains('지정된 결재자만'));
        }

        System.runAs(approver) {
            QuoteApprovalService.ActionResult firstDecision =
                QuoteApprovalService.processDecision(
                    submitResult.approvalRequestId,
                    QuoteApprovalService.STATUS_APPROVED,
                    '정상 승인'
                );
            System.assertEquals(true, firstDecision.success);

            QuoteApprovalService.ActionResult duplicateDecision =
                QuoteApprovalService.processDecision(
                    submitResult.approvalRequestId,
                    QuoteApprovalService.STATUS_APPROVED,
                    '중복 승인'
                );
            System.assertEquals(false, duplicateDecision.success);
            System.assert(duplicateDecision.message.contains('이미 처리된 결재 요청입니다'));
        }
        Test.stopTest();
    }

    @IsTest
    static void invocableAndWorkspaceControllerBridgeApprovalFlow() {
        User approver = createUser('approver8');
        Opportunity opportunityRecord = createOpportunity('인보커블 브리지', approver.Id);
        Quote quoteRecord = createSyncedQuote(opportunityRecord.Id);
        attachPdf(quoteRecord.Id, 'quote-invocable.pdf');

        QuoteApprovalRequestInvocable.Request requestPayload =
            new QuoteApprovalRequestInvocable.Request();
        requestPayload.quoteId = quoteRecord.Id;
        requestPayload.requestDetail = 'Flow에서 전달한 상세 요청';

        Test.startTest();
        List<QuoteApprovalRequestInvocable.Response> responses =
            QuoteApprovalRequestInvocable.submit(
                new List<QuoteApprovalRequestInvocable.Request>{ requestPayload }
            );
        System.runAs(approver) {
            QuoteApprovalService.WorkspaceData workspace =
                QuoteApprovalWorkspaceController.getWorkspaceData(responses[0].approvalRequestId);
            System.assertEquals(true, workspace.canApprove);
            System.assertEquals(true, workspace.canReject);

            QuoteApprovalService.ActionResult approveResult =
                QuoteApprovalWorkspaceController.approveRequest(
                    responses[0].approvalRequestId,
                    '컨트롤러 승인'
                );
            System.assertEquals(true, approveResult.success);
        }
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertNotEquals(null, responses[0].approvalRequestId);
    }

    private static Opportunity createOpportunity(String name, Id approverId) {
        User accountOwner = createUserWithManager('acown', approverId);

        Account accountRecord = new Account(
            Name = name + ' 거래처',
            OwnerId = accountOwner.Id
        );
        insert accountRecord;

        Pricebook2 pricebookRecord = new Pricebook2(
            Name = name + ' 가격표',
            IsActive = true
        );
        insert pricebookRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = name,
            AccountId = accountRecord.Id,
            StageName = getOpenStageName(),
            CloseDate = Date.today().addDays(14),
            Pricebook2Id = pricebookRecord.Id
        );
        insert opportunityRecord;
        return opportunityRecord;
    }

    private static User createUserWithManager(String aliasSeed, Id managerId) {
        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
        ];
        String uniqueToken = String.valueOf(DateTime.now().getTime());
        String alias = aliasSeed.length() > 8 ? aliasSeed.substring(0, 8) : aliasSeed;
        User userRecord = new User(
            Alias = alias,
            Email = aliasSeed + '.' + uniqueToken + '@owner.example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = '계정담당',
            LanguageLocaleKey = 'ko',
            LocaleSidKey = 'ko_KR',
            ProfileId = profileRecord.Id,
            TimeZoneSidKey = 'Asia/Seoul',
            Username = aliasSeed + '.' + uniqueToken + '@owner.example.com',
            ManagerId = managerId
        );
        insert userRecord;
        return userRecord;
    }

    private static Quote createSyncedQuote(Id opportunityId) {
        Quote quoteRecord = createQuote(opportunityId, QuoteApprovalService.QUOTE_STATUS_REQUEST);

        update new Opportunity(
            Id = opportunityId,
            SyncedQuoteId = quoteRecord.Id
        );
        return quoteRecord;
    }

    private static Quote createQuote(Id opportunityId, String statusValue) {
        Quote quoteRecord = new Quote(
            Name = '승인 대상 견적',
            OpportunityId = opportunityId,
            Status = statusValue,
            ExpirationDate = Date.today().addDays(30),
            Description = '결재 문서에 포함될 견적 설명'
        );
        insert quoteRecord;
        return quoteRecord;
    }

    private static void attachPdf(Id quoteId, String fileName) {
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName.replace('.pdf', ''),
            PathOnClient = fileName,
            VersionData = Blob.valueOf('PDF test content'),
            FirstPublishLocationId = quoteId
        );
        insert contentVersion;
    }

    private static User createUser(String aliasSeed) {
        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
        ];

        String uniqueToken = String.valueOf(DateTime.now().getTime());
        User userRecord = new User(
            Alias = aliasSeed.length() > 8 ? aliasSeed.substring(0, 8) : aliasSeed,
            Email = aliasSeed + '.' + uniqueToken + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = '결재자',
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
            if (entry.isActive() && !entry.isDefaultValue()) {
                return entry.getValue();
            }
        }

        return Schema.SObjectType.Opportunity.fields.StageName.getPicklistValues()[0].getValue();
    }
}
