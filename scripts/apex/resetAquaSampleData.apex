Id currentUserId = UserInfo.getUserId();
Id approverUserId = currentUserId;

List<User> approverCandidates = [
    SELECT Id
    FROM User
    WHERE IsActive = true AND Id != :currentUserId
    ORDER BY Name
    LIMIT 1
];
if (!approverCandidates.isEmpty()) {
    approverUserId = approverCandidates[0].Id;
}

List<Opportunity> syncedOpportunities = [
    SELECT Id, SyncedQuoteId
    FROM Opportunity
    WHERE SyncedQuoteId != null
];
for (Opportunity opportunityRecord : syncedOpportunities) {
    opportunityRecord.SyncedQuoteId = null;
}
if (!syncedOpportunities.isEmpty()) {
    update syncedOpportunities;
}

List<Quote_Approval_Request__c> approvalRequestsToDelete = [
    SELECT Id
    FROM Quote_Approval_Request__c
];
if (!approvalRequestsToDelete.isEmpty()) {
    Database.delete(approvalRequestsToDelete, false);
}

List<Task> tasksToDelete = [
    SELECT Id
    FROM Task
];
if (!tasksToDelete.isEmpty()) {
    Database.delete(tasksToDelete, false);
}

List<QuoteLineItem> quoteLineItemsToDelete = [
    SELECT Id
    FROM QuoteLineItem
];
if (!quoteLineItemsToDelete.isEmpty()) {
    Database.delete(quoteLineItemsToDelete, false);
}

List<Quote> quotesToDelete = [
    SELECT Id
    FROM Quote
];
if (!quotesToDelete.isEmpty()) {
    Database.delete(quotesToDelete, false);
}

List<Contract> contractsToDelete = [
    SELECT Id
    FROM Contract
];
if (!contractsToDelete.isEmpty()) {
    Database.delete(contractsToDelete, false);
}

List<OpportunityLineItem> opportunityLineItemsToDelete = [
    SELECT Id
    FROM OpportunityLineItem
];
if (!opportunityLineItemsToDelete.isEmpty()) {
    Database.delete(opportunityLineItemsToDelete, false);
}

List<Contact> contactsToDelete = [
    SELECT Id
    FROM Contact
];
if (!contactsToDelete.isEmpty()) {
    Database.delete(contactsToDelete, false);
}

List<Opportunity> opportunitiesToDelete = [
    SELECT Id
    FROM Opportunity
];
if (!opportunitiesToDelete.isEmpty()) {
    Database.delete(opportunitiesToDelete, false);
}

List<Lead> leadsToDelete = [
    SELECT Id
    FROM Lead
];
if (!leadsToDelete.isEmpty()) {
    Database.delete(leadsToDelete, false);
}

List<PricebookEntry> pricebookEntriesToDelete = [
    SELECT Id
    FROM PricebookEntry
];
if (!pricebookEntriesToDelete.isEmpty()) {
    Database.delete(pricebookEntriesToDelete, false);
}

List<Product2> productsToDelete = [
    SELECT Id
    FROM Product2
];
if (!productsToDelete.isEmpty()) {
    Database.delete(productsToDelete, false);
}

List<Pricebook2> customPricebooksToDelete = [
    SELECT Id
    FROM Pricebook2
    WHERE IsStandard = false
];
if (!customPricebooksToDelete.isEmpty()) {
    Database.delete(customPricebooksToDelete, false);
}

List<Account> accountsToDelete = [
    SELECT Id
    FROM Account
];
if (!accountsToDelete.isEmpty()) {
    Database.delete(accountsToDelete, false);
}

Pricebook2 standardPricebook = [
    SELECT Id, IsActive
    FROM Pricebook2
    WHERE IsStandard = true
    LIMIT 1
];
if (!standardPricebook.IsActive) {
    standardPricebook.IsActive = true;
    update standardPricebook;
}

Pricebook2 aquaPricebook = new Pricebook2(
    Name = 'Aqua B2B 가격표',
    IsActive = true
);
insert aquaPricebook;

