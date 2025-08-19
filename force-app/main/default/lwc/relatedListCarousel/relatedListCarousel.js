import { LightningElement, api, track } from 'lwc';
import getRecommendations from '@salesforce/apex/RecommendationController.getRecommendations';
import { NavigationMixin } from 'lightning/navigation';

export default class RelatedListCarousel extends NavigationMixin(LightningElement) {
    @api recordId;
    @api targetObjectApiName; // Which object type to display (e.g., 'Product2')
    @api fieldsList; // comma-separated API names for dynamic fields

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
        if (!this.targetObjectApiName) {
            return 'Recommended Records';
        }
        
        // Convert API name to readable label
        const objectLabel = this.getObjectLabel(this.targetObjectApiName);
        return `Recommended ${objectLabel}`;
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
        if (this.recordId && this.targetObjectApiName) {
            this.fetchRecommendations();
        } else {
            this.error = 'Configuration error: recordId and targetObjectApiName are required.';
        }
    }

    fetchRecommendations() {
        let fields = this.fieldsArray;
        console.log('Fetching recommendations with fields:', fields);

        getRecommendations({ 
            recordId: this.recordId, 
            targetObjectApiName: this.targetObjectApiName,
            fieldApiNames: fields 
        })
        .then(results => {
            console.log('Received recommendations:', results);
            
            const addFlds = this.additionalFields;

            this.tableData = results.map((rec, index) => {
                const fieldsData = addFlds.map(fld => {
                    const rawValue = rec.fields[fld];
                    const isImageField = (fld === 'current_product_image__c' || fld.toLowerCase().includes('image'));
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

                // Add score field if not already in the list
                if (rec.score && !addFlds.includes('score')) {
                    fieldsData.push({
                        label: 'Recommendation Score',
                        value: rec.score.toFixed(2),
                        apiName: 'score',
                        isImage: false
                    });
                }

                return {
                    Id: rec.recordId,
                    title: rec.name || `Record ${index + 1}`,
                    url: '/' + rec.recordId,
                    fields: fieldsData,
                    score: rec.score
                };
            });

            this.error = undefined;
            this.currentIndex = 0;
            this.updateCardClasses();
        })
        .catch(err => {
            console.error('Error fetching recommendations:', err);
            this.error = err.body?.message || err.message || 'Error fetching recommendations';
            this.tableData = [];
            this.currentIndex = 0;
        });
    }

    toggleCollapse() {
        this.isCollapsed = !this.isCollapsed;
    }

    handleHeaderClick() {
        // Navigate to full list view if needed
        console.log('Header clicked - could navigate to full recommendations view');
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
            let isActive = false;

            // Stack cards: active (current), middle (next), bottom (next+1)
            if (position === 0) {
                cardClass += ' card-active';
                isActive = true; // This card gets the item number
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
                position: position,
                isActive: isActive
            };
        });
    }

    getObjectLabel(apiName) {
        // Map common Salesforce objects to their proper labels
        const objectLabelMap = {
            'Product2': 'Products',
            'Account': 'Accounts', 
            'Contact': 'Contacts',
            'Lead': 'Leads',
            'Opportunity': 'Opportunities',
            'Case': 'Cases',
            'User': 'Users',
            'Campaign': 'Campaigns',
            'Task': 'Tasks',
            'Event': 'Events'
        };
        
        // Check if it's a known standard object
        if (objectLabelMap[apiName]) {
            return objectLabelMap[apiName];
        }
        
        // For custom objects, humanize the API name
        return this.humanizeLabel(apiName);
    }

    humanizeLabel(apiName) {
        if (!apiName) return '';
        return apiName
            .replace(/__c$|__r$/, '')
            .replace(/_/g, ' ')
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .split(' ')
            .map(w => w.charAt(0).toUpperCase() + w.slice(1))
            .join(' ');
    }
}