public with sharing class QuotePdfGenerationService {
    public class GeneratorSummary {
        @AuraEnabled
        public Id quoteId;

        @AuraEnabled
        public String quoteName;

        @AuraEnabled
        public String quoteNumber;

        @AuraEnabled
        public String accountName;

        @AuraEnabled
        public String opportunityName;

        @AuraEnabled
        public String statusLabel;

        @AuraEnabled
        public String proposalScenario;

        @AuraEnabled
        public Date expirationDate;

        @AuraEnabled
        public Decimal grandTotal;

        @AuraEnabled
        public Integer existingPdfCount;
    }

    public class GenerationResult {
        @AuraEnabled
        public Boolean success;

        @AuraEnabled
        public String message;

        @AuraEnabled
        public Id contentDocumentId;

        @AuraEnabled
        public Id contentVersionId;

        @AuraEnabled
        public String fileTitle;

        @AuraEnabled
        public Integer revisionNumber;
    }

    @AuraEnabled(cacheable=true)
    public static GeneratorSummary getGeneratorSummary(Id quoteId) {
        if (quoteId == null) {
            throw new AuraHandledException('견적 레코드를 찾을 수 없습니다.');
        }

        Quote quoteRecord = [
            SELECT
                Id,
                Name,
                QuoteNumber,
                Status,
                ExpirationDate,
                GrandTotal,
                Total_Quoted_Amount__c,
                Proposal_Scenario__c,
                Account.Name,
                Opportunity.Name
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        GeneratorSummary summary = new GeneratorSummary();
        summary.quoteId = quoteRecord.Id;
        summary.quoteName = quoteRecord.Name;
        summary.quoteNumber = quoteRecord.QuoteNumber;
        summary.accountName = quoteRecord.Account == null ? null : quoteRecord.Account.Name;
        summary.opportunityName = quoteRecord.Opportunity == null ? null : quoteRecord.Opportunity.Name;
        summary.statusLabel = getQuoteStatusLabel(quoteRecord.Status);
        summary.proposalScenario = quoteRecord.Proposal_Scenario__c;
        summary.expirationDate = quoteRecord.ExpirationDate;
        summary.grandTotal = quoteRecord.Total_Quoted_Amount__c == null
            ? quoteRecord.GrandTotal
            : quoteRecord.Total_Quoted_Amount__c;
        summary.existingPdfCount = countLinkedPdfs(quoteId);
        return summary;
    }

    @AuraEnabled
    public static GenerationResult generateBrandedPdf(Id quoteId) {
        GenerationResult result = new GenerationResult();
        result.success = false;

        if (quoteId == null) {
            result.message = '견적 레코드를 찾을 수 없습니다.';
            return result;
        }

        Quote quoteRecord = [
            SELECT Id, Name, Revision_Count__c
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        Integer revisionNumber = getNextRevisionNumber(quoteRecord);
        String fileTitle = buildFileTitle(quoteRecord.Name, revisionNumber);

        Blob pdfBody;
        try {
            pdfBody = buildPdfBody(quoteId);
        } catch (Exception ex) {
            result.message = '견적 PDF를 생성하지 못했습니다. ' + ex.getMessage();
            return result;
        }

        if (pdfBody == null || pdfBody.size() == 0) {
            result.message = '생성된 PDF 내용이 비어 있습니다.';
            return result;
        }

        Savepoint savepointMarker = Database.setSavepoint();
        try {
            ContentVersion contentVersion = new ContentVersion(
                Title = fileTitle,
                PathOnClient = fileTitle + '.pdf',
                VersionData = pdfBody,
                FirstPublishLocationId = quoteId
            );
            insert contentVersion;

            contentVersion = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentVersion.Id
                LIMIT 1
            ];

            update new Quote(
                Id = quoteId,
                Revision_Count__c = revisionNumber
            );

            result.success = true;
            result.message = 'Aqua 견적서 PDF를 생성했습니다.';
            result.contentVersionId = contentVersion.Id;
            result.contentDocumentId = contentVersion.ContentDocumentId;
            result.fileTitle = fileTitle;
            result.revisionNumber = revisionNumber;
            return result;
        } catch (Exception ex) {
            Database.rollback(savepointMarker);
            result.message = '견적 PDF를 저장하지 못했습니다. ' + ex.getMessage();
            return result;
        }
    }

    private static Blob buildPdfBody(Id quoteId) {
        if (Test.isRunningTest()) {
            return Blob.valueOf('Aqua Quote PDF');
        }

        PageReference pdfPage = Page.AquaQuotePdf;
        pdfPage.getParameters().put('id', String.valueOf(quoteId));
        return pdfPage.getContentAsPDF();
    }

    @TestVisible
    private static Integer getNextRevisionNumber(Quote quoteRecord) {
        Integer currentRevision = quoteRecord.Revision_Count__c == null
            ? 0
            : Integer.valueOf(String.valueOf(quoteRecord.Revision_Count__c));
        Integer detectedPdfCount = countLinkedPdfs(quoteRecord.Id);
        return Math.max(currentRevision, detectedPdfCount) + 1;
    }

    @TestVisible
    private static Integer countLinkedPdfs(Id recordId) {
        Set<Id> linkedDocumentIds = new Set<Id>();
        for (ContentDocumentLink documentLink : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ]) {
            linkedDocumentIds.add(documentLink.ContentDocumentId);
        }

        if (linkedDocumentIds.isEmpty()) {
            return 0;
        }

        Integer pdfCount = 0;
        for (ContentVersion versionRecord : [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId IN :linkedDocumentIds
                AND IsLatest = true
                AND FileType = 'PDF'
        ]) {
            pdfCount++;
        }
        return pdfCount;
    }

    private static String buildFileTitle(String quoteName, Integer revisionNumber) {
        String safeName = String.isBlank(quoteName) ? 'Quote' : quoteName;
        safeName = safeName.replaceAll('[\\\\/:*?\"<>|]', ' ');
        safeName = safeName.replaceAll('\\s+', ' ').trim();
        return safeName + ' Aqua V' + revisionNumber;
    }

    private static String getQuoteStatusLabel(String rawValue) {
        if (String.isBlank(rawValue)) {
            return rawValue;
        }

        for (Schema.PicklistEntry entry : Schema.SObjectType.Quote.fields.Status.getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == rawValue) {
                return entry.getLabel();
            }
        }
        return rawValue;
    }
}