List<Product2> aquaProducts = new List<Product2>{
    new Product2(
        Name = 'Aqua Pure Slim Rental',
        ProductCode = 'AQ-RENT-PURE-SLIM',
        Family = '정수기',
        Description = '소형 사무실용 정수전용 렌탈 모델',
        Aqua_Pricing_Type__c = '렌탈 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua CoolHot Plus Rental',
        ProductCode = 'AQ-RENT-COOLHOT-PLUS',
        Family = '정수기',
        Description = '냉온정 겸용 오피스 렌탈 모델',
        Aqua_Pricing_Type__c = '렌탈 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Ice Pro Rental',
        ProductCode = 'AQ-RENT-ICE-PRO',
        Family = '정수기',
        Description = '얼음 기능이 포함된 프리미엄 렌탈 모델',
        Aqua_Pricing_Type__c = '렌탈 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Flow Max Rental',
        ProductCode = 'AQ-RENT-FLOW-MAX',
        Family = '정수기',
        Description = '대형 사업장용 대용량 렌탈 모델',
        Aqua_Pricing_Type__c = '렌탈 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Pure Slim Purchase',
        ProductCode = 'AQ-BUY-PURE-SLIM',
        Family = '정수기',
        Description = '소형 사무실용 정수전용 구매 모델',
        Aqua_Pricing_Type__c = '구매 일시금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua CoolHot Plus Purchase',
        ProductCode = 'AQ-BUY-COOLHOT-PLUS',
        Family = '정수기',
        Description = '냉온정 겸용 오피스 구매 모델',
        Aqua_Pricing_Type__c = '구매 일시금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Ice Pro Purchase',
        ProductCode = 'AQ-BUY-ICE-PRO',
        Family = '정수기',
        Description = '얼음 기능이 포함된 프리미엄 구매 모델',
        Aqua_Pricing_Type__c = '구매 일시금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Flow Max Purchase',
        ProductCode = 'AQ-BUY-FLOW-MAX',
        Family = '정수기',
        Description = '대형 사업장용 대용량 구매 모델',
        Aqua_Pricing_Type__c = '구매 일시금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Care Basic Visit',
        ProductCode = 'AQ-CARE-BASIC',
        Family = '서비스',
        Description = '월 1회 방문 관리 서비스',
        Aqua_Pricing_Type__c = '서비스 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Care Premium Visit',
        ProductCode = 'AQ-CARE-PREMIUM',
        Family = '서비스',
        Description = '월 2회 방문 관리 서비스',
        Aqua_Pricing_Type__c = '서비스 월과금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Installation Standard',
        ProductCode = 'AQ-INSTALL-STANDARD',
        Family = '설치',
        Description = '기본 설치비',
        Aqua_Pricing_Type__c = '설치 일시금',
        IsActive = true
    ),
    new Product2(
        Name = 'Aqua Installation Large Site',
        ProductCode = 'AQ-INSTALL-LARGE',
        Family = '설치',
        Description = '대형 사업장 설치비',
        Aqua_Pricing_Type__c = '설치 일시금',
        IsActive = true
    )
};
insert aquaProducts;

Map<String, Product2> productByCode = new Map<String, Product2>();
for (Product2 productRecord : aquaProducts) {
    productByCode.put(productRecord.ProductCode, productRecord);
}

insert new List<PricebookEntry>{
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-PURE-SLIM').Id,
        UnitPrice = 35000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-COOLHOT-PLUS').Id,
        UnitPrice = 42000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-ICE-PRO').Id,
        UnitPrice = 51000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-FLOW-MAX').Id,
        UnitPrice = 65000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-PURE-SLIM').Id,
        UnitPrice = 740000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-COOLHOT-PLUS').Id,
        UnitPrice = 1050000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-ICE-PRO').Id,
        UnitPrice = 1580000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-FLOW-MAX').Id,
        UnitPrice = 1980000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-CARE-BASIC').Id,
        UnitPrice = 4000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-CARE-PREMIUM').Id,
        UnitPrice = 9000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-INSTALL-STANDARD').Id,
        UnitPrice = 60000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = productByCode.get('AQ-INSTALL-LARGE').Id,
        UnitPrice = 130000,
        IsActive = true
    )
};

