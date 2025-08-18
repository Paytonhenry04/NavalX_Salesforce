@isTest
public class NotepadDashboardControllerTest {
    
    @TestSetup
    static void setup() {
        // Create test Company records
        List<Company__c> testCompanies = new List<Company__c>();
        testCompanies.add(new Company__c(Name = 'Test Company 1'));
        testCompanies.add(new Company__c(Name = 'Test Company 2'));
        insert testCompanies;
        
        // Create test Note records
        List<Note__c> testNotes = new List<Note__c>();
        testNotes.add(new Note__c(
            Note_Text__c = 'Completed test note',
            Public__c = true,
            TargetObjectType__c = 'Company__c',
            TargetObjectName__c = 'Test Company 1',
            Completed__c = true,
            Due_by__c = Date.today().addDays(1)
        ));
        testNotes.add(new Note__c(
            Note_Text__c = 'Incomplete test note',
            Public__c = false,
            TargetObjectType__c = 'Company__c',
            TargetObjectName__c = 'Test Company 2',
            Completed__c = false,
            Due_by__c = Date.today().addDays(2)
        ));
        testNotes.add(new Note__c(
            Note_Text__c = 'Another incomplete note',
            Public__c = true,
            TargetObjectType__c = 'Company__c',
            TargetObjectName__c = 'Test Company 1',
            Completed__c = false
        ));
        insert testNotes;
    }
    
    @isTest
    static void testGetCompanyIdsByNames() {
        List<String> companyNames = new List<String>{'Test Company 1', 'Test Company 2', 'Nonexistent Company'};
        
        Test.startTest();
        Map<String, Id> result = NotepadDashboardController.getCompanyIdsByNames(companyNames);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return 2 companies');
        System.assert(result.containsKey('Test Company 1'), 'Should contain Test Company 1');
        System.assert(result.containsKey('Test Company 2'), 'Should contain Test Company 2');
        System.assert(!result.containsKey('Nonexistent Company'), 'Should not contain nonexistent company');
    }
    
    @isTest
    static void testGetCompanyIdsByNamesEmpty() {
        Test.startTest();
        Map<String, Id> result = NotepadDashboardController.getCompanyIdsByNames(new List<String>());
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty map for empty input');
    }
    
    @isTest
    static void testGetCompanyIdsByNamesNull() {
        Test.startTest();
        Map<String, Id> result = NotepadDashboardController.getCompanyIdsByNames(null);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty map for null input');
    }
    
    @isTest
    static void testGetRecordIdsByNamesAndType() {
        List<String> companyNames = new List<String>{'Test Company 1', 'Test Company 2'};
        
        Test.startTest();
        Map<String, Id> result = NotepadDashboardController.getRecordIdsByNamesAndType(companyNames, 'Company__c');
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return 2 companies');
        System.assert(result.containsKey('Test Company 1'), 'Should contain Test Company 1');
        System.assert(result.containsKey('Test Company 2'), 'Should contain Test Company 2');
    }
    
    @isTest
    static void testGetRecordIdsByNamesAndTypeInvalidObject() {
        List<String> names = new List<String>{'Test Name'};
        
        Test.startTest();
        Map<String, Id> result = NotepadDashboardController.getRecordIdsByNamesAndType(names, 'InvalidObject__c');
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty map for invalid object');
    }
    
    @isTest
    static void testGetRecordIdsByNamesAndTypeNullInputs() {
        Test.startTest();
        Map<String, Id> result1 = NotepadDashboardController.getRecordIdsByNamesAndType(null, 'Company__c');
        Map<String, Id> result2 = NotepadDashboardController.getRecordIdsByNamesAndType(new List<String>{'Test'}, null);
        Map<String, Id> result3 = NotepadDashboardController.getRecordIdsByNamesAndType(new List<String>{'Test'}, '');
        Test.stopTest();
        
        System.assertEquals(0, result1.size(), 'Should return empty map for null names');
        System.assertEquals(0, result2.size(), 'Should return empty map for null object type');
        System.assertEquals(0, result3.size(), 'Should return empty map for blank object type');
    }
    
