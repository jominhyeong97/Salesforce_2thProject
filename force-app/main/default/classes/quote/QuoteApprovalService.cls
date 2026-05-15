public with sharing class QuoteApprovalService {
    public static final String STATUS_PENDING = '승인대기';
    public static final String STATUS_APPROVED = '승인';
    public static final String STATUS_REJECTED = '반려';
    public static final String QUOTE_STATUS_DRAFT = 'Draft';
    public static final String QUOTE_STATUS_REQUEST = 'In Review';
    public static final String QUOTE_STATUS_PRESENTED = 'Presented';
    public static final String QUOTE_STATUS_ACCEPTED = 'Accepted';
    public static final String QUOTE_STATUS_REQUEST_LABEL = '승인 요청';
    public static final String QUOTE_STATUS_PRESENTED_LABEL = '견적서 송부';
    public static final String QUOTE_STATUS_ACCEPTED_LABEL = '견적 확정';

    private static final String NOTIFICATION_TYPE_DEVELOPER_NAME = 'Approval_Notification';

    public class SubmitResult {
        @AuraEnabled
        public Boolean success;

        @AuraEnabled
        public Id approvalRequestId;

        @AuraEnabled
        public String message;

        @AuraEnabled
        public Id approverId;

        @AuraEnabled
        public Id quoteId;

        @AuraEnabled
        public Id pdfDocumentId;

        @AuraEnabled
        public Id pdfVersionId;
    }

    public class ActionResult {
        @AuraEnabled
        public Boolean success;

        @AuraEnabled
        public Id approvalRequestId;

        @AuraEnabled
        public Id opportunityId;

        @AuraEnabled
        public String status;

        @AuraEnabled
        public String message;
    }

    public class WorkspaceData {
        @AuraEnabled
        public Id approvalRequestId;

        @AuraEnabled
        public String approvalRequestName;

        @AuraEnabled
        public String status;

        @AuraEnabled
        public String requestDetail;

        @AuraEnabled
        public String decisionComment;

        @AuraEnabled
        public Datetime requestedAt;

        @AuraEnabled
        public Datetime respondedAt;

        @AuraEnabled
        public String requesterName;

        @AuraEnabled
        public String approverName;

        @AuraEnabled
        public String approverTitle;

        @AuraEnabled
        public String opportunityName;

        @AuraEnabled
        public String opportunityUrl;

        @AuraEnabled
        public String quoteName;

        @AuraEnabled
        public String quoteUrl;

        @AuraEnabled
        public String quotePdfTitle;

        @AuraEnabled
        public String quotePdfDocumentId;

        @AuraEnabled
        public String quotePdfPreviewUrl;

        @AuraEnabled
        public String quotePdfRecordUrl;

        @AuraEnabled
        public String sealImageUrl;

        @AuraEnabled
        public String snapshotJson;

        @AuraEnabled
        public Boolean canApprove;

        @AuraEnabled
        public Boolean canReject;

        @AuraEnabled
        public Boolean canPrint;
    }

    private class PdfFileInfo {
        public Id documentId;
        public Id versionId;
        public String title;
    }

    private class ApprovalSnapshot {
        public String requestDetail;
        public String requestedAt;
        public OpportunitySnapshot opportunity;
        public QuoteSnapshot quote;
        public List<QuoteLineSnapshot> quoteLines = new List<QuoteLineSnapshot>();
        public FileSnapshot submittedPdf;
    }

    private class OpportunitySnapshot {
        public Id id;
        public String name;
        public String stageName;
        public String accountName;
    }

    private class QuoteSnapshot {
        public Id id;
        public String name;
        public String status;
        public Date expirationDate;
        public Decimal subtotal;
        public Decimal tax;
        public Decimal shippingHandling;
        public Decimal grandTotal;
        public Decimal totalPrice;
        public String quoteToName;
        public String quoteToAddress;
        public String description;
    }

    private class QuoteLineSnapshot {
        public String productName;
        public Decimal quantity;
        public Decimal unitPrice;
        public Decimal totalPrice;
        public Decimal discount;
        public String description;
    }

    private class FileSnapshot {
        public Id documentId;
        public Id versionId;
        public String title;
    }

    public static SubmitResult submitApprovalRequest(Id opportunityId, String requestDetail) {
        return submitApprovalRequestInternal(opportunityId, null, requestDetail);
    }

    public static SubmitResult submitApprovalRequestByQuote(Id quoteId, String requestDetail) {
        SubmitResult result = new SubmitResult();
        result.success = false;

        if (quoteId == null) {
            result.message = '견적 레코드를 찾을 수 없습니다.';
            return result;
        }

        Quote quoteRecord;
        try {
            quoteRecord = [
                SELECT Id, OpportunityId
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];
        } catch (Exception ex) {
            result.message = '견적 정보를 불러오지 못했습니다. ' + ex.getMessage();
            return result;
        }

        if (quoteRecord.OpportunityId == null) {
            result.message = '기회에 연결되지 않은 견적은 승인 요청을 보낼 수 없습니다.';
            return result;
        }

        return submitApprovalRequestInternal(quoteRecord.OpportunityId, quoteRecord.Id, requestDetail);
    }

    private static SubmitResult submitApprovalRequestInternal(
        Id opportunityId,
        Id sourceQuoteId,
        String requestDetail
    ) {
        SubmitResult result = new SubmitResult();
        result.success = false;

        if (opportunityId == null) {
            result.message = '기회 레코드를 찾을 수 없습니다.';
            return result;
        }

        if (String.isBlank(requestDetail)) {
            result.message = '결재 요청 상세를 입력해 주세요.';
            return result;
        }

        Opportunity opportunityRecord;
        try {
            opportunityRecord = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    Account.Name,
                    Account.Owner.ManagerId,
                    OwnerId,
                    Quote_Approver__c,
                    Current_Approval_Request__c,
                    Quote_Approval_Status__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
        } catch (Exception ex) {
            result.message = '기회 정보를 불러오지 못했습니다. ' + ex.getMessage();
            return result;
        }

        Id approverId = opportunityRecord.Account != null &&
            opportunityRecord.Account.Owner != null
            ? opportunityRecord.Account.Owner.ManagerId
            : null;

        if (approverId == null) {
            result.message = '계정 담당자의 상위 매니저가 지정되지 않았습니다. 계정 소유자에게 매니저를 설정한 후 다시 시도해 주세요.';
            return result;
        }

        if (approverId == UserInfo.getUserId()) {
            result.message = '요청자와 결재자(계정 담당자 매니저)가 동일합니다. 계정 소유자의 매니저 설정을 확인해 주세요.';
            return result;
        }

        Id targetQuoteId = sourceQuoteId;
        if (targetQuoteId == null) {
            Opportunity opportunityWithSyncedQuote = [
                SELECT Id, SyncedQuoteId
                FROM Opportunity
                WHERE Id = :opportunityRecord.Id
                LIMIT 1
            ];
            if (opportunityWithSyncedQuote.SyncedQuoteId == null) {
                result.message = '승인 요청 대상 견적이 없습니다. 견적을 먼저 선택해 주세요.';
                return result;
            }
            targetQuoteId = opportunityWithSyncedQuote.SyncedQuoteId;
        }

        Quote quoteRecord = [
            SELECT
                Id,
                Name,
                Status,
                ExpirationDate,
                Subtotal,
                Tax,
                ShippingHandling,
                GrandTotal,
                TotalPrice,
                QuoteToName,
                QuoteToAddress,
                Description,
                OpportunityId
            FROM Quote
            WHERE Id = :targetQuoteId
            LIMIT 1
        ];

        if (quoteRecord.Status != QUOTE_STATUS_REQUEST) {
            result.message =
                '"' +
                QUOTE_STATUS_REQUEST_LABEL +
                '" 상태의 견적서에서만 승인 요청을 보낼 수 있습니다.';
            return result;
        }

        List<Quote_Approval_Request__c> pendingRequests = [
            SELECT Id, Name
            FROM Quote_Approval_Request__c
            WHERE Quote__c = :targetQuoteId
                AND Status__c = :STATUS_PENDING
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!pendingRequests.isEmpty()) {
            result.approvalRequestId = pendingRequests[0].Id;
            result.message =
                '이미 승인 대기 중인 요청이 있습니다. 기존 요청을 확인해 주세요. (' +
                pendingRequests[0].Name +
                ')';
            return result;
        }

        PdfFileInfo pdfFile = findLatestPdfForQuote(quoteRecord.Id);
        if (pdfFile == null) {
            result.message =
                '견적 PDF가 없습니다. PDF 생성 기능으로 견적서를 생성하거나 PDF 파일을 첨부한 후 다시 시도해 주세요.';
            return result;
        }

        ApprovalSnapshot snapshot = buildSnapshot(
            opportunityRecord,
            quoteRecord,
            requestDetail,
            pdfFile
        );

        Savepoint savepointMarker = Database.setSavepoint();
        try {
            Quote_Approval_Request__c approvalRequest = new Quote_Approval_Request__c(
                OpporTunity__c = opportunityRecord.Id,
                Quote__c = quoteRecord.Id,
                Requester__c = UserInfo.getUserId(),
                Approver__c = approverId,
                Status__c = STATUS_PENDING,
                Request_Detail__c = requestDetail.trim(),
                Requested_At__c = System.now(),
                Submitted_Pdf_Document_Id__c = String.valueOf(pdfFile.documentId),
                Submitted_Pdf_Version_Id__c = String.valueOf(pdfFile.versionId),
                Snapshot_Json__c = JSON.serialize(snapshot)
            );
            insert approvalRequest;
            shareApprovalRequest(
                approvalRequest.Id,
                approvalRequest.Approver__c,
                opportunityRecord.OwnerId
            );

            update new Opportunity(
                Id = opportunityRecord.Id,
                Quote_Approval_Status__c = STATUS_PENDING,
                Current_Approval_Request__c = approvalRequest.Id
            );

            sendRequestNotification(approvalRequest, opportunityRecord, quoteRecord);

            result.success = true;
            result.approvalRequestId = approvalRequest.Id;
            result.approverId = approverId;
            result.quoteId = quoteRecord.Id;
            result.pdfDocumentId = pdfFile.documentId;
            result.pdfVersionId = pdfFile.versionId;
            result.message = '견적 승인 요청을 전송했습니다.';
            return result;
        } catch (Exception ex) {
            Database.rollback(savepointMarker);
            result.message = '승인 요청을 저장하지 못했습니다. ' + ex.getMessage();
            return result;
        }
    }

    public static ActionResult processDecision(
        Id approvalRequestId,
        String targetStatus,
        String decisionComment
    ) {
        ActionResult result = new ActionResult();
        result.success = false;
        result.status = targetStatus;
        result.approvalRequestId = approvalRequestId;

        if (approvalRequestId == null) {
            result.message = '결재 요청 레코드를 찾을 수 없습니다.';
            return result;
        }

        if (targetStatus != STATUS_APPROVED && targetStatus != STATUS_REJECTED) {
            result.message = '지원하지 않는 결재 처리 상태입니다.';
            return result;
        }

        Quote_Approval_Request__c approvalRequest = [
            SELECT
                Id,
                Name,
                Status__c,
                Requester__c,
                Requester__r.Name,
                Approver__c,
                Approver__r.Name,
                OpporTunity__c,
                OpporTunity__r.Name,
                OpporTunity__r.StageName,
                OpporTunity__r.OwnerId,
                Quote__c
            FROM Quote_Approval_Request__c
            WHERE Id = :approvalRequestId
            LIMIT 1
        ];

        Id currentUserId = UserInfo.getUserId();
        if (approvalRequest.Approver__c != currentUserId) {
            result.message = '지정된 결재자만 이 요청을 처리할 수 있습니다.';
            return result;
        }

        if (approvalRequest.Requester__c == currentUserId) {
            result.message = '요청자는 자신의 결재 요청을 승인하거나 반려할 수 없습니다.';
            return result;
        }

        if (approvalRequest.Status__c != STATUS_PENDING) {
            result.message = '이미 처리된 결재 요청입니다.';
            return result;
        }

        Savepoint savepointMarker = Database.setSavepoint();
        try {
            update new Quote_Approval_Request__c(
                Id = approvalRequest.Id,
                Status__c = targetStatus,
                Decision_By__c = currentUserId,
                Decision_Comment__c = decisionComment,
                Responded_At__c = System.now()
            );

            Opportunity opportunityUpdate = new Opportunity(
                Id = approvalRequest.OpporTunity__c,
                Quote_Approval_Status__c = targetStatus,
                Current_Approval_Request__c = approvalRequest.Id
            );
            update opportunityUpdate;
            update new Quote(
                Id = approvalRequest.Quote__c,
                Status = targetStatus == STATUS_APPROVED
                    ? QUOTE_STATUS_PRESENTED
                    : QUOTE_STATUS_DRAFT
            );

            sendDecisionNotification(approvalRequest, targetStatus);

            result.success = true;
            result.opportunityId = approvalRequest.OpporTunity__c;
            result.message = targetStatus == STATUS_APPROVED
                ? '견적 승인 처리가 완료되었습니다.'
                : '견적 반려 처리가 완료되었습니다.';

            return result;
        } catch (Exception ex) {
            Database.rollback(savepointMarker);
            result.message = '결재 처리 중 오류가 발생했습니다. ' + ex.getMessage();
            return result;
        }
    }

    public static WorkspaceData getWorkspaceData(Id approvalRequestId) {
        Quote_Approval_Request__c approvalRequest = [
            SELECT
                Id,
                Name,
                Status__c,
                Request_Detail__c,
                Decision_Comment__c,
                Requested_At__c,
                Responded_At__c,
                Requester__c,
                Requester__r.Name,
                Approver__c,
                Approver__r.Name,
                Approver__r.Title,
                Approver__r.Approval_Seal_Document_Id__c,
                OpporTunity__c,
                OpporTunity__r.Name,
                Quote__c,
                Quote__r.Name,
                Submitted_Pdf_Document_Id__c,
                Submitted_Pdf_Version_Id__c,
                Snapshot_Json__c
            FROM Quote_Approval_Request__c
            WHERE Id = :approvalRequestId
            LIMIT 1
        ];

        WorkspaceData workspace = new WorkspaceData();
        workspace.approvalRequestId = approvalRequest.Id;
        workspace.approvalRequestName = approvalRequest.Name;
        workspace.status = approvalRequest.Status__c;
        workspace.requestDetail = approvalRequest.Request_Detail__c;
        workspace.decisionComment = approvalRequest.Decision_Comment__c;
        workspace.requestedAt = approvalRequest.Requested_At__c;
        workspace.respondedAt = approvalRequest.Responded_At__c;
        workspace.requesterName = approvalRequest.Requester__r == null
            ? null
            : approvalRequest.Requester__r.Name;
        workspace.approverName = approvalRequest.Approver__r == null
            ? null
            : approvalRequest.Approver__r.Name;
        workspace.approverTitle = approvalRequest.Approver__r == null
            ? null
            : approvalRequest.Approver__r.Title;
        workspace.opportunityName = approvalRequest.OpporTunity__r == null
            ? null
            : approvalRequest.OpporTunity__r.Name;
        workspace.opportunityUrl = approvalRequest.OpporTunity__c == null
            ? null
            : buildRecordUrl('Opportunity', String.valueOf(approvalRequest.OpporTunity__c));
        workspace.quoteName = approvalRequest.Quote__r == null ? null : approvalRequest.Quote__r.Name;
        workspace.quoteUrl = approvalRequest.Quote__c == null
            ? null
            : buildRecordUrl('Quote', String.valueOf(approvalRequest.Quote__c));
        workspace.quotePdfTitle = '견적 PDF';
        workspace.quotePdfDocumentId = approvalRequest.Submitted_Pdf_Document_Id__c;
        workspace.quotePdfPreviewUrl = buildVersionDownloadUrl(
            approvalRequest.Submitted_Pdf_Version_Id__c
        );
        workspace.quotePdfRecordUrl = buildRecordUrl(
            'ContentDocument',
            approvalRequest.Submitted_Pdf_Document_Id__c
        );
        workspace.sealImageUrl = buildSealImageUrl(
            approvalRequest.Approver__r == null
                ? null
                : approvalRequest.Approver__r.Approval_Seal_Document_Id__c
        );

        String snapshotJson = approvalRequest.Snapshot_Json__c;
        if (String.isBlank(snapshotJson) && approvalRequest.Quote__c != null) {
            Opportunity opportunityRecord = [
                SELECT Id, Name, StageName, Account.Name
                FROM Opportunity
                WHERE Id = :approvalRequest.OpporTunity__c
                LIMIT 1
            ];
            Quote quoteRecord = [
                SELECT
                    Id,
                    Name,
                    Status,
                    ExpirationDate,
                    Subtotal,
                    Tax,
                    ShippingHandling,
                    GrandTotal,
                    TotalPrice,
                    QuoteToName,
                    QuoteToAddress,
                    Description
                FROM Quote
                WHERE Id = :approvalRequest.Quote__c
                LIMIT 1
            ];
            PdfFileInfo pdfFile = new PdfFileInfo();
            pdfFile.documentId = tryParseId(approvalRequest.Submitted_Pdf_Document_Id__c);
            pdfFile.versionId = tryParseId(approvalRequest.Submitted_Pdf_Version_Id__c);
            pdfFile.title = '견적 PDF';
            snapshotJson = JSON.serialize(
                buildSnapshot(opportunityRecord, quoteRecord, approvalRequest.Request_Detail__c, pdfFile)
            );
        }
        workspace.snapshotJson = snapshotJson;

        Boolean canAct = approvalRequest.Status__c == STATUS_PENDING &&
            approvalRequest.Approver__c == UserInfo.getUserId() &&
            approvalRequest.Requester__c != UserInfo.getUserId();
        workspace.canApprove = canAct;
        workspace.canReject = canAct;
        workspace.canPrint = approvalRequest.Status__c == STATUS_APPROVED;
        return workspace;
    }

    private static ApprovalSnapshot buildSnapshot(
        Opportunity opportunityRecord,
        Quote quoteRecord,
        String requestDetail,
        PdfFileInfo pdfFile
    ) {
        ApprovalSnapshot snapshot = new ApprovalSnapshot();
        snapshot.requestDetail = requestDetail;
        snapshot.requestedAt = String.valueOf(System.now());
        snapshot.opportunity = new OpportunitySnapshot();
        snapshot.opportunity.id = opportunityRecord.Id;
        snapshot.opportunity.name = opportunityRecord.Name;
        snapshot.opportunity.stageName = opportunityRecord.StageName;
        snapshot.opportunity.accountName = opportunityRecord.Account == null
            ? null
            : opportunityRecord.Account.Name;

        snapshot.quote = new QuoteSnapshot();
        snapshot.quote.id = quoteRecord.Id;
        snapshot.quote.name = quoteRecord.Name;
        snapshot.quote.status = getQuoteStatusLabel(quoteRecord.Status);
        snapshot.quote.expirationDate = quoteRecord.ExpirationDate;
        snapshot.quote.subtotal = quoteRecord.Subtotal;
        snapshot.quote.tax = quoteRecord.Tax;
        snapshot.quote.shippingHandling = quoteRecord.ShippingHandling;
        snapshot.quote.grandTotal = quoteRecord.GrandTotal;
        snapshot.quote.totalPrice = quoteRecord.TotalPrice;
        snapshot.quote.quoteToName = quoteRecord.QuoteToName;
        snapshot.quote.quoteToAddress = formatAddress(quoteRecord.QuoteToAddress);
        snapshot.quote.description = quoteRecord.Description;

        for (QuoteLineItem lineItem : [
            SELECT
                Quantity,
                UnitPrice,
                TotalPrice,
                Discount,
                Description,
                PricebookEntry.Product2.Name
            FROM QuoteLineItem
            WHERE QuoteId = :quoteRecord.Id
            ORDER BY CreatedDate ASC
        ]) {
            QuoteLineSnapshot lineSnapshot = new QuoteLineSnapshot();
            lineSnapshot.productName = lineItem.PricebookEntry == null ||
                    lineItem.PricebookEntry.Product2 == null
                ? null
                : lineItem.PricebookEntry.Product2.Name;
            lineSnapshot.quantity = lineItem.Quantity;
            lineSnapshot.unitPrice = lineItem.UnitPrice;
            lineSnapshot.totalPrice = lineItem.TotalPrice;
            lineSnapshot.discount = lineItem.Discount;
            lineSnapshot.description = lineItem.Description;
            snapshot.quoteLines.add(lineSnapshot);
        }

        if (pdfFile != null) {
            snapshot.submittedPdf = new FileSnapshot();
            snapshot.submittedPdf.documentId = pdfFile.documentId;
            snapshot.submittedPdf.versionId = pdfFile.versionId;
            snapshot.submittedPdf.title = pdfFile.title;
        }

        return snapshot;
    }

    private static PdfFileInfo findLatestPdfForQuote(Id quoteId) {
        List<ContentVersion> directVersions = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE FirstPublishLocationId = :quoteId
                AND IsLatest = true
                AND FileType = 'PDF'
            ORDER BY ContentModifiedDate DESC
            LIMIT 1
        ];
        if (!directVersions.isEmpty()) {
            return toPdfFileInfo(directVersions[0]);
        }

        Set<Id> linkedDocumentIds = new Set<Id>();
        for (ContentDocumentLink documentLink : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :quoteId
        ]) {
            linkedDocumentIds.add(documentLink.ContentDocumentId);
        }

        if (linkedDocumentIds.isEmpty()) {
            return null;
        }

        List<ContentVersion> linkedVersions = [
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE ContentDocumentId IN :linkedDocumentIds
                AND IsLatest = true
                AND FileType = 'PDF'
            ORDER BY ContentModifiedDate DESC
            LIMIT 1
        ];
        return linkedVersions.isEmpty() ? null : toPdfFileInfo(linkedVersions[0]);
    }

    private static PdfFileInfo toPdfFileInfo(ContentVersion versionRecord) {
        PdfFileInfo pdfFile = new PdfFileInfo();
        pdfFile.documentId = versionRecord.ContentDocumentId;
        pdfFile.versionId = versionRecord.Id;
        pdfFile.title = versionRecord.Title;
        return pdfFile;
    }

    private static void sendRequestNotification(
        Quote_Approval_Request__c approvalRequest,
        Opportunity opportunityRecord,
        Quote quoteRecord
    ) {
        String title = '견적 승인 요청';
        String body =
            opportunityRecord.Name +
            ' / ' +
            quoteRecord.Name +
            ' 견적에 대한 승인 요청이 도착했습니다.';
        sendNotification(
            title,
            body,
            approvalRequest.Id,
            buildWorkspacePageRef(approvalRequest.Id),
            new Set<Id>{ approvalRequest.Approver__c }
        );
    }

    private static void sendDecisionNotification(
        Quote_Approval_Request__c approvalRequest,
        String targetStatus
    ) {
        Set<Id> recipientIds = new Set<Id>();
        if (approvalRequest.Requester__c != null) {
            recipientIds.add(approvalRequest.Requester__c);
        }
        if (approvalRequest.OpporTunity__r != null &&
            approvalRequest.OpporTunity__r.OwnerId != null) {
            recipientIds.add(approvalRequest.OpporTunity__r.OwnerId);
        }
        if (recipientIds.isEmpty()) {
            return;
        }

        String title = targetStatus == STATUS_APPROVED ? '견적 승인 완료' : '견적 반려';
        String body = approvalRequest.Name + ' 요청이 ' + targetStatus + ' 처리되었습니다.';
        sendNotification(
            title,
            body,
            approvalRequest.Id,
            buildWorkspacePageRef(approvalRequest.Id),
            recipientIds
        );
    }

    private static void sendNotification(
        String title,
        String body,
        Id targetId,
        String targetPageRef,
        Set<Id> recipientIds
    ) {
        if (recipientIds == null || recipientIds.isEmpty() || Test.isRunningTest()) {
            return;
        }

        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :NOTIFICATION_TYPE_DEVELOPER_NAME
            LIMIT 1
        ];
        if (notificationTypes.isEmpty()) {
            return;
        }

        try {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(title);
            notification.setBody(body);
            notification.setNotificationTypeId(notificationTypes[0].Id);
            if (!String.isBlank(targetPageRef)) {
                notification.setTargetPageRef(targetPageRef);
            } else if (targetId != null) {
                notification.setTargetId(targetId);
            }
            Set<String> recipientIdStrings = new Set<String>();
            for (Id recipientId : recipientIds) {
                recipientIdStrings.add(String.valueOf(recipientId));
            }
            notification.send(recipientIdStrings);
        } catch (Exception ex) {
            System.debug(
                LoggingLevel.WARN,
                'Quote approval notification was not sent: ' + ex.getMessage()
            );
        }
    }

    @TestVisible
    private static String getQuoteStatusLabel(String statusValue) {
        if (String.isBlank(statusValue)) {
            return statusValue;
        }

        for (Schema.PicklistEntry entry :
            Schema.SObjectType.Quote.fields.Status.getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == statusValue) {
                return entry.getLabel();
            }
        }
        return statusValue;
    }

    private static String buildRecordUrl(String objectApiName, String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }
        return '/lightning/r/' + objectApiName + '/' + recordId + '/view';
    }

    private static String buildVersionDownloadUrl(String versionId) {
        if (String.isBlank(versionId)) {
            return null;
        }
        return '/sfc/servlet.shepherd/version/download/' + versionId;
    }

    private static String buildSealImageUrl(String documentId) {
        Id parsedDocumentId = tryParseId(documentId);
        if (parsedDocumentId == null) {
            return null;
        }

        List<ContentVersion> sealVersions = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :parsedDocumentId
                AND IsLatest = true
            LIMIT 1
        ];
        return sealVersions.isEmpty() ? null : buildVersionDownloadUrl(sealVersions[0].Id);
    }

    private static String buildWorkspacePageRef(Id approvalRequestId) {
        if (approvalRequestId == null) {
            return null;
        }

        Map<String, Object> pageReference = new Map<String, Object>{
            'type' => 'standard__component',
            'attributes' => new Map<String, Object>{
                'componentName' => 'c__quoteApprovalWorkspace'
            },
            'state' => new Map<String, Object>{
                'c__recordId' => String.valueOf(approvalRequestId)
            }
        };
        return JSON.serialize(pageReference);
    }

    private static void shareApprovalRequest(
        Id approvalRequestId,
        Id approverId,
        Id opportunityOwnerId
    ) {
        List<Quote_Approval_Request__Share> sharesToInsert = new List<Quote_Approval_Request__Share>();

        if (approvalRequestId != null && approverId != null) {
            Quote_Approval_Request__Share approverShare = new Quote_Approval_Request__Share();
            approverShare.ParentId = approvalRequestId;
            approverShare.UserOrGroupId = approverId;
            approverShare.AccessLevel = 'Edit';
            approverShare.RowCause = Schema.Quote_Approval_Request__Share.RowCause.Manual;
            sharesToInsert.add(approverShare);
        }

        if (approvalRequestId != null &&
            opportunityOwnerId != null &&
            opportunityOwnerId != approverId) {
            Quote_Approval_Request__Share ownerShare = new Quote_Approval_Request__Share();
            ownerShare.ParentId = approvalRequestId;
            ownerShare.UserOrGroupId = opportunityOwnerId;
            ownerShare.AccessLevel = 'Read';
            ownerShare.RowCause = Schema.Quote_Approval_Request__Share.RowCause.Manual;
            sharesToInsert.add(ownerShare);
        }

        if (!sharesToInsert.isEmpty()) {
            Database.insert(sharesToInsert, false);
        }
    }

    private static String formatAddress(Address addr) {
        if (addr == null) {
            return null;
        }
        List<String> lines = new List<String>();
        if (!String.isBlank(addr.getStreet())) {
            lines.add(addr.getStreet().trim());
        }
        List<String> cityLine = new List<String>();
        if (!String.isBlank(addr.getCity())) {
            cityLine.add(addr.getCity().trim());
        }
        if (!String.isBlank(addr.getState())) {
            cityLine.add(addr.getState().trim());
        }
        if (!String.isBlank(addr.getPostalCode())) {
            cityLine.add(addr.getPostalCode().trim());
        }
        if (!cityLine.isEmpty()) {
            lines.add(String.join(cityLine, ' '));
        }
        if (!String.isBlank(addr.getCountry())) {
            lines.add(addr.getCountry().trim());
        }
        return lines.isEmpty() ? null : String.join(lines, '\n');
    }

    private static Id tryParseId(String rawIdValue) {
        if (String.isBlank(rawIdValue)) {
            return null;
        }

        try {
            return (Id) rawIdValue;
        } catch (Exception ex) {
            return null;
        }
    }
}
