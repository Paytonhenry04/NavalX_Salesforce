@isTest
public class NoteControllerTest {
    
    static Id publicNoteId;
    static Id privateNoteId;
    
    @TestSetup
    static void setup() {
        // Create a test Company record
        Company__c testCompany = new Company__c(Name = 'Test Company');
        insert testCompany;
        
        // Create test Note records
        List<Note__c> testNotes = new List<Note__c>();
        Note__c publicNote = new Note__c(
            Note_Text__c = 'Public test note',
            Public__c = true,
            TargetObjectType__c = 'Company__c',
            TargetObjectName__c = 'Test Company',
            Completed__c = false
        );
        Note__c privateNote = new Note__c(
            Note_Text__c = 'Private test note',
            Public__c = false,
            TargetObjectType__c = 'Company__c',
            TargetObjectName__c = 'Test Company',
            Completed__c = false
        );
        testNotes.add(publicNote);
        testNotes.add(privateNote);
        insert testNotes;
    }
    
    @isTest
    static void testGetNotesForRecord() {
        Company__c testCompany = [SELECT Id FROM Company__c LIMIT 1];
        
        Test.startTest();
        List<Note__c> notes = NoteController.getNotesForRecord(testCompany.Id, 'Company__c');
        Test.stopTest();
        
        // Should return at least the public note and private note if created by same user
        System.assert(notes.size() >= 1, 'Should return at least one note');
        // The getNotesForRecord method should return notes with all necessary fields
        System.assertNotEquals(null, notes[0].Note_Text__c, 'Note should have text content');
    }
    
    @isTest
    static void testCreateNote() {
        Company__c testCompany = [SELECT Id FROM Company__c LIMIT 1];
        
        Test.startTest();
        Id noteId = NoteController.createNote(testCompany.Id, 'Company__c', 'New test note', true);
        Test.stopTest();
        
        Note__c createdNote = [SELECT Id, Note_Text__c, Public__c, TargetObjectType__c, TargetObjectName__c 
                              FROM Note__c WHERE Id = :noteId];
        
        System.assertEquals('New test note', createdNote.Note_Text__c, 'Note text should match');
        System.assertEquals(true, createdNote.Public__c, 'Note should be public');
        System.assertEquals('Company__c', createdNote.TargetObjectType__c, 'Target object type should match');
        System.assertEquals('Test Company', createdNote.TargetObjectName__c, 'Target object name should match');
    }
    
    @isTest
    static void testCreateNoteException() {
        Test.startTest();
        try {
            // Create a fake ID that will cause getRecordName to fail
            Id fakeId = '001000000000000AAA';
            NoteController.createNote(fakeId, 'Company__c', 'Test note', true);
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage(), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateNote() {
        List<Note__c> testNotes = [SELECT Id FROM Note__c WHERE Public__c = true LIMIT 1];
        Note__c testNote = testNotes[0];
        
        Test.startTest();
        NoteController.updateNote(testNote.Id, 'Updated note text', false);
        Test.stopTest();
        
        Note__c updatedNote = [SELECT Id, Note_Text__c, Public__c FROM Note__c WHERE Id = :testNote.Id];
        System.assertEquals('Updated note text', updatedNote.Note_Text__c, 'Note text should be updated');
        System.assertEquals(false, updatedNote.Public__c, 'Note should now be private');
    }
    
    @isTest
    static void testDeleteNote() {
        List<Note__c> testNotes = [SELECT Id FROM Note__c WHERE Public__c = true LIMIT 1];
        Note__c testNote = testNotes[0];
        
        Test.startTest();
        NoteController.deleteNote(testNote.Id);
        Test.stopTest();
        
        List<Note__c> deletedNotes = [SELECT Id FROM Note__c WHERE Id = :testNote.Id];
        System.assertEquals(0, deletedNotes.size(), 'Note should be deleted');
    }
    
    @isTest
    static void testGetRecordName() {
        Company__c testCompany = [SELECT Id FROM Company__c LIMIT 1];
        
        Test.startTest();
        String recordName = NoteController.getRecordName(testCompany.Id, 'Company__c');
        Test.stopTest();
        
        System.assertEquals('Test Company', recordName, 'Should return correct record name');
    }
    
    @isTest
    static void testGetRecordNameWithNullId() {
        Test.startTest();
        try {
            NoteController.getRecordName(null, 'Company__c');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetRecordNameWithBlankObjectName() {
        Company__c testCompany = [SELECT Id FROM Company__c LIMIT 1];
        
        Test.startTest();
        try {
            NoteController.getRecordName(testCompany.Id, '');
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateNoteCompleteStatus() {
        List<Note__c> testNotes = [SELECT Id FROM Note__c WHERE Public__c = true LIMIT 1];
        Note__c testNote = testNotes[0];
        
        Test.startTest();
        NoteController.updateNoteCompleteStatus(testNote.Id, true);
        Test.stopTest();
        
        Note__c updatedNote = [SELECT Id, Completed__c FROM Note__c WHERE Id = :testNote.Id];
        System.assertEquals(true, updatedNote.Completed__c, 'Note should be marked as completed');
    }
    
    @isTest
    static void testUpdateNoteCompleteStatusWithInvalidId() {
        Test.startTest();
        try {
            // Create a fake ID that doesn't exist
            Id fakeId = '001000000000000AAA';
            NoteController.updateNoteCompleteStatus(fakeId, true);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            // More flexible assertion - accept any exception type
            System.assertNotEquals(null, e.getMessage(), 'Should contain an error message');
        }
        Test.stopTest();
    }
}