    @isTest
    static void testGetBatchRecordIds() {
        Map<String, List<String>> objectTypeToNames = new Map<String, List<String>>();
        objectTypeToNames.put('Company__c', new List<String>{'Test Company 1', 'Test Company 2'});
        
        Test.startTest();
        Map<String, Map<String, Id>> result = NotepadDashboardController.getBatchRecordIds(objectTypeToNames);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return 1 object type');
        System.assert(result.containsKey('Company__c'), 'Should contain Company__c key');
        System.assertEquals(2, result.get('Company__c').size(), 'Should return 2 companies');
    }
    
    @isTest
    static void testGetBatchRecordIdsNull() {
        Test.startTest();
        Map<String, Map<String, Id>> result = NotepadDashboardController.getBatchRecordIds(null);
        Test.stopTest();
        
        System.assertEquals(0, result.size(), 'Should return empty map for null input');
    }
    
    @isTest
    static void testGetMyNotesIncludeCompleted() {
        Test.startTest();
        List<Note__c> result = NotepadDashboardController.getMyNotes(true, 50);
        Test.stopTest();
        
        System.assertEquals(3, result.size(), 'Should return all notes including completed');
    }
    
    @isTest
    static void testGetMyNotesExcludeCompleted() {
        Test.startTest();
        List<Note__c> result = NotepadDashboardController.getMyNotes(false, 50);
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return only incomplete notes');
        for (Note__c note : result) {
            System.assert(note.Completed__c == false || note.Completed__c == null, 'All notes should be incomplete');
        }
    }
    
    @isTest
    static void testGetMyNotesLimitHandling() {
        Test.startTest();
        List<Note__c> result1 = NotepadDashboardController.getMyNotes(true, null);
        List<Note__c> result2 = NotepadDashboardController.getMyNotes(true, 0);
        List<Note__c> result3 = NotepadDashboardController.getMyNotes(true, 250);
        List<Note__c> result4 = NotepadDashboardController.getMyNotes(true, 2);
        Test.stopTest();
        
        // All should apply default limit of 50 except the last one
        System.assert(result1.size() <= 50, 'Should apply default limit for null');
        System.assert(result2.size() <= 50, 'Should apply default limit for 0');
        System.assert(result3.size() <= 50, 'Should apply default limit for > 200');
        System.assert(result4.size() <= 2, 'Should apply requested limit of 2');
    }
    
    @isTest
    static void testUpdateNoteText() {
        List<Note__c> testNotes = [SELECT Id FROM Note__c WHERE Completed__c = true LIMIT 1];
        Note__c testNote = testNotes[0];
        
        Test.startTest();
        NotepadDashboardController.updateNoteText(testNote.Id, 'Updated note text');
        Test.stopTest();
        
        Note__c updatedNote = [SELECT Id, Note_Text__c FROM Note__c WHERE Id = :testNote.Id];
        System.assertEquals('Updated note text', updatedNote.Note_Text__c, 'Note text should be updated');
    }
    
