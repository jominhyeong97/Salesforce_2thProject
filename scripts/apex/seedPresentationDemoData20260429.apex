Date baseDate = Date.newInstance(2026, 4, 29);
Id ownerId = UserInfo.getUserId();
String convertedStatus = 'Qualified_Converted';
String marker = '[발표 2026-04-29]';

List<Map<String, Object>> specs = new List<Map<String, Object>>{
    new Map<String, Object>{
        'leadName' => '김수현',
        'isPersonal' => false,
        'companyName' => '에이펙스피트니스랩',
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '신규 도입',
        'intent' => '견적 요청',
        'productType' => '냉온정',
        'timeline' => '1개월 이내',
        'region' => '서울',
        'term' => 12,
        'endOffsetDays' => 1,
        'closeDate' => '2026-04-12',
        'unitCount' => 2,
        'rentalBudget' => '10만-20만원',
        'businessNumber' => '135-81-62001',
        'phone' => '010-2100-1001',
        'email' => 'demo-20260429-01@aquacrm.local',
        'website' => 'https://apexfitlab.example.com',
        'street' => '서울특별시 강남구 테헤란로 231',
        'city' => '강남구',
        'state' => '서울특별시',
        'postalCode' => '06142',
        'memo' => '웹투리드 유입 후 본사 피트니스룸용 렌탈 계약',
        'utmSource' => 'kakao-search',
        'utmMedium' => 'paid-search',
        'utmCampaign' => '2026-spring-demo'
    },
    new Map<String, Object>{
        'leadName' => '박지훈',
        'isPersonal' => false,
        'companyName' => '오션브릿지호텔 판교',
        'source' => 'Other',
        'salesModel' => '비교 후 결정',
        'scenario' => '경쟁사 교체',
        'intent' => '데모 요청',
        'productType' => '얼음정수기',
        'timeline' => '즉시',
        'region' => '경기',
        'term' => 24,
        'endOffsetDays' => 14,
        'closeDate' => '2026-04-05',
        'unitCount' => 3,
        'rentalBudget' => '20만원 이상',
        'businessNumber' => '204-88-51012',
        'phone' => '010-2100-1002',
        'email' => 'demo-20260429-02@aquacrm.local',
        'website' => 'https://oceanbridgehotel.example.com',
        'street' => '경기도 성남시 분당구 판교역로 166',
        'city' => '성남시 분당구',
        'state' => '경기도',
        'postalCode' => '13529',
        'memo' => '리드 생성 버튼으로 등록한 호텔 라운지 교체 계약',
        'currentContractEndOffsetDays' => 14
    },
    new Map<String, Object>{
        'leadName' => '이정민',
        'isPersonal' => false,
        'companyName' => '그린웨이브치과네트워크',
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '렌탈 유지 검토',
        'intent' => '제품 문의',
        'productType' => '정수전용',
        'timeline' => '3개월 이내',
        'region' => '인천',
        'term' => 18,
        'endOffsetDays' => 28,
        'closeDate' => '2026-03-28',
        'unitCount' => 2,
        'rentalBudget' => '5만-10만원',
        'businessNumber' => '312-86-70023',
        'phone' => '010-2100-1003',
        'email' => 'demo-20260429-03@aquacrm.local',
        'website' => 'https://greenwavedental.example.com',
        'street' => '인천광역시 연수구 센트럴로 263',
        'city' => '연수구',
        'state' => '인천광역시',
        'postalCode' => '22006',
        'memo' => '웹 유입 후 지점별 유지 렌탈 재계약',
        'currentContractEndOffsetDays' => 28,
        'utmSource' => 'naver-blog',
        'utmMedium' => 'content',
        'utmCampaign' => 'clinic-refresh'
    },
    new Map<String, Object>{
        'leadName' => '최유진',
        'isPersonal' => false,
        'companyName' => '스카이로지스 동탄센터',
        'source' => 'Other',
        'salesModel' => '구매',
        'scenario' => '추가 설치',
        'intent' => '기술 문의',
        'productType' => '대용량',
        'timeline' => '6개월 이내',
        'region' => '경기',
        'term' => 36,
        'endOffsetDays' => 45,
        'closeDate' => '2026-03-20',
        'unitCount' => 4,
        'purchaseBudget' => '300만원 이상',
        'budgetRange' => '5천만-1억원',
        'businessNumber' => '421-81-30034',
        'phone' => '010-2100-1004',
        'email' => 'demo-20260429-04@aquacrm.local',
        'website' => 'https://skylogis.example.com',
        'street' => '경기도 화성시 동탄기흥로 590',
        'city' => '화성시',
        'state' => '경기도',
        'postalCode' => '18469',
        'memo' => '물류센터 휴게공간 추가 설치용 구매 계약'
    },
    new Map<String, Object>{
        'leadName' => '서민규',
        'isPersonal' => false,
        'companyName' => '루미나카페 서초플래그십',
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '신규 도입',
        'intent' => '견적 요청',
        'productType' => '얼음정수기',
        'timeline' => '즉시',
        'region' => '서울',
        'term' => 6,
        'endOffsetDays' => 60,
        'closeDate' => '2026-04-18',
        'unitCount' => 1,
        'rentalBudget' => '5만-10만원',
        'businessNumber' => '512-87-81045',
        'phone' => '010-2100-1005',
        'email' => 'demo-20260429-05@aquacrm.local',
        'website' => 'https://luminacafe.example.com',
        'street' => '서울특별시 서초구 서초대로 398',
        'city' => '서초구',
        'state' => '서울특별시',
        'postalCode' => '06619',
        'memo' => '웹투리드 유입 후 카페 플래그십 단기 렌탈 계약',
        'utmSource' => 'instagram',
        'utmMedium' => 'social',
        'utmCampaign' => 'cafe-showcase'
    },
    new Map<String, Object>{
        'leadName' => '한소라',
        'isPersonal' => false,
        'companyName' => '넥스트메디 재활센터',
        'source' => 'Other',
        'salesModel' => '렌탈',
        'scenario' => '렌탈→구매 전환',
        'intent' => '제품 문의',
        'productType' => '냉온정',
        'timeline' => '3개월 이내',
        'region' => '부산',
        'term' => 30,
        'endOffsetDays' => 75,
        'closeDate' => '2026-02-27',
        'unitCount' => 3,
        'rentalBudget' => '20만원 이상',
        'purchaseBudget' => '100만-300만원',
        'businessNumber' => '617-88-92056',
        'phone' => '010-2100-1006',
        'email' => 'demo-20260429-06@aquacrm.local',
        'website' => 'https://nextmedirehab.example.com',
        'street' => '부산광역시 해운대구 센텀동로 45',
        'city' => '해운대구',
        'state' => '부산광역시',
        'postalCode' => '48058',
        'memo' => '전화 상담으로 전환된 의료기관 장기 계약',
        'currentContractEndOffsetDays' => 60
    },
    new Map<String, Object>{
        'leadName' => '정우성',
        'isPersonal' => false,
        'companyName' => '브라이트스터디 청라캠퍼스',
        'source' => 'Web',
        'salesModel' => '비교 후 결정',
        'scenario' => '경쟁사 교체',
        'intent' => '데모 요청',
        'productType' => '정수전용',
        'timeline' => '1개월 이내',
        'region' => '인천',
        'term' => 15,
        'endOffsetDays' => 90,
        'closeDate' => '2026-04-01',
        'unitCount' => 2,
        'rentalBudget' => '10만-20만원',
        'businessNumber' => '705-86-43067',
        'phone' => '010-2100-1007',
        'email' => 'demo-20260429-07@aquacrm.local',
        'website' => 'https://brightstudy.example.com',
        'street' => '인천광역시 서구 청라한내로 110',
        'city' => '서구',
        'state' => '인천광역시',
        'postalCode' => '22738',
        'memo' => '웹 유입 후 학원 상담실 교체 계약',
        'currentContractEndOffsetDays' => 45,
        'utmSource' => 'youtube',
        'utmMedium' => 'video',
        'utmCampaign' => 'education-demo'
    },
    new Map<String, Object>{
        'leadName' => '오세훈',
        'isPersonal' => false,
        'companyName' => '한결세무컨설팅 본점',
        'source' => 'Other',
        'salesModel' => '렌탈',
        'scenario' => '렌탈 유지 검토',
        'intent' => '견적 요청',
        'productType' => '냉온정',
        'timeline' => '6개월 이내',
        'region' => '대전',
        'term' => 54,
        'endOffsetDays' => 120,
        'closeDate' => '2026-01-10',
        'unitCount' => 2,
        'rentalBudget' => '10만-20만원',
        'businessNumber' => '803-81-54078',
        'phone' => '010-2100-1008',
        'email' => 'demo-20260429-08@aquacrm.local',
        'website' => 'https://hankyul-tax.example.com',
        'street' => '대전광역시 서구 둔산로 100',
        'city' => '서구',
        'state' => '대전광역시',
        'postalCode' => '35241',
        'memo' => '직접 생성한 장기 유지 렌탈 발표용 계약',
        'currentContractEndOffsetDays' => 75
    },
    new Map<String, Object>{
        'leadName' => '강민서',
        'isPersonal' => true,
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '신규 도입',
        'intent' => '제품 문의',
        'productType' => '정수전용',
        'timeline' => '즉시',
        'region' => '경기',
        'term' => 9,
        'endOffsetDays' => 150,
        'closeDate' => '2026-04-20',
        'unitCount' => 1,
        'rentalBudget' => '5만-10만원',
        'phone' => '010-2100-1009',
        'email' => 'demo-20260429-09@aquacrm.local',
        'website' => 'https://home-demo-09.example.com',
        'street' => '경기도 용인시 수지구 광교중앙로 338',
        'city' => '용인시 수지구',
        'state' => '경기도',
        'postalCode' => '16943',
        'memo' => '웹투리드로 유입된 개인 고객 첫 렌탈 계약',
        'utmSource' => 'google-search',
        'utmMedium' => 'paid-search',
        'utmCampaign' => 'home-landing'
    },
    new Map<String, Object>{
        'leadName' => '박준호',
        'isPersonal' => true,
        'source' => 'Other',
        'salesModel' => '비교 후 결정',
        'scenario' => '렌탈 유지 검토',
        'intent' => '견적 요청',
        'productType' => '냉온정',
        'timeline' => '1개월 이내',
        'region' => '서울',
        'term' => 21,
        'endOffsetDays' => 180,
        'closeDate' => '2026-03-31',
        'unitCount' => 1,
        'rentalBudget' => '10만-20만원',
        'phone' => '010-2100-1010',
        'email' => 'demo-20260429-10@aquacrm.local',
        'website' => 'https://home-demo-10.example.com',
        'street' => '서울특별시 마포구 월드컵북로 396',
        'city' => '마포구',
        'state' => '서울특별시',
        'postalCode' => '03925',
        'memo' => '직접 생성한 개인 고객 비교 상담 후 계약',
        'currentContractEndOffsetDays' => 90
    },
    new Map<String, Object>{
        'leadName' => '최서윤',
        'isPersonal' => true,
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '경쟁사 교체',
        'intent' => '데모 요청',
        'productType' => '얼음정수기',
        'timeline' => '3개월 이내',
        'region' => '광주',
        'term' => 42,
        'endOffsetDays' => 210,
        'closeDate' => '2025-12-30',
        'unitCount' => 1,
        'rentalBudget' => '20만원 이상',
        'phone' => '010-2100-1011',
        'email' => 'demo-20260429-11@aquacrm.local',
        'website' => 'https://home-demo-11.example.com',
        'street' => '광주광역시 서구 상무중앙로 58',
        'city' => '서구',
        'state' => '광주광역시',
        'postalCode' => '61949',
        'memo' => '웹 유입 개인 고객의 경쟁사 교체 장기 계약',
        'currentContractEndOffsetDays' => 120,
        'utmSource' => 'kakao-channel',
        'utmMedium' => 'message',
        'utmCampaign' => 'ice-promo'
    },
    new Map<String, Object>{
        'leadName' => '이도윤',
        'isPersonal' => true,
        'source' => 'Other',
        'salesModel' => '구매',
        'scenario' => '신규 도입',
        'intent' => '기술 문의',
        'productType' => '대용량',
        'timeline' => '6개월 이내',
        'region' => '대구',
        'term' => 27,
        'endOffsetDays' => 240,
        'closeDate' => '2026-02-14',
        'unitCount' => 2,
        'purchaseBudget' => '100만-300만원',
        'budgetRange' => '1천만-5천만원',
        'phone' => '010-2100-1012',
        'email' => 'demo-20260429-12@aquacrm.local',
        'website' => 'https://home-demo-12.example.com',
        'street' => '대구광역시 수성구 달구벌대로 2435',
        'city' => '수성구',
        'state' => '대구광역시',
        'postalCode' => '42088',
        'memo' => '수동 등록한 개인 고객의 구매형 계약'
    },
    new Map<String, Object>{
        'leadName' => '정하린',
        'isPersonal' => true,
        'source' => 'Web',
        'salesModel' => '렌탈',
        'scenario' => '렌탈 유지 검토',
        'intent' => '제품 문의',
        'productType' => '정수전용',
        'timeline' => '6개월 이후',
        'region' => '울산',
        'term' => 60,
        'endOffsetDays' => 270,
        'closeDate' => '2025-11-30',
        'unitCount' => 1,
        'rentalBudget' => '5만-10만원',
        'phone' => '010-2100-1013',
        'email' => 'demo-20260429-13@aquacrm.local',
        'website' => 'https://home-demo-13.example.com',
        'street' => '울산광역시 남구 삼산로 261',
        'city' => '남구',
        'state' => '울산광역시',
        'postalCode' => '44705',
        'memo' => '웹투리드 유입 개인 고객의 장기 유지 계약',
        'currentContractEndOffsetDays' => 150,
        'utmSource' => 'blog-review',
        'utmMedium' => 'organic',
        'utmCampaign' => 'longterm-home'
    },
    new Map<String, Object>{
        'leadName' => '윤지후',
        'isPersonal' => true,
        'source' => 'Other',
        'salesModel' => '렌탈',
        'scenario' => '추가 설치',
        'intent' => '견적 요청',
        'productType' => '냉온정',
        'timeline' => '1개월 이내',
        'region' => '경기',
        'term' => 48,
        'endOffsetDays' => 300,
        'closeDate' => '2026-04-08',
        'unitCount' => 2,
        'rentalBudget' => '10만-20만원',
        'phone' => '010-2100-1014',
        'email' => 'demo-20260429-14@aquacrm.local',
        'website' => 'https://home-demo-14.example.com',
        'street' => '경기도 고양시 일산동구 정발산로 24',
        'city' => '고양시 일산동구',
        'state' => '경기도',
        'postalCode' => '10403',
        'memo' => '직접 생성한 개인 고객의 복수 설치 계약'
    },
    new Map<String, Object>{
        'leadName' => '한예준',
        'isPersonal' => true,
        'source' => 'Web',
        'salesModel' => '비교 후 결정',
        'scenario' => '렌탈→구매 전환',
        'intent' => '데모 요청',
        'productType' => '얼음정수기',
        'timeline' => '3개월 이내',
        'region' => '제주',
        'term' => 72,
        'endOffsetDays' => 360,
        'closeDate' => '2025-10-15',
        'unitCount' => 1,
        'rentalBudget' => '20만원 이상',
        'purchaseBudget' => '300만원 이상',
        'phone' => '010-2100-1015',
        'email' => 'demo-20260429-15@aquacrm.local',
        'website' => 'https://home-demo-15.example.com',
        'street' => '제주특별자치도 제주시 첨단로 242',
        'city' => '제주시',
        'state' => '제주특별자치도',
        'postalCode' => '63309',
        'memo' => '웹 유입 개인 고객의 장기 전환형 계약',
        'currentContractEndOffsetDays' => 210,
        'utmSource' => 'display-ad',
        'utmMedium' => 'banner',
        'utmCampaign' => 'jeju-premium'
    }
};

