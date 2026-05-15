import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

import convertLeadRecord from '@salesforce/apex/LeadConversionWorkspaceController.convertLeadRecord';
import getWorkspaceData from '@salesforce/apex/LeadConversionWorkspaceController.getWorkspaceData';

export default class LeadConversionWorkspace extends NavigationMixin(LightningElement) {
    _recordId;
    workspace;
    errorMessage;
    isLoading = false;
    actionInProgress = false;

    convertedStatus = '';
    accountMode = 'new';
    selectedAccountId;
    newAccountName = '';
    contactMode = 'new';
    selectedContactId;
    createOpportunity = true;
    opportunityName = '';

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

    get isBusy() {
        return this.isLoading || this.actionInProgress;
    }

    get showConvertAction() {
        return Boolean(this.workspace && !this.workspace.lead?.isConverted);
    }

    get disableConvert() {
        return this.isBusy || !this.workspace || !this.convertedStatus;
    }

    get cancelButtonLabel() {
        return this.workspace?.lead?.isConverted ? '닫기' : '취소';
    }

    get leadTitle() {
        return this.workspace?.lead?.company || this.workspace?.lead?.name || '리드';
    }

    get leadSubtitle() {
        return [this.workspace?.lead?.name, this.workspace?.lead?.email, this.workspace?.lead?.phone]
            .filter(Boolean)
            .join(' · ');
    }

    get priorityLabel() {
        return this.workspace?.lead?.salesPriority || '미분류';
    }

    get priorityPillClass() {
        const priority = this.workspace?.lead?.salesPriority;
        if (priority === 'Hot') {
            return 'pill hot';
        }
        if (priority === 'Warm') {
            return 'pill warm';
        }
        return 'pill cold';
    }

    get showLeadScore() {
        return this.workspace?.lead?.leadScore !== null && this.workspace?.lead?.leadScore !== undefined;
    }

    get leadScoreLabel() {
        return `점수 ${this.workspace?.lead?.leadScore}`;
    }

    get salesActionSummary() {
        return this.workspace?.lead?.salesActionSummary || '영업 액션 요약이 아직 생성되지 않았습니다.';
    }

    get summaryCards() {
        if (!this.workspace?.lead) {
            return [];
        }

        const lead = this.workspace.lead;
        return [
            {
                key: 'status',
                label: '리드 상태',
                value: lead.status || '-'
            },
            {
                key: 'consultationType',
                label: '상담 유형',
                value: lead.consultationType || '-'
            },
            {
                key: 'routingGroup',
                label: '라우팅 그룹',
                value: lead.routingGroup || '-'
            },
            {
                key: 'contractEndWindow',
                label: '계약 종료',
                value: lead.contractEndWindow || '-'
            }
        ];
    }

    get statusOptions() {
        return (this.workspace?.convertedStatuses || []).map((option) => ({
            label: option.label,
            value: option.value
        }));
    }

    get hasAccountSuggestions() {
        return (this.workspace?.accountSuggestions || []).length > 0;
    }

    get hasContactSuggestions() {
        return (this.workspace?.contactSuggestions || []).length > 0;
    }

    get accountOptions() {
        return (this.workspace?.accountSuggestions || []).map((account) => ({
            label: account.label || account.name,
            value: account.id
        }));
    }

    get contactOptions() {
        return (this.workspace?.contactSuggestions || []).map((contact) => ({
            label: contact.label || contact.name,
            value: contact.id
        }));
    }

    get accountModeOptions() {
        const options = [];
        if (this.hasAccountSuggestions) {
            options.push({
                label: '기존 거래처',
                value: 'existing'
            });
        }
        if (this.contactMode !== 'existing') {
            options.push({
                label: '신규 거래처',
                value: 'new'
            });
        }
        return options;
    }

    get contactModeOptions() {
        const options = [];
        if (this.hasContactSuggestions) {
            options.push({
                label: '기존 연락처',
                value: 'existing'
            });
        }
        options.push({
            label: '신규 연락처',
            value: 'new'
        });
        return options;
    }