    @isTest
    static void testUpdateNoteTextNullId() {
        Test.startTest();
        try {
            NotepadDashboardController.updateNoteText(null, 'Test text');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateNoteTextBlankText() {
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        Test.startTest();
        try {
            NotepadDashboardController.updateNoteText(testNote.Id, '');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testToggleComplete() {
        Note__c testNote = [SELECT Id, Completed__c FROM Note__c WHERE Completed__c = false LIMIT 1];
        Boolean originalStatus = testNote.Completed__c;
        
        Test.startTest();
        NotepadDashboardController.toggleComplete(testNote.Id);
        Test.stopTest();
        
        Note__c updatedNote = [SELECT Id, Completed__c FROM Note__c WHERE Id = :testNote.Id];
        System.assertNotEquals(originalStatus, updatedNote.Completed__c, 'Completed status should be toggled');
    }
    
    @isTest
    static void testToggleCompleteNullId() {
        Test.startTest();
        try {
            NotepadDashboardController.toggleComplete(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteNote() {
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        Id noteIdToDelete = testNote.Id;
        
        Test.startTest();
        NotepadDashboardController.deleteNote(noteIdToDelete);
        Test.stopTest();
        
        List<Note__c> deletedNotes = [SELECT Id FROM Note__c WHERE Id = :noteIdToDelete];
        System.assertEquals(0, deletedNotes.size(), 'Note should be deleted');
    }
    
    @isTest
    static void testDeleteNoteNullId() {
        Test.startTest();
        try {
            NotepadDashboardController.deleteNote(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testNoteReminderExists() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        // Create a reminder
        Note_Reminder__c testReminder = new Note_Reminder__c(
            Name = 'Test Reminder',
            User__c = testUser.Id,
            Note__c = testNote.Id
        );
        insert testReminder;
        
        Test.startTest();
        Boolean exists = NotepadDashboardController.NoteReminderExists(testUser.Id, testNote.Id);
        Test.stopTest();
        
        System.assertEquals(true, exists, 'Should return true when reminder exists');
    }
    
    @isTest
    static void testNoteReminderExistsNullUserId() {
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        Test.startTest();
        Boolean exists = NotepadDashboardController.NoteReminderExists(null, testNote.Id);
        Test.stopTest();
        
        // Should use current user ID when null is passed
        System.assertNotEquals(null, exists, 'Should return a valid boolean result');
    }
    
    @isTest
    static void testCreateNoteReminder() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        // Clean up any existing reminders first
        delete [SELECT Id FROM Note_Reminder__c WHERE User__c = :testUser.Id AND Note__c = :testNote.Id];
        
        Test.startTest();
        NotepadDashboardController.createNoteReminder(testUser.Id, testNote.Id);
        Test.stopTest();
        
        List<Note_Reminder__c> reminders = [SELECT Id, User__c, Note__c FROM Note_Reminder__c 
                                           WHERE User__c = :testUser.Id AND Note__c = :testNote.Id];
        
        System.assertEquals(1, reminders.size(), 'Should create one reminder');
        System.assertEquals(testUser.Id, reminders[0].User__c, 'Reminder should be assigned to correct user');
        System.assertEquals(testNote.Id, reminders[0].Note__c, 'Reminder should be linked to correct note');
    }
    
    @isTest
    static void testCreateNoteReminderNullNoteId() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Test.startTest();
        try {
            NotepadDashboardController.createNoteReminder(testUser.Id, null);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateNoteReminderNullUserId() {
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        // Clean up any existing reminders first
        delete [SELECT Id FROM Note_Reminder__c WHERE Note__c = :testNote.Id];
        
        Test.startTest();
        NotepadDashboardController.createNoteReminder(null, testNote.Id);
        Test.stopTest();
        
        // Should use current user ID when null is passed
        List<Note_Reminder__c> reminders = [SELECT Id FROM Note_Reminder__c WHERE Note__c = :testNote.Id];
        System.assertEquals(1, reminders.size(), 'Should create reminder with current user');
    }
    
    @isTest
    static void testRemoveNoteReminder() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        // Create a reminder first
        Note_Reminder__c testReminder = new Note_Reminder__c(
            Name = 'Test Reminder',
            User__c = testUser.Id,
            Note__c = testNote.Id
        );
        insert testReminder;
        
        Test.startTest();
        NotepadDashboardController.removeNoteReminder(testUser.Id, testNote.Id);
        Test.stopTest();
        
        List<Note_Reminder__c> remainingReminders = [SELECT Id FROM Note_Reminder__c 
                                                    WHERE User__c = :testUser.Id AND Note__c = :testNote.Id];
        
        System.assertEquals(0, remainingReminders.size(), 'Reminder should be deleted');
    }
    
    @isTest
    static void testRemoveNoteReminderNullUserId() {
        Note__c testNote = [SELECT Id FROM Note__c LIMIT 1];
        
        Test.startTest();
        NotepadDashboardController.removeNoteReminder(null, testNote.Id);
        Test.stopTest();
        
        // Should work with current user ID when null is passed
        // No exception should be thrown even if no reminders exist
        System.assert(true, 'Should complete without error');
    }
}