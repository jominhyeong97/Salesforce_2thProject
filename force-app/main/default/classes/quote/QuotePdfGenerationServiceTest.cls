@IsTest
private class QuotePdfGenerationServiceTest {
    @IsTest
    static void generatesBrandedPdfAndUpdatesRevision() {
        Quote quoteRecord = createQuoteData();

        Test.startTest();
        QuotePdfGenerationService.GeneratorSummary summary =
            QuotePdfGenerationService.getGeneratorSummary(quoteRecord.Id);
        QuotePdfGenerationService.GenerationResult result =
            QuotePdfGenerationService.generateBrandedPdf(quoteRecord.Id);
        Test.stopTest();

        System.assertEquals(quoteRecord.Id, summary.quoteId);
        System.assertEquals('렌탈/구매 병행', summary.proposalScenario);
        System.assertEquals(0, summary.existingPdfCount);

        System.assertEquals(true, result.success);
        System.assertNotEquals(null, result.contentDocumentId);
        System.assertNotEquals(null, result.contentVersionId);
        System.assertEquals(1, result.revisionNumber);

        Quote updatedQuote = [
            SELECT Revision_Count__c
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];
        System.assertEquals(1, Integer.valueOf(String.valueOf(updatedQuote.Revision_Count__c)));

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :quoteRecord.Id
        ];
        System.assertEquals(1, links.size());
    }

    @IsTest
    static void loadsQuoteDataIntoPdfController() {
        Quote quoteRecord = createQuoteData();

        Test.setCurrentPage(Page.AquaQuotePdf);
        ApexPages.currentPage().getParameters().put('id', quoteRecord.Id);

        AquaQuotePdfController controller = new AquaQuotePdfController();

        System.assertEquals('Aqua', controller.brandCompanyName);
        System.assertEquals('고객사 구매팀', controller.getPreparedForName());
        System.assert(controller.getPreparedForAddressHtml().contains('서울특별시'));
        System.assertEquals('buyer@example.com', controller.getContactEmail());
        System.assertEquals('02-1234-5678', controller.getContactPhone());
        System.assertEquals('Aqua 테스트 고객', controller.getAccountName());
        System.assertEquals('02-1234-5678', controller.getAccountPhone());
        System.assertEquals('https://customer.example.com', controller.getAccountWebsite());
        System.assertEquals('Aqua Quote 기회', controller.getOpportunityName());
        System.assertEquals('Proposal/Price Quote', controller.getOpportunityStageName());
        System.assertEquals('초안', controller.getQuoteStatusLabel());
        System.assertEquals(true, controller.getHasRentalSummary());
        System.assertEquals(true, controller.getHasPurchaseSummary());
        System.assertEquals(true, controller.getHasDescription());
        System.assertEquals(true, controller.getHasDiscountJustification());
        System.assertEquals(true, controller.getHasContactBlock());
        System.assertEquals(false, controller.getHasNoContactBlock());
        System.assertEquals(false, controller.getHasNoDescription());
        System.assertEquals(false, controller.getHasNoLineItems());
        System.assert(controller.getQuoteDescriptionHtml().contains('렌탈과 구매 옵션'));
        System.assert(controller.getDiscountJustificationHtml().contains('프로모션'));
        System.assert(controller.getSubtotalAmount() > 0);
        System.assert(controller.getNetAmount() > 0);
        System.assert(controller.getGrandTotalAmount() > 0);
        System.assertEquals(2, controller.lineItems.size());
        System.assertEquals('10%', controller.lineItems[0].getDiscountLabel());
        System.assertEquals('-', controller.lineItems[1].getDiscountLabel());
    }

    @IsTest
    static void handlesEmptyAndFallbackQuoteStates() {
        Quote quoteRecord = createMinimalQuoteData();

        Test.setCurrentPage(Page.AquaQuotePdf);
        AquaQuotePdfController emptyController = new AquaQuotePdfController();
        System.assertEquals('Aqua', emptyController.brandCompanyName);
        System.assertEquals(true, emptyController.getHasNoLineItems());
        System.assertEquals(true, emptyController.getHasNoContactBlock());
        System.assertEquals(true, emptyController.getHasNoDescription());
        System.assertEquals(0, emptyController.getGrandTotalAmount());

        ApexPages.currentPage().getParameters().put('id', quoteRecord.Id);
        AquaQuotePdfController controller = new AquaQuotePdfController();
        System.assertEquals('Fallback 거래처', controller.getPreparedForName());
        System.assertEquals(false, controller.getHasRentalSummary());
        System.assertEquals(false, controller.getHasPurchaseSummary());
        System.assertEquals(false, controller.getHasDescription());
        System.assertEquals(false, controller.getHasDiscountJustification());
        System.assertEquals(true, controller.getHasNoLineItems());
        System.assertEquals(true, controller.getHasNoContactBlock());
        System.assertEquals(true, controller.getHasNoDescription());
        System.assertEquals(null, controller.getPreparedForAddressHtml());
        System.assertEquals(null, controller.getContactEmail());
        System.assertEquals(null, controller.getContactPhone());
        System.assertEquals(null, controller.getDiscountJustificationHtml());
    }

    @IsTest
    static void supportsSecondRevisionAndGuardClauses() {
        Quote quoteRecord = createQuoteData();

        QuotePdfGenerationService.GenerationResult nullResult =
            QuotePdfGenerationService.generateBrandedPdf(null);
        System.assertEquals(false, nullResult.success);

        try {
            QuotePdfGenerationService.getGeneratorSummary(null);
            System.assert(false, '견적 ID가 없으면 예외가 발생해야 합니다.');
        } catch (AuraHandledException ex) {
            System.assertNotEquals(null, ex);
        }

        Test.startTest();
        QuotePdfGenerationService.generateBrandedPdf(quoteRecord.Id);
        QuotePdfGenerationService.GeneratorSummary firstSummary =
            QuotePdfGenerationService.getGeneratorSummary(quoteRecord.Id);
        QuotePdfGenerationService.GenerationResult secondResult =
            QuotePdfGenerationService.generateBrandedPdf(quoteRecord.Id);
        Test.stopTest();

        System.assertEquals(1, firstSummary.existingPdfCount);
        System.assertEquals(true, secondResult.success);
        System.assertEquals(2, secondResult.revisionNumber);
        System.assertEquals(2, QuotePdfGenerationService.countLinkedPdfs(quoteRecord.Id));

        Quote updatedQuote = [
            SELECT Revision_Count__c
            FROM Quote
            WHERE Id = :quoteRecord.Id
        ];
        System.assertEquals(2, Integer.valueOf(String.valueOf(updatedQuote.Revision_Count__c)));
    }

    private static Quote createQuoteData() {
        Account accountRecord = new Account(
            Name = 'Aqua 테스트 고객',
            Phone = '02-1234-5678',
            Website = 'https://customer.example.com'
        );
        insert accountRecord;

        Contact contactRecord = new Contact(
            LastName = '구매담당',
            AccountId = accountRecord.Id,
            Email = 'buyer@example.com',
            Phone = '010-1111-2222'
        );
        insert contactRecord;

        Pricebook2 pricebookRecord = new Pricebook2(
            Name = 'Aqua Quote Pricebook',
            IsActive = true
        );
        insert pricebookRecord;

        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(
            Id = standardPricebookId,
            IsActive = true
        );

        Product2 rentalProduct = new Product2(
            Name = 'Aqua 정수 시스템',
            ProductCode = 'AQ-100',
            IsActive = true
        );
        Product2 serviceProduct = new Product2(
            Name = 'Aqua 설치 서비스',
            ProductCode = 'AQ-SVC',
            IsActive = true
        );
        insert new List<Product2>{ rentalProduct, serviceProduct };

        insert new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = rentalProduct.Id,
                UnitPrice = 1500000,
                IsActive = true
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = serviceProduct.Id,
                UnitPrice = 120000,
                IsActive = true
            )
        };

        PricebookEntry rentalEntry = new PricebookEntry(
            Pricebook2Id = pricebookRecord.Id,
            Product2Id = rentalProduct.Id,
            UnitPrice = 1400000,
            IsActive = true
        );
        PricebookEntry serviceEntry = new PricebookEntry(
            Pricebook2Id = pricebookRecord.Id,
            Product2Id = serviceProduct.Id,
            UnitPrice = 100000,
            IsActive = true
        );
        insert new List<PricebookEntry>{ rentalEntry, serviceEntry };

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Aqua Quote 기회',
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            AccountId = accountRecord.Id,
            Pricebook2Id = pricebookRecord.Id
        );
        insert opportunityRecord;

        Quote quoteRecord = new Quote(
            Name = 'Aqua 4월 제안',
            OpportunityId = opportunityRecord.Id,
            ContactId = contactRecord.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(14),
            QuoteToName = '고객사 구매팀',
            BillingName = '고객사 본사',
            BillingStreet = '서울특별시 강남구 테헤란로 1',
            BillingCity = '서울',
            BillingPostalCode = '06100',
            BillingCountry = '대한민국',
            ShippingName = '설치 현장',
            ShippingStreet = '서울특별시 송파구 올림픽로 10',
            ShippingCity = '서울',
            ShippingPostalCode = '05500',
            ShippingCountry = '대한민국',
            Email = 'buyer@example.com',
            Phone = '02-1234-5678',
            Proposal_Scenario__c = '렌탈/구매 병행',
            Monthly_Rental_Fee__c = 250000,
            Installation_Fee__c = 100000,
            Rental_Term_Months__c = 36,
            Purchase_Total_Amount__c = 4500000,
            Description = '본 제안은 렌탈과 구매 옵션을 함께 비교할 수 있도록 준비했습니다.',
            Discount_Justification__c = '초기 도입 고객 프로모션을 반영했습니다.'
        );
        insert quoteRecord;

        insert new List<QuoteLineItem>{
            new QuoteLineItem(
                QuoteId = quoteRecord.Id,
                PricebookEntryId = rentalEntry.Id,
                Quantity = 2,
                UnitPrice = 1400000,
                Discount = 10,
                Description = '주요 장비 구성'
            ),
            new QuoteLineItem(
                QuoteId = quoteRecord.Id,
                PricebookEntryId = serviceEntry.Id,
                Quantity = 1,
                UnitPrice = 100000,
                Discount = 0,
                Description = '설치 및 초기 세팅'
            )
        };

        return [
            SELECT Id
            FROM Quote
            WHERE Id = :quoteRecord.Id
            LIMIT 1
        ];
    }

    private static Quote createMinimalQuoteData() {
        Account accountRecord = new Account(Name = 'Fallback 거래처');
        insert accountRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name = 'Fallback 기회',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(7),
            AccountId = accountRecord.Id
        );
        insert opportunityRecord;

        Quote quoteRecord = new Quote(
            Name = 'Fallback 견적',
            OpportunityId = opportunityRecord.Id,
            Status = 'Draft',
            ExpirationDate = Date.today().addDays(7)
        );
        insert quoteRecord;

        return quoteRecord;
    }
}
