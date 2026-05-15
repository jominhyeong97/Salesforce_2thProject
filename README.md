# AquaFlow CRM

렌탈과 구매가 모두 가능한 정수기 업체 `Aqua`를 위한 Salesforce CRM 프로젝트입니다.

## Scope

- Web-to-Lead로 Aqua 상담 유입을 받고 리드 데이터로 전환합니다.
- 리드 점수, 계약 종료 윈도우, Task SLA로 영업 우선순위를 자동화합니다.
- 상담 유형, 영업 라우팅 그룹, 영업 액션 요약을 자동 산출합니다.
- 리드 전환 화면에서 기존 거래처/연락처 추천, 기회 생성 여부, 전환 후 이동까지 한 번에 처리합니다.
- 계정/연락처 리스트에서 한국식 단일 `이름` 입력 모달로 연락처를 생성합니다.
- 견적 승인 Flow/LWC와 내부 결재 문서 흐름을 관리합니다.
- 영업사원이 홈에서 Hot 리드, 지연 Task, 갱신 관찰, 견적 후속을 한 번에 봅니다.
- 수주 실패 사유와 재공략 가능성을 데이터로 남깁니다.

## Project Layout

- 현재 deployable metadata는 다시 `force-app/main/default` 기준으로 관리합니다.
- 객체/필드/레이아웃/클래스/플로우를 한 프로젝트 안에서 유지하고, 도메인 구분은 파일명과 문서로 관리합니다.
- Apex 클래스는 `force-app/main/default/classes` 아래에서 `common`, `lead`, `opportunity`, `quote` 하위 폴더로 정리합니다.
- 작업 이력과 규칙은 `README.md`, `LEADSCORE.md`, `PRICING_RULES.md`에 계속 누적합니다.

## Current Rules

- `Hot`: 80점 이상, 1일 SLA Task 생성, 즉시 확인 알림 전송
- `Warm`: 55점 이상, 3일 SLA Task 생성
- `Cold`: 54점 이하, 즉시 대응 Task 미생성
- `Renewal Watch`: `렌탈`이며 계약 종료가 `31-60일` 또는 `61-90일`이면 7일 SLA Task 생성
- `영업 Task 유형`: `초기 상담` / `견적 후속` / `계약 갱신` / `구매 전환` / `재공략`
- `계약 종료 윈도우`: 미입력 / 종료 지남 / 30일 이내 / 31-60일 / 61-90일 / 90일 초과
- `Task 액션 유형`: 초기 상담 / 경쟁사 교체 제안 / 렌탈 갱신 / 구매 전환 / 대형 설치 검토 / 견적 후속
- `상담 유형`: 초기 상담 / 견적 상담 / 데모 상담 / 기술 상담 / 파트너 상담 / 경쟁사 교체 상담 / 렌탈 갱신 상담 / 구매 전환 상담 / 대형 설치 상담
- `영업 라우팅 그룹`: 인바운드 / 인사이드 세일즈 / 리텐션 / 전략 영업 / 엔터프라이즈 / 파트너
- `Closed Lost`가 `재오픈 가능성 = 높음/보통`이면 재공략 Task를 자동 생성합니다.
- 렌탈 총액 기준은 `월 렌탈료 x 계약기간 + 설치비`입니다.
- 구매 총액 기준은 `구매 총액 + 설치비`입니다.
- 리드 예상 금액은 제품 유형, 수량, 서비스 선호도, 렌탈/구매 방식 기준으로 자동 계산합니다.
- 기회 실무 총액은 표준 `Amount` 대신 `Calculated_Total_Amount__c`를 기준으로 봅니다.
- 견적 최종 제안 금액은 `Total_Quoted_Amount__c`를 기준으로 봅니다.
- 견적은 `견적 유형`으로 `렌탈안 / 구매안 / 렌탈/구매 병행`을 구분합니다.
- `렌탈안` 또는 `렌탈/구매 병행` 견적은 `렌탈 기간(개월)`이 없으면 저장할 수 없습니다.
- 수동 리드 생성은 웹투리드와 같은 상담 필드 구조를 따르며, 이름은 단일 `이름` 입력으로 받아 `LastName`에 저장합니다.

## Work Log

