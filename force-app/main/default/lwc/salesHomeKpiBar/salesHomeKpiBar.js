import { LightningElement, wire } from 'lwc';
import getOpportunityContractKpiData from '@salesforce/apex/SalesRepHomeController.getOpportunityContractKpiData';

const THEME_CLASS = {
    active: 'kpi-card kpi-active',
    success: 'kpi-card kpi-success',
    fail: 'kpi-card kpi-fail',
    pending: 'kpi-card kpi-pending',
    expiring: 'kpi-card kpi-expiring',
    new: 'kpi-card kpi-new'
};

export default class SalesHomeKpiBar extends LightningElement {
    data;
    errorMessage;

    @wire(getOpportunityContractKpiData)
    wiredData({ data, error }) {
        if (data) {
            this.data = data;
            this.errorMessage = undefined;
            return;
        }
        if (error) {
            this.data = undefined;
            this.errorMessage = this.reduceError(error);
        }
    }

    get hasData() {
        return Boolean(this.data);
    }

    get isLoading() {
        return !this.data && !this.errorMessage;
    }

    get opportunityMetrics() {
        return this.buildCards(this.data?.opportunityMetrics);
    }

    get contractMetrics() {
        return this.buildCards(this.data?.contractMetrics);
    }

    buildCards(metrics = []) {
        return (metrics || []).map((card) => ({
            label: card.label,
            value: card.value ?? 0,
            helperText: card.helperText,
            cardClass: THEME_CLASS[card.theme] || 'kpi-card'
        }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }
        return error?.body?.message || error?.message || 'KPI 데이터를 불러오지 못했습니다.';
    }
}
