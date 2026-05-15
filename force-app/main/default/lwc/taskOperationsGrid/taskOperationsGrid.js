import { LightningElement, api } from 'lwc';

const COLUMNS = [
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
    { label: '회사/거래처', fieldName: 'company', type: 'text' },
    { label: '설명', fieldName: 'descriptionPreview', type: 'text', wrapText: true },
    { label: '마감일', fieldName: 'activityDate', type: 'date-local' },
    { label: '우선순위', fieldName: 'priority', type: 'text' },
    { label: '상태', fieldName: 'status', type: 'text' }
];

export default class TaskOperationsGrid extends LightningElement {
    @api rows = [];

    columns = COLUMNS;

    get normalizedRows() {
        return (this.rows || []).map((row) => ({
            ...row,
            relatedLabel: row.relatedName || row.company || '관련 레코드',
            descriptionPreview: this.truncateDescription(row.description)
        }));
    }

    get hasRows() {
        return this.normalizedRows.length > 0;
    }

    truncateDescription(value) {
        if (!value) {
            return '';
        }

        const normalized = value.replace(/\s+/g, ' ').trim();
        if (normalized.length <= 120) {
            return normalized;
        }

        return `${normalized.slice(0, 117)}...`;
    }
}
