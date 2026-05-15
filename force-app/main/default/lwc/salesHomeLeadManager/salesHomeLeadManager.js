import { LightningElement, wire } from 'lwc';

import getLeadManagementData from '@salesforce/apex/SalesRepHomeController.getLeadManagementData';

const LEAD_COLUMNS = [
    {
        label: '리드',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'displayName' },
            target: '_blank'
        }
    },
    { label: '점수', fieldName: 'leadScore', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: '긴급도', fieldName: 'salesPriority', type: 'text' },
    { label: '상담 유형', fieldName: 'consultationType', type: 'text' },
    { label: '라우팅', fieldName: 'routingGroup', type: 'text' },
    { label: '계약 윈도우', fieldName: 'contractEndWindow', type: 'text' }
];

const REGION_COLUMNS = [
    { label: '지역', fieldName: 'region', type: 'text' },
    { label: '리드 수', fieldName: 'leadCount', type: 'number', cellAttributes: { alignment: 'left' } }
];

export default class SalesHomeLeadManager extends LightningElement {
    data;
    errorMessage;

    leadColumns = LEAD_COLUMNS;
    regionColumns = REGION_COLUMNS;

    @wire(getLeadManagementData)
    wiredData({ data, error }) {
        if (data) {
            this.data = {
                ...data,
                hotLeads: this.normalizeLeads(data.hotLeads),
                warmLeads: this.normalizeLeads(data.warmLeads),
                quoteFollowUps: this.normalizeLeads(data.quoteFollowUps),
                regionalInflows: data.regionalInflows || []
            };
            this.errorMessage = undefined;
            return;
        }

        if (error) {
            this.data = undefined;
            this.errorMessage = this.reduceError(error);
        }
    }

    get metrics() {
        return this.data?.metrics || [];
    }

    get isLoading() {
        return !this.data && !this.errorMessage;
    }

    get hotLeads() {
        return this.data?.hotLeads || [];
    }

    get warmLeads() {
        return this.data?.warmLeads || [];
    }

    get quoteFollowUps() {
        return this.data?.quoteFollowUps || [];
    }

    get regionalInflows() {
        return this.data?.regionalInflows || [];
    }

    get hasHotLeads() {
        return this.hotLeads.length > 0;
    }

    get hasWarmLeads() {
        return this.warmLeads.length > 0;
    }

    get hasQuoteFollowUps() {
        return this.quoteFollowUps.length > 0;
    }

    get hasRegionalInflows() {
        return this.regionalInflows.length > 0;
    }

    normalizeLeads(leads = []) {
        return leads.map((lead) => ({
            ...lead,
            displayName: lead.company || lead.name || '리드'
        }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || '리드 관리 데이터를 불러오지 못했습니다.';
    }
}
