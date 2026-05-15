import { LightningElement, api } from 'lwc';

const VF_PAGE_VERSION = '20260428-3';

export default class ContactKakaoMap extends LightningElement {
    @api recordId;

    get iframeSrc() {
        return this.recordId
            ? `/apex/KakaoContactMap?id=${this.recordId}&v=${VF_PAGE_VERSION}`
            : `/apex/KakaoContactMap?v=${VF_PAGE_VERSION}`;
    }
}
