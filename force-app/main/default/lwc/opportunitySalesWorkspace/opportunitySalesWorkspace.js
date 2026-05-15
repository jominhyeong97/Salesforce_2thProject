import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELD_API = {
    SALES_MODEL: 'Opportunity.Sales_Model__c',
    CALCULATED_TOTAL: 'Opportunity.Calculated_Total_Amount__c',
    MONTHLY_RENTAL_FEE: 'Opportunity.Monthly_Rental_Fee__c',
    RENTAL_TERM: 'Opportunity.Rental_Term_Months__c',
    INSTALLATION_FEE: 'Opportunity.Installation_Fee__c',
    PURCHASE_TOTAL: 'Opportunity.Purchase_Total_Amount__c',
    QUOTE_APPROVAL_STATUS: 'Opportunity.Quote_Approval_Status__c',
    BUSINESS_VERIFIED: 'Opportunity.Business_Verified__c',
    DECISION_STATUS: 'Opportunity.Decision_Status__c',
    CUSTOMER_SCENARIO: 'Opportunity.Customer_Scenario__c',
    EXPECTED_INSTALL_DATE: 'Opportunity.Expected_Install_Date__c',
    REOPEN_POTENTIAL: 'Opportunity.Reopen_Potential__c',
    STAGE_NAME: 'Opportunity.StageName'
};

const REQUIRED_FIELDS = ['Opportunity.Id'];
const OPTIONAL_FIELDS = Object.values(FIELD_API);

export default class OpportunitySalesWorkspace extends LightningElement {
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
        if (!this.record.error) return undefined;
        if (Array.isArray(this.record.error.body)) {
            return this.record.error.body.map((item) => item.message).join(' ');
        }
        return this.record.error.body?.message || this.record.error.message;
    }

    // ── Sales Model ──────────────────────────────────────────────

    get salesModel() {
        return this.getText(FIELD_API.SALES_MODEL);
    }

    get salesModelBadgeClass() {
        const model = this.getRaw(FIELD_API.SALES_MODEL);
        if (model === '렌탈') return 'badge badge-rental slds-m-top_x-small';
        if (model === '구매') return 'badge badge-purchase slds-m-top_x-small';
        return 'badge badge-compare slds-m-top_x-small';
    }

    get isRental() {
        return this.getRaw(FIELD_API.SALES_MODEL) === '렌탈';
    }

    get isPurchase() {
        return this.getRaw(FIELD_API.SALES_MODEL) === '구매';
    }

    get isCompare() {
        return this.getRaw(FIELD_API.SALES_MODEL) === '비교 후 결정';
    }

    // ── Calculated Total ─────────────────────────────────────────

    get totalAmount() {
        return this.getText(FIELD_API.CALCULATED_TOTAL);
    }

    // ── Pricing Formula Rows ─────────────────────────────────────

    get showRentalFormula() {
        return this.isRental || this.isCompare;
    }

    get showPurchaseFormula() {
        return this.isPurchase || this.isCompare;
    }

    get hasMonthlyFee() {
        const v = this.getFieldData(FIELD_API.MONTHLY_RENTAL_FEE)?.value;
        return v != null && v !== 0;
    }

    get hasRentalTerm() {
        const v = this.getFieldData(FIELD_API.RENTAL_TERM)?.value;
        return v != null && v !== 0;
    }

    get hasInstallationFee() {
        const v = this.getFieldData(FIELD_API.INSTALLATION_FEE)?.value;
        return v != null && v !== 0;
    }

    get hasPurchaseAmount() {
        const v = this.getFieldData(FIELD_API.PURCHASE_TOTAL)?.value;
        return v != null && v !== 0;
    }

    get hasPricingData() {
        return this.hasMonthlyFee || this.hasRentalTerm || this.hasInstallationFee || this.hasPurchaseAmount;
    }

    get monthlyRentalFee() {
        return this.getText(FIELD_API.MONTHLY_RENTAL_FEE);
    }

    get rentalTermLabel() {
        const field = this.getFieldData(FIELD_API.RENTAL_TERM);
        if (!field || field.value == null) return '-';
        return `${field.value}개월`;
    }

    get installationFee() {
        return this.getText(FIELD_API.INSTALLATION_FEE);
    }

    get purchaseTotalAmount() {
        return this.getText(FIELD_API.PURCHASE_TOTAL);
    }

    // ── Status Indicators ────────────────────────────────────────

    get businessVerifiedLabel() {
        const field = this.getFieldData(FIELD_API.BUSINESS_VERIFIED);
        return field && field.value ? '검증 완료' : '미검증';
    }

    get businessVerifiedClass() {
        const field = this.getFieldData(FIELD_API.BUSINESS_VERIFIED);
        return field && field.value
            ? 'field-value slds-m-top_x-small status-success'
            : 'field-value slds-m-top_x-small status-warning';
    }

    get approvalStatus() {
        return this.getText(FIELD_API.QUOTE_APPROVAL_STATUS);
    }

    get approvalStatusClass() {
        const status = this.getRaw(FIELD_API.QUOTE_APPROVAL_STATUS);
        if (status === '승인') return 'field-value slds-m-top_x-small status-success';
        if (status === '승인대기') return 'field-value slds-m-top_x-small status-warning';
        if (status === '반려') return 'field-value slds-m-top_x-small status-error';
        return 'field-value slds-m-top_x-small status-neutral';
    }

    get decisionStatus() {
        return this.getText(FIELD_API.DECISION_STATUS);
    }

    // ── Customer Context ─────────────────────────────────────────

    get customerScenario() {
        return this.getText(FIELD_API.CUSTOMER_SCENARIO);
    }

    get expectedInstallDate() {
        return this.getText(FIELD_API.EXPECTED_INSTALL_DATE);
    }

    get showReopenPotential() {
        return this.getRaw(FIELD_API.STAGE_NAME) === '수주 실패';
    }

    get reopenPotential() {
        return this.getText(FIELD_API.REOPEN_POTENTIAL);
    }

    get reopenPotentialClass() {
        const val = this.getRaw(FIELD_API.REOPEN_POTENTIAL);
        if (val === '높음') return 'field-value slds-m-top_x-small status-success';
        if (val === '낮음') return 'field-value slds-m-top_x-small status-error';
        return 'field-value slds-m-top_x-small status-warning';
    }

    // ── Helpers ──────────────────────────────────────────────────

    getFieldData(apiName) {
        const fieldKey = apiName.split('.').pop();
        return this.record.data?.fields?.[fieldKey];
    }

    getRaw(apiName) {
        return this.getFieldData(apiName)?.value ?? null;
    }

    getText(apiName) {
        const field = this.getFieldData(apiName);
        if (!field) return '-';
        const value = field.displayValue ?? field.value;
        if (value === null || value === undefined || value === '') return '-';
        return String(value);
    }
}
