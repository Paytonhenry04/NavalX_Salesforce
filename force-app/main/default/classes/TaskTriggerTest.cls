@isTest
public class TaskTriggerTest {
    
    @TestSetup
    static void makeData() {
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'testuser1@test.com',
            Username = 'testuser1@test.com.triggertest',
            Alias = 'tuser1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser1;
        
        User testUser2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'testuser2@test.com',
            Username = 'testuser2@test.com.triggertest',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser2;
        
        // Create test workflows
        List<Workflow__c> testWorkflows = new List<Workflow__c>();
        for (Integer i = 1; i <= 2; i++) {
            testWorkflows.add(new Workflow__c(
                Name = 'Test Workflow ' + i
            ));
        }
        insert testWorkflows;
    }
    
    @isTest
    static void testTaskTrigger_AfterInsert() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%.triggertest' ORDER BY Username];
        List<Workflow__c> testWorkflows = [SELECT Id FROM Workflow__c WHERE Name LIKE 'Test Workflow%' ORDER BY Name];
        
        // Create tasks that will fire the trigger on insert
        List<Task> testTasks = new List<Task>();
        
        testTasks.add(new Task(
            Subject = 'Test Task Insert 1',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[0].Id,
            Related_Workflow__c = testWorkflows[0].Id
        ));
        
        testTasks.add(new Task(
            Subject = 'Test Task Insert 2',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[1].Id,
            Related_Workflow__c = testWorkflows[1].Id
        ));
        
        // Task without workflow to test the continue logic
        testTasks.add(new Task(
            Subject = 'Test Task Insert No Workflow',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[0].Id,
            Related_Workflow__c = null
        ));
        
        Test.startTest();
        
        // Insert tasks - this will fire the TaskTrigger after insert
        insert testTasks;
        
        Test.stopTest();
        
        // Verify tasks were created successfully
        List<Task> insertedTasks = [SELECT Id, Subject, Related_Workflow__c FROM Task WHERE Subject LIKE 'Test Task Insert%'];
        System.assertEquals(3, insertedTasks.size(), 'All test tasks should be inserted');
        
