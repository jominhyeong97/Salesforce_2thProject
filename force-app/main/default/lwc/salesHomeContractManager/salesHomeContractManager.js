import { LightningElement, wire } from 'lwc';

import getContractManagementData from '@salesforce/apex/SalesRepHomeController.getContractManagementData';

const CONTRACT_COLUMNS = [
    {
        label: '계약',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'displayName' },
            target: '_blank'
        }
    },
    { label: '거래처', fieldName: 'accountName', type: 'text' },
    { label: '상태', fieldName: 'status', type: 'text' },
    { label: '종료일', fieldName: 'endDate', type: 'date-local' }
];

const APPROVAL_COLUMNS = [
    {
        label: '승인 요청',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'approvalRequestName' },
            target: '_blank'
        }
    },
    { label: '기회', fieldName: 'opportunityName', type: 'text' },
    { label: '견적', fieldName: 'quoteName', type: 'text' },
    { label: '결재자', fieldName: 'approverName', type: 'text' },
    { label: '요청 일시', fieldName: 'requestedAt', type: 'date' }
];

export default class SalesHomeContractManager extends LightningElement {
    data;
    errorMessage;

    contractColumns = CONTRACT_COLUMNS;
    approvalColumns = APPROVAL_COLUMNS;

    @wire(getContractManagementData)
    wiredData({ data, error }) {
        if (data) {
            this.data = {
                ...data,
                expiringContracts: this.normalizeContracts(data.expiringContracts),
                pendingApprovals: data.pendingApprovals || []
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

    get expiringContracts() {
        return this.data?.expiringContracts || [];
    }

    get pendingApprovals() {
        return this.data?.pendingApprovals || [];
    }

    get renewalListViewLabel() {
        return this.data?.renewalListViewLabel || '';
    }

    get hasExpiringContracts() {
        return this.expiringContracts.length > 0;
    }

    get hasPendingApprovals() {
        return this.pendingApprovals.length > 0;
    }

    normalizeContracts(contracts = []) {
        return contracts.map((contract) => ({
            ...contract,
            displayName: contract.contractNumber || contract.name || '계약'
        }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || '계약 관리 데이터를 불러오지 못했습니다.';
    }
}
