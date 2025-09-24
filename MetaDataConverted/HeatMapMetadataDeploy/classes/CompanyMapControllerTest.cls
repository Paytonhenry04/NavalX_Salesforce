@isTest
public class CompanyMapControllerTest {
    
    static List<Company__c> createTestCompanies() {
        List<Company__c> testCompanies = new List<Company__c>();
        
        testCompanies.add(new Company__c(
            Name = 'Test Company 1',
            Location__Latitude__s = 37.7749,
            Location__Longitude__s = -122.4194
        ));
        
        testCompanies.add(new Company__c(
            Name = 'Test Company 2', 
            Location__Latitude__s = 40.7128,
            Location__Longitude__s = -74.0060
        ));
        
        insert testCompanies;
        return testCompanies;
    }
    
    static List<Lab_Research_Center__c> createTestLabs() {
        List<Lab_Research_Center__c> testLabs = new List<Lab_Research_Center__c>();
        
        testLabs.add(new Lab_Research_Center__c(
            Name = 'Test Lab 1',
            Location__Latitude__s = 42.3601,
            Location__Longitude__s = -71.0589
        ));
        
        testLabs.add(new Lab_Research_Center__c(
            Name = 'Test Lab 2',
            Location__Latitude__s = 41.8781,
            Location__Longitude__s = -87.6298
        ));
        
        insert testLabs;
        return testLabs;
    }
    
    static List<Company__c> createCompaniesWithNullValues() {
        List<Company__c> testCompanies = new List<Company__c>();
        
        testCompanies.add(new Company__c(
            Name = 'Test Company Valid',
            Location__Latitude__s = 34.0522,
            Location__Longitude__s = -118.2437
        ));
        
        insert testCompanies;
        
       
        testCompanies[0].Location__Latitude__s = null;
        testCompanies[0].Location__Longitude__s = null;
        update testCompanies;
        
        return testCompanies;
    }
    
    static List<Lab_Research_Center__c> createLabsWithNullValues() {
        List<Lab_Research_Center__c> testLabs = new List<Lab_Research_Center__c>();
        
        testLabs.add(new Lab_Research_Center__c(
            Name = 'Test Lab Valid',
            Location__Latitude__s = 39.9526,
            Location__Longitude__s = -75.1652
        ));
        
        insert testLabs;
        
        
        testLabs[0].Location__Latitude__s = null;
        testLabs[0].Location__Longitude__s = null;
        update testLabs;
        
        return testLabs;
    }
    
    @isTest
    static void testGetCompanyLocation_ValidCompany() {
        List<Company__c> companies = createTestCompanies();
        Company__c testCompany = companies[0];
        
        Test.startTest();
        CompanyMapController.CompanyWrapper result = CompanyMapController.getCompanyLocation(testCompany.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(testCompany.Id, result.Id, 'Id should match');
        System.assertEquals('Test Company 1', result.Name, 'Name should match');
        System.assertEquals(37.7749, result.Latitude, 'Latitude should match');
        System.assertEquals(-122.4194, result.Longitude, 'Longitude should match');
        System.assertEquals('Company', result.Type, 'Type should be Company');
    }
    
    @isTest
    static void testGetCompanyLocation_CompanyWithNullLocation() {
        List<Company__c> companies = createCompaniesWithNullValues();
        Company__c testCompany = companies[0];
        
        Test.startTest();
        CompanyMapController.CompanyWrapper result = CompanyMapController.getCompanyLocation(testCompany.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(testCompany.Id, result.Id, 'Id should match');
        System.assertEquals('Test Company Valid', result.Name, 'Name should match');
        System.assertEquals(null, result.Latitude, 'Latitude should be null');
        System.assertEquals(null, result.Longitude, 'Longitude should be null');
        System.assertEquals('Company', result.Type, 'Type should be Company');
    }
    
    @isTest
    static void testGetAllCompanyLocations() {
        createTestCompanies();
        createCompaniesWithNullValues();
        
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllCompanyLocations();
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return 2 companies with valid locations');
        
        System.assertEquals('Test Company 1', results[0].Name, 'First company should be Test Company 1');
        System.assertEquals('Test Company 2', results[1].Name, 'Second company should be Test Company 2');
        
        for (CompanyMapController.CompanyWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.Latitude, 'Latitude should not be null');
            System.assertNotEquals(null, wrapper.Longitude, 'Longitude should not be null');
            System.assertEquals('Company', wrapper.Type, 'Type should be Company');
        }
    }
    
    @isTest
    static void testGetAllLabLocations() {
        createTestLabs();
        createLabsWithNullValues();
        
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllLabLocations();
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return 2 labs with valid locations');
        
        System.assertEquals('Test Lab 1', results[0].Name, 'First lab should be Test Lab 1');
        System.assertEquals('Test Lab 2', results[1].Name, 'Second lab should be Test Lab 2');
        
        for (CompanyMapController.CompanyWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.Latitude, 'Latitude should not be null');
            System.assertNotEquals(null, wrapper.Longitude, 'Longitude should not be null');
            System.assertEquals('Lab', wrapper.Type, 'Type should be Lab');
        }
    }
    