- 2026-04-27: Task에 `영업 Task 유형` 커스텀 필드를 추가하고, 리드 후속 Task를 `초기 상담 / 견적 후속 / 계약 갱신 / 구매 전환` 체계로 표준화했습니다.
- 2026-04-27: Opportunity가 `수주 실패`로 전환되면서 `재오픈 가능성`이 `높음/보통`이면 `재공략` Task가 자동 생성되도록 `OpportunityReengagementHandler`를 추가했습니다.
- 2026-04-27: `salesRepHomeSummary`와 `SalesRepHomeController`를 확장해 `오늘 처리할 Hot Lead`, `SLA 임박 Task`, `계약 종료 30일 이내 고객`, `이번 달 견적 승인 대기`, `Closed Lost 재공략 예정`, `지역별 리드 유입`을 한 화면에서 보도록 구성했습니다.
- 2026-04-27: Lead 레코드 페이지 `FlexiPage4`에 영업 자격화/유입/지역 필드를 노출하고, Contract 리스트뷰에 `Renewals Next 60 Days` 롤링 필터를 추가했습니다.
- 2026-04-27: Opportunity가 `계약 생성` 또는 `마감됨` 단계로 들어오면 동기화 Quote 기준으로 표준 Contract를 자동 생성하고 Quote의 `ContractId`를 연결하는 `RTF_Create_Contract_for_Completed_Opportunity` Flow를 추가했습니다.
- 2026-04-27: 렌탈/구매 가격 구조를 분리하기 위해 `Product2.Aqua_Pricing_Type__c`와 리드/기회/견적 가격 계산 필드를 추가하고, `AquaPricingSupport`로 리드 예상 금액, 기회 실무 총액, 견적 최종 제안 금액을 자동 계산하도록 정리했습니다.
- 2026-04-27: `OpportunityLineItemTrigger`, `QuoteLineItemTrigger`를 추가해 라인아이템 변경 시 기회/견적 가격이 다시 집계되도록 구성했습니다.
- 2026-04-27: Aqua 견적 PDF가 `Total_Quoted_Amount__c`를 우선 사용하도록 수정하고, `렌탈 계약 총액 / 구매 총액 / 최종 제안 금액`이 보이도록 문서를 보강했습니다.
- 2026-04-27: 계약 자동 생성 Flow의 완료 단계 기준을 `수주 완료`로 맞추고, 계약기간은 Quote 값이 없으면 Opportunity의 렌탈 기간을 우선 사용하도록 보정했습니다.
- 2026-04-27: `scripts/apex/resetAquaSampleData.apex` 샘플데이터를 월 렌탈료 3만원대 구조에 맞춰 전면 교체하고, 렌탈/구매 SKU와 설치비/서비스 SKU를 분리했습니다.
- 2026-04-27: 가격 구조 개편을 `4th_Org`에 실배포했고, `AquaPricingSupportTest`, `LeadSalesAutomationHandlerTest`, `OpportunityBusinessVerificationTest`, `OpportunityReengagementHandlerTest`, `QuotePdfGenerationServiceTest` 포함 25건이 통과했습니다. 배포 ID는 `0AfdM00000ZRxvtSAD`입니다.
- 2026-04-27: Quote의 `견적 유형` 라벨을 명확히 하고, `렌탈안 / 렌탈/구매 병행`일 때 `렌탈 기간(개월)` 입력을 강제하는 Validation Rule을 추가했습니다. Opportunity의 `렌탈/구매` 선택이 명확하면 Quote 생성 시 `견적 유형`과 `렌탈 기간`도 자동 상속되도록 보정했습니다.
- 2026-04-27: Quote 유형/렌탈기간 강제 규칙을 `4th_Org`에 실배포했고, `AquaPricingSupportTest`, `QuotePdfGenerationServiceTest`, `QuoteStatusGuardHandlerTest`, `QuoteApprovalServiceTest`, `SalesRepHomeControllerTest`, `OpportunityBusinessVerificationTest` 포함 36건이 통과했습니다. 배포 ID는 `0AfdM00000ZS0gsSAD`입니다.
- 2026-04-27: 표준 Lead 생성 화면의 `성/이름` 분리 입력 대신 웹투리드와 같은 상담 항목과 단일 `이름` 입력을 사용하는 `New_Lead_KR` Quick Action, `leadCreateAction` Aura 번들, `leadListQuickActionLauncher` 런처를 추가했습니다.
- 2026-04-27: 웹투리드형 리드 생성 경로를 `4th_Org`에 실배포했습니다. 배포 ID는 `0AfdM00000ZSG0rSAH`입니다.
- 2026-04-27: 리드 목록 "새로 만들기" 버튼을 커스텀 폼으로 교체하기 위해 `leadCreateAction`에 `lightning:actionOverride` 인터페이스를 추가하고, `Lead.object-meta.xml`의 `New` 액션을 `type=LightningComponent`, `content=leadCreateAction`으로 override했습니다. Salesforce 제약상 Quick Action 이름(New_Lead_KR)으로는 New override가 불가하고 컴포넌트 이름 직접 참조만 가능합니다. `Lead.New_Lead_KR` 오브젝트 전용 Quick Action도 함께 추가했습니다. 배포 ID는 `0AfdM00000ZS9BbSAL`(quickAction), `0AfdM00000ZSYFASA5`(object+aura)입니다.
- 2026-04-28: 영업 홈 화면 상단에 기회·계약 KPI 바(`salesHomeKpiBar`)를 추가했습니다. 기회 파이프라인(진행 중·이번 달 수주·이번 달 실패·견적 승인 대기)과 계약 현황(활성·60일 만료 예정·이번 달 신규)을 색상 구분 카드로 표시합니다. 리드 관리에 Warm Lead 탭을 추가했고, Task 관리 SLA 창을 내일까지→7일 이내로, 계약 만료 범위를 30일→60일로 확대했으며 견적 승인 대기 THIS_MONTH 필터를 제거해 전체 대기 건이 보이도록 개선했습니다. `SalesRepHomeControllerTest` 1건 통과. 배포 ID `0AfdM00000ZUcgPSAT`(코드), `0AfdM00000ZUcrhSAD`(테스트).
- 2026-04-28: 기회 상세 페이지용 `opportunitySalesWorkspace` LWC를 추가했습니다. 상담 방식 배지(렌탈/구매/비교 후 결정)와 계산 총 금액을 히어로 영역에 표시하고, 상담 방식에 따라 `월 렌탈료 × 계약기간 + 설치비` 또는 `구매 금액 + 설치비` 가격 공식 행을 조건부로 렌더링합니다. 진행 상태(사업자 검증/견적 결재 상태/의사결정 상태)와 고객 상황(고객 상황/희망 설치일/재오픈 가능성)도 포함합니다. 배포 ID는 `0AfdM00000ZUc25SAD`입니다. App Builder에서 기회 레코드 페이지 상단에 배치 필요.
- 2026-04-28: 견적 승인 결재자를 수동 지정(`Quote_Approver__c`) 대신 계정 담당자(Account Owner)의 상위 매니저(`Account.Owner.ManagerId`)에서 자동으로 결정하도록 `QuoteApprovalService`를 변경했습니다. 테스트는 `createUserWithManager` 헬퍼로 Account Owner → Manager 체인을 구성하도록 재작성했으며 12건 전부 통과했습니다. 배포 ID는 `0AfdM00000ZUb4PSAT`입니다.
- 2026-04-28: 견적 "동기화 시작" 버튼이 아무 반응 없는 문제를 수정했습니다. `SyncQuote`가 `IsSyncing=true`로 UPDATE할 때 `RentalTermRequiredForRentalQuote` Validation Rule이 발동해 렌탈 기간이 없는 견적을 막는 구조였으며, 오류 필드(`Rental_Term_Months__c`)가 SyncQuote 다이얼로그에 표시되지 않아 무반응처럼 보였습니다. `AquaPricingSupport.prepareQuotes`에서 UPDATE 시(SyncQuote 포함) 렌탈 기간 소스가 없으면 `DEFAULT_RENTAL_TERM_MONTHS(36)`로 채우도록 수정했습니다. INSERT 시에는 기존 Validation Rule이 그대로 동작해 사용자가 직접 입력하도록 유지됩니다. `AquaPricingSupportTest` 6건 전부 통과. 배포 ID는 `0AfdM00000ZUbnZSAT`입니다.
- 2026-04-27: `leadCreateAction` 취소 버튼이 action override 컨텍스트에서 작동하지 않는 문제를 수정했습니다. `$A.get("e.force:closeQuickAction")`은 항상 truthy를 반환해 else 분기가 실행되지 않는 문제였으며, `lightning:isUrlAddressable`과 `pageReference` 어트리뷰트로 컨텍스트를 판별해 override 시엔 Lead 목록으로 이동, Quick Action 모달 시엔 closeQuickAction을 실행하도록 수정했습니다. 배포 ID는 `0AfdM00000ZSYPBSA5`입니다.
- 2026-04-24: Apex 클래스 폴더를 `classes/common`, `classes/lead`, `classes/opportunity`, `classes/quote` 하위 폴더로 정리하고 dry-run 배포로 구조를 검증했습니다.
- 2026-04-24: package directory 분리 실험 후, 사용자 작업 방식에 맞춰 Apex/Flow/LWC를 다시 `force-app/main/default` 구조로 복원했습니다.
- 2026-04-24: Lead 자동화에 `상담 유형`, `영업 라우팅 그룹`, `영업 액션 요약` 필드를 추가하고 규칙 기반 분류를 확장했습니다.
- 2026-04-24: `Cold` 리드 중 렌탈 계약 종료 `31-90일` 구간에 대해 7일 SLA `Renewal Watch` Task 자동화를 추가했습니다.
- 2026-04-24: 영업 홈에서 Hot 리드, 지연 Task, 갱신 관찰, 견적 후속을 볼 수 있는 `salesRepHomeSummary` LWC와 `SalesRepHomeController`를 추가했습니다.
- 2026-04-24: `leadConversionWorkspace` LWC와 `LeadConversionWorkspaceController`를 추가해 리드 전환 시 기존 거래처/연락처 추천, 기회 생성 선택, 전환 후 이동을 지원했습니다.
- 2026-04-24: `Lead.Lead_Conversion_Workspace` Quick Action 메타데이터를 추가했습니다. 다만 이 org의 Metadata API에서는 `LightningWebComponent` 액션을 `Layout.quickActionList`에 직접 넣을 수 없어, 레코드 페이지 액션 배치는 Setup에서 수동으로 마무리해야 합니다.
- 2026-04-24: `4th_Org`에 리드 전환 워크스페이스를 실배포했고, `LeadConversionWorkspaceControllerTest` 4건이 모두 통과했습니다. 배포 ID는 `0AfdM00000ZIwW1SAL`입니다.
- 2026-04-24: `Account.New_Contact_KR` Lightning Component Quick Action을 추가해 `성/이름` 분리 대신 단일 `이름` 입력으로 연락처를 생성하도록 구성했습니다. 다만 이 org의 Metadata API에서는 `LightningComponent` 액션을 `Layout.quickActionList`에 직접 넣을 수 없어, Account 레이아웃 액션 배치는 Setup에서 수동으로 마무리해야 합니다.
- 2026-04-24: `accountContactCreateAction` Aura 번들과 `Account.New_Contact_KR` Quick Action을 `4th_Org`에 실배포했습니다. Aura 번들 배포 ID는 `0AfdM00000ZIz8vSAD`, Quick Action 배포 ID는 `0AfdM00000ZIyMYSA1`입니다.
- 2026-04-24: Contact 기본 `새로 만들기` 모달은 플랫폼 제약으로 직접 바꾸기 어려워, 별도 글로벌 Quick Action `New_Contact_KR`을 추가해 한국식 단일 이름 입력 모달을 우회 경로로 제공했습니다.
- 2026-04-24: 글로벌 Quick Action `New_Contact_KR`과 최신 `accountContactCreateAction` 번들을 `4th_Org`에 실배포했습니다. 배포 ID는 `0AfdM00000ZIxqISAT`입니다.
- 2026-04-24: Contact 탭 리스트뷰에서 사용할 수 있도록 `Contact_Create_KR` 리스트 버튼, `ContactCreateFromListViewKR` Visualforce 페이지, `ContactListViewCreateController`를 추가했습니다.
- 2026-04-24: Contact 리스트뷰용 한국식 연락처 생성 경로를 `4th_Org`에 실배포했고, `ContactListViewCreateControllerTest` 3건이 모두 통과했습니다. 배포 ID는 `0AfdM00000ZJ63xSAD`입니다.
- 2026-04-24: `accountContactCreateAction` 모달에 `계정명 검색`, `부서`, `리드소스`, `이메일`, `전화`, `휴대전화`, `직함` 표준 필드를 추가하고, 테스트용 안내 문구를 제거했습니다.
- 2026-04-24: 새 페이지 기반 `Contact_Create_KR` 경로 대신 `contactListQuickActionLauncher` Aura 컴포넌트로 Contact 오브젝트 홈에서 `Global.New_Contact_KR` 모달을 여는 구조로 전환했습니다.
- 2026-04-24: Contact 모달 확장/리스트 런처를 `4th_Org`에 실배포했습니다. 배포 ID는 `0AfdM00000ZJ6iISAT`입니다.
- 2026-04-24: Contact 검색 레이아웃에서 기존 `Contact_Create_KR` 버튼 참조를 제거하고, 이전 Visualforce/WebLink/Apex 리스트뷰 경로를 `4th_Org`와 프로젝트에서 삭제했습니다. Contact 검색 레이아웃 정리 배포 ID는 `0AfdM00000ZJ9bJSAT`, 삭제 배포 ID는 `0AfdM00000ZJ9eXSAT`입니다.
- 2026-04-24: Account 화면에서 계정 검색값을 바꿔도 저장 시 기존 AccountId로 덮어쓰지 않도록 `accountContactCreateAction` submit 로직을 보정했습니다. 배포 ID는 `0AfdM00000ZJ9oDSAT`입니다.
- 2026-04-23: Quote 승인 요청 Flow와 결재 워크스페이스 LWC를 구현했습니다.
- 2026-04-23: Aqua Web-to-Lead 폼에 렌탈·구매 상담 필드와 UTM 추적을 연결했습니다.
- 2026-04-23: Lead/Opportunity/Quote에 CRM 분석 및 Aqua 영업 필드를 추가했습니다.
- 2026-04-23: `scripts/apex/resetAquaSampleData.apex`로 Aqua 샘플 데이터를 초기화할 수 있게 정리했습니다.
- 2026-04-23: 리드 점수, 계약 종료 윈도우, Warm/Hot Task SLA 자동화를 추가했습니다.

