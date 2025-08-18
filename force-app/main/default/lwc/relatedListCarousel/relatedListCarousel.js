import { LightningElement, api, track } from 'lwc';
import getRelatedRecords from '@salesforce/apex/RelatedRecordsController.getRelatedRecords';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedListCarousel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api parentObjectApiName;
    @api childObjectApiName;
    @api lookupFieldApiName;
    @api childRelationshipName;
    @api fieldsList;
    @api flexipageId;
    @api cmpId;

    @track tableData = [];
    @track error;
    @track isCollapsed = false;
    @track currentIndex = 0;

    get collapseIconName() {
        return this.isCollapsed ? 'utility:chevronright' : 'utility:chevrondown';
    }

    get fieldsArray() {
        return (this.fieldsList || '').split(',').map(f => f.trim()).filter(f => f);
    }

    get firstField() {
        return this.fieldsArray.length > 0 ? this.fieldsArray[0] : null;
    }

    get additionalFields() {
        return this.fieldsArray.length > 1 ? this.fieldsArray.slice(1) : [];
    }

    get cardTitle() {
        if (this.childRelationshipName) {
            return `Related ${this.childRelationshipName.replace(/__r$/, '')}`;
        }
        return 'Related Records';
    }

    get hasRecords() {
        return Array.isArray(this.tableData) && this.tableData.length > 0;
    }

    get noRecordsNoError() {
        return !this.hasRecords && !this.error;
    }

    get showLeftArrow() {
        return this.hasRecords && this.currentIndex > 0;
    }

    get showRightArrow() {
        return this.hasRecords && this.currentIndex < this.tableData.length - 1;
    }

    get carouselInfo() {
        if (!this.hasRecords) {
            return '';
        }
        const current = this.currentIndex + 1;
        const total = this.tableData.length;
        return `${current} of ${total}`;
    }

    connectedCallback() {
        this.fetchAllRelatedRecords();
    }

    fetchAllRelatedRecords() {
        if (!this.recordId || !this.childObjectApiName || !this.lookupFieldApiName || !this.fieldsList) {
            this.error = 'Configuration error: check childObjectApiName, lookupFieldApiName, and fieldsList.';
            this.tableData = [];
            return;
        }

        getRelatedRecords({
            parentId: this.recordId,
            childObjectApiName: this.childObjectApiName,
            lookupFieldApiName: this.lookupFieldApiName,
            fieldsString: this.fieldsList,
            limitSize: 200
        })
        .then(results => {
            const firstFld = this.firstField;
            const addFlds = this.additionalFields;

            this.tableData = results.map((rec, index) => {
                const fields = addFlds.map(fld => {
                    const rawValue = rec[fld];
                    const isImageField = (fld === 'current_product_image__c');
                    let displayValue = rawValue;

                    if (isImageField && rawValue) {
                        displayValue = `/sfc/servlet.shepherd/document/download/${rawValue}`;
                    }

                    return {
                        label: this.humanizeLabel(fld),
                        value: displayValue,
                        apiName: fld,
                        isImage: isImageField && Boolean(rawValue)
                    };
                });

                return {
                    Id: rec.Id,
                    title: rec[firstFld] || `Record ${index + 1}`,
                    url: '/' + rec.Id,
                    fields: fields
                };
            });

            this.error = undefined;
            // Start with last card active for stacking effect
            this.currentIndex = Math.max(0, this.tableData.length - 1);
            this.updateCardClasses();
        })
        .catch(err => {
            this.error = err.body && err.body.message ? err.body.message : JSON.stringify(err);
            this.tableData = [];
            this.currentIndex = 0;
        });
    }

    toggleCollapse() {
        this.isCollapsed = !this.isCollapsed;
    }

    handleHeaderClick() {
        if (this.flexipageId && this.cmpId) {
            const url = '/lightning/cmp/force__dynamicRelatedListViewAll' +
                `?force__flexipageId=${this.flexipageId}` +
                `&force__cmpId=${this.cmpId}` +
                `&force__recordId=${this.recordId}`;
            window.open(url, '_self');
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.parentObjectApiName,
                relationshipApiName: this.childRelationshipName,
                actionName: 'view'
            }
        });
    }

    handlePrevious() {
        if (this.currentIndex > 0) {
            this.currentIndex--;
            this.updateCardClasses();
        }
    }

    handleNext() {
        if (this.currentIndex < this.tableData.length - 1) {
            this.currentIndex++;
            this.updateCardClasses();
        }
    }

    updateCardClasses() {
        this.tableData = this.tableData.map((rec, index) => {
            const position = index - this.currentIndex;
            let cardClass = 'record-card';

            // Stack cards: active (current), middle (previous), bottom (2 back)
            if (position === 0) {
                cardClass += ' card-active';
            } else if (position === -1) {
                cardClass += ' card-middle';
            } else if (position === -2) {
                cardClass += ' card-bottom';
            } else {
                cardClass += ' card-hidden';
            }

            return { 
                ...rec, 
                cardClass,
                position: position
            };
        });
    }

    humanizeLabel(apiName) {
        return apiName
            .replace(/__c$|__r$/, '')
            .replace(/_/g, ' ')
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .split(' ')
            .map(w => w.charAt(0).toUpperCase() + w.slice(1))
            .join(' ');
    }
}