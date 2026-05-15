import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const REQUIRED_FIELDS = ['Lead.Id'];

const FIELD_API = {
    LEAD_SCORE: 'Lead.Lead_Score__c',
    PRIORITY: 'Lead.Sales_Priority__c',
    CONSULTATION_TYPE: 'Lead.Consultation_Type__c',
    ROUTING_GROUP: 'Lead.Sales_Routing_Group__c',
    CONTRACT_END_WINDOW: 'Lead.Contract_End_Window__c',
    CONTRACT_END_DATE: 'Lead.Current_Contract_End_Date__c',
    ACTION_SUMMARY: 'Lead.Sales_Action_Summary__c',
    INQUIRY_INTENT: 'Lead.Inquiry_Intent__c',
    SALES_MODEL: 'Lead.Sales_Model__c',
    CUSTOMER_SCENARIO: 'Lead.Customer_Scenario__c',
    DESIRED_PRODUCT_TYPE: 'Lead.Desired_Product_Type__c',
    ESTIMATED_UNIT_COUNT: 'Lead.Estimated_Unit_Count__c',
    SERVICE_PREFERENCE: 'Lead.Service_Preference__c',
    EXPECTED_RENTAL_TERM: 'Lead.Expected_Rental_Term_Months__c',
    ESTIMATED_MONTHLY_RENTAL_FEE: 'Lead.Estimated_Monthly_Rental_Fee__c',
    ESTIMATED_PURCHASE_AMOUNT: 'Lead.Estimated_Purchase_Amount__c',
    ESTIMATED_TOTAL_AMOUNT: 'Lead.Estimated_Total_Amount__c',
    CURRENT_MONTHLY_RENTAL_FEE: 'Lead.Current_Monthly_Rental_Fee__c',
    PURCHASE_TIMELINE: 'Lead.Purchase_Timeline__c',
    DESIRED_RENTAL_BUDGET: 'Lead.Desired_Rental_Budget__c',
    DESIRED_PURCHASE_BUDGET: 'Lead.Desired_Purchase_Budget__c',
    BUDGET_RANGE: 'Lead.Budget_Range__c',
    COMPETITOR_IN_USE: 'Lead.Competitor_In_Use__c',
    PAIN_POINTS: 'Lead.Pain_Points__c',
    GEO_REGION: 'Lead.Geo_Region__c',
    GEO_CITY: 'Lead.Geo_City__c',
    UTM_SOURCE: 'Lead.UTM_Source__c',
    UTM_MEDIUM: 'Lead.UTM_Medium__c',
    UTM_CAMPAIGN: 'Lead.UTM_Campaign__c',
    LANDING_PAGE_URL: 'Lead.Landing_Page_URL__c'
};

const OPTIONAL_FIELDS = Object.values(FIELD_API);

const CLASSIFICATION_FIELDS = [
    { label: '긴급도', apiName: FIELD_API.PRIORITY },
    { label: '리드 점수', apiName: FIELD_API.LEAD_SCORE },
    { label: '상담 유형', apiName: FIELD_API.CONSULTATION_TYPE },
    { label: '라우팅 그룹', apiName: FIELD_API.ROUTING_GROUP },
    { label: '계약 종료 윈도우', apiName: FIELD_API.CONTRACT_END_WINDOW },
    { label: '현재 계약 종료일', apiName: FIELD_API.CONTRACT_END_DATE }
];

const CONTEXT_FIELDS = [
    { label: '문의 의도', apiName: FIELD_API.INQUIRY_INTENT },
    { label: '영업 모델', apiName: FIELD_API.SALES_MODEL },
    { label: '고객 상황', apiName: FIELD_API.CUSTOMER_SCENARIO },
    { label: '희망 제품군', apiName: FIELD_API.DESIRED_PRODUCT_TYPE },
    { label: '예상 수량', apiName: FIELD_API.ESTIMATED_UNIT_COUNT },
    { label: '관리 선호', apiName: FIELD_API.SERVICE_PREFERENCE },
    { label: '구매 시점', apiName: FIELD_API.PURCHASE_TIMELINE },
    { label: '희망 렌탈 예산', apiName: FIELD_API.DESIRED_RENTAL_BUDGET },
    { label: '희망 구매 예산', apiName: FIELD_API.DESIRED_PURCHASE_BUDGET },
    { label: '예산 범위', apiName: FIELD_API.BUDGET_RANGE },
    { label: '사용 경쟁사', apiName: FIELD_API.COMPETITOR_IN_USE },
    { label: '문제점', apiName: FIELD_API.PAIN_POINTS, size: 'full' }
];

