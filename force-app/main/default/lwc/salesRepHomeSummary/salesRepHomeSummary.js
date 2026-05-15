import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getDashboardData from '@salesforce/apex/SalesRepHomeController.getDashboardData';

const THEME_CLASS_MAP = {
    hot: 'metric-card hot',
    task: 'metric-card task',
    contract: 'metric-card contract',
    quote: 'metric-card quote',
    reengagement: 'metric-card reengagement',
    region: 'metric-card region'
};

export default class SalesRepHomeSummary extends LightningElement {
    wiredDashboardResult;
    dashboard;
    errorMessage;
    isRefreshing = false;

    @wire(getDashboardData)
    wiredDashboard(result) {
        this.wiredDashboardResult = result;

        if (result.data) {
            this.dashboard = this.normalizeDashboard(result.data);
            this.errorMessage = undefined;
            return;
        }

        if (result.error) {
            this.dashboard = undefined;
            this.errorMessage = this.reduceError(result.error);
        }
    }

    get isLoading() {
        return !this.dashboard && !this.errorMessage;
    }

    get isBusy() {
        return this.isLoading || this.isRefreshing;
    }

    get hasData() {
        return Boolean(this.dashboard);
    }

    get metrics() {
        return this.dashboard?.metrics || [];
    }

    get hotLeads() {
        return this.dashboard?.hotLeads || [];
    }

    get slaTasks() {
        return this.dashboard?.slaTasks || [];
    }

    get expiringContracts() {
        return this.dashboard?.expiringContracts || [];
    }

    get pendingApprovals() {
        return this.dashboard?.pendingApprovals || [];
    }

    get reengagementTasks() {
        return this.dashboard?.reengagementTasks || [];
    }

    get regionalInflows() {
        return this.dashboard?.regionalInflows || [];
    }

    get hasHotLeads() {
        return this.hotLeads.length > 0;
    }

    get hasSlaTasks() {
        return this.slaTasks.length > 0;
    }

    get hasExpiringContracts() {
        return this.expiringContracts.length > 0;
    }

    get hasPendingApprovals() {
        return this.pendingApprovals.length > 0;
    }

    get hasReengagementTasks() {
        return this.reengagementTasks.length > 0;
    }

    get hasRegionalInflows() {
        return this.regionalInflows.length > 0;
    }

    async handleRefresh() {
        if (!this.wiredDashboardResult || this.isRefreshing) {
            return;
        }

        this.isRefreshing = true;
        try {
            await refreshApex(this.wiredDashboardResult);
        } finally {
            this.isRefreshing = false;
        }
    }

    normalizeDashboard(data) {
        return {
            metrics: (data.metrics || []).map((card, index) => ({
                ...card,
                key: `metric-${index}`,
                cardClass: THEME_CLASS_MAP[card.theme] || 'metric-card'
            })),
            hotLeads: this.normalizeLeads(data.hotLeads),
            slaTasks: this.normalizeTasks(data.slaTasks),
            expiringContracts: this.normalizeContracts(data.expiringContracts),
            pendingApprovals: this.normalizeApprovals(data.pendingApprovals),
            reengagementTasks: this.normalizeTasks(data.reengagementTasks),
            regionalInflows: this.normalizeRegions(data.regionalInflows)
        };
    }

    normalizeLeads(leads = []) {
        return leads.map((lead, index) => {
            const recordLabel = lead.company || lead.name || '리드';
            const metaLine = [lead.consultationType, lead.routingGroup, lead.contractEndWindow]
                .filter(Boolean)
                .join(' · ');

            return {
                ...lead,
                key: `lead-${lead.id || index}`,
                recordLabel,
                metaLine,
                scoreLabel:
                    lead.leadScore === null || lead.leadScore === undefined
                        ? ''
                        : `점수 ${lead.leadScore}`,
                windowLabel: lead.contractEndDate
                    ? this.formatDate(lead.contractEndDate)
                    : lead.contractEndWindow || '',
                priorityClass: `priority-pill ${this.resolvePriorityClass(lead.salesPriority)}`
            };
        });
    }

    normalizeTasks(tasks = []) {
        return tasks.map((task, index) => ({
            ...task,
            key: `task-${task.id || index}`,
            metaLine: [task.salesTaskType, task.relatedName, task.company].filter(Boolean).join(' · '),
            activityDateLabel: task.activityDate ? this.formatDate(task.activityDate) : '-',
            priorityClass: `priority-pill ${this.resolvePriorityClass(task.priority)}`,
            relatedLabel: task.relatedName || '관련 레코드'
        }));
    }

    normalizeContracts(contracts = []) {
        return contracts.map((contract, index) => ({
            ...contract,
            key: `contract-${contract.id || index}`,
            recordLabel: contract.accountName || contract.name || '계약',
            metaLine: [contract.contractNumber, contract.status].filter(Boolean).join(' · '),
            endDateLabel: contract.endDate ? this.formatDate(contract.endDate) : '-'
        }));
    }

    normalizeApprovals(approvals = []) {
        return approvals.map((approval, index) => ({
            ...approval,
            key: `approval-${approval.id || index}`,
            recordLabel: approval.opportunityName || approval.approvalRequestName || '승인 요청',
            metaLine: [approval.quoteName, approval.approverName].filter(Boolean).join(' · '),
            requestedAtLabel: approval.requestedAt ? this.formatDateTime(approval.requestedAt) : '-'
        }));
    }

    normalizeRegions(regions = []) {
        const maxCount = regions.reduce(
            (highest, row) => Math.max(highest, Number(row.leadCount || 0)),
            0
        );

        return regions.map((region, index) => ({
            ...region,
            key: `region-${index}`,
            countLabel: `${region.leadCount || 0}건`,
            barStyle: `width: ${maxCount ? Math.max((region.leadCount / maxCount) * 100, 12) : 12}%`
        }));
    }

    resolvePriorityClass(value) {
        if (value === 'Hot' || value === 'High') {
            return 'hot';
        }
        if (value === 'Warm' || value === 'Normal') {
            return 'warm';
        }
        return 'cold';
    }

    formatDate(value) {
        if (!value) {
            return '';
        }

        const dateValue = new Date(value);
        if (Number.isNaN(dateValue.getTime())) {
            return value;
        }

        return new Intl.DateTimeFormat('ko-KR', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(dateValue);
    }

    formatDateTime(value) {
        if (!value) {
            return '';
        }

        const dateValue = new Date(value);
        if (Number.isNaN(dateValue.getTime())) {
            return value;
        }

        return new Intl.DateTimeFormat('ko-KR', {
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).format(dateValue);
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }

        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return '영업 요약을 불러오는 중 오류가 발생했습니다.';
    }
}