insert new List<PricebookEntry>{
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-PURE-SLIM').Id,
        UnitPrice = 32000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-COOLHOT-PLUS').Id,
        UnitPrice = 39000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-ICE-PRO').Id,
        UnitPrice = 47000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-RENT-FLOW-MAX').Id,
        UnitPrice = 61000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-PURE-SLIM').Id,
        UnitPrice = 690000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-COOLHOT-PLUS').Id,
        UnitPrice = 980000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-ICE-PRO').Id,
        UnitPrice = 1490000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-BUY-FLOW-MAX').Id,
        UnitPrice = 1890000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-CARE-BASIC').Id,
        UnitPrice = 4000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-CARE-PREMIUM').Id,
        UnitPrice = 9000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-INSTALL-STANDARD').Id,
        UnitPrice = 50000,
        IsActive = true
    ),
    new PricebookEntry(
        Pricebook2Id = aquaPricebook.Id,
        Product2Id = productByCode.get('AQ-INSTALL-LARGE').Id,
        UnitPrice = 120000,
        IsActive = true
    )
};

Map<String, Id> aquaPricebookEntryIdByCode = new Map<String, Id>();
for (PricebookEntry entryRecord : [
    SELECT Id, Product2.ProductCode
    FROM PricebookEntry
    WHERE Pricebook2Id = :aquaPricebook.Id
]) {
    aquaPricebookEntryIdByCode.put(entryRecord.Product2.ProductCode, entryRecord.Id);
}

List<Account> aquaAccounts = new List<Account>{
    new Account(
        Name = '에버그린오피스',
        Phone = '02-6310-2200',
        BillingCity = '서울',
        BillingState = '서울특별시',
        BillingCountry = '대한민국',
        Website = 'https://evergreen.aqua-demo.kr'
    ),
    new Account(
        Name = '한빛메디케어',
        Phone = '031-8042-1180',
        BillingCity = '성남',
        BillingState = '경기도',
        BillingCountry = '대한민국',
        Website = 'https://hanbitmed.aqua-demo.kr'
    ),
    new Account(
        Name = '시티플러스호텔',
        Phone = '051-742-8820',
        BillingCity = '부산',
        BillingState = '부산광역시',
        BillingCountry = '대한민국',
        Website = 'https://cityplushotel.aqua-demo.kr'
    ),
    new Account(
        Name = '미래로지스',
        Phone = '032-771-9050',
        BillingCity = '인천',
        BillingState = '인천광역시',
        BillingCountry = '대한민국',
        Website = 'https://miraelogis.aqua-demo.kr'
    ),
    new Account(
        Name = '다온학원',
        Phone = '042-611-4020',
        BillingCity = '대전',
        BillingState = '대전광역시',
        BillingCountry = '대한민국',
        Website = 'https://daonacademy.aqua-demo.kr'
    )
};
insert aquaAccounts;

Map<String, Account> accountByName = new Map<String, Account>();
for (Account accountRecord : aquaAccounts) {
    accountByName.put(accountRecord.Name, accountRecord);
}

insert new List<Contact>{
    new Contact(
        LastName = '김지현',
        Title = '총무팀 대리',
        Email = 'jihyeon.kim@evergreen.aqua-demo.kr',
        MobilePhone = '010-2101-2201',
        AccountId = accountByName.get('에버그린오피스').Id
    ),
    new Contact(
        LastName = '이도윤',
        Title = '행정실장',
        Email = 'doyoon.lee@hanbitmed.aqua-demo.kr',
        MobilePhone = '010-3101-1180',
        AccountId = accountByName.get('한빛메디케어').Id
    ),
    new Contact(
        LastName = '박수아',
        Title = '시설팀 매니저',
        Email = 'sua.park@cityplushotel.aqua-demo.kr',
        MobilePhone = '010-4402-8820',
        AccountId = accountByName.get('시티플러스호텔').Id
    ),
    new Contact(
        LastName = '최민석',
        Title = '구매팀 차장',
        Email = 'minseok.choi@miraelogis.aqua-demo.kr',
        MobilePhone = '010-5503-9050',
        AccountId = accountByName.get('미래로지스').Id
    ),
    new Contact(
        LastName = '정서연',
        Title = '원장',
        Email = 'seoyeon.jeong@daonacademy.aqua-demo.kr',
        MobilePhone = '010-6604-4020',
        AccountId = accountByName.get('다온학원').Id
    )
};

