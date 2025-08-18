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

    // Always show arrows when there are records (for cycling)
    get showLeftArrow() {
        return this.hasRecords && this.tableData.length > 1;
    }

    get showRightArrow() {
        return this.hasRecords && this.tableData.length > 1;
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
            // Start with first item (index 0)
            this.currentIndex = 0;
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
        if (this.tableData.length <= 1) return;
        
        // Go to previous item, or cycle to last item if at beginning
        if (this.currentIndex > 0) {
            this.currentIndex--;
        } else {
            this.currentIndex = this.tableData.length - 1; // Cycle to last item
        }
        this.updateCardClasses();
    }

    handleNext() {
        if (this.tableData.length <= 1) return;
        
        // Go to next item, or cycle to first item if at end
        if (this.currentIndex < this.tableData.length - 1) {
            this.currentIndex++;
        } else {
            this.currentIndex = 0; // Cycle back to first item
        }
        this.updateCardClasses();
    }

    updateCardClasses() {
        this.tableData = this.tableData.map((rec, index) => {
            const position = index - this.currentIndex;
            let cardClass = 'record-card';

            // Stack cards: active (current), middle (next), bottom (next+1)
            if (position === 0) {
                cardClass += ' card-active';
            } else if (position === 1 || (this.currentIndex === this.tableData.length - 1 && index === 0)) {
                // Show next card, or first card if we're at the last item
                cardClass += ' card-middle';
            } else if (position === 2 || 
                      (this.currentIndex === this.tableData.length - 1 && index === 1) ||
                      (this.currentIndex === this.tableData.length - 2 && index === 0)) {
                // Show card after next, handle wrapping for last items
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