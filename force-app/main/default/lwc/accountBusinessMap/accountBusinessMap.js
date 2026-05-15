import { LightningElement, api } from 'lwc';

const VF_PAGE_VERSION = '20260428-3';

export default class AccountBusinessMap extends LightningElement {
    @api recordId;

    get iframeSrc() {
        return this.recordId
            ? `/apex/KakaoAccountMap?id=${this.recordId}&v=${VF_PAGE_VERSION}`
            : `/apex/KakaoAccountMap?v=${VF_PAGE_VERSION}`;
    }
}
