@IsTest
private class AquaPricingSupportTest {
    @IsTest
    static void calculatesLeadEstimatesFromProductAndServicePreference() {
        Lead leadRecord = new Lead(
            LastName = '가격리드',
            Company = '가격리드 주식회사',
            Status = 'Inbound_Received',
            LeadSource = 'Web',
            Sales_Model__c = '렌탈',
            Desired_Product_Type__c = '정수전용',
            Estimated_Unit_Count__c = 2,
            Service_Preference__c = '방문 관리',
            Inquiry_Intent__c = '견적 요청',
            Purchase_Timeline__c = '1개월 이내'
        );

        insert leadRecord;

        Lead savedLead = [
            SELECT
                Expected_Rental_Term_Months__c,
                Estimated_Monthly_Rental_Fee__c,
                Estimated_Purchase_Amount__c,
                Estimated_Total_Amount__c
            FROM Lead
            WHERE Id = :leadRecord.Id
        ];

        System.assertEquals(36, savedLead.Expected_Rental_Term_Months__c.intValue());
        System.assertEquals(72000, savedLead.Estimated_Monthly_Rental_Fee__c);
        System.assertEquals(1380000, savedLead.Estimated_Purchase_Amount__c);
        System.assertEquals(2642000, savedLead.Estimated_Total_Amount__c);
    }