insert new List<Lead>{
    new Lead(
        LastName = '박서윤',
        Company = '푸른나무치과',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'sypark@bluedental.aqua-demo.kr',
        MobilePhone = '010-7011-1001',
        Inquiry_Intent__c = '견적 요청',
        Budget_Range__c = '1천만원 미만',
        Purchase_Timeline__c = '1개월 이내',
        Competitor_In_Use__c = '코웨이',
        Pain_Points__c = '대기실과 진료실에서 얼음 기능이 있는 정수기를 원하며 현재 렌탈비가 높습니다.',
        Sales_Model__c = '비교 후 결정',
        Customer_Scenario__c = '경쟁사 교체',
        Desired_Product_Type__c = '얼음정수기',
        Estimated_Unit_Count__c = 2,
        Desired_Rental_Budget__c = '10만-20만원',
        Desired_Purchase_Budget__c = '100만-300만원',
        Service_Preference__c = '방문 관리',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'google',
        UTM_Medium__c = 'cpc',
        UTM_Campaign__c = 'aqua_office_q2',
        UTM_Content__c = 'search_ad',
        UTM_Term__c = '치과 정수기',
        Landing_Page_URL__c = 'https://aqua.example.com/clinic',
        Web_Form_Submitted_At__c = System.now().addDays(-3)
    ),
    new Lead(
        LastName = '한지우',
        Company = '리버뷰스터디카페',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'jw.han@riverview.aqua-demo.kr',
        MobilePhone = '010-7011-1002',
        Inquiry_Intent__c = '제품 문의',
        Budget_Range__c = '1천만원 미만',
        Purchase_Timeline__c = '3개월 이내',
        Pain_Points__c = '여름철 이용객 증가에 대비해 냉온정 모델을 비교 중입니다.',
        Sales_Model__c = '구매',
        Customer_Scenario__c = '신규 도입',
        Desired_Product_Type__c = '냉온정',
        Estimated_Unit_Count__c = 1,
        Desired_Purchase_Budget__c = '50만-100만원',
        Service_Preference__c = '상관없음',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'naver',
        UTM_Medium__c = 'blog',
        UTM_Campaign__c = 'aqua_studycafe',
        Landing_Page_URL__c = 'https://aqua.example.com/studycafe',
        Web_Form_Submitted_At__c = System.now().addDays(-2)
    ),
    new Lead(
        LastName = '오민규',
        Company = '더원피트니스',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'mk.oh@theonefit.aqua-demo.kr',
        MobilePhone = '010-7011-1003',
        Inquiry_Intent__c = '견적 요청',
        Budget_Range__c = '1천만원 미만',
        Purchase_Timeline__c = '즉시',
        Competitor_In_Use__c = 'SK매직',
        Pain_Points__c = '락커룸과 프런트에 각각 설치할 제품이 필요하며 필터 교체 대응 속도가 중요합니다.',
        Sales_Model__c = '렌탈',
        Customer_Scenario__c = '경쟁사 교체',
        Desired_Product_Type__c = '냉온정',
        Estimated_Unit_Count__c = 2,
        Current_Monthly_Rental_Fee__c = 142000,
        Desired_Rental_Budget__c = '10만-20만원',
        Service_Preference__c = '방문 관리',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'google',
        UTM_Medium__c = 'cpc',
        UTM_Campaign__c = 'aqua_fitness_hot',
        UTM_Content__c = 'hero',
        UTM_Term__c = '헬스장 정수기',
        Landing_Page_URL__c = 'https://aqua.example.com/fitness',
        Web_Form_Submitted_At__c = System.now().addHours(-10)
    ),
    new Lead(
        LastName = '윤가은',
        Company = '스튜디오모아',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'ge.yoon@studioaqua-demo.kr',
        MobilePhone = '010-7011-1004',
        Inquiry_Intent__c = '데모 요청',
        Budget_Range__c = '1천만원 미만',
        Purchase_Timeline__c = '1개월 이내',
        Pain_Points__c = '촬영 현장 이동이 잦아 셀프 관리형 제품과 방문 관리형 제품을 함께 비교하고 싶습니다.',
        Sales_Model__c = '비교 후 결정',
        Customer_Scenario__c = '추가 설치',
        Desired_Product_Type__c = '정수전용',
        Estimated_Unit_Count__c = 1,
        Desired_Rental_Budget__c = '5만-10만원',
        Desired_Purchase_Budget__c = '50만원 미만',
        Service_Preference__c = '상관없음',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'instagram',
        UTM_Medium__c = 'social',
        UTM_Campaign__c = 'aqua_creator',
        Landing_Page_URL__c = 'https://aqua.example.com/creator',
        Web_Form_Submitted_At__c = System.now().addDays(-1)
    ),
    new Lead(
        LastName = '장예린',
        Company = '케어웍스랩',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'yr.jang@careworks.aqua-demo.kr',
        MobilePhone = '010-7011-1005',
        Inquiry_Intent__c = '제품 문의',
        Budget_Range__c = '미정',
        Purchase_Timeline__c = '6개월 이후',
        Pain_Points__c = '사옥 이전 이후에 도입 예정이라 예산과 설치 수량을 아직 확정하지 못했습니다.',
        Sales_Model__c = '구매',
        Customer_Scenario__c = '신규 도입',
        Desired_Product_Type__c = '대용량',
        Estimated_Unit_Count__c = 3,
        Desired_Purchase_Budget__c = '미정',
        Service_Preference__c = '미정',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'newsletter',
        UTM_Medium__c = 'email',
        UTM_Campaign__c = 'aqua_b2b_nurture',
        Landing_Page_URL__c = 'https://aqua.example.com/corporate',
        Web_Form_Submitted_At__c = System.now().addDays(-5)
    ),
    new Lead(
        LastName = '김태린',
        Company = '온누리행정사무소',
        Status = 'Inbound_Received',
        LeadSource = 'Web',
        Email = 'tr.kim@onnuri.aqua-demo.kr',
        MobilePhone = '010-7011-1006',
        Inquiry_Intent__c = '견적 요청',
        Budget_Range__c = '1천만원 미만',
        Purchase_Timeline__c = '즉시',
        Competitor_In_Use__c = 'LG퓨리케어',
        Pain_Points__c = '기존 제품 소음이 크고 방문 관리 일정이 자주 밀려 빠른 교체가 필요합니다.',
        Sales_Model__c = '렌탈',
        Customer_Scenario__c = '경쟁사 교체',
        Desired_Product_Type__c = '정수전용',
        Estimated_Unit_Count__c = 1,
        Current_Monthly_Rental_Fee__c = 63000,
        Desired_Rental_Budget__c = '5만-10만원',
        Service_Preference__c = '방문 관리',
        Browser_Language__c = 'ko-KR',
        Browser_Timezone__c = 'Asia/Seoul',
        UTM_Source__c = 'google',
        UTM_Medium__c = 'cpc',
        UTM_Campaign__c = 'aqua_fast_replace',
        UTM_Content__c = 'cta',
        UTM_Term__c = '사무실 정수기 렌탈',
        Landing_Page_URL__c = 'https://aqua.example.com/replace',
        Web_Form_Submitted_At__c = System.now().addHours(-2)
    )
};

