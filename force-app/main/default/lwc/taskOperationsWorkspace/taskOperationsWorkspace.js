import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getWorkspaceData from '@salesforce/apex/TaskOperationsWorkspaceController.getWorkspaceData';

export default class TaskOperationsWorkspace extends NavigationMixin(LightningElement) {
    wiredResult;
    data;
    errorMessage;
    isRefreshing = false;

    @wire(getWorkspaceData)
    wiredWorkspace(result) {
        this.wiredResult = result;

        if (result.data) {
            this.data = result.data;
            this.errorMessage = undefined;
            return;
        }

        if (result.error) {
            this.data = undefined;
            this.errorMessage = this.reduceError(result.error);
        }
    }

    get isLoading() {
        return !this.data && !this.errorMessage;
    }

    get isBusy() {
        return this.isLoading || this.isRefreshing;
    }

    get metrics() {
        return this.data?.metrics || [];
    }

    get openTasks() {
        return this.data?.openTasks || [];
    }

    get slaTasks() {
        return this.data?.slaTasks || [];
    }

    get overdueTasks() {
        return this.data?.overdueTasks || [];
    }

    get renewalTasks() {
        return this.data?.renewalTasks || [];
    }

    get reengagementTasks() {
        return this.data?.reengagementTasks || [];
    }

    async handleRefresh() {
        if (!this.wiredResult || this.isRefreshing) {
            return;
        }

        this.isRefreshing = true;
        try {
            await refreshApex(this.wiredResult);
        } finally {
            this.isRefreshing = false;
        }
    }

    handleNewTask() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            }
        });
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || 'Task 운영 데이터를 불러오지 못했습니다.';
    }
}