    get isExistingAccountMode() {
        return this.accountMode === 'existing';
    }

    get isExistingContactMode() {
        return this.contactMode === 'existing';
    }

    get selectedAccountSuggestion() {
        return (this.workspace?.accountSuggestions || []).find(
            (account) => account.id === this.selectedAccountId
        );
    }

    get selectedContactSuggestion() {
        return (this.workspace?.contactSuggestions || []).find(
            (contact) => contact.id === this.selectedContactId
        );
    }

    get selectedAccountHelpText() {
        const account = this.selectedAccountSuggestion;
        if (!account) {
            return '기존 거래처를 선택하면 해당 계정으로 바로 전환됩니다.';
        }
        return account.isExactMatch
            ? '리드 회사명과 동일한 거래처를 추천했습니다.'
            : '기존 거래처에 연결해 중복 생성을 줄입니다.';
    }

    get selectedContactHelpText() {
        const contact = this.selectedContactSuggestion;
        if (!contact) {
            return '기존 연락처를 선택하면 해당 연락처에 리드를 연결합니다.';
        }
        return contact.isExactMatch
            ? '리드 이메일과 동일한 연락처를 추천했습니다.'
            : '기존 연락처를 재사용해 중복 생성을 줄입니다.';
    }

    get convertedLinks() {
        const lead = this.workspace?.lead;
        if (!lead) {
            return [];
        }

        return [
            {
                key: 'account',
                label: '거래처',
                actionLabel: '거래처 보기',
                url: this.buildRecordUrl('Account', lead.convertedAccountId)
            },
            {
                key: 'contact',
                label: '연락처',
                actionLabel: '연락처 보기',
                url: this.buildRecordUrl('Contact', lead.convertedContactId)
            },
            {
                key: 'opportunity',
                label: '기회',
                actionLabel: '기회 보기',
                url: this.buildRecordUrl('Opportunity', lead.convertedOpportunityId)
            }
        ].filter((item) => Boolean(item.url));
    }

    async loadWorkspace() {
        if (!this._recordId || this.isLoading) {
            return;
        }

        this.isLoading = true;
        this.errorMessage = undefined;

        try {
            const workspace = await getWorkspaceData({
                leadId: this._recordId
            });
            this.workspace = workspace;
            this.initializeFormState();
        } catch (error) {
            this.workspace = undefined;
            this.errorMessage = this.reduceError(error);
        } finally {
            this.isLoading = false;
        }
    }

    initializeFormState() {
        this.convertedStatus = this.statusOptions[0]?.value || '';
        this.accountMode = this.resolveMode(
            this.workspace?.recommendedAccountMode,
            this.hasAccountSuggestions
        );
        this.contactMode = this.resolveMode(
            this.workspace?.recommendedContactMode,
            this.hasContactSuggestions
        );
        this.selectedAccountId =
            this.workspace?.recommendedAccountId || this.workspace?.accountSuggestions?.[0]?.id;
        this.selectedContactId =
            this.workspace?.recommendedContactId || this.workspace?.contactSuggestions?.[0]?.id;
        this.newAccountName = this.workspace?.lead?.company || '';
        this.createOpportunity = true;
        this.opportunityName = this.workspace?.recommendedOpportunityName || '';

        if (this.contactMode === 'existing') {
            this.syncAccountWithSelectedContact();
        }
    }

    resolveMode(recommendedMode, hasSuggestions) {
        if (recommendedMode === 'existing' && hasSuggestions) {
            return 'existing';
        }
        return 'new';
    }

    handleConvertedStatusChange(event) {
        this.convertedStatus = event.detail.value;
    }

    handleCreateOpportunityChange(event) {
        this.createOpportunity = event.target.checked;
        if (!this.createOpportunity) {
            this.opportunityName = '';
        } else if (!this.opportunityName) {
            this.opportunityName = this.workspace?.recommendedOpportunityName || '';
        }
    }

    handleOpportunityNameChange(event) {
        this.opportunityName = event.target.value;
    }