List<Lead> leadsToInsert = new List<Lead>();
Map<Id, Map<String, Object>> specByLeadId = new Map<Id, Map<String, Object>>();
Map<Id, Map<String, Object>> specByAccountId = new Map<Id, Map<String, Object>>();
Map<Id, Map<String, Object>> specByOpportunityId = new Map<Id, Map<String, Object>>();
List<String> creationSummary = new List<String>();

for (Map<String, Object> spec : specs) {
    Boolean isPersonal = (Boolean) spec.get('isPersonal');
    String leadName = String.valueOf(spec.get('leadName'));
    Integer term = Integer.valueOf(String.valueOf(spec.get('term')));
    Decimal unitCount = Decimal.valueOf(String.valueOf(spec.get('unitCount')));
    String companyName = isPersonal
        ? CustomerIdentitySupport.buildPersonalCompanyName(leadName)
        : String.valueOf(spec.get('companyName'));

    Date currentContractEndDate = null;
    if (spec.containsKey('currentContractEndOffsetDays')) {
        currentContractEndDate =
            baseDate.addDays(Integer.valueOf(String.valueOf(spec.get('currentContractEndOffsetDays'))));
    }

    Lead leadRecord = new Lead(
        OwnerId = ownerId,
        LastName = leadName,
        Company = companyName,
        Status = '인바운드 접수',
        LeadSource = String.valueOf(spec.get('source')),
        Phone = String.valueOf(spec.get('phone')),
        Email = String.valueOf(spec.get('email')),
        Street = String.valueOf(spec.get('street')),
        City = String.valueOf(spec.get('city')),
        State = String.valueOf(spec.get('state')),
        PostalCode = String.valueOf(spec.get('postalCode')),
        Country = '대한민국',
        Website = String.valueOf(spec.get('website')),
        Sales_Model__c = String.valueOf(spec.get('salesModel')),
        Customer_Scenario__c = String.valueOf(spec.get('scenario')),
        Inquiry_Intent__c = String.valueOf(spec.get('intent')),
        Desired_Product_Type__c = String.valueOf(spec.get('productType')),
        Purchase_Timeline__c = String.valueOf(spec.get('timeline')),
        Expected_Rental_Term_Months__c = term,
        Estimated_Unit_Count__c = unitCount,
        Geo_Region__c = String.valueOf(spec.get('region')),
        Current_Contract_End_Date__c = currentContractEndDate,
        Description = marker + ' ' + String.valueOf(spec.get('memo'))
    );

    if (spec.containsKey('rentalBudget')) {
        leadRecord.Desired_Rental_Budget__c = String.valueOf(spec.get('rentalBudget'));
    }
    if (spec.containsKey('purchaseBudget')) {
        leadRecord.Desired_Purchase_Budget__c = String.valueOf(spec.get('purchaseBudget'));
    }
    if (spec.containsKey('budgetRange')) {
        leadRecord.Budget_Range__c = String.valueOf(spec.get('budgetRange'));
    }
    if (String.valueOf(spec.get('source')) == 'Web') {
        leadRecord.UTM_Source__c = spec.containsKey('utmSource')
            ? String.valueOf(spec.get('utmSource'))
            : 'website';
        leadRecord.UTM_Medium__c = spec.containsKey('utmMedium')
            ? String.valueOf(spec.get('utmMedium'))
            : 'webform';
        leadRecord.UTM_Campaign__c = spec.containsKey('utmCampaign')
            ? String.valueOf(spec.get('utmCampaign'))
            : 'presentation-demo';
        leadRecord.Landing_Page_URL__c = 'https://demo.aquacrm.local/webtolead';
        leadRecord.Browser_Language__c = 'ko-KR';
        leadRecord.Browser_Timezone__c = 'Asia/Seoul';
    }

    leadsToInsert.add(leadRecord);
}

