import { LightningElement, wire } from 'lwc';

import getTaskManagementData from '@salesforce/apex/SalesRepHomeController.getTaskManagementData';

const TASK_COLUMNS = [
    {
        label: 'Task',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'subject' },
            target: '_blank'
        }
    },
    { label: '유형', fieldName: 'salesTaskType', type: 'text' },
    {
        label: '관련 레코드',
        fieldName: 'relatedRecordUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'relatedLabel' },
            target: '_blank'
        }
    },
    { label: '마감일', fieldName: 'activityDate', type: 'date-local' },
    { label: '우선순위', fieldName: 'priority', type: 'text' },
    { label: '상태', fieldName: 'status', type: 'text' }
];

export default class SalesHomeTaskManager extends LightningElement {
    data;
    errorMessage;

    taskColumns = TASK_COLUMNS;

    @wire(getTaskManagementData)
    wiredData({ data, error }) {
        if (data) {
            this.data = {
                ...data,
                slaTasks: this.normalizeTasks(data.slaTasks),
                reengagementTasks: this.normalizeTasks(data.reengagementTasks)
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

    get slaTasks() {
        return this.data?.slaTasks || [];
    }

    get reengagementTasks() {
        return this.data?.reengagementTasks || [];
    }

    get hasSlaTasks() {
        return this.slaTasks.length > 0;
    }

    get hasReengagementTasks() {
        return this.reengagementTasks.length > 0;
    }

    normalizeTasks(tasks = []) {
        return tasks.map((task) => ({
            ...task,
            relatedLabel: task.relatedName || task.company || '관련 레코드',
            relatedRecordUrl: task.relatedRecordUrl || null
        }));
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(' ');
        }
        if (error?.body?.message) {
            return error.body.message;
        }
        return error?.message || 'Task 관리 데이터를 불러오지 못했습니다.';
    }
}