const PRICING_FIELDS = [
    { label: '예상 계약기간(개월)', apiName: FIELD_API.EXPECTED_RENTAL_TERM },
    { label: '현재 월 렌탈료', apiName: FIELD_API.CURRENT_MONTHLY_RENTAL_FEE },
    { label: '예상 월 렌탈료', apiName: FIELD_API.ESTIMATED_MONTHLY_RENTAL_FEE },
    { label: '예상 구매금액', apiName: FIELD_API.ESTIMATED_PURCHASE_AMOUNT },
    { label: '예상 총액', apiName: FIELD_API.ESTIMATED_TOTAL_AMOUNT, size: 'full' }
];

const INBOUND_FIELDS = [
    { label: '지역', apiName: FIELD_API.GEO_REGION },
    { label: '도시', apiName: FIELD_API.GEO_CITY },
    { label: 'UTM Source', apiName: FIELD_API.UTM_SOURCE },
    { label: 'UTM Medium', apiName: FIELD_API.UTM_MEDIUM },
    { label: 'UTM Campaign', apiName: FIELD_API.UTM_CAMPAIGN },
    { label: '랜딩 페이지 URL', apiName: FIELD_API.LANDING_PAGE_URL }
];

export default class LeadSalesWorkspace extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: REQUIRED_FIELDS,
        optionalFields: OPTIONAL_FIELDS
    })
    record;

    get hasRecord() {
        return Boolean(this.record.data);
    }

    get isLoading() {
        return !this.record.data && !this.record.error;
    }

    get errorMessage() {
        if (!this.record.error) {
            return undefined;
        }
        if (Array.isArray(this.record.error.body)) {
            return this.record.error.body.map((item) => item.message).join(' ');
        }
        return this.record.error.body?.message || this.record.error.message;
    }

    get scoreLabel() {
        return this.getFieldText(FIELD_API.LEAD_SCORE);
    }

    get priority() {
        return this.getFieldText(FIELD_API.PRIORITY);
    }

    get consultationType() {
        return this.getFieldText(FIELD_API.CONSULTATION_TYPE);
    }

    get routingGroup() {
        return this.getFieldText(FIELD_API.ROUTING_GROUP);
    }

    get contractEndWindow() {
        return this.getFieldText(FIELD_API.CONTRACT_END_WINDOW);
    }

    get actionSummary() {
        return this.getOptionalFieldText(FIELD_API.ACTION_SUMMARY);
    }

    get classificationFields() {
        return this.buildFieldRows(CLASSIFICATION_FIELDS);
    }

    get contextFields() {
        return this.buildFieldRows(CONTEXT_FIELDS);
    }

    get pricingFields() {
        return this.buildFieldRows(PRICING_FIELDS);
    }

    get inboundFields() {
        return this.buildFieldRows(INBOUND_FIELDS);
    }

    buildFieldRows(fieldDefinitions) {
        return fieldDefinitions.map((fieldDefinition) => ({
            key: fieldDefinition.apiName,
            label: fieldDefinition.label,
            value: this.getFieldText(fieldDefinition.apiName),
            className:
                fieldDefinition.size === 'full'
                    ? 'slds-col slds-size_1-of-1'
                    : 'slds-col slds-size_1-of-1 slds-large-size_1-of-2'
        }));
    }

    getFieldText(apiName) {
        const field = this.getFieldData(apiName);
        if (!field) {
            return '-';
        }

        const value = field.displayValue ?? field.value;
        if (value === null || value === undefined || value === '') {
            return '-';
        }

        return String(value);
    }

    getOptionalFieldText(apiName) {
        const field = this.getFieldData(apiName);
        if (!field) {
            return undefined;
        }

        const value = field.displayValue ?? field.value;
        if (value === null || value === undefined || value === '') {
            return undefined;
        }

        return String(value);
    }

    getFieldData(apiName) {
        const fieldKey = apiName.split('.').pop();
        return this.record.data?.fields?.[fieldKey];
    }
}