insert leadsToInsert;

for (Integer index = 0; index < leadsToInsert.size(); index++) {
    specByLeadId.put(leadsToInsert[index].Id, specs[index]);
}

List<Database.LeadConvert> convertRequests = new List<Database.LeadConvert>();
for (Lead leadRecord : leadsToInsert) {
    Map<String, Object> spec = specByLeadId.get(leadRecord.Id);
    Integer term = Integer.valueOf(String.valueOf(spec.get('term')));

    Database.LeadConvert convertRequest = new Database.LeadConvert();
    convertRequest.setLeadId(leadRecord.Id);
    convertRequest.setConvertedStatus(convertedStatus);
    convertRequest.setOpportunityName(leadRecord.Company + ' - ' + String.valueOf(term) + '개월 계약');
    convertRequests.add(convertRequest);
}

List<Database.LeadConvertResult> conversionResults = Database.convertLead(convertRequests, false);
for (Integer index = 0; index < conversionResults.size(); index++) {
    Database.LeadConvertResult result = conversionResults[index];
    Lead sourceLead = leadsToInsert[index];
    if (!result.isSuccess()) {
        List<String> errors = new List<String>();
        for (Database.Error errorRecord : result.getErrors()) {
            errors.add(errorRecord.getMessage());
        }
        System.debug(
            LoggingLevel.ERROR,
            'Lead conversion failed for ' + sourceLead.Email + ': ' + String.join(errors, ' / ')
        );
        continue;
    }

    Map<String, Object> spec = specByLeadId.get(sourceLead.Id);
    specByAccountId.put(result.getAccountId(), spec);
    specByOpportunityId.put(result.getOpportunityId(), spec);
    creationSummary.add(
        sourceLead.Company + ' / ' + String.valueOf(spec.get('source')) + ' / ' +
        String.valueOf(spec.get('term')) + '개월'
    );
}

