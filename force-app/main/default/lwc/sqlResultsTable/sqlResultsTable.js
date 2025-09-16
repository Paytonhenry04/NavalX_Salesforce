import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SqlResultsTable extends LightningElement {
    @api value;
    
    @track showTable = true;
    @track processedRows = [];
    @track displayedRowCount = 8; // Start with fewer rows for text display
    
    // Configuration for agent chat window - text display
    MAX_FIELD_LENGTH = 35; // Shorter for inline text display
    INITIAL_ROWS = 8;
    LOAD_MORE_INCREMENT = 6;
    MAX_DISPLAY_ROWS = 30; // Limit for performance in chat window
    
    get hasData() {
        return this.value && this.value.rows && this.value.rows.length > 0;
    }
    
    get columns() {
        return this.value?.columns || [];
    }
    
    get totalRows() {
        return this.value?.totalRows || 0;
    }
    
    get totalRowsLabel() {
        const count = this.totalRows;
        return `${count} ${count === 1 ? 'row' : 'rows'}`;
    }
    
    get executionTime() {
        const time = this.value?.executionTime;
        return time ? `${time}` : 'N/A';
    }
    
    get columnCount() {
        return this.columns.length;
    }
    
    get showJson() {
        return !this.showTable;
    }
    
    get viewToggleLabel() {
        return this.showTable ? 'JSON View' : 'List View';
    }
    
    get viewToggleIcon() {
        return this.showTable ? 'utility:preview' : 'utility:list';
    }
    
    get hasMoreRows() {
        return this.totalRows > this.displayedRowCount;
    }
    
    get canLoadMore() {
        return this.hasMoreRows && this.displayedRowCount < this.MAX_DISPLAY_ROWS;
    }
    
    get formattedJson() {
        if (!this.hasData) return '';
        
        // Create a clean object for JSON display
        const cleanData = {
            totalRows: this.totalRows,
            executionTime: this.value.executionTime,
            columns: this.columns,
            rows: this.value.rows.slice(0, this.displayedRowCount).map(row => {
                const rowObj = {};
                row.cells.forEach(cell => {
                    rowObj[cell.key] = cell.value;
                });
                return rowObj;
            })
        };
        
        return JSON.stringify(cleanData, null, 2);
    }
    
    connectedCallback() {
        this.processTextData();
    }
    
    processTextData() {
        if (!this.hasData) return;
        
        try {
            // Process rows for text display with intelligent truncation
            this.processedRows = this.value.rows
                .slice(0, this.displayedRowCount)
                .map((row, index) => ({
                    id: `row-${index}`,
                    displayIndex: index + 1,
                    cells: row.cells.map(cell => {
                        const isLink = cell.key === 'Record Page' && cell.value?.startsWith('http');
                        return {
                            key: this.formatFieldName(cell.key),
                            value: cell.value || '',
                            fullValue: cell.value || '',
                            displayValue: this.formatFieldValue(cell.value),
                            isLink: isLink
                        };
                    })
                }));
        } catch (error) {
            console.error('Error processing text data:', error);
            this.showErrorToast('Failed to process query results');
        }
    }
    
    formatFieldName(fieldName) {
        // Convert field names to readable format
        return fieldName
            .replace(/_/g, ' ')
            .replace(/([A-Z])/g, ' $1')
            .replace(/\b\w/g, l => l.toUpperCase())
            .trim();
    }
    
    formatFieldValue(value) {
        if (value === null || value === undefined || value === '') {
            return 'N/A';
        }
        

        const stringValue = String(value).trim();
        
        // Handle different data types intelligently
        
        // Boolean values
        if (typeof value === 'boolean') {
            return value ? 'Yes' : 'No';
        }
        
        // Numbers - format for readability
        if (!isNaN(value) && !isNaN(parseFloat(value))) {
            const num = parseFloat(value);
            
            // Large numbers
            if (Math.abs(num) >= 1000000) {
                return (num / 1000000).toFixed(1) + 'M';
            } else if (Math.abs(num) >= 1000) {
                return (num / 1000).toFixed(1) + 'K';
            }
            
            // Decimals
            if (num % 1 !== 0) {
                return num.toFixed(2);
            }
            
            return num.toString();
        }
        
        // URLs - handle Record Page links specially
        if (stringValue.match(/^https?:\/\//)) {
            try {
                const url = new URL(stringValue);
                // For Record Page fields, show a more descriptive text but keep full URL in title
                if (value && (typeof value === 'string') && value.includes('lightning/r/')) {
                    return 'Open Record →';
                }
                // For other URLs, show domain only
                return url.hostname;
            } catch (e) {
                // Fall through to regular string handling
            }
        }
        
        // Email addresses - truncate if too long
        if (stringValue.includes('@') && stringValue.includes('.')) {
            if (stringValue.length > this.MAX_FIELD_LENGTH) {
                const [localPart, domain] = stringValue.split('@');
                if (localPart.length > 10) {
                    return `${localPart.substring(0, 8)}...@${domain}`;
                }
            }
            return stringValue;
        }
        
        // Regular strings - intelligent truncation
        if (stringValue.length > this.MAX_FIELD_LENGTH) {
            // Try to break at word boundaries
            const truncated = stringValue.substring(0, this.MAX_FIELD_LENGTH);
            const lastSpace = truncated.lastIndexOf(' ');
            
            if (lastSpace > this.MAX_FIELD_LENGTH * 0.7) {
                return truncated.substring(0, lastSpace) + '...';
            } else {
                return truncated + '...';
            }
        }
        
        return stringValue;
    }
    
    toggleView() {
        this.showTable = !this.showTable;
    }
    
    loadMoreRows() {
        this.displayedRowCount = Math.min(
            this.displayedRowCount + this.LOAD_MORE_INCREMENT,
            this.MAX_DISPLAY_ROWS,
            this.totalRows
        );
        this.processTextData();
    }
    
    async copyAsJson() {
        try {
            const jsonString = this.formattedJson;
            await navigator.clipboard.writeText(jsonString);
            this.showSuccessToast('JSON copied to clipboard');
        } catch (error) {
            console.error('Copy failed:', error);
            this.showErrorToast('Failed to copy to clipboard');
        }
    }
    
    async copyJsonContent() {
        await this.copyAsJson();
    }
    
    downloadCsv() {
        try {
            const csvContent = this.generateCsvContent();
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            
            // Create download link
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', `query_results_${Date.now()}.csv`);
            link.style.visibility = 'hidden';
            
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            
            this.showSuccessToast('CSV file downloaded');
        } catch (error) {
            console.error('Download failed:', error);
            this.showErrorToast('Failed to download CSV');
        }
    }
    
    generateCsvContent() {
        if (!this.hasData) return '';
        
        // CSV Header
        const headers = this.columns.map(col => `"${col}"`).join(',');
        
        // CSV Rows
        const rows = this.value.rows.map(row => {
            return this.columns.map(col => {
                const cell = row.cells.find(c => c.key === col);
                const value = cell ? cell.value || '' : '';
                // Escape quotes and wrap in quotes
                return `"${String(value).replace(/"/g, '""')}"`;
            }).join(',');
        });
        
        return [headers, ...rows].join('\n');
    }
    
    showSuccessToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
            mode: 'dismissible'
        }));
    }
    
    showErrorToast(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissible'
        }));
    }
}