List<Opportunity> aquaOpportunities = new List<Opportunity>{
    new Opportunity(
        Name = '에버그린오피스 본사 정수기 교체',
        AccountId = accountByName.get('에버그린오피스').Id,
        CloseDate = Date.today().addDays(20),
        StageName = '제안 및 견적',
        Pricebook2Id = aquaPricebook.Id,
        Sales_Model__c = '렌탈',
        Rental_Term_Months__c = 36,
        Customer_Scenario__c = '경쟁사 교체',
        Expected_Install_Date__c = Date.today().addDays(28),
        Decision_Status__c = '견적중',
        Quote_Approver__c = approverUserId,
        Business_Number__c = '120-88-10234'
    ),
    new Opportunity(
        Name = '한빛메디케어 의원 확장 구매',
        AccountId = accountByName.get('한빛메디케어').Id,
        CloseDate = Date.today().addDays(12),
        StageName = '제안 및 견적',
        Pricebook2Id = aquaPricebook.Id,
        Sales_Model__c = '구매',
        Customer_Scenario__c = '추가 설치',
        Expected_Install_Date__c = Date.today().addDays(18),
        Decision_Status__c = '견적중',
        Quote_Approver__c = approverUserId,
        Business_Number__c = '214-81-33012'
    ),
    new Opportunity(
        Name = '시티플러스호텔 연회장 대용량 도입',
        AccountId = accountByName.get('시티플러스호텔').Id,
        CloseDate = Date.today().addDays(45),
        StageName = '기회 발굴',
        Pricebook2Id = aquaPricebook.Id,
        Sales_Model__c = '구매',
        Customer_Scenario__c = '신규 도입',
        Expected_Install_Date__c = Date.today().addDays(60),
        Decision_Status__c = '검토중',
        Business_Number__c = '621-86-45019'
    ),
    new Opportunity(
        Name = '미래로지스 휴게실 렌탈 교체',
        AccountId = accountByName.get('미래로지스').Id,
        CloseDate = Date.today().addDays(-7),
        StageName = '수주 실패',
        Pricebook2Id = aquaPricebook.Id,
        Sales_Model__c = '렌탈',
        Rental_Term_Months__c = 36,
        Customer_Scenario__c = '경쟁사 교체',
        Expected_Install_Date__c = Date.today().addDays(14),
        Decision_Status__c = '보류',
        Lost_Reason_Primary__c = '가격',
        Lost_Reason_Secondary__c = '경쟁사 선택',
        Lost_Reason_Detail__c = '기존 렌탈료 비교에서 타사 제안이 월 2만원 낮아 고객이 타사로 결정했습니다.',
        Lost_To_Competitor__c = '코웨이',
        Reopen_Potential__c = '보통',
        Business_Number__c = '137-81-51208'
    ),
    new Opportunity(
        Name = '다온학원 강의동 신규 설치',
        AccountId = accountByName.get('다온학원').Id,
        CloseDate = Date.today().addDays(25),
        StageName = '제안 및 견적',
        Pricebook2Id = aquaPricebook.Id,
        Sales_Model__c = '렌탈',
        Rental_Term_Months__c = 48,
        Customer_Scenario__c = '신규 도입',
        Expected_Install_Date__c = Date.today().addDays(35),
        Decision_Status__c = '견적중',
        Quote_Approver__c = approverUserId,
        Business_Number__c = '314-82-72011'
    )
};
insert aquaOpportunities;

