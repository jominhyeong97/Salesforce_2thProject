public with sharing class AquaQuotePdfController {
    public class LineItemView {
        public Integer sequence { get; private set; }
        public String productName { get; private set; }
        public String productCode { get; private set; }
        public String description { get; private set; }
        public Decimal quantity { get; private set; }
        public Decimal unitPrice { get; private set; }
        public Decimal totalPrice { get; private set; }
        public Decimal discountPercent { get; private set; }

        public LineItemView(Integer sequence, QuoteLineItem lineItem) {
            this.sequence = sequence;
            this.productName = lineItem.PricebookEntry == null ||
                    lineItem.PricebookEntry.Product2 == null
                ? null
                : lineItem.PricebookEntry.Product2.Name;
            this.productCode = lineItem.PricebookEntry == null ||
                    lineItem.PricebookEntry.Product2 == null
                ? null
                : lineItem.PricebookEntry.Product2.ProductCode;
            this.description = lineItem.Description;
            this.quantity = lineItem.Quantity;
            this.unitPrice = lineItem.UnitPrice;
            this.totalPrice = lineItem.TotalPrice;
            this.discountPercent = lineItem.Discount;
        }

        public String getDiscountLabel() {
            if (discountPercent == null || discountPercent == 0) {
                return '-';
            }
            return discountPercent.stripTrailingZeros().format() + '%';
        }
    }

    public Quote quoteRecord { get; private set; }
    public Contact contactRecord { get; private set; }
    public List<LineItemView> lineItems { get; private set; }
    public String brandCompanyName { get; private set; }
    public String brandTitle { get; private set; }
    public String brandSubtitle { get; private set; }
    public String footerNote { get; private set; }

    public AquaQuotePdfController() {
        this.lineItems = new List<LineItemView>();
        loadBranding();

        Id quoteId = tryParseId(
            ApexPages.currentPage() == null ? null : ApexPages.currentPage().getParameters().get('id')
        );
        if (quoteId != null) {
            loadQuote(quoteId);
        }
    }

    public String getPreparedForName() {
        return firstPopulated(new List<String>{
            quoteRecord == null ? null : quoteRecord.QuoteToName,
            quoteRecord == null ? null : quoteRecord.BillingName,
            quoteRecord == null ? null : quoteRecord.ShippingName,
            quoteRecord == null || quoteRecord.Account == null ? null : quoteRecord.Account.Name
        });
    }

    public String getPreparedForAddressHtml() {
        return toHtmlLineBreaks(
            firstPopulated(new List<String>{
                formatAddress(quoteRecord == null ? null : quoteRecord.QuoteToAddress),
                formatAddress(quoteRecord == null ? null : quoteRecord.BillingAddress),
                formatAddress(quoteRecord == null ? null : quoteRecord.ShippingAddress)
            })
        );
    }

    public String getContactName() {
        return contactRecord == null ? null : contactRecord.Name;
    }

    public String getContactEmail() {
        return firstPopulated(new List<String>{
            quoteRecord == null ? null : quoteRecord.Email,
            contactRecord == null ? null : contactRecord.Email
        });
    }

    public String getContactPhone() {
        return firstPopulated(new List<String>{
            quoteRecord == null ? null : quoteRecord.Phone,
            contactRecord == null ? null : contactRecord.Phone
        });
    }

    public String getAccountName() {
        return quoteRecord == null || quoteRecord.Account == null ? null : quoteRecord.Account.Name;
    }

    public String getAccountPhone() {
        return quoteRecord == null || quoteRecord.Account == null
            ? null
            : quoteRecord.Account.Phone;
    }

    public String getAccountWebsite() {
        return quoteRecord == null || quoteRecord.Account == null
            ? null
            : quoteRecord.Account.Website;
    }

    public String getOpportunityName() {
        return quoteRecord == null || quoteRecord.Opportunity == null
            ? null
            : quoteRecord.Opportunity.Name;
    }

    public String getOpportunityStageName() {
        return quoteRecord == null || quoteRecord.Opportunity == null
            ? null
            : quoteRecord.Opportunity.StageName;
    }

    public String getQuoteStatusLabel() {
        return getPicklistLabel(
            Schema.SObjectType.Quote.fields.Status,
            quoteRecord == null ? null : quoteRecord.Status
        );
    }

    public Decimal getNetAmount() {
        return quoteRecord == null || quoteRecord.TotalPrice == null ? 0 : quoteRecord.TotalPrice;
    }

    public Decimal getSubtotalAmount() {
        return quoteRecord == null || quoteRecord.Subtotal == null ? 0 : quoteRecord.Subtotal;
    }

    public Decimal getDiscountAmount() {
        Decimal discountAmount = getSubtotalAmount() - getNetAmount();
        return discountAmount < 0 ? 0 : discountAmount;
    }

    public Decimal getTaxAmount() {
        return quoteRecord == null || quoteRecord.Tax == null ? 0 : quoteRecord.Tax;
    }

    public Decimal getShippingAmount() {
        return quoteRecord == null || quoteRecord.ShippingHandling == null
            ? 0
            : quoteRecord.ShippingHandling;
    }

    public Decimal getGrandTotalAmount() {
        if (quoteRecord == null) {
            return 0;
        }
        if (quoteRecord.Total_Quoted_Amount__c != null) {
            return quoteRecord.Total_Quoted_Amount__c;
        }
        return quoteRecord.GrandTotal == null ? getNetAmount() : quoteRecord.GrandTotal;
    }

    public Decimal getRentalContractTotalAmount() {
        if (quoteRecord == null || quoteRecord.Monthly_Rental_Fee__c == null) {
            return null;
        }

        Decimal rentalTermMonths = quoteRecord.Rental_Term_Months__c == null
            ? 36
            : quoteRecord.Rental_Term_Months__c;
        Decimal installationFee = quoteRecord.Installation_Fee__c == null
            ? 0
            : quoteRecord.Installation_Fee__c;
        return (quoteRecord.Monthly_Rental_Fee__c * rentalTermMonths) + installationFee;
    }

    public Boolean getHasQuotedTotalAmount() {
        return quoteRecord != null && quoteRecord.Total_Quoted_Amount__c != null;
    }

    public Boolean getHasRentalSummary() {
        return quoteRecord != null &&
            (quoteRecord.Monthly_Rental_Fee__c != null ||
            quoteRecord.Installation_Fee__c != null ||
            quoteRecord.Rental_Term_Months__c != null);
    }

    public Boolean getHasPurchaseSummary() {
        return quoteRecord != null && quoteRecord.Purchase_Total_Amount__c != null;
    }

    public Boolean getHasDescription() {
        return quoteRecord != null && !String.isBlank(quoteRecord.Description);
    }

    public Boolean getHasDiscountJustification() {
        return quoteRecord != null && !String.isBlank(quoteRecord.Discount_Justification__c);
    }

    public Boolean getHasContactBlock() {
        return !String.isBlank(getContactName()) ||
            !String.isBlank(getContactEmail()) ||
            !String.isBlank(getContactPhone());
    }

    public Boolean getHasNoContactBlock() {
        return !getHasContactBlock();
    }

    public Boolean getHasNoDescription() {
        return !getHasDescription();
    }

    public Boolean getHasNoLineItems() {
        return lineItems == null || lineItems.isEmpty();
    }

    public String getQuoteDescriptionHtml() {
        return toHtmlLineBreaks(quoteRecord == null ? null : quoteRecord.Description);
    }

    public String getDiscountJustificationHtml() {
        return toHtmlLineBreaks(quoteRecord == null ? null : quoteRecord.Discount_Justification__c);
    }

    private void loadBranding() {
        brandCompanyName = safeLabel(System.Label.Aqua_Quote_Company_Name, 'Aqua');
        brandTitle = safeLabel(System.Label.Aqua_Quote_Document_Title, '견적 제안서');
        brandSubtitle = safeLabel(
            System.Label.Aqua_Quote_Document_Subtitle,
            '고객 제안 내용을 읽기 쉽게 정리한 견적 문서입니다.'
        );
        footerNote = safeLabel(
            System.Label.Aqua_Quote_Footer_Note,
            '본 견적은 제안 기준으로 작성되었으며 세부 조건은 최종 협의에 따라 조정될 수 있습니다.'
        );
    }

    private void loadQuote(Id quoteId) {
        quoteRecord = [
            SELECT
                Id,
                Name,
                QuoteNumber,
                Status,
                ExpirationDate,
                Description,
                Subtotal,
                TotalPrice,
                Tax,
                ShippingHandling,
                GrandTotal,
                QuoteToName,
                QuoteToAddress,
                BillingName,
                BillingAddress,
                ShippingName,
                ShippingAddress,
                ContactId,
                Email,
                Phone,
                AccountId,
                Account.Name,
                Account.Phone,
                Account.Website,
                OpportunityId,
                Opportunity.Name,
                Opportunity.StageName,
                Proposal_Scenario__c,
                Monthly_Rental_Fee__c,
                Installation_Fee__c,
                Rental_Term_Months__c,
                Purchase_Total_Amount__c,
                Total_Quoted_Amount__c,
                Discount_Justification__c
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];

        if (quoteRecord.ContactId != null) {
            List<Contact> contacts = [
                SELECT Id, Name, Email, Phone
                FROM Contact
                WHERE Id = :quoteRecord.ContactId
                LIMIT 1
            ];
            contactRecord = contacts.isEmpty() ? null : contacts[0];
        }

        Integer sequence = 1;
        for (QuoteLineItem lineItem : [
            SELECT
                Quantity,
                UnitPrice,
                TotalPrice,
                Discount,
                Description,
                PricebookEntry.Product2.Name,
                PricebookEntry.Product2.ProductCode
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY SortOrder ASC, CreatedDate ASC
        ]) {
            lineItems.add(new LineItemView(sequence, lineItem));
            sequence++;
        }
    }

    private static String getPicklistLabel(
        Schema.DescribeFieldResult fieldDescribe,
        String rawValue
    ) {
        if (String.isBlank(rawValue)) {
            return rawValue;
        }
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive() && entry.getValue() == rawValue) {
                return entry.getLabel();
            }
        }
        return rawValue;
    }

    private static String safeLabel(String labelValue, String fallback) {
        return String.isBlank(labelValue) ? fallback : labelValue;
    }

    private static String firstPopulated(List<String> values) {
        for (String candidate : values) {
            if (!String.isBlank(candidate)) {
                return candidate.trim();
            }
        }
        return null;
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

    private static String stringValue(Object rawValue) {
        if (rawValue == null) {
            return null;
        }
        String text = String.valueOf(rawValue);
        return String.isBlank(text) ? null : text.trim();
    }

    private static String toHtmlLineBreaks(String rawValue) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        String normalized = rawValue.escapeHtml4();
        normalized = normalized.replace('\r\n', '<br/>');
        normalized = normalized.replace('\n', '<br/>');
        return normalized;
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
