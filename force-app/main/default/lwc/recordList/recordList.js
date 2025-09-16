import { LightningElement, api } from 'lwc';

export default class RecordList extends LightningElement {
    @api value; // Agentforce injects the data

    get hasAggregates() {
        if (!this.value) return false;
        
        let aggregatesArray = [];
        
        // Handle the nested structure from Data Cloud SQL
        if (this.value.formattedResult && this.value.formattedResult.Aggregates) {
            aggregatesArray = this.value.formattedResult.Aggregates;
        } else if (this.value.Aggregates) {
            aggregatesArray = this.value.Aggregates;
        }

        return aggregatesArray && aggregatesArray.length > 0;
    }

    get hasMeaningfulRecords() {
        return this.records && this.records.length > 0 && 
               this.records.some(record => record.name && record.name.trim() && record.name !== 'Unnamed Record');
    }

    get shouldShowComponent() {
        // Don't show the component if there are aggregates - let the agent handle those
        if (this.hasAggregates) {
            return false;
        }
        
        // Only show if we have meaningful records
        return this.hasMeaningfulRecords;
    }

    get records() {
        if (!this.value) return [];
        
        let recordsArray = [];
        
        // Handle the nested structure from Data Cloud SQL
        if (this.value.formattedResult && this.value.formattedResult.Records) {
            recordsArray = this.value.formattedResult.Records;
        } else if (this.value.Records) {
            recordsArray = this.value.Records;
        }

        // Map records to display format
        return recordsArray.map((record, index) => {
            // Get the record ID from either Record_Id or id__c field
            let recordId = record.Record_Id;
            if (!recordId && record.Fields) {
                const idField = record.Fields.find(f => f.Field_Name === 'id__c');
                recordId = idField ? idField.Value : null;
            }

            return {
                key: recordId || `record-${index}`,
                number: index + 1,
                name: record.Name || 'Unnamed Record',
                url: recordId && record.Object_API_Name 
                    ? `/lightning/r/${record.Object_API_Name}/${recordId}/view`
                    : null
            };
        });
    }
}