Map<String, Opportunity> opportunityByName = new Map<String, Opportunity>();
for (Opportunity opportunityRecord : aquaOpportunities) {
    opportunityByName.put(opportunityRecord.Name, opportunityRecord);
}

insert new List<OpportunityLineItem>{
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('에버그린오피스 본사 정수기 교체').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-RENT-ICE-PRO'),
        Quantity = 2,
        UnitPrice = 47000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('에버그린오피스 본사 정수기 교체').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-CARE-PREMIUM'),
        Quantity = 2,
        UnitPrice = 9000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('에버그린오피스 본사 정수기 교체').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-LARGE'),
        Quantity = 1,
        UnitPrice = 120000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('한빛메디케어 의원 확장 구매').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-BUY-COOLHOT-PLUS'),
        Quantity = 2,
        UnitPrice = 980000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('한빛메디케어 의원 확장 구매').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-STANDARD'),
        Quantity = 1,
        UnitPrice = 50000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('시티플러스호텔 연회장 대용량 도입').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-BUY-FLOW-MAX'),
        Quantity = 2,
        UnitPrice = 1890000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('시티플러스호텔 연회장 대용량 도입').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-LARGE'),
        Quantity = 1,
        UnitPrice = 120000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('미래로지스 휴게실 렌탈 교체').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-RENT-COOLHOT-PLUS'),
        Quantity = 2,
        UnitPrice = 39000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('미래로지스 휴게실 렌탈 교체').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-CARE-BASIC'),
        Quantity = 2,
        UnitPrice = 4000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('다온학원 강의동 신규 설치').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-RENT-PURE-SLIM'),
        Quantity = 3,
        UnitPrice = 32000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('다온학원 강의동 신규 설치').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-CARE-BASIC'),
        Quantity = 3,
        UnitPrice = 4000
    ),
    new OpportunityLineItem(
        OpportunityId = opportunityByName.get('다온학원 강의동 신규 설치').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-LARGE'),
        Quantity = 1,
        UnitPrice = 120000
    )
};

