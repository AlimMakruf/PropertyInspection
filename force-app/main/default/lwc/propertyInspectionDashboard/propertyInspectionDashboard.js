import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PropertyInspectionDashboard extends LightningElement {
    @api recordId;
    error;
    records = [];
    filteredRecords = [];
    isModalOpen = false;

    // Store wired result for refresh
    wiredResult;

    selectedStatus = '';
    selectedType = '';

    statusOptions = [
        { label: 'All', value: '' },
        { label: 'Not Started', value: 'Not Started' },
        { label: 'In Progress', value: 'In Progress' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Failed', value: 'Failed' }
    ];
    typeOptions = [
        { label: 'All', value: '' },
        { label: 'Initial', value: 'Initial' },
        { label: 'Annual', value: 'Annual' },
        { label: 'Move-Out', value: 'Move-Out' },
        { label: 'Maintenance', value: 'Maintenance' }
    ];

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Property_Inspections__r',
        fields: [
            'Property_Inspection__c.Id',
            'Property_Inspection__c.Name',
            'Property_Inspection__c.Inspection_Date__c',
            'Property_Inspection__c.Inspection_Type__c',
            'Property_Inspection__c.Inspection_Status__c',
            'Property_Inspection__c.Overall_Rating__c'
        ],
    })
    wiredRecords(value) {
        this.wiredResult = value;
        const { data, error } = value;
        if (data) {
            this.records = data.records.map(record => {
                const status = record.fields.Inspection_Status__c.value;
                let variant = 'slds-theme_default';
                if (status === 'Completed') variant = 'slds-theme_success';
                else if (status === 'In Progress') variant = 'slds-theme_warning';
                else if (status === 'Not Started') variant = 'slds-theme_alert';
                else if (status === 'Failed') variant = 'slds-theme_error';

                return {
                    id: record.id,
                    inspectionDate: record.fields.Inspection_Date__c.value,
                    inspectionType: record.fields.Inspection_Type__c.value,
                    status: status,
                    rating: record.fields.Overall_Rating__c.value,
                    inspectorName: record.fields.Name.value,
                    variant: variant
                };
            });
            this.filteredRecords = [...this.records];
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.records = [];
            this.filteredRecords = [];
        }
    }

    get hasFilteredRecords() {
        return this.filteredRecords && this.filteredRecords.length > 0;
    }

    get avgRating() {
        if (this.filteredRecords?.length > 0) {
            const validRatings = this.filteredRecords
                .map(r => r.rating)
                .filter(r => r != null && !isNaN(r));
            const total = validRatings.reduce((sum, r) => sum + r, 0);
            return validRatings.length > 0 ? (total / validRatings.length).toFixed(2) : '0.00';
        }
        return '0.00';
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.applyFilters();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.applyFilters();
    }

    applyFilters() {
        this.filteredRecords = this.records.filter(record => {
            const statusMatch = !this.selectedStatus || record.status === this.selectedStatus;
            const typeMatch = !this.selectedType || record.inspectionType === this.selectedType;
            return statusMatch && typeMatch;
        });
    }

    openFlowModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleFlowStatusChange(event) {
        const status = event.detail.status;
        console.log('Flow status changed to: ' + status);
        if (status === 'FINISHED' || status === 'SUCCESS') {
            this.isModalOpen = false;
            // Refresh the data
            refreshApex( this.wiredResult );
            // Reapply current filters after refresh
            this.applyFilters();
        }
        // Optionally handle other statuses like 'ERROR'
    }
}