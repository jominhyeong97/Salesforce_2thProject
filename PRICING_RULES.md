# Aqua Pricing Rules

렌탈과 구매가 함께 존재하는 `Aqua` 영업 구조를 Salesforce 안에서 일관되게 계산하기 위한 운영 문서입니다.

## 목적

- 리드 단계에서는 빠른 예상 금액을 자동 계산합니다.
- 기회 단계에서는 실제 라인아이템 기준 실무 총액을 계산합니다.
- 견적 단계에서는 고객에게 제안할 최종 금액을 계산합니다.
- 계약 단계에서는 렌탈일 경우 계약기간이 빠지지 않도록 연결합니다.

## 기준 개체

- `Lead`: 예상 금액 계산
- `Opportunity`: 실무 총액 계산
- `Quote`: 고객 제안 금액 계산
- `Product2 / PricebookEntry`: 가격 기준 데이터
- `Contract`: 렌탈 계약기간 보관

## 제품 가격 구분 규칙

`Product2.Aqua_Pricing_Type__c`로 가격 성격을 구분합니다.

- `렌탈 월과금`
- `서비스 월과금`
- `구매 일시금`
- `설치 일시금`

이 값은 기회와 견적의 라인아이템 합계를 어떤 바구니에 넣을지 결정하는 기준입니다.

## 리드 계산 규칙

리드 계산은 `AquaPricingSupport`에서 처리합니다.

- 렌탈 리드:
  - `Expected_Rental_Term_Months__c`가 비어 있으면 기본 `36개월`
  - `Estimated_Total_Amount__c = Estimated_Monthly_Rental_Fee__c x 계약기간 + 설치비`
- 구매 리드:
  - `Estimated_Total_Amount__c = Estimated_Purchase_Amount__c + 설치비`
- `비교 후 결정` 리드:
  - 렌탈 예산만 있으면 렌탈 방식으로 총액 계산
  - 구매 예산만 있으면 구매 방식으로 총액 계산
  - 둘 다 있거나 둘 다 없으면 총액은 비워 둠

리드 예상 금액 계산에 쓰는 주요 필드:

- `Desired_Product_Type__c`
- `Estimated_Unit_Count__c`
- `Service_Preference__c`
- `Sales_Model__c`
- `Desired_Rental_Budget__c`
- `Desired_Purchase_Budget__c`

## 기회 계산 규칙

기회 계산은 `OpportunityLineItem` 기준입니다.

- 렌탈:
  - `Monthly_Rental_Fee__c = 렌탈 월과금 + 서비스 월과금 합계`
  - `Calculated_Total_Amount__c = Monthly_Rental_Fee__c x Rental_Term_Months__c + Installation_Fee__c`
- 구매:
  - `Purchase_Total_Amount__c = 구매 일시금 합계`
  - `Calculated_Total_Amount__c = Purchase_Total_Amount__c + Installation_Fee__c`
- 라인아이템이 모두 삭제되면 가격 계산 필드는 모두 `null`로 초기화

기회에서 총액 판단 기준은 표준 `Amount`가 아니라 아래 필드입니다.

- `Calculated_Total_Amount__c`

표준 `Opportunity.Amount`는 Salesforce의 라인아이템 롤업 동작과 충돌할 수 있어서 렌탈 총계 기준 필드로 쓰지 않습니다.

## 견적 계산 규칙

견적 계산은 `QuoteLineItem` 기준입니다.

- `Proposal_Scenario__c = 렌탈안`:
  - `Total_Quoted_Amount__c = Monthly_Rental_Fee__c x Rental_Term_Months__c + Installation_Fee__c`
- `Proposal_Scenario__c = 구매안`:
  - `Total_Quoted_Amount__c = Purchase_Total_Amount__c + Installation_Fee__c`
- `Proposal_Scenario__c = 렌탈/구매 병행`:
  - 한쪽 값만 존재하면 해당 방식 총액 사용
  - 둘 다 존재하면 총액은 자동 확정하지 않음
- 라인아이템이 모두 삭제되면 견적 가격 필드는 모두 `null`로 초기화

견적에서 최종 금액 판단 기준은 아래 필드입니다.

- `Total_Quoted_Amount__c`

## 계약 생성 규칙

`RTF_Create_Contract_for_Completed_Opportunity` Flow 기준입니다.

- Opportunity가 `수주 완료` 또는 `계약 생성` 단계로 변경되면 실행
- 동기화 Quote가 있고 아직 Contract가 없을 때만 생성
- 계약기간 결정 우선순위:
  - `Quote.Rental_Term_Months__c`
  - `Opportunity.Rental_Term_Months__c`
  - 없으면 `12개월`

## 샘플 가격 기준

`scripts/apex/resetAquaSampleData.apex`에서 아래 구조를 사용합니다.

### Aqua B2B 가격표

- 렌탈 월요금:
  - `AQ-RENT-PURE-SLIM`: `32,000`
  - `AQ-RENT-COOLHOT-PLUS`: `39,000`
  - `AQ-RENT-ICE-PRO`: `47,000`
  - `AQ-RENT-FLOW-MAX`: `61,000`
- 구매 일시금:
  - `AQ-BUY-PURE-SLIM`: `690,000`
  - `AQ-BUY-COOLHOT-PLUS`: `980,000`
  - `AQ-BUY-ICE-PRO`: `1,490,000`
  - `AQ-BUY-FLOW-MAX`: `1,890,000`
- 서비스 월요금:
  - `AQ-CARE-BASIC`: `4,000`
  - `AQ-CARE-PREMIUM`: `9,000`
- 설치비:
  - `AQ-INSTALL-STANDARD`: `50,000`
  - `AQ-INSTALL-LARGE`: `120,000`

## 예시

- 렌탈 예시:
  - 월 렌탈료 `112,000`
  - 계약기간 `36개월`
  - 설치비 `120,000`
  - 총액 `4,152,000`

- 구매 예시:
  - 구매금액 `1,960,000`
  - 설치비 `50,000`
  - 총액 `2,010,000`

## 관련 파일

- [AquaPricingSupport.cls](C:/Users/user/Documents/SalesforceProjects/4th_Project/force-app/main/default/classes/common/AquaPricingSupport.cls)
- [AquaPricingSupportTest.cls](C:/Users/user/Documents/SalesforceProjects/4th_Project/force-app/main/default/classes/common/AquaPricingSupportTest.cls)
- [RTF_Create_Contract_for_Completed_Opportunity.flow-meta.xml](C:/Users/user/Documents/SalesforceProjects/4th_Project/force-app/main/default/flows/RTF_Create_Contract_for_Completed_Opportunity.flow-meta.xml)
- [resetAquaSampleData.apex](C:/Users/user/Documents/SalesforceProjects/4th_Project/scripts/apex/resetAquaSampleData.apex)