## Key Files

- `webtolead-test.html`: Aqua Web-to-Lead 테스트 폼
- `force-app/main/default/classes/lead/LeadConversionWorkspaceController.cls`: 리드 전환 추천/실행 API
- `force-app/main/default/classes/lead/LeadSalesAutomationHandler.cls`: 리드 점수화 및 Task 자동화
- `force-app/main/default/classes/lead/SalesRepHomeController.cls`: 영업 홈 요약 카드/리스트 집계 API
- `force-app/main/default/classes/common/AquaPricingSupport.cls`: 렌탈/구매 가격 계산 공통 로직
- `force-app/main/default/classes/opportunity/OpportunityReengagementHandler.cls`: Closed Lost 재공략 Task 자동화
- `force-app/main/default/flows/RTF_Create_Contract_for_Completed_Opportunity.flow-meta.xml`: 기회 완료 시 계약 자동 생성 Flow
- `force-app/main/default/classes/quote/QuoteApprovalService.cls`: 견적 승인 로직
- `force-app/main/default/pages/AquaQuotePdf.page`: Aqua 브랜드 견적 PDF 템플릿
- `force-app/main/default/lwc/quotePdfGenerator/*`: Aqua 견적 PDF 생성 액션 UI
- `force-app/main/default/objects/Quote/validationRules/RentalTermRequiredForRentalQuote.validationRule-meta.xml`: 렌탈 견적 기간 필수 규칙
- `force-app/main/default/objects/Activity/fields/Sales_Task_Type__c.field-meta.xml`: 표준화된 영업 Task 유형 필드
- `force-app/main/default/aura/accountContactCreateAction/*`: 한국식 연락처 생성 Quick Action UI
- `force-app/main/default/aura/contactListQuickActionLauncher/*`: Contact 오브젝트 홈에서 연락처 생성 모달을 여는 런처
- `force-app/main/default/aura/leadCreateAction/*`: 웹투리드형 리드 생성 Quick Action UI
- `force-app/main/default/aura/leadListQuickActionLauncher/*`: 앱/리스트 페이지에서 웹투리드형 리드 생성 모달을 여는 런처
- `force-app/main/default/quickActions/Account.New_Contact_KR.quickAction-meta.xml`: Account용 한국식 연락처 생성 액션
- `force-app/main/default/quickActions/New_Contact_KR.quickAction-meta.xml`: Contact 생성용 글로벌 한국식 연락처 생성 액션
- `force-app/main/default/quickActions/New_Lead_KR.quickAction-meta.xml`: Lead 생성용 글로벌 웹투리드형 생성 액션
- `force-app/main/default/quickActions/Lead.New_Lead_KR.quickAction-meta.xml`: Lead 오브젝트 전용 웹투리드형 생성 액션 (New 버튼 override 연동용)
- `force-app/main/default/lwc/leadConversionWorkspace/*`: 리드 전환 워크스페이스 LWC
- `force-app/main/default/quickActions/Lead.Lead_Conversion_Workspace.quickAction-meta.xml`: 리드 전환 Quick Action
- `force-app/main/default/lwc/salesRepHomeSummary/*`: 영업 홈 요약 LWC
- `force-app/main/default/lwc/quoteApprovalWorkspace/*`: 견적 승인 워크스페이스 UI
- `LEADSCORE.md`: 리드 점수, 상담 유형, 라우팅 그룹 운영 문서
- `PRICING_RULES.md`: 렌탈/구매 가격 계산 규칙 문서
- `scripts/apex/resetAquaSampleData.apex`: Aqua 샘플 데이터 리셋 스크립트