    @isTest
    static void testGetAllLocations() {
        createTestCompanies();
        createTestLabs();
        
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllLocations();
        Test.stopTest();
        
        System.assertEquals(4, results.size(), 'Should return 4 total locations');
        
        Integer companyCount = 0;
        Integer labCount = 0;
        
        for (CompanyMapController.CompanyWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.Latitude, 'Latitude should not be null');
            System.assertNotEquals(null, wrapper.Longitude, 'Longitude should not be null');
            
            if (wrapper.Type == 'Company') {
                companyCount++;
            } else if (wrapper.Type == 'Lab') {
                labCount++;
            }
        }
        
        System.assertEquals(2, companyCount, 'Should have 2 companies');
        System.assertEquals(2, labCount, 'Should have 2 labs');
    }
    
    @isTest
    static void testGetAllCompanyLocations_NoData() {
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllCompanyLocations();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no companies exist');
    }
    
    @isTest
    static void testGetAllLabLocations_NoData() {
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllLabLocations();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no labs exist');
    }
    
    @isTest
    static void testGetAllLocations_NoData() {
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllLocations();
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no data exists');
    }
    
    @isTest
    static void testCompanyWrapper_Properties() {
        CompanyMapController.CompanyWrapper wrapper = new CompanyMapController.CompanyWrapper();
        
        wrapper.Id = Id.valueOf('001000000000001AAA');
        wrapper.Name = 'Test Name';
        wrapper.Latitude = 123.456;
        wrapper.Longitude = -78.901;
        wrapper.Type = 'Test Type';
        
        System.assertEquals('001000000000001AAA', String.valueOf(wrapper.Id), 'Id property should work');
        System.assertEquals('Test Name', wrapper.Name, 'Name property should work');
        System.assertEquals(123.456, wrapper.Latitude, 'Latitude property should work');
        System.assertEquals(-78.901, wrapper.Longitude, 'Longitude property should work');
        System.assertEquals('Test Type', wrapper.Type, 'Type property should work');
    }
    
    @isTest
    static void testGetAllLocations_FilteringNullValues() {
        createTestCompanies();
        createTestLabs();
        createCompaniesWithNullValues();
        createLabsWithNullValues();
        
        Test.startTest();
        List<CompanyMapController.CompanyWrapper> results = CompanyMapController.getAllLocations();
        Test.stopTest();
        
        System.assertEquals(4, results.size(), 'Should return only records with valid coordinates');
        
        for (CompanyMapController.CompanyWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.Latitude, 'All results should have valid latitude');
            System.assertNotEquals(null, wrapper.Longitude, 'All results should have valid longitude');
        }
    }
}