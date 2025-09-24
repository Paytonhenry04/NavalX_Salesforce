public with sharing class CompanyMapController {
    @AuraEnabled(cacheable=true)
    public static CompanyWrapper getCompanyLocation(Id companyId) {
        Company__c record = [
            SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
            FROM Company__c
            WHERE Id = :companyId
            LIMIT 1
        ];
        CompanyWrapper wrap = new CompanyWrapper();
        wrap.Id = record.Id;
        wrap.Name = record.Name; 
        wrap.Latitude = record.Location__Latitude__s;
        wrap.Longitude = record.Location__Longitude__s;
        wrap.Type = 'Company';
        return wrap;
    }
    
    // Updated method to get all companies with valid locations
    @AuraEnabled(cacheable=true)
    public static List<CompanyWrapper> getAllCompanyLocations() {
        List<CompanyWrapper> companies = new List<CompanyWrapper>();
        
        List<Company__c> records = [
            SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
            FROM Company__c
            WHERE Location__Latitude__s != null 
            AND Location__Longitude__s != null
            ORDER BY Name
        ];
        
        for (Company__c record : records) {
            CompanyWrapper wrap = new CompanyWrapper();
            wrap.Id = record.Id;
            wrap.Name = record.Name;
            wrap.Latitude = record.Location__Latitude__s;
            wrap.Longitude = record.Location__Longitude__s;
            wrap.Type = 'Company';
            companies.add(wrap);
        }
        
        return companies;
    }
    
    // New method to get all lab research centers with valid locations
    @AuraEnabled(cacheable=true)
    public static List<CompanyWrapper> getAllLabLocations() {
        List<CompanyWrapper> labs = new List<CompanyWrapper>();
        
        List<Lab_Research_Center__c> records = [
            SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
            FROM Lab_Research_Center__c
            WHERE Location__Latitude__s != null 
            AND Location__Longitude__s != null
            ORDER BY Name
        ];
        
        for (Lab_Research_Center__c record : records) {
            CompanyWrapper wrap = new CompanyWrapper();
            wrap.Id = record.Id;
            wrap.Name = record.Name;
            wrap.Latitude = record.Location__Latitude__s;
            wrap.Longitude = record.Location__Longitude__s;
            wrap.Type = 'Lab';
            labs.add(wrap);
        }
        
        return labs;
    }
    
    // New method to get all locations (companies and labs) in one call
    @AuraEnabled(cacheable=true)
    public static List<CompanyWrapper> getAllLocations() {
        List<CompanyWrapper> allLocations = new List<CompanyWrapper>();
        
        // Add companies
        allLocations.addAll(getAllCompanyLocations());
        
        // Add labs
        allLocations.addAll(getAllLabLocations());
        
        return allLocations;
    }
    
    public class CompanyWrapper {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;  
        @AuraEnabled public Double Latitude;
        @AuraEnabled public Double Longitude;
        @AuraEnabled public String Type; // 'Company' or 'Lab'
    }
}