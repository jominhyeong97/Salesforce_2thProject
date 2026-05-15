import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import approveRequest from '@salesforce/apex/QuoteApprovalWorkspaceController.approveRequest';
import getWorkspaceData from '@salesforce/apex/QuoteApprovalWorkspaceController.getWorkspaceData';
import rejectRequest from '@salesforce/apex/QuoteApprovalWorkspaceController.rejectRequest';

const KRW_FORMATTER = new Intl.NumberFormat('ko-KR', {
    style: 'currency',
    currency: 'KRW',
    maximumFractionDigits: 0
});

export default class QuoteApprovalWorkspace extends NavigationMixin(LightningElement) {
    _recordId;
    workspace;
    snapshot;
    errorMessage;
    decisionComment = '';
    isLoading = false;
    actionInProgress = false;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        if (value && value !== this._recordId) {
            this._recordId = value;
            this.loadWorkspace();
        }
    }

    @wire(CurrentPageReference)
    handlePageReference(pageReference) {
        const pageStateRecordId =
            pageReference?.state?.c__recordId || pageReference?.attributes?.recordId;
        if (pageStateRecordId && pageStateRecordId !== this._recordId) {
            this._recordId = pageStateRecordId;
            this.loadWorkspace();
        }
    }

    connectedCallback() {
        if (this._recordId) {
            this.loadWorkspace();
        }
    }

    get showPdfPreview() {
        return Boolean(this.workspace?.quotePdfDocumentId);
    }

    get canPrintDocument() {
        return Boolean(this.snapshot);
    }

    get showActionPanel() {
        return Boolean(this.workspace?.canApprove || this.workspace?.canReject);
    }

    get showSealImage() {
        return this.workspace?.status === '승인' && Boolean(this.workspace?.sealImageUrl);
    }

    get showSealFallback() {
        return this.workspace?.status === '승인' && !this.workspace?.sealImageUrl;
    }

    async loadWorkspace() {
        if (!this._recordId || this.isLoading) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const workspace = await getWorkspaceData({
                approvalRequestId: this._recordId
            });

            this.workspace = workspace;
            this.decisionComment = workspace?.decisionComment || '';
            this.snapshot = this.normalizeSnapshot(workspace?.snapshotJson);
        } catch (error) {
            this.workspace = undefined;
            this.snapshot = undefined;
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleDecisionCommentChange(event) {
        this.decisionComment = event.target.value;
    }

    async handleApprove() {
        await this.processDecision('approve');
    }

    async handleReject() {
        await this.processDecision('reject');
    }

    handlePrint() {
        const documentSection = this.template.querySelector('.document');
        if (!documentSection) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '인쇄 불가',
                    message: '인쇄할 기안문서를 먼저 불러와 주세요.',
                    variant: 'error'
                })
            );
            return;
        }

        const printableDocument = documentSection.cloneNode(true);
        printableDocument.querySelectorAll('.no-print').forEach((element) => element.remove());

        const printFrame = document.createElement('iframe');
        printFrame.setAttribute('title', 'quote-approval-print-frame');
        printFrame.style.position = 'fixed';
        printFrame.style.width = '0';
        printFrame.style.height = '0';
        printFrame.style.border = '0';
        printFrame.style.right = '0';
        printFrame.style.bottom = '0';
        document.body.appendChild(printFrame);

        const cleanup = () => {
            window.setTimeout(() => {
                if (printFrame.parentNode) {
                    printFrame.parentNode.removeChild(printFrame);
                }
            }, 1000);
        };

        const printWindow = printFrame.contentWindow;
        if (!printWindow) {
            cleanup();
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '인쇄 불가',
                    message: '인쇄용 프레임을 생성하지 못했습니다.',
                    variant: 'error'
                })
            );
            return;
        }

        printWindow.document.open();
        printWindow.document.write(this.buildPrintDocumentHtml(printableDocument.outerHTML));
        printWindow.document.close();

        window.setTimeout(() => {
            printWindow.focus();
            printWindow.print();
            cleanup();
        }, 300);
    }

    handleOpenFilePreview() {
        if (!this.workspace?.quotePdfDocumentId) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: this.workspace.quotePdfDocumentId
            }
        });
    }

    buildPrintDocumentHtml(documentHtml) {
        return `
            <!doctype html>
            <html lang="ko">
                <head>
                    <meta charset="utf-8" />
                    <title>견적 결재 기안문서</title>
                    <style>
                        body {
                            background: #ffffff;
                            color: #1f2933;
                            font-family: Arial, sans-serif;
                            margin: 0;
                            padding: 24px;
                        }
                        .document {
                            border: none;
                            border-radius: 0;
                            box-shadow: none;
                            margin: 0 auto;
                            max-width: 980px;
                            padding: 0;
                        }
                        .document-header {
                            align-items: center;
                            border-bottom: 1px solid #dddbda;
                            display: flex;
                            gap: 16px;
                            justify-content: space-between;
                            padding-bottom: 16px;
                        }
                        .document-title {
                            font-size: 26px;
                            margin: 0;
                        }
                        .document-subtitle,
                        .eyebrow {
                            color: #706e6b;
                            margin: 0;
                        }
                        .eyebrow {
                            font-size: 12px;
                            font-weight: 700;
                            letter-spacing: 0.04em;
                            text-transform: uppercase;
                        }
                        .document-grid,
                        .totals-grid {
                            display: grid;
                            gap: 12px;
                            grid-template-columns: repeat(2, minmax(0, 1fr));
                            margin-top: 16px;
                        }
                        .document-card {
                            background: #ffffff;
                            border: 1px solid #dddbda;
                            border-radius: 4px;
                            display: flex;
                            flex-direction: column;
                            gap: 6px;
                            min-height: 72px;
                            padding: 14px;
                        }
                        .document-card.emphasis {
                            background: #f3f3f3;
                        }
                        .summary-label {
                            color: #706e6b;
                            font-size: 12px;
                            font-weight: 700;
                        }
                        .document-section {
                            margin-top: 24px;
                        }
                        .section-title {
                            font-size: 16px;
                            margin: 0 0 12px;
                        }
                        .detail-text {
                            line-height: 1.6;
                            margin: 8px 0 0;
                            white-space: pre-wrap;
                        }
                        .line-table {
                            border-collapse: collapse;
                            width: 100%;
                        }
                        .line-table th,
                        .line-table td {
                            border: 1px solid #dddbda;
                            padding: 10px;
                            text-align: left;
                            vertical-align: top;
                        }
                        .line-table thead th {
                            background: #f3f3f3;
                            font-weight: 700;
                        }
                        .signature-section {
                            align-items: flex-start;
                            display: grid;
                            gap: 16px;
                            grid-template-columns: 1fr 180px;
                        }
                        .signature-box {
                            align-items: center;
                            background: #fafaf9;
                            border: 1px solid #dddbda;
                            border-radius: 4px;
                            display: flex;
                            height: 150px;
                            justify-content: center;
                            overflow: hidden;
                        }
                        .seal-image {
                            max-height: 120px;
                            max-width: 120px;
                            object-fit: contain;
                        }
                        .seal-fallback {
                            border: 2px solid #0176d3;
                            border-radius: 999px;
                            color: #0176d3;
                            font-size: 16px;
                            font-weight: 700;
                            padding: 12px 16px;
                        }
                    </style>
                </head>
                <body>${documentHtml}</body>
            </html>
        `;
    }

    async processDecision(mode) {
        if (!this._recordId || this.actionInProgress) {
            return;
        }

        this.actionInProgress = true;
        try {
            const actionMethod = mode === 'approve' ? approveRequest : rejectRequest;
            const result = await actionMethod({
                approvalRequestId: this._recordId,
                decisionComment: this.decisionComment
            });

            if (!result?.success) {
                throw new Error(result?.message || '결재 처리에 실패했습니다.');
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: mode === 'approve' ? '승인 완료' : '반려 완료',
                    message: result.message,
                    variant: 'success'
                })
            );

            await this.loadWorkspace();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '처리 실패',
                    message: this.reduceError(error),
                    variant: 'error'
                })
            );
        } finally {
            this.actionInProgress = false;
        }
    }

    normalizeSnapshot(snapshotJson) {
        if (!snapshotJson) {
            return undefined;
        }

        try {
            const parsed = JSON.parse(snapshotJson);
            const quote = parsed.quote || {};
            const quoteLines = (parsed.quoteLines || []).map((line, index) => ({
                key: `${index}-${line.productName || 'line'}`,
                productName: line.productName || '-',
                quantityDisplay: this.formatNumber(line.quantity),
                unitPriceDisplay: this.formatCurrency(line.unitPrice),
                totalPriceDisplay: this.formatCurrency(line.totalPrice),
                description: line.description || '-'
            }));

            return {
                requestDetail: parsed.requestDetail || this.workspace?.requestDetail || '',
                requestedAtDisplay: this.formatDate(parsed.requestedAt),
                opportunity: {
                    name: parsed.opportunity?.name || this.workspace?.opportunityName || '-',
                    accountName: parsed.opportunity?.accountName || '-'
                },
                quote: {
                    name: quote.name || this.workspace?.quoteName || '-',
                    status: quote.status || '-',
                    expirationDateDisplay: this.formatDate(quote.expirationDate),
                    subtotalDisplay: this.formatCurrency(quote.subtotal),
                    taxDisplay: this.formatCurrency(quote.tax),
                    shippingHandlingDisplay: this.formatCurrency(quote.shippingHandling),
                    grandTotalDisplay: this.formatCurrency(quote.grandTotal),
                    totalPriceDisplay: this.formatCurrency(quote.totalPrice)
                },
                quoteLines
            };
        } catch (error) {
            this.errorMessage = '기안문서 스냅샷을 해석하지 못했습니다.';
            return undefined;
        }
    }

    formatCurrency(value) {
        if (value === null || value === undefined || value === '') {
            return '-';
        }

        const numericValue = Number(value);
        return Number.isNaN(numericValue) ? '-' : KRW_FORMATTER.format(numericValue);
    }

    formatNumber(value) {
        if (value === null || value === undefined || value === '') {
            return '-';
        }

        const numericValue = Number(value);
        return Number.isNaN(numericValue)
            ? '-'
            : new Intl.NumberFormat('ko-KR').format(numericValue);
    }

    formatDate(value) {
        if (!value) {
            return '-';
        }

        const dateValue = new Date(value);
        if (Number.isNaN(dateValue.getTime())) {
            return value;
        }

        return new Intl.DateTimeFormat('ko-KR', {
            year: 'numeric',
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

        return '알 수 없는 오류가 발생했습니다.';
    }
}