List<Account> accountsToUpdate = new List<Account>();
for (Account accountRecord : [
    SELECT Id, Name, Description
    FROM Account
    WHERE Id IN :specByAccountId.keySet()
]) {
    Map<String, Object> spec = specByAccountId.get(accountRecord.Id);
    accountRecord.Description = marker + ' ' + String.valueOf(spec.get('memo'));
    accountsToUpdate.add(accountRecord);
}
if (!accountsToUpdate.isEmpty()) {
    update accountsToUpdate;
}

List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
DateTime verificationTimestamp = DateTime.newInstance(2026, 4, 29, 9, 0, 0);
for (Opportunity opportunityRecord : [
    SELECT
        Id,
        Name,
        AccountId,
        StageName,
        CloseDate,
        LeadSource,
        Sales_Model__c,
        Rental_Term_Months__c,
        Description,
        Business_Number__c,
        Business_Verified__c,
        Business_Verified_At__c,
        Business_Verification_Notes__c
    FROM Opportunity
    WHERE Id IN :specByOpportunityId.keySet()
]) {
    Map<String, Object> spec = specByOpportunityId.get(opportunityRecord.Id);
    Boolean isPersonal = (Boolean) spec.get('isPersonal');
    Integer term = Integer.valueOf(String.valueOf(spec.get('term')));

    opportunityRecord.Name = opportunityRecord.Name;
    opportunityRecord.StageName = '수주 완료';
    opportunityRecord.CloseDate = Date.valueOf(String.valueOf(spec.get('closeDate')));
    opportunityRecord.LeadSource = String.valueOf(spec.get('source'));
    opportunityRecord.Sales_Model__c = String.valueOf(spec.get('salesModel'));
    opportunityRecord.Rental_Term_Months__c = term;
    opportunityRecord.Description = marker + ' ' + String.valueOf(spec.get('memo'));

    if (!isPersonal) {
        opportunityRecord.Business_Number__c = String.valueOf(spec.get('businessNumber'));
        opportunityRecord.Business_Verified__c = true;
        opportunityRecord.Business_Verified_At__c = verificationTimestamp;
        opportunityRecord.Business_Verification_Notes__c = '발표용 더미 데이터 검증 완료';
    }

    opportunitiesToUpdate.add(opportunityRecord);
}
if (!opportunitiesToUpdate.isEmpty()) {
    update opportunitiesToUpdate;
}

List<Contract> contractsToInsert = new List<Contract>();
for (Id accountId : specByAccountId.keySet()) {
    Map<String, Object> spec = specByAccountId.get(accountId);
    Integer term = Integer.valueOf(String.valueOf(spec.get('term')));
    Integer endOffsetDays = Integer.valueOf(String.valueOf(spec.get('endOffsetDays')));
    Date startDate = baseDate.addDays(endOffsetDays + 1).addMonths(-term);

    contractsToInsert.add(new Contract(
        AccountId = accountId,
        StartDate = startDate,
        ContractTerm = term,
        Status = 'Draft',
        Description = marker + ' ' + String.valueOf(spec.get('memo')),
        SpecialTerms = marker + ' ' + String.valueOf(term) + '개월 발표용 계약'
    ));
}

insert contractsToInsert;
for (Contract contractRecord : contractsToInsert) {
    contractRecord.Status = 'Activated';
}
update contractsToInsert;

System.debug('Presentation demo data created: ' + creationSummary.size() + ' records');
for (String summaryLine : creationSummary) {
    System.debug('DEMO_ROW|' + summaryLine);
}
