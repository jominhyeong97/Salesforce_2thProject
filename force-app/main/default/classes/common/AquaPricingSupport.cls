public class AquaPricingSupport {
    @TestVisible private static final String SALES_MODEL_RENTAL = '렌탈';
    @TestVisible private static final String SALES_MODEL_PURCHASE = '구매';
    @TestVisible private static final String SALES_MODEL_COMPARE = '비교 후 결정';

    @TestVisible private static final String QUOTE_SCENARIO_RENTAL = '렌탈안';
    @TestVisible private static final String QUOTE_SCENARIO_PURCHASE = '구매안';
    @TestVisible private static final String QUOTE_SCENARIO_COMPARE = '렌탈/구매 병행';

    @TestVisible private static final String PRICING_TYPE_RENTAL = '렌탈 월과금';
    @TestVisible private static final String PRICING_TYPE_SERVICE = '서비스 월과금';
    @TestVisible private static final String PRICING_TYPE_PURCHASE = '구매 일시금';
    @TestVisible private static final String PRICING_TYPE_INSTALLATION = '설치 일시금';

    @TestVisible private static final Integer DEFAULT_RENTAL_TERM_MONTHS = 36;

    private static final Map<String, LeadPricingTemplate> LEAD_TEMPLATE_BY_PRODUCT =
        buildLeadTemplateByProduct();
    private static final Map<String, Decimal> SERVICE_MONTHLY_BY_PREFERENCE =
        buildServiceMonthlyByPreference();

    private static Set<Id> opportunityIdsInProgress = new Set<Id>();
    private static Set<Id> quoteIdsInProgress = new Set<Id>();

    private class OpportunityPricingRecalculationJob implements Queueable {
        private final List<Id> opportunityIds;

        public OpportunityPricingRecalculationJob(Set<Id> opportunityIds) {
            this.opportunityIds = new List<Id>(opportunityIds);
        }

        public void execute(QueueableContext context) {
            AquaPricingSupport.recalculateOpportunities(new Set<Id>(opportunityIds));
        }
    }

    private class LeadPricingTemplate {
        public Decimal monthlyRentalFeePerUnit;
        public Decimal purchaseAmountPerUnit;
        public Decimal installationFee;

        public LeadPricingTemplate(
            Decimal monthlyRentalFeePerUnit,
            Decimal purchaseAmountPerUnit,
            Decimal installationFee
        ) {
            this.monthlyRentalFeePerUnit = monthlyRentalFeePerUnit;
            this.purchaseAmountPerUnit = purchaseAmountPerUnit;
            this.installationFee = installationFee;
        }
    }

    @TestVisible
    private class OpportunityPricingSnapshot {
        public String salesModel;
        public Decimal rentalTermMonths;
        public Decimal monthlyRentalTotal;
        public Decimal installationTotal;
        public Decimal purchaseTotal;
        public Decimal calculatedTotal;
    }

    private class PricingAccumulator {
        public Decimal monthlyRentalTotal = 0;
        public Decimal installationTotal = 0;
        public Decimal purchaseTotal = 0;
        public Boolean hasRecurring = false;
        public Boolean hasPurchase = false;
        public Boolean hasAmbiguous = false;

        public Boolean hasAnyLines() {
            return hasRecurring || hasPurchase || installationTotal > 0 || hasAmbiguous;
        }
    }

    public static void prepareLeads(List<Lead> leadRecords) {
        for (Lead leadRecord : leadRecords) {
            if (leadRecord == null) {
                continue;
            }

            if (shouldDefaultLeadRentalTerm(leadRecord) &&
                leadRecord.Expected_Rental_Term_Months__c == null) {
                leadRecord.Expected_Rental_Term_Months__c = DEFAULT_RENTAL_TERM_MONTHS;
            }

            applyLeadPricing(leadRecord);
        }
    }

    public static void prepareOpportunities(
        List<Opportunity> newRecords,
        Map<Id, Opportunity> oldMap
    ) {
        for (Opportunity opportunityRecord : newRecords) {
            if (opportunityRecord == null) {
                continue;
            }

            if (shouldDefaultOpportunityRentalTerm(opportunityRecord) &&
                opportunityRecord.Rental_Term_Months__c == null) {
                opportunityRecord.Rental_Term_Months__c = DEFAULT_RENTAL_TERM_MONTHS;
            }
        }
    }

    public static void afterOpportunities(
        List<Opportunity> newRecords,
        Map<Id, Opportunity> oldMap
    ) {
        Set<Id> opportunityIds = new Set<Id>();
        if (newRecords == null) {
            return;
        }

        for (Opportunity opportunityRecord : newRecords) {
            if (opportunityRecord == null || opportunityRecord.Id == null) {
                continue;
            }

            if (oldMap == null) {
                opportunityIds.add(opportunityRecord.Id);
                continue;
            }

            Opportunity oldOpportunity = oldMap.get(opportunityRecord.Id);
            if (oldOpportunity == null ||
                oldOpportunity.Sales_Model__c != opportunityRecord.Sales_Model__c ||
                oldOpportunity.Rental_Term_Months__c != opportunityRecord.Rental_Term_Months__c ||
                oldOpportunity.Monthly_Rental_Fee__c != opportunityRecord.Monthly_Rental_Fee__c ||
                oldOpportunity.Installation_Fee__c != opportunityRecord.Installation_Fee__c ||
                oldOpportunity.Purchase_Total_Amount__c != opportunityRecord.Purchase_Total_Amount__c ||
                oldOpportunity.Calculated_Total_Amount__c != opportunityRecord.Calculated_Total_Amount__c) {
                opportunityIds.add(opportunityRecord.Id);
            }
        }

        recalculateOpportunities(opportunityIds);
    }

    public static void prepareQuotes(List<Quote> newRecords, Map<Id, Quote> oldMap) {
        Map<Id, Opportunity> opportunityById = loadQuoteOpportunities(newRecords);

        for (Quote quoteRecord : newRecords) {
            if (quoteRecord == null) {
                continue;
            }

            Opportunity relatedOpportunity = quoteRecord.OpportunityId == null
                ? null
                : opportunityById.get(quoteRecord.OpportunityId);

            if (String.isBlank(quoteRecord.Proposal_Scenario__c)) {
                quoteRecord.Proposal_Scenario__c = resolveProposalScenarioFromSalesModel(
                    relatedOpportunity == null ? null : relatedOpportunity.Sales_Model__c
                );
            }

            if (requiresQuoteRentalTerm(quoteRecord.Proposal_Scenario__c) &&
                quoteRecord.Rental_Term_Months__c == null) {
                Decimal sourceTerm = relatedOpportunity != null
                    ? relatedOpportunity.Rental_Term_Months__c
                    : null;
                if (sourceTerm != null) {
                    quoteRecord.Rental_Term_Months__c = sourceTerm;
                } else if (oldMap != null) {
                    // On update (e.g. SyncQuote), fill a default so the validation rule
                    // doesn't silently block the operation with a field not shown in the dialog.
                    quoteRecord.Rental_Term_Months__c = DEFAULT_RENTAL_TERM_MONTHS;
                }
            }
        }
    }

    public static void afterQuotes(List<Quote> newRecords, Map<Id, Quote> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        if (newRecords == null) {
            return;
        }

        for (Quote quoteRecord : newRecords) {
            if (quoteRecord == null || quoteRecord.Id == null) {
                continue;
            }

            if (oldMap == null) {
                quoteIds.add(quoteRecord.Id);
                continue;
            }

            Quote oldQuote = oldMap.get(quoteRecord.Id);
            if (oldQuote == null ||
                oldQuote.Proposal_Scenario__c != quoteRecord.Proposal_Scenario__c ||
                oldQuote.Rental_Term_Months__c != quoteRecord.Rental_Term_Months__c) {
                quoteIds.add(quoteRecord.Id);
            }
        }

        recalculateQuotes(quoteIds);
    }

    public static void recalculateOpportunities(Set<Id> opportunityIds) {
        Set<Id> targetIds = new Set<Id>();
        for (Id opportunityId : opportunityIds) {
            if (opportunityId != null && !opportunityIdsInProgress.contains(opportunityId)) {
                targetIds.add(opportunityId);
            }
        }
        if (targetIds.isEmpty()) {
            return;
        }

        opportunityIdsInProgress.addAll(targetIds);
        try {
            Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>([
                SELECT
                    Id,
                    Sales_Model__c,
                    Rental_Term_Months__c,
                    Monthly_Rental_Fee__c,
                    Installation_Fee__c,
                    Purchase_Total_Amount__c,
                    Calculated_Total_Amount__c
                FROM Opportunity
                WHERE Id IN :targetIds
            ]);

            Map<Id, PricingAccumulator> accumulatorsByOpportunityId = new Map<Id, PricingAccumulator>();
            for (OpportunityLineItem lineItem : [
                SELECT
                    OpportunityId,
                    TotalPrice,
                    PricebookEntry.Product2.Family,
                    PricebookEntry.Product2.ProductCode,
                    PricebookEntry.Product2.Aqua_Pricing_Type__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :targetIds
            ]) {
                Opportunity parentOpportunity = opportunitiesById.get(lineItem.OpportunityId);
                if (parentOpportunity == null) {
                    continue;
                }

                if (!accumulatorsByOpportunityId.containsKey(lineItem.OpportunityId)) {
                    accumulatorsByOpportunityId.put(lineItem.OpportunityId, new PricingAccumulator());
                }
                PricingAccumulator accumulator = accumulatorsByOpportunityId.get(lineItem.OpportunityId);
                String pricingType = resolvePricingType(
                    parentOpportunity.Sales_Model__c,
                    null,
                    lineItem.PricebookEntry.Product2.Aqua_Pricing_Type__c,
                    lineItem.PricebookEntry.Product2.Family,
                    lineItem.PricebookEntry.Product2.ProductCode
                );
                applyLineAmountToAccumulator(accumulator, pricingType, lineItem.TotalPrice);
            }

            List<Opportunity> updates = new List<Opportunity>();
            for (Id opportunityId : targetIds) {
                Opportunity existingOpportunity = opportunitiesById.get(opportunityId);
                if (existingOpportunity == null) {
                    continue;
                }

                PricingAccumulator accumulator = accumulatorsByOpportunityId.containsKey(opportunityId)
                    ? accumulatorsByOpportunityId.get(opportunityId)
                    : new PricingAccumulator();
                Boolean hasPricingLines = accumulator.hasAnyLines();
                Decimal monthlyRentalTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.monthlyRentalTotal,
                        existingOpportunity.Monthly_Rental_Fee__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal installationTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.installationTotal,
                        existingOpportunity.Installation_Fee__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal purchaseTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.purchaseTotal,
                        existingOpportunity.Purchase_Total_Amount__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal calculatedTotal = hasPricingLines
                    ? calculateOpportunityTotal(
                        existingOpportunity.Sales_Model__c,
                        monthlyRentalTotal,
                        installationTotal,
                        purchaseTotal,
                        existingOpportunity.Rental_Term_Months__c,
                        accumulator
                    )
                    : null;

                if (!hasOpportunityPricingChanged(
                    existingOpportunity,
                    monthlyRentalTotal,
                    installationTotal,
                    purchaseTotal,
                    calculatedTotal
                )) {
                    continue;
                }

                Opportunity updateRecord = new Opportunity(Id = opportunityId);
                updateRecord.Monthly_Rental_Fee__c = monthlyRentalTotal;
                updateRecord.Installation_Fee__c = installationTotal;
                updateRecord.Purchase_Total_Amount__c = purchaseTotal;
                updateRecord.Calculated_Total_Amount__c = calculatedTotal;
                updates.add(updateRecord);
            }

            if (!updates.isEmpty()) {
                update updates;
            }
        } finally {
            opportunityIdsInProgress.removeAll(targetIds);
        }
    }

    public static void enqueueOpportunityRecalculation(Set<Id> opportunityIds) {
        Set<Id> targetIds = new Set<Id>();
        for (Id opportunityId : opportunityIds) {
            if (opportunityId != null) {
                targetIds.add(opportunityId);
            }
        }
        if (targetIds.isEmpty()) {
            return;
        }

        System.enqueueJob(new OpportunityPricingRecalculationJob(targetIds));
    }

    @TestVisible
    private static OpportunityPricingSnapshot previewOpportunityPricing(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        Opportunity opportunityRecord = [
            SELECT Id, Sales_Model__c, Rental_Term_Months__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        PricingAccumulator accumulator = new PricingAccumulator();
        for (OpportunityLineItem lineItem : [
            SELECT
                TotalPrice,
                PricebookEntry.Product2.Family,
                PricebookEntry.Product2.ProductCode,
                PricebookEntry.Product2.Aqua_Pricing_Type__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]) {
            String pricingType = resolvePricingType(
                opportunityRecord.Sales_Model__c,
                null,
                lineItem.PricebookEntry.Product2.Aqua_Pricing_Type__c,
                lineItem.PricebookEntry.Product2.Family,
                lineItem.PricebookEntry.Product2.ProductCode
            );
            applyLineAmountToAccumulator(accumulator, pricingType, lineItem.TotalPrice);
        }

        OpportunityPricingSnapshot snapshot = new OpportunityPricingSnapshot();
        snapshot.salesModel = opportunityRecord.Sales_Model__c;
        snapshot.rentalTermMonths = opportunityRecord.Rental_Term_Months__c;
        snapshot.monthlyRentalTotal = normalizeCurrency(accumulator.monthlyRentalTotal);
        snapshot.installationTotal = normalizeCurrency(accumulator.installationTotal);
        snapshot.purchaseTotal = normalizeCurrency(accumulator.purchaseTotal);
        snapshot.calculatedTotal = calculateOpportunityTotal(
            opportunityRecord.Sales_Model__c,
            snapshot.monthlyRentalTotal,
            snapshot.installationTotal,
            snapshot.purchaseTotal,
            opportunityRecord.Rental_Term_Months__c,
            accumulator
        );
        return snapshot;
    }

    public static void recalculateQuotes(Set<Id> quoteIds) {
        Set<Id> targetIds = new Set<Id>();
        for (Id quoteId : quoteIds) {
            if (quoteId != null && !quoteIdsInProgress.contains(quoteId)) {
                targetIds.add(quoteId);
            }
        }
        if (targetIds.isEmpty()) {
            return;
        }

        quoteIdsInProgress.addAll(targetIds);
        try {
            Map<Id, Quote> quotesById = new Map<Id, Quote>([
                SELECT
                    Id,
                    Proposal_Scenario__c,
                    Rental_Term_Months__c,
                    Monthly_Rental_Fee__c,
                    Installation_Fee__c,
                    Purchase_Total_Amount__c,
                    Total_Quoted_Amount__c,
                    Opportunity.Sales_Model__c
                FROM Quote
                WHERE Id IN :targetIds
            ]);

            Map<Id, PricingAccumulator> accumulatorsByQuoteId = new Map<Id, PricingAccumulator>();
            for (QuoteLineItem lineItem : [
                SELECT
                    QuoteId,
                    TotalPrice,
                    PricebookEntry.Product2.Family,
                    PricebookEntry.Product2.ProductCode,
                    PricebookEntry.Product2.Aqua_Pricing_Type__c
                FROM QuoteLineItem
                WHERE QuoteId IN :targetIds
            ]) {
                Quote parentQuote = quotesById.get(lineItem.QuoteId);
                if (parentQuote == null) {
                    continue;
                }

                if (!accumulatorsByQuoteId.containsKey(lineItem.QuoteId)) {
                    accumulatorsByQuoteId.put(lineItem.QuoteId, new PricingAccumulator());
                }
                PricingAccumulator accumulator = accumulatorsByQuoteId.get(lineItem.QuoteId);
                String pricingType = resolvePricingType(
                    parentQuote.Opportunity == null ? null : parentQuote.Opportunity.Sales_Model__c,
                    parentQuote.Proposal_Scenario__c,
                    lineItem.PricebookEntry.Product2.Aqua_Pricing_Type__c,
                    lineItem.PricebookEntry.Product2.Family,
                    lineItem.PricebookEntry.Product2.ProductCode
                );
                applyLineAmountToAccumulator(accumulator, pricingType, lineItem.TotalPrice);
            }

            List<Quote> updates = new List<Quote>();
            for (Id quoteId : targetIds) {
                Quote existingQuote = quotesById.get(quoteId);
                if (existingQuote == null) {
                    continue;
                }

                PricingAccumulator accumulator = accumulatorsByQuoteId.containsKey(quoteId)
                    ? accumulatorsByQuoteId.get(quoteId)
                    : new PricingAccumulator();
                Boolean hasPricingLines = accumulator.hasAnyLines();
                Decimal monthlyRentalTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.monthlyRentalTotal,
                        existingQuote.Monthly_Rental_Fee__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal installationTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.installationTotal,
                        existingQuote.Installation_Fee__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal purchaseTotal = hasPricingLines
                    ? resolveStoredValue(
                        accumulator.purchaseTotal,
                        existingQuote.Purchase_Total_Amount__c,
                        accumulator.hasAmbiguous
                    )
                    : null;
                Decimal totalQuotedAmount = hasPricingLines
                    ? calculateQuoteTotal(
                        existingQuote.Proposal_Scenario__c,
                        monthlyRentalTotal,
                        installationTotal,
                        purchaseTotal,
                        existingQuote.Rental_Term_Months__c,
                        accumulator
                    )
                    : null;
                String proposalScenario = hasPricingLines
                    ? resolveProposalScenario(existingQuote.Proposal_Scenario__c, accumulator)
                    : existingQuote.Proposal_Scenario__c;

                if (!hasQuotePricingChanged(
                    existingQuote,
                    proposalScenario,
                    monthlyRentalTotal,
                    installationTotal,
                    purchaseTotal,
                    totalQuotedAmount
                )) {
                    continue;
                }

                Quote updateRecord = new Quote(Id = quoteId);
                updateRecord.Proposal_Scenario__c = proposalScenario;
                updateRecord.Monthly_Rental_Fee__c = monthlyRentalTotal;
                updateRecord.Installation_Fee__c = installationTotal;
                updateRecord.Purchase_Total_Amount__c = purchaseTotal;
                updateRecord.Total_Quoted_Amount__c = totalQuotedAmount;
                updates.add(updateRecord);
            }

            if (!updates.isEmpty()) {
                update updates;
            }
        } finally {
            quoteIdsInProgress.removeAll(targetIds);
        }
    }

    @TestVisible
    private static void applyLeadPricing(Lead leadRecord) {
        LeadPricingTemplate template = LEAD_TEMPLATE_BY_PRODUCT.get(leadRecord.Desired_Product_Type__c);
        Decimal quantity = leadRecord.Estimated_Unit_Count__c == null || leadRecord.Estimated_Unit_Count__c <= 0
            ? 1
            : leadRecord.Estimated_Unit_Count__c;
        Decimal serviceMonthlyFeePerUnit = resolveServiceMonthlyFee(leadRecord.Service_Preference__c);

        Decimal estimatedMonthlyRentalFee = template == null
            ? null
            : normalizeCurrency((template.monthlyRentalFeePerUnit + serviceMonthlyFeePerUnit) * quantity);
        Decimal estimatedPurchaseAmount = template == null
            ? null
            : normalizeCurrency(template.purchaseAmountPerUnit * quantity);
        Decimal estimatedInstallationFee = template == null
            ? null
            : normalizeCurrency(template.installationFee);
        Decimal estimatedTotalAmount = calculateLeadTotal(
            leadRecord,
            estimatedMonthlyRentalFee,
            estimatedPurchaseAmount,
            estimatedInstallationFee
        );

        leadRecord.Estimated_Monthly_Rental_Fee__c = estimatedMonthlyRentalFee;
        leadRecord.Estimated_Purchase_Amount__c = estimatedPurchaseAmount;
        leadRecord.Estimated_Total_Amount__c = estimatedTotalAmount;
    }

    @TestVisible
    private static Decimal calculateLeadTotal(
        Lead leadRecord,
        Decimal estimatedMonthlyRentalFee,
        Decimal estimatedPurchaseAmount,
        Decimal estimatedInstallationFee
    ) {
        Decimal installationFee = estimatedInstallationFee == null ? 0 : estimatedInstallationFee;

        if (leadRecord.Sales_Model__c == SALES_MODEL_RENTAL) {
            Decimal term = resolveLeadRentalTerm(leadRecord);
            return estimatedMonthlyRentalFee == null
                ? null
                : normalizeCurrency((estimatedMonthlyRentalFee * term) + installationFee);
        }
        if (leadRecord.Sales_Model__c == SALES_MODEL_PURCHASE) {
            return estimatedPurchaseAmount == null
                ? null
                : normalizeCurrency(estimatedPurchaseAmount + installationFee);
        }

        Boolean hasRentalBudget = hasSpecifiedValue(leadRecord.Desired_Rental_Budget__c);
        Boolean hasPurchaseBudget = hasSpecifiedValue(leadRecord.Desired_Purchase_Budget__c);
        if (hasRentalBudget && !hasPurchaseBudget && estimatedMonthlyRentalFee != null) {
            Decimal term = resolveLeadRentalTerm(leadRecord);
            return normalizeCurrency((estimatedMonthlyRentalFee * term) + installationFee);
        }
        if (hasPurchaseBudget && !hasRentalBudget && estimatedPurchaseAmount != null) {
            return normalizeCurrency(estimatedPurchaseAmount + installationFee);
        }
        return null;
    }

    @TestVisible
    private static Decimal calculateOpportunityTotal(
        String salesModel,
        Decimal monthlyRentalTotal,
        Decimal installationTotal,
        Decimal purchaseTotal,
        Decimal rentalTermMonths,
        PricingAccumulator accumulator
    ) {
        Decimal safeInstallation = installationTotal == null ? 0 : installationTotal;

        if (salesModel == SALES_MODEL_RENTAL) {
            Decimal safeMonthly = monthlyRentalTotal == null ? 0 : monthlyRentalTotal;
            return normalizeCurrency((safeMonthly * resolveTerm(rentalTermMonths)) + safeInstallation);
        }
        if (salesModel == SALES_MODEL_PURCHASE) {
            Decimal safePurchase = purchaseTotal == null ? 0 : purchaseTotal;
            return normalizeCurrency(safePurchase + safeInstallation);
        }
        if (salesModel == SALES_MODEL_COMPARE) {
            Boolean hasRentalValue = monthlyRentalTotal != null;
            Boolean hasPurchaseValue = purchaseTotal != null;
            if (hasRentalValue && !hasPurchaseValue) {
                return normalizeCurrency((monthlyRentalTotal * resolveTerm(rentalTermMonths)) + safeInstallation);
            }
            if (hasPurchaseValue && !hasRentalValue) {
                return normalizeCurrency(purchaseTotal + safeInstallation);
            }
            return null;
        }
        if (accumulator.hasRecurring && !accumulator.hasPurchase && monthlyRentalTotal != null) {
            return normalizeCurrency((monthlyRentalTotal * resolveTerm(rentalTermMonths)) + safeInstallation);
        }
        if (accumulator.hasPurchase && !accumulator.hasRecurring && purchaseTotal != null) {
            return normalizeCurrency(purchaseTotal + safeInstallation);
        }
        return null;
    }

    @TestVisible
    private static Decimal calculateQuoteTotal(
        String proposalScenario,
        Decimal monthlyRentalTotal,
        Decimal installationTotal,
        Decimal purchaseTotal,
        Decimal rentalTermMonths,
        PricingAccumulator accumulator
    ) {
        Decimal safeInstallation = installationTotal == null ? 0 : installationTotal;

        if (proposalScenario == QUOTE_SCENARIO_RENTAL) {
            Decimal safeMonthly = monthlyRentalTotal == null ? 0 : monthlyRentalTotal;
            return normalizeCurrency((safeMonthly * resolveTerm(rentalTermMonths)) + safeInstallation);
        }
        if (proposalScenario == QUOTE_SCENARIO_PURCHASE) {
            Decimal safePurchase = purchaseTotal == null ? 0 : purchaseTotal;
            return normalizeCurrency(safePurchase + safeInstallation);
        }
        if (proposalScenario == QUOTE_SCENARIO_COMPARE) {
            Boolean hasRentalValue = monthlyRentalTotal != null;
            Boolean hasPurchaseValue = purchaseTotal != null;
            if (hasRentalValue && !hasPurchaseValue) {
                return normalizeCurrency((monthlyRentalTotal * resolveTerm(rentalTermMonths)) + safeInstallation);
            }
            if (hasPurchaseValue && !hasRentalValue) {
                return normalizeCurrency(purchaseTotal + safeInstallation);
            }
            return null;
        }
        if (accumulator.hasRecurring && !accumulator.hasPurchase && monthlyRentalTotal != null) {
            return normalizeCurrency((monthlyRentalTotal * resolveTerm(rentalTermMonths)) + safeInstallation);
        }
        if (accumulator.hasPurchase && !accumulator.hasRecurring && purchaseTotal != null) {
            return normalizeCurrency(purchaseTotal + safeInstallation);
        }
        return null;
    }

    @TestVisible
    private static String resolvePricingType(
        String salesModel,
        String proposalScenario,
        String explicitPricingType,
        String productFamily,
        String productCode
    ) {
        if (!String.isBlank(explicitPricingType)) {
            return explicitPricingType;
        }

        String normalizedCode = String.isBlank(productCode) ? '' : productCode.toUpperCase();
        if (productFamily == '설치' || normalizedCode.contains('INSTALL')) {
            return PRICING_TYPE_INSTALLATION;
        }
        if (productFamily == '서비스' || normalizedCode.contains('CARE') || normalizedCode.contains('SVC')) {
            return PRICING_TYPE_SERVICE;
        }
        if (proposalScenario == QUOTE_SCENARIO_RENTAL || salesModel == SALES_MODEL_RENTAL) {
            return PRICING_TYPE_RENTAL;
        }
        if (proposalScenario == QUOTE_SCENARIO_PURCHASE || salesModel == SALES_MODEL_PURCHASE) {
            return PRICING_TYPE_PURCHASE;
        }
        return null;
    }

    @TestVisible
    private static String resolveProposalScenario(String existingScenario, PricingAccumulator accumulator) {
        if (!String.isBlank(existingScenario)) {
            return existingScenario;
        }
        if (accumulator.hasRecurring && accumulator.hasPurchase) {
            return QUOTE_SCENARIO_COMPARE;
        }
        if (accumulator.hasRecurring) {
            return QUOTE_SCENARIO_RENTAL;
        }
        if (accumulator.hasPurchase) {
            return QUOTE_SCENARIO_PURCHASE;
        }
        return QUOTE_SCENARIO_COMPARE;
    }

    private static void applyLineAmountToAccumulator(
        PricingAccumulator accumulator,
        String pricingType,
        Decimal totalPrice
    ) {
        Decimal normalizedAmount = normalizeCurrency(totalPrice);

        if (pricingType == PRICING_TYPE_RENTAL || pricingType == PRICING_TYPE_SERVICE) {
            accumulator.monthlyRentalTotal += normalizedAmount == null ? 0 : normalizedAmount;
            accumulator.hasRecurring = true;
            return;
        }
        if (pricingType == PRICING_TYPE_INSTALLATION) {
            accumulator.installationTotal += normalizedAmount == null ? 0 : normalizedAmount;
            return;
        }
        if (pricingType == PRICING_TYPE_PURCHASE) {
            accumulator.purchaseTotal += normalizedAmount == null ? 0 : normalizedAmount;
            accumulator.hasPurchase = true;
            return;
        }
        accumulator.hasAmbiguous = true;
    }

    private static Boolean hasOpportunityPricingChanged(
        Opportunity existingOpportunity,
        Decimal monthlyRentalTotal,
        Decimal installationTotal,
        Decimal purchaseTotal,
        Decimal calculatedTotal
    ) {
        return existingOpportunity.Monthly_Rental_Fee__c != monthlyRentalTotal ||
            existingOpportunity.Installation_Fee__c != installationTotal ||
            existingOpportunity.Purchase_Total_Amount__c != purchaseTotal ||
            existingOpportunity.Calculated_Total_Amount__c != calculatedTotal;
    }

    private static Boolean hasQuotePricingChanged(
        Quote existingQuote,
        String proposalScenario,
        Decimal monthlyRentalTotal,
        Decimal installationTotal,
        Decimal purchaseTotal,
        Decimal totalQuotedAmount
    ) {
        return existingQuote.Proposal_Scenario__c != proposalScenario ||
            existingQuote.Monthly_Rental_Fee__c != monthlyRentalTotal ||
            existingQuote.Installation_Fee__c != installationTotal ||
            existingQuote.Purchase_Total_Amount__c != purchaseTotal ||
            existingQuote.Total_Quoted_Amount__c != totalQuotedAmount;
    }

    private static Decimal resolveStoredValue(
        Decimal computedValue,
        Decimal existingValue,
        Boolean hasAmbiguousProducts
    ) {
        if (hasAmbiguousProducts && existingValue != null) {
            return normalizeCurrency(existingValue);
        }
        Decimal normalizedComputedValue = normalizeCurrency(computedValue);
        if (normalizedComputedValue != null && normalizedComputedValue > 0) {
            return normalizedComputedValue;
        }
        return null;
    }

    private static Decimal normalizeCurrency(Decimal rawValue) {
        return rawValue == null ? null : rawValue.setScale(0);
    }

    private static Decimal resolveLeadRentalTerm(Lead leadRecord) {
        return resolveTerm(leadRecord.Expected_Rental_Term_Months__c);
    }

    private static Decimal resolveTerm(Decimal rawTerm) {
        return rawTerm == null || rawTerm <= 0 ? DEFAULT_RENTAL_TERM_MONTHS : rawTerm;
    }

    private static Boolean shouldDefaultLeadRentalTerm(Lead leadRecord) {
        return leadRecord.Sales_Model__c == SALES_MODEL_RENTAL;
    }

    private static Boolean shouldDefaultOpportunityRentalTerm(Opportunity opportunityRecord) {
        return opportunityRecord.Sales_Model__c == SALES_MODEL_RENTAL;
    }

    @TestVisible
    private static String resolveProposalScenarioFromSalesModel(String salesModel) {
        if (salesModel == SALES_MODEL_RENTAL) {
            return QUOTE_SCENARIO_RENTAL;
        }
        if (salesModel == SALES_MODEL_PURCHASE) {
            return QUOTE_SCENARIO_PURCHASE;
        }
        return null;
    }

    @TestVisible
    private static Boolean requiresQuoteRentalTerm(String proposalScenario) {
        return proposalScenario == QUOTE_SCENARIO_RENTAL ||
            proposalScenario == QUOTE_SCENARIO_COMPARE;
    }

    private static Map<Id, Opportunity> loadQuoteOpportunities(List<Quote> quoteRecords) {
        Set<Id> opportunityIds = new Set<Id>();
        for (Quote quoteRecord : quoteRecords) {
            if (quoteRecord != null && quoteRecord.OpportunityId != null) {
                opportunityIds.add(quoteRecord.OpportunityId);
            }
        }

        if (opportunityIds.isEmpty()) {
            return new Map<Id, Opportunity>();
        }

        return new Map<Id, Opportunity>([
            SELECT Id, Sales_Model__c, Rental_Term_Months__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    private static Decimal resolveServiceMonthlyFee(String servicePreference) {
        Decimal monthlyFee = SERVICE_MONTHLY_BY_PREFERENCE.get(servicePreference);
        return monthlyFee == null ? 0 : monthlyFee;
    }

    private static Boolean hasSpecifiedValue(String rawValue) {
        return !String.isBlank(rawValue) && rawValue != '미정';
    }

    private static Map<String, LeadPricingTemplate> buildLeadTemplateByProduct() {
        return new Map<String, LeadPricingTemplate>{
            '정수전용' => new LeadPricingTemplate(32000, 690000, 50000),
            '냉온정' => new LeadPricingTemplate(39000, 980000, 50000),
            '얼음정수기' => new LeadPricingTemplate(47000, 1490000, 50000),
            '대용량' => new LeadPricingTemplate(61000, 1890000, 120000)
        };
    }

    private static Map<String, Decimal> buildServiceMonthlyByPreference() {
        return new Map<String, Decimal>{
            '방문 관리' => 4000,
            '셀프 관리' => 0,
            '상관없음' => 4000,
            '미정' => 4000
        };
    }
}
