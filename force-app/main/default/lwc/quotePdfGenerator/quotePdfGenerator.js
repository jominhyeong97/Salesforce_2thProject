import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement } from 'lwc';

import generateBrandedPdf from '@salesforce/apex/QuotePdfGenerationService.generateBrandedPdf';
import getGeneratorSummary from '@salesforce/apex/QuotePdfGenerationService.getGeneratorSummary';

export default class QuotePdfGenerator extends NavigationMixin(LightningElement) {
    _recordId;
    summary;
    isLoading = true;
    isGenerating = false;
    hasLoaded = false;

    @api
    set recordId(value) {
        this._recordId = value;

        if (value && !this.hasLoaded) {
            this.hasLoaded = true;
            this.loadSummary();
        }
    }

    get recordId() {
        return this._recordId;
    }

    get quoteName() {
        return this.summary?.quoteName ?? '-';
    }

    get accountName() {
        return this.summary?.accountName ?? '-';
    }

    get statusLabel() {
        return this.summary?.statusLabel ?? '-';
    }

    get proposalScenario() {
        return this.summary?.proposalScenario ?? '-';
    }

    get expirationDate() {
        return this.summary?.expirationDate ?? null;
    }

    get existingPdfCount() {
        return this.summary?.existingPdfCount ?? 0;
    }

    get grandTotal() {
        return this.summary?.grandTotal ?? null;
    }

    get hasExistingPdf() {
        return this.existingPdfCount > 0;
    }

    get generateButtonLabel() {
        return this.isGenerating ? '생성 중...' : this.hasExistingPdf ? '새 버전 생성' : 'Aqua PDF 생성';
    }

    get disableGenerate() {
        return this.isLoading || this.isGenerating || !this.recordId;
    }

    async loadSummary() {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;
        try {
            this.summary = await getGeneratorSummary({ quoteId: this.recordId });
        } catch (error) {
            this.showToast('오류', this.normalizeError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleGenerate() {
        if (this.disableGenerate) {
            return;
        }

        this.isGenerating = true;
        try {
            const result = await generateBrandedPdf({ quoteId: this.recordId });

            if (!result?.success) {
                this.showToast('생성 실패', result?.message || '견적 PDF를 생성하지 못했습니다.', 'error');
                return;
            }

            this.showToast('생성 완료', result.message, 'success');

            this.dispatchEvent(new CloseActionScreenEvent());

            if (result.contentDocumentId) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__namedPage',
                    attributes: {
                        pageName: 'filePreview'
                    },
                    state: {
                        selectedRecordId: result.contentDocumentId
                    }
                });
            }
        } catch (error) {
            this.showToast('오류', this.normalizeError(error), 'error');
        } finally {
            this.isGenerating = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    normalizeError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (Array.isArray(error?.body) && error.body.length > 0) {
            return error.body.map((entry) => entry.message).join(', ');
        }
        return error?.message || '알 수 없는 오류가 발생했습니다.';
    }
}
