import { LightningElement, wire, track, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from 'lightning/navigation';
import leafletResource from '@salesforce/resourceUrl/Leaflet';
import getAllLocations from '@salesforce/apex/CompanyMapController.getAllLocations';
import leafletHeat from '@salesforce/resourceUrl/LeafletHeat';

export default class AllCompaniesMap extends NavigationMixin(LightningElement) {
    @track locations = [];
    @track selectedView = 'all'; // Default to show all selection
    map;
    markers = []; // Store all markers for filtering
    leafletLoaded = false;
    isLoading = true;
    error;

    // Configuration properties for Lightning App Builder
    @api height = 1000; // Default height in pixels

    heatLayer; 
    isHeatMap = false; 

    // View filter options
    viewOptions = [
        { label: 'All Locations', value: 'all' },
        { label: 'Companies Only', value: 'companies' },
        { label: 'Research Labs Only', value: 'labs' },

        { label: 'Heatmap', value: 'heatmap' }
    ];

    @wire(getAllLocations)
    wiredLocations({ error, data }) {
        if (data) {
            this.locations = data;
            this.error = undefined;
            this.isLoading = false;
            
            if (this.hasLocations) {
                if (!this.leafletLoaded) {
                    this.loadLeafletAndInitializeMap();
                } else {
                    this.initializeMap();
                }
            }
        } else if (error) {
            this.error = error.body?.message || 'Unknown error occurred';
            this.locations = [];
            this.isLoading = false;
            this.teardownMap();
        }
    }

    get hasLocations() {
        return this.locations && this.locations.length > 0;
    }

    get noLocations() {
        return !this.isLoading && !this.error && (!this.locations || this.locations.length === 0);
    }

    get locationsCount() {
        return this.locations ? this.locations.length : 0;
    }

    get companiesCount() {
        return this.locations ? this.locations.filter(loc => loc.Type === 'Company').length : 0;
    }

    get labsCount() {
        return this.locations ? this.locations.filter(loc => loc.Type === 'Lab').length : 0;
    }

    // Get filtered locations based on selected view
    get filteredLocations() {
        if (!this.locations) return [];
        
        switch (this.selectedView) {
            case 'companies':
                return this.locations.filter(loc => loc.Type === 'Company');
            case 'labs':
                return this.locations.filter(loc => loc.Type === 'Lab');
            case 'all':
            default:
                return this.locations;
        }
    }

    // Handle map resize when dimensions change (called when properties change)
    renderedCallback() {
        // Apply dynamic height to map container
        const mapContainer = this.template.querySelector('.map-container');
        if (mapContainer && this.height) {
            mapContainer.style.height = `${this.height}px`;
        }
        
        // Handle map resize when dimensions change
        if (this.map) {
            // Use setTimeout to ensure DOM has updated
            setTimeout(() => {
                this.map.invalidateSize();
            }, 100);
        }
    }

    get visibleLocationsCount() {
        return this.filteredLocations.length;
    }

    get visibleCompaniesCount() {
        return this.filteredLocations.filter(loc => loc.Type === 'Company').length;
    }

    get visibleLabsCount() {
        return this.filteredLocations.filter(loc => loc.Type === 'Lab').length;
    }

    // Handle view filter change
    handleViewChange(event) {
        this.selectedView = event.detail.value;

        if (this.selectedView === 'heatmap') {
            this.showHeatMap(); 
        } else {
            this.isHeatMap = false; 
            this.updateMapMarkers();
        }
    }

    // handle heatmap button toggle
    toggleHeatmap() {
        this.isHeatMap = !this.isHeatMap;
        
        if (this.isHeatMap) {
            this.showHeatMap();
        } else {
            // remove heat layer 
            if (this.heatLayer) {
                this.map.removeLayer(this.heatLayer);
                this.heatLayer = null;
            }
            this.updateMapMarkers();     
        }
    }

    showHeatMap() {
        if (!this.map || !window.L.heatLayer) return;

        this.markers.forEach(marker => this.map.removeLayer(marker)); //remove markers first

        if (this.heatLayer) {
            this.map.removeLayer(this.heatLayer);
        }

        const heatData = this.locations.map(loc => [
            loc.Latitude, loc.Longitude, 0.8 // weight of each point
        ])

        this.heatLayer = L.heatLayer(heatData, {
            radius: 20,
            blur: 25,
            maxZoom: 17,
            minOpacity: 0.3
        });
        this.heatLayer.addTo(this.map);

        if (heatData.length > 0) {
            const bounds = L.latLngBounds(heatData.map(([lat, lng]) => [lat, lng]));
            this.map.fitBounds(bounds);
        }
    }

    async loadLeafletAndInitializeMap() {
        try {
            await Promise.all([
                loadStyle(this, leafletResource + '/dist/leaflet.css'),
                loadScript(this, leafletResource + '/dist/leaflet.js'), 

                loadScript(this, leafletHeat + '/leafletheat/leaflet-heat.js')
            ]);
            this.leafletLoaded = true;
            this.initializeMap();
        } catch (error) {
            this.error = 'Failed to load map resources';
            console.error('Error loading Leaflet:', error);
        }
    }

    createCustomIcon(color) {
        return L.divIcon({
            html: `<div style="
                background-color: ${color};
                width: 20px;
                height: 20px;
                border-radius: 50%;
                border: 2px solid white;
                box-shadow: 0 2px 4px rgba(0,0,0,0.3);
            "></div>`,
            className: 'custom-marker',
            iconSize: [20, 20],
            iconAnchor: [10, 10]
        });
    }

    initializeMap() {
        const container = this.template.querySelector('.map-container');
        if (!container || !this.hasLocations) return;

        this.teardownMap();

        // Initialize map
        this.map = L.map(container, {
            zoomControl: true,
            scrollWheelZoom: true
        });

        // Add tile layer
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 18
        }).addTo(this.map);

        // Create all markers but don't add them to the map yet
        this.createAllMarkers();
        
        // Update map markers based on current filter
        this.updateMapMarkers();

        // Ensure map renders properly
        setTimeout(() => {
            if (this.map) {
                this.map.invalidateSize();
            }
        }, 100);
    }

    createAllMarkers() {
        this.markers = [];
        
        this.locations.forEach(location => {
            // Determine marker color and icon based on type
            const isCompany = location.Type === 'Company';
            const markerColor = isCompany ? '#1976d2' : '#f57c00'; // Blue for companies, Orange for labs
            const customIcon = this.createCustomIcon(markerColor);
            
            const marker = L.marker([location.Latitude, location.Longitude], {
                icon: customIcon
            })
                .bindPopup(`
                    <div style="text-align: center;">
                        <strong>${location.Name}</strong><br>
                        <small style="color: ${markerColor}; font-weight: bold;">
                            ${isCompany ? 'Company' : 'Research Lab'}
                        </small><br>
                        <small>Click to view details</small>
                    </div>
                `).bindTooltip(`${location.Name} (${location.Type})`, {
                    permanent: false,
                    direction: 'top',
                    offset: [0, -10]
                });
            
            // Add click event to navigate to record
            marker.on('click', () => {
                this.navigateToRecord(location.Id, location.Type);
            });

            // Store marker with location data for filtering
            marker.locationData = location;
            this.markers.push(marker);
        });
    }

    updateMapMarkers() {
        if (!this.map) return;

        // Remove all markers from map
        this.markers.forEach(marker => {
            this.map.removeLayer(marker);
        });

        // Get filtered locations
        const filteredLocations = this.filteredLocations;
        const visibleMarkers = [];

        // Add only the filtered markers to the map
        this.markers.forEach(marker => {
            const shouldShow = filteredLocations.some(loc => 
                loc.Id === marker.locationData.Id && loc.Type === marker.locationData.Type
            );
            
            if (shouldShow) {
                marker.addTo(this.map);
                visibleMarkers.push(marker);
            }
        });

        // Fit map to show visible markers
        if (visibleMarkers.length > 0) {
            const bounds = this.calculateBoundsForMarkers(visibleMarkers);
            if (bounds) {
                this.map.fitBounds(bounds, {
                    padding: [20, 20]
                });
            }
        }
    }

    calculateBounds() {
        const filteredLocs = this.filteredLocations;
        if (!filteredLocs || filteredLocs.length === 0) return null;

        const latitudes = filteredLocs.map(l => l.Latitude);
        const longitudes = filteredLocs.map(l => l.Longitude);

        const minLat = Math.min(...latitudes);
        const maxLat = Math.max(...latitudes);
        const minLng = Math.min(...longitudes);
        const maxLng = Math.max(...longitudes);

        return [[minLat, minLng], [maxLat, maxLng]];
    }

    calculateBoundsForMarkers(markers) {
        if (!markers || markers.length === 0) return null;

        const latitudes = markers.map(m => m.locationData.Latitude);
        const longitudes = markers.map(m => m.locationData.Longitude);

        const minLat = Math.min(...latitudes);
        const maxLat = Math.max(...latitudes);
        const minLng = Math.min(...longitudes);
        const maxLng = Math.max(...longitudes);

        return [[minLat, minLng], [maxLat, maxLng]];
    }

    navigateToRecord(recordId, recordType) {
        const objectApiName = recordType === 'Company' ? 'Company__c' : 'Lab_Research_Center__c';
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            }
        });
    }

    teardownMap() {
        if (this.map) {
            this.map.remove();
            this.map = null;
        }
        this.markers = [];
    }

    disconnectedCallback() {
        this.teardownMap();
    }
}