    handleAccountModeChange(event) {
        this.accountMode = event.detail.value;
        if (this.accountMode === 'existing' && !this.selectedAccountId) {
            this.selectedAccountId =
                this.workspace?.recommendedAccountId || this.workspace?.accountSuggestions?.[0]?.id;
        }
    }

    handleAccountSelectionChange(event) {
        this.selectedAccountId = event.detail.value;
    }

    handleNewAccountNameChange(event) {
        this.newAccountName = event.target.value;
    }

    handleContactModeChange(event) {
        this.contactMode = event.detail.value;
        if (this.contactMode === 'existing' && !this.selectedContactId) {
            this.selectedContactId =
                this.workspace?.recommendedContactId || this.workspace?.contactSuggestions?.[0]?.id;
        }

        if (this.contactMode === 'existing') {
            this.syncAccountWithSelectedContact();
        }
    }

    handleContactSelectionChange(event) {
        this.selectedContactId = event.detail.value;
        this.syncAccountWithSelectedContact();
    }

    syncAccountWithSelectedContact() {
        const selectedContact = this.selectedContactSuggestion;
        if (!selectedContact?.accountId) {
            return;
        }

        this.accountMode = 'existing';
        this.selectedAccountId = selectedContact.accountId;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleRefresh() {
        if (this.isBusy) {
            return;
        }
        await this.loadWorkspace();
    }

    async handleConvert() {
        const validationMessage = this.validateBeforeConvert();
        if (validationMessage) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '전환 정보 확인',
                    message: validationMessage,
                    variant: 'error'
                })
            );
            return;
        }

        this.actionInProgress = true;

        try {
            const result = await convertLeadRecord({
                leadId: this._recordId,
                convertedStatus: this.convertedStatus,
                existingAccountId: this.accountMode === 'existing' ? this.selectedAccountId : null,
                existingContactId: this.contactMode === 'existing' ? this.selectedContactId : null,
                accountName: this.accountMode === 'new' ? this.newAccountName : null,
                createOpportunity: this.createOpportunity,
                opportunityName: this.createOpportunity ? this.opportunityName : null
            });

            if (!result?.success) {
                throw new Error(result?.message || '리드 전환에 실패했습니다.');
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: '전환 완료',
                    message: result.message,
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());

            const target = this.resolveNavigationTarget(result);
            if (target) {
                window.setTimeout(() => {
                    this[NavigationMixin.Navigate](
                        {
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: target.recordId,
                                objectApiName: target.objectApiName,
                                actionName: 'view'
                            }
                        },
                        true
                    );
                }, 0);
            }
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '전환 실패',
                    message: this.reduceError(error),
                    variant: 'error'
                })
            );
        } finally {
            this.actionInProgress = false;
        }
    }

    validateBeforeConvert() {
        if (!this.convertedStatus) {
            return '전환 완료 상태를 선택하세요.';
        }

        if (this.accountMode === 'existing' && !this.selectedAccountId) {
            return '기존 거래처를 선택하세요.';
        }

        if (this.accountMode === 'new' && !this.newAccountName?.trim()) {
            return '신규 거래처 이름을 입력하세요.';
        }

        if (this.contactMode === 'existing' && !this.selectedContactId) {
            return '기존 연락처를 선택하세요.';
        }

        if (this.createOpportunity && !this.opportunityName?.trim()) {
            return '기회 이름을 입력하세요.';
        }

        return '';
    }

    resolveNavigationTarget(result) {
        if (result?.opportunityId) {
            return {
                recordId: result.opportunityId,
                objectApiName: 'Opportunity'
            };
        }

        if (result?.accountId) {
            return {
                recordId: result.accountId,
                objectApiName: 'Account'
            };
        }

        if (result?.contactId) {
            return {
                recordId: result.contactId,
                objectApiName: 'Contact'
            };
        }

        return null;
    }

    buildRecordUrl(objectApiName, recordId) {
        return recordId ? `/lightning/r/${objectApiName}/${recordId}/view` : null;
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