List<Quote> aquaQuotes = new List<Quote>{
    new Quote(
        Name = 'AQ-2026-001',
        OpportunityId = opportunityByName.get('에버그린오피스 본사 정수기 교체').Id,
        Pricebook2Id = aquaPricebook.Id,
        Status = 'In Review',
        ExpirationDate = Date.today().addDays(14),
        Proposal_Scenario__c = '렌탈안',
        Rental_Term_Months__c = 36,
        Approval_Requested_At__c = System.now().addDays(-1),
        Revision_Count__c = 1
    ),
    new Quote(
        Name = 'AQ-2026-002',
        OpportunityId = opportunityByName.get('한빛메디케어 의원 확장 구매').Id,
        Pricebook2Id = aquaPricebook.Id,
        Status = 'Accepted',
        ExpirationDate = Date.today().addDays(10),
        Proposal_Scenario__c = '구매안',
        Approval_Requested_At__c = System.now().addDays(-4),
        Approval_Decided_At__c = System.now().addDays(-3),
        Sent_To_Customer_At__c = System.now().addDays(-3),
        Revision_Count__c = 2,
        Discount_Justification__c = '의원 확장 오픈 일정 맞춤 조건으로 설치비를 일부 조정했습니다.'
    ),
    new Quote(
        Name = 'AQ-2026-003',
        OpportunityId = opportunityByName.get('다온학원 강의동 신규 설치').Id,
        Pricebook2Id = aquaPricebook.Id,
        Status = 'Draft',
        ExpirationDate = Date.today().addDays(20),
        Proposal_Scenario__c = '렌탈안',
        Rental_Term_Months__c = 48,
        Revision_Count__c = 0
    )
};
insert aquaQuotes;

Map<String, Quote> quoteByName = new Map<String, Quote>();
for (Quote quoteRecord : aquaQuotes) {
    quoteByName.put(quoteRecord.Name, quoteRecord);
}

insert new List<QuoteLineItem>{
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-001').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-RENT-ICE-PRO'),
        Quantity = 2,
        UnitPrice = 47000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-001').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-CARE-PREMIUM'),
        Quantity = 2,
        UnitPrice = 9000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-001').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-LARGE'),
        Quantity = 1,
        UnitPrice = 120000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-002').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-BUY-COOLHOT-PLUS'),
        Quantity = 2,
        UnitPrice = 980000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-002').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-STANDARD'),
        Quantity = 1,
        UnitPrice = 50000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-003').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-RENT-PURE-SLIM'),
        Quantity = 3,
        UnitPrice = 32000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-003').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-CARE-BASIC'),
        Quantity = 3,
        UnitPrice = 4000
    ),
    new QuoteLineItem(
        QuoteId = quoteByName.get('AQ-2026-003').Id,
        PricebookEntryId = aquaPricebookEntryIdByCode.get('AQ-INSTALL-LARGE'),
        Quantity = 1,
        UnitPrice = 120000
    )
};

update new Opportunity(
    Id = opportunityByName.get('한빛메디케어 의원 확장 구매').Id,
    StageName = '계약 진행',
    Decision_Status__c = '내부결재중'
);

System.debug('Aqua sample data reset complete.');