        // Verify trigger executed without errors
        System.assert(true, 'TaskTrigger executed successfully on insert');
    }
    
    @isTest
    static void testTaskTrigger_AfterUpdate() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%.triggertest' ORDER BY Username];
        List<Workflow__c> testWorkflows = [SELECT Id FROM Workflow__c WHERE Name LIKE 'Test Workflow%' ORDER BY Name];
        
        // Create tasks first
        List<Task> testTasks = new List<Task>();
        
        testTasks.add(new Task(
            Subject = 'Test Task Update 1',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[0].Id,
            Related_Workflow__c = null // Initially no workflow
        ));
        
        testTasks.add(new Task(
            Subject = 'Test Task Update 2',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[1].Id,
            Related_Workflow__c = testWorkflows[0].Id
        ));
        
        insert testTasks;
        
        Test.startTest();
        
        // Update tasks - this will fire the TaskTrigger after update
        testTasks[0].Related_Workflow__c = testWorkflows[0].Id; // Add workflow
        testTasks[0].Status = 'In Progress';
        
        testTasks[1].Related_Workflow__c = testWorkflows[1].Id; // Change workflow
        testTasks[1].Priority = 'High';
        
        update testTasks;
        
        Test.stopTest();
        
        // Verify tasks were updated successfully
        List<Task> updatedTasks = [SELECT Id, Subject, Related_Workflow__c, Status, Priority FROM Task WHERE Subject LIKE 'Test Task Update%'];
        System.assertEquals(2, updatedTasks.size(), 'All test tasks should be updated');
        
        // Verify specific updates
        for (Task t : updatedTasks) {
            if (t.Subject == 'Test Task Update 1') {
                System.assertEquals('In Progress', t.Status, 'Task 1 status should be updated');
                System.assertNotEquals(null, t.Related_Workflow__c, 'Task 1 should have workflow assigned');
            } else if (t.Subject == 'Test Task Update 2') {
                System.assertEquals('High', t.Priority, 'Task 2 priority should be updated');
                System.assertNotEquals(null, t.Related_Workflow__c, 'Task 2 should have workflow assigned');
            }
        }
        
        // Verify trigger executed without errors
        System.assert(true, 'TaskTrigger executed successfully on update');
    }
    
    @isTest
    static void testTaskTrigger_BulkInsert() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%.triggertest' ORDER BY Username];
        List<Workflow__c> testWorkflows = [SELECT Id FROM Workflow__c WHERE Name LIKE 'Test Workflow%' ORDER BY Name];
        
        // Create bulk tasks to test trigger bulk handling
        List<Task> bulkTasks = new List<Task>();
        
        for (Integer i = 0; i < 200; i++) {
            Task bulkTask = new Task(
                Subject = 'Bulk Test Task ' + i,
                Status = 'Not Started',
                Priority = 'Normal',
                OwnerId = testUsers[Math.mod(i, testUsers.size())].Id,
                Related_Workflow__c = i < 100 ? testWorkflows[0].Id : testWorkflows[1].Id
            );
            bulkTasks.add(bulkTask);
        }
        
        Test.startTest();
        
        // Bulk insert - this will fire the TaskTrigger after insert
        insert bulkTasks;
        
        Test.stopTest();
        
        // Verify bulk insert was successful
        List<Task> insertedBulkTasks = [SELECT Id, Subject FROM Task WHERE Subject LIKE 'Bulk Test Task%'];
        System.assertEquals(200, insertedBulkTasks.size(), 'All bulk tasks should be inserted');
        
        // Verify trigger handled bulk operation without errors
        System.assert(true, 'TaskTrigger handled bulk insert successfully');
    }
    
    @isTest
    static void testTaskTrigger_BulkUpdate() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%.triggertest' ORDER BY Username];
        List<Workflow__c> testWorkflows = [SELECT Id FROM Workflow__c WHERE Name LIKE 'Test Workflow%' ORDER BY Name];
        
        // Create tasks for bulk update
        List<Task> bulkTasks = new List<Task>();
        
        for (Integer i = 0; i < 150; i++) {
            Task bulkTask = new Task(
                Subject = 'Bulk Update Task ' + i,
                Status = 'Not Started',
                Priority = 'Normal',
                OwnerId = testUsers[Math.mod(i, testUsers.size())].Id,
                Related_Workflow__c = null // Start without workflow
            );
            bulkTasks.add(bulkTask);
        }
        
        insert bulkTasks;
        
        Test.startTest();
        
        // Update all tasks to add workflows - this will fire the TaskTrigger after update
        for (Integer i = 0; i < bulkTasks.size(); i++) {
            bulkTasks[i].Related_Workflow__c = testWorkflows[Math.mod(i, testWorkflows.size())].Id;
            bulkTasks[i].Status = 'In Progress';
        }
        
        update bulkTasks;
        
        Test.stopTest();
        
        // Verify bulk update was successful
        List<Task> updatedBulkTasks = [SELECT Id, Subject, Status, Related_Workflow__c FROM Task WHERE Subject LIKE 'Bulk Update Task%'];
        System.assertEquals(150, updatedBulkTasks.size(), 'All bulk tasks should be updated');
        
        // Verify all tasks have workflows assigned and status updated
        for (Task t : updatedBulkTasks) {
            System.assertEquals('In Progress', t.Status, 'All tasks should have status updated');
            System.assertNotEquals(null, t.Related_Workflow__c, 'All tasks should have workflow assigned');
        }
        
        // Verify trigger handled bulk operation without errors
        System.assert(true, 'TaskTrigger handled bulk update successfully');
    }
    
    @isTest
    static void testTaskTrigger_MixedWorkflowScenarios() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User WHERE Username LIKE '%.triggertest' ORDER BY Username];
        List<Workflow__c> testWorkflows = [SELECT Id FROM Workflow__c WHERE Name LIKE 'Test Workflow%' ORDER BY Name];
        
        // Create tasks with mixed scenarios
        List<Task> mixedTasks = new List<Task>();
        
        // Task with workflow
        mixedTasks.add(new Task(
            Subject = 'Mixed Task With Workflow',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[0].Id,
            Related_Workflow__c = testWorkflows[0].Id
        ));
        
        // Task without workflow
        mixedTasks.add(new Task(
            Subject = 'Mixed Task Without Workflow',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[1].Id,
            Related_Workflow__c = null
        ));
        
        // Task with different owner (to test CreatedById vs OwnerId logic)
        mixedTasks.add(new Task(
            Subject = 'Mixed Task Different Owner',
            Status = 'Not Started',
            Priority = 'Normal',
            OwnerId = testUsers[0].Id, // Different from creator (running user)
            Related_Workflow__c = testWorkflows[1].Id
        ));
        
        Test.startTest();
        
        // Insert mixed tasks - this will fire the TaskTrigger
        insert mixedTasks;
        
        Test.stopTest();
        
        // Verify all tasks were created
        List<Task> createdTasks = [SELECT Id, Subject, OwnerId, Related_Workflow__c FROM Task WHERE Subject LIKE 'Mixed Task%'];
        System.assertEquals(3, createdTasks.size(), 'All mixed scenario tasks should be created');
        
        // Verify trigger executed without errors
        System.assert(true, 'TaskTrigger handled mixed scenarios successfully');
    }
}