    @IsTest
    static void recalculatesOpportunityPricingFromLineItems() {
        PricingFixture fixture = createPricingFixture();
        Opportunity rentalOpportunity = new Opportunity(
            Name = '렌탈 가격 기회',
            AccountId = fixture.accountId,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(20),
            Pricebook2Id = fixture.pricebookId,
            Sales_Model__c = '렌탈',
            Rental_Term_Months__c = 36
        );
        insert rentalOpportunity;

        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.rentalEntryId,
                Quantity = 2,
                UnitPrice = 39000
            ),
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.serviceEntryId,
                Quantity = 2,
                UnitPrice = 4000
            ),
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.installEntryId,
                Quantity = 1,
                UnitPrice = 50000
            )
        };

        Test.startTest();
        insert opportunityLineItems;
        Test.stopTest();

        AquaPricingSupport.OpportunityPricingSnapshot pricingSnapshot =
            AquaPricingSupport.previewOpportunityPricing(rentalOpportunity.Id);
        Opportunity updatedOpportunity = [
            SELECT
                Rental_Term_Months__c,
                Monthly_Rental_Fee__c,
                Installation_Fee__c,
                Purchase_Total_Amount__c,
                Calculated_Total_Amount__c
            FROM Opportunity
            WHERE Id = :rentalOpportunity.Id
        ];

        System.assertEquals('렌탈', pricingSnapshot.salesModel);
        System.assertEquals(36, pricingSnapshot.rentalTermMonths.intValue());
        System.assertEquals(86000, pricingSnapshot.monthlyRentalTotal);
        System.assertEquals(50000, pricingSnapshot.installationTotal);
        System.assertEquals(3146000, pricingSnapshot.calculatedTotal);
        System.assertEquals(36, updatedOpportunity.Rental_Term_Months__c.intValue());
        System.assertEquals(86000, updatedOpportunity.Monthly_Rental_Fee__c);
        System.assertEquals(50000, updatedOpportunity.Installation_Fee__c);
        System.assertEquals(null, updatedOpportunity.Purchase_Total_Amount__c);
        System.assertEquals(3146000, updatedOpportunity.Calculated_Total_Amount__c);
    }

    @IsTest
    static void clearsOpportunityPricingWhenLineItemsAreRemoved() {
        PricingFixture fixture = createPricingFixture();
        Opportunity rentalOpportunity = new Opportunity(
            Name = '렌탈 가격 삭제 기회',
            AccountId = fixture.accountId,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(20),
            Pricebook2Id = fixture.pricebookId,
            Sales_Model__c = '렌탈',
            Rental_Term_Months__c = 36
        );
        insert rentalOpportunity;

        List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.rentalEntryId,
                Quantity = 2,
                UnitPrice = 39000
            ),
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.serviceEntryId,
                Quantity = 2,
                UnitPrice = 4000
            ),
            new OpportunityLineItem(
                OpportunityId = rentalOpportunity.Id,
                PricebookEntryId = fixture.installEntryId,
                Quantity = 1,
                UnitPrice = 50000
            )
        };

        Test.startTest();
        insert opportunityLineItems;
        delete opportunityLineItems;
        Test.stopTest();

        Opportunity clearedOpportunity = [
            SELECT
                Monthly_Rental_Fee__c,
                Installation_Fee__c,
                Purchase_Total_Amount__c,
                Calculated_Total_Amount__c
            FROM Opportunity
            WHERE Id = :rentalOpportunity.Id
        ];

        System.assertEquals(null, clearedOpportunity.Monthly_Rental_Fee__c);
        System.assertEquals(null, clearedOpportunity.Installation_Fee__c);
        System.assertEquals(null, clearedOpportunity.Purchase_Total_Amount__c);
        System.assertEquals(null, clearedOpportunity.Calculated_Total_Amount__c);
    }

    @IsTest
    static void recalculatesQuotePricingAndGeneratorSummary() {
        PricingFixture fixture = createPricingFixture();
        Opportunity purchaseOpportunity = new Opportunity(
            Name = '구매 가격 기회',
            AccountId = fixture.accountId,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = fixture.pricebookId,
            Sales_Model__c = '구매'
        );
        insert purchaseOpportunity;

        Quote quoteRecord = new Quote(
            Name = '구매 가격 견적',
            OpportunityId = purchaseOpportunity.Id,
            Pricebook2Id = fixture.pricebookId,
            Status = 'Draft',
            Proposal_Scenario__c = '구매안',
            ExpirationDate = Date.today().addDays(14)
        );
        insert quoteRecord;

        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
            new QuoteLineItem(
                QuoteId = quoteRecord.Id,
                PricebookEntryId = fixture.purchaseEntryId,
                Quantity = 2,
                UnitPrice = 980000
            ),
            new QuoteLineItem(
                QuoteId = quoteRecord.Id,
                PricebookEntryId = fixture.installEntryId,
                Quantity = 1,
                UnitPrice = 50000
            )
        };
        insert quoteLineItems;

        Quote updatedQuote = [
            SELECT
                Proposal_Scenario__c,
                Monthly_Rental_Fee__c,
                Installation_Fee__c,
                Purchase_Total_Amount__c,
                Total_Quoted_Amount__c
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];

        Test.startTest();
        QuotePdfGenerationService.GeneratorSummary summary =
            QuotePdfGenerationService.getGeneratorSummary(quoteRecord.Id);
        Test.stopTest();

        System.assertEquals('구매안', updatedQuote.Proposal_Scenario__c);
        System.assertEquals(null, updatedQuote.Monthly_Rental_Fee__c);
        System.assertEquals(50000, updatedQuote.Installation_Fee__c);
        System.assertEquals(1960000, updatedQuote.Purchase_Total_Amount__c);
        System.assertEquals(2010000, updatedQuote.Total_Quoted_Amount__c);
        System.assertEquals(2010000, summary.grandTotal);

        delete quoteLineItems;

        Quote clearedQuote = [
            SELECT
                Proposal_Scenario__c,
                Monthly_Rental_Fee__c,
                Installation_Fee__c,
                Purchase_Total_Amount__c,
                Total_Quoted_Amount__c
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];

        System.assertEquals('구매안', clearedQuote.Proposal_Scenario__c);
        System.assertEquals(null, clearedQuote.Monthly_Rental_Fee__c);
        System.assertEquals(null, clearedQuote.Installation_Fee__c);
        System.assertEquals(null, clearedQuote.Purchase_Total_Amount__c);
        System.assertEquals(null, clearedQuote.Total_Quoted_Amount__c);
    }

    @IsTest
    static void inheritsQuoteScenarioAndRentalTermFromOpportunity() {
        PricingFixture fixture = createPricingFixture();
        Opportunity rentalOpportunity = new Opportunity(
            Name = '렌탈 견적 상속 기회',
            AccountId = fixture.accountId,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(15),
            Pricebook2Id = fixture.pricebookId,
            Sales_Model__c = '렌탈',
            Rental_Term_Months__c = 48
        );
        insert rentalOpportunity;

        Quote quoteRecord = new Quote(
            Name = '렌탈 상속 견적',
            OpportunityId = rentalOpportunity.Id,
            Pricebook2Id = fixture.pricebookId,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(7)
        );
        insert quoteRecord;

        Quote savedQuote = [
            SELECT Proposal_Scenario__c, Rental_Term_Months__c
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];

        System.assertEquals('렌탈안', savedQuote.Proposal_Scenario__c);
        System.assertEquals(48, savedQuote.Rental_Term_Months__c.intValue());
    }

    @IsTest
    static void blocksRentalQuoteWithoutRentalTerm() {
        PricingFixture fixture = createPricingFixture();
        Opportunity purchaseOpportunity = new Opportunity(
            Name = '렌탈 기간 검증 기회',
            AccountId = fixture.accountId,
            StageName = '기회 발굴',
            CloseDate = Date.today().addDays(15),
            Pricebook2Id = fixture.pricebookId,
            Sales_Model__c = '구매'
        );
        insert purchaseOpportunity;

        Quote quoteRecord = new Quote(
            Name = '렌탈 기간 누락 견적',
            OpportunityId = purchaseOpportunity.Id,
            Pricebook2Id = fixture.pricebookId,
            Status = 'Draft',
            Proposal_Scenario__c = '렌탈안',
            ExpirationDate = Date.today().addDays(7)
        );

        Database.SaveResult result = Database.insert(quoteRecord, false);
        System.assertEquals(false, result.isSuccess());
        System.assert(result.getErrors()[0].getMessage().contains('렌탈 기간(개월)을 입력'));
    }

    private static PricingFixture createPricingFixture() {
        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = standardPricebookId, IsActive = true);

        Account accountRecord = new Account(Name = '가격 테스트 거래처');
        insert accountRecord;

        Product2 rentalProduct = new Product2(
            Name = 'Aqua Rental CoolHot',
            ProductCode = 'AQ-RENT-COOLHOT',
            Family = '정수기',
            Aqua_Pricing_Type__c = '렌탈 월과금',
            IsActive = true
        );
        Product2 serviceProduct = new Product2(
            Name = 'Aqua Care Basic',
            ProductCode = 'AQ-CARE-BASIC',
            Family = '서비스',
            Aqua_Pricing_Type__c = '서비스 월과금',
            IsActive = true
        );
        Product2 installProduct = new Product2(
            Name = 'Aqua Install',
            ProductCode = 'AQ-INSTALL-STANDARD',
            Family = '설치',
            Aqua_Pricing_Type__c = '설치 일시금',
            IsActive = true
        );
        Product2 purchaseProduct = new Product2(
            Name = 'Aqua Purchase CoolHot',
            ProductCode = 'AQ-BUY-COOLHOT',
            Family = '정수기',
            Aqua_Pricing_Type__c = '구매 일시금',
            IsActive = true
        );
        insert new List<Product2>{ rentalProduct, serviceProduct, installProduct, purchaseProduct };

        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = rentalProduct.Id,
                UnitPrice = 39000,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = serviceProduct.Id,
                UnitPrice = 4000,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = installProduct.Id,
                UnitPrice = 50000,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = purchaseProduct.Id,
                UnitPrice = 980000,
                IsActive = true
            )
        };

        Map<String, Id> entryIdByCode = new Map<String, Id>();
        Set<Id> productIds = new Set<Id>{
            rentalProduct.Id,
            serviceProduct.Id,
            installProduct.Id,
            purchaseProduct.Id
        };

        for (PricebookEntry entryRecord : [
            SELECT Id, Product2.ProductCode
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND Product2Id IN :productIds
        ]) {
            entryIdByCode.put(entryRecord.Product2.ProductCode, entryRecord.Id);
        }

        PricingFixture fixture = new PricingFixture();
        fixture.accountId = accountRecord.Id;
        fixture.pricebookId = standardPricebookId;
        fixture.rentalEntryId = entryIdByCode.get('AQ-RENT-COOLHOT');
        fixture.serviceEntryId = entryIdByCode.get('AQ-CARE-BASIC');
        fixture.installEntryId = entryIdByCode.get('AQ-INSTALL-STANDARD');
        fixture.purchaseEntryId = entryIdByCode.get('AQ-BUY-COOLHOT');
        return fixture;
    }

    private class PricingFixture {
        public Id accountId;
        public Id pricebookId;
        public Id rentalEntryId;
        public Id serviceEntryId;
        public Id installEntryId;
        public Id purchaseEntryId;
    }
}
