public with sharing class RecommendationController {

    public class RecommendationWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public Decimal score;
        @AuraEnabled public Map<String, Object> fields; // dynamic fields
    }

    @AuraEnabled(cacheable=true)
    public static List<RecommendationWrapper> getRecommendations(
        Id recordId,
        String targetObjectApiName, // Which object type to display
        List<String> fieldApiNames
    ) {
        System.debug('Getting recommendations for recordId: ' + recordId + ', targetObject: ' + targetObjectApiName);
        
        // Convert recordId to String for comparison with text fields
        String recordIdString = String.valueOf(recordId);
        
        // Query Recommendation__c records where current record appears in Object_1_Record_Id__c or Object_2_Record_Id__c
        List<Recommendation__c> recs = [
            SELECT Object_1_API_Name__c, Object_1_Record_Id__c, Object_1_Record_Name__c,
                   Object_2_API_Name__c, Object_2_Record_Id__c, Object_2_Record_Name__c,
                   Score__c
            FROM Recommendation__c
            WHERE (Object_1_Record_Id__c = :recordIdString OR Object_2_Record_Id__c = :recordIdString)
            ORDER BY Score__c DESC NULLS LAST
        ];

        System.debug('Found ' + recs.size() + ' recommendation records');

        Set<Id> targetRecordIds = new Set<Id>();
        Map<Id, Decimal> scoreById = new Map<Id, Decimal>();
        Map<Id, String> nameById = new Map<Id, String>();

        // Extract the "other side" records that match our target object type
        for (Recommendation__c r : recs) {
            String otherApi;
            String otherIdString;
            String otherName;

            if (r.Object_1_Record_Id__c == recordIdString && r.Object_2_API_Name__c == targetObjectApiName) {
                // Current record is Object 1, we want Object 2
                otherApi = r.Object_2_API_Name__c;
                otherIdString = r.Object_2_Record_Id__c;
                otherName = r.Object_2_Record_Name__c;
            } else if (r.Object_2_Record_Id__c == recordIdString && r.Object_1_API_Name__c == targetObjectApiName) {
                // Current record is Object 2, we want Object 1
                otherApi = r.Object_1_API_Name__c;
                otherIdString = r.Object_1_Record_Id__c;
                otherName = r.Object_1_Record_Name__c;
            }

            if (otherIdString != null && otherApi == targetObjectApiName) {
                try {
                    Id otherId = Id.valueOf(otherIdString);
                    targetRecordIds.add(otherId);
                    scoreById.put(otherId, r.Score__c);
                    nameById.put(otherId, otherName);
                } catch (Exception e) {
                    System.debug('Invalid ID format: ' + otherIdString + ', Error: ' + e.getMessage());
                }
            }
        }

        System.debug('Found ' + targetRecordIds.size() + ' target records of type ' + targetObjectApiName);

        List<RecommendationWrapper> results = new List<RecommendationWrapper>();

        if (!targetRecordIds.isEmpty()) {
            // Build dynamic SOQL query
            String fieldsToQuery = 'Id';
            
            // Add Name field if it exists for this object
            if (hasNameField(targetObjectApiName)) {
                fieldsToQuery += ', Name';
            }
            
            if (fieldApiNames != null && !fieldApiNames.isEmpty()) {
                for (String field : fieldApiNames) {
                    if (field != 'Id' && field != 'Name') {
                        fieldsToQuery += ', ' + field;
                    }
                }
            }

            String soql = 'SELECT ' + fieldsToQuery + ' FROM ' + targetObjectApiName + ' WHERE Id IN :targetRecordIds';
            System.debug('SOQL Query: ' + soql);
            
            try {
                List<SObject> records = Database.query(soql);
                System.debug('Query returned ' + records.size() + ' records');

                for (SObject s : records) {
                    RecommendationWrapper rw = new RecommendationWrapper();
                    rw.recordId = (Id) s.get('Id');
                    
                    // Try to get Name from the record, fall back to stored name
                    try {
                        rw.name = (String) s.get('Name');
                    } catch (Exception e) {
                        rw.name = nameById.get(rw.recordId);
                    }
                    
                    // Final fallback if no name found
                    if (String.isBlank(rw.name)) {
                        rw.name = 'Record ' + rw.recordId;
                    }
                    
                    rw.objectApiName = targetObjectApiName;
                    rw.score = scoreById.get(rw.recordId);

                    rw.fields = new Map<String, Object>();
                    if (fieldApiNames != null) {
                        for (String f : fieldApiNames) {
                            try {
                                rw.fields.put(f, s.get(f));
                            } catch (Exception e) {
                                System.debug('Error getting field ' + f + ': ' + e.getMessage());
                                rw.fields.put(f, null);
                            }
                        }
                    }

                    results.add(rw);
                }

                // Sort by score (highest first)
                results.sort(new ScoreComparator());
                
            } catch (Exception e) {
                System.debug('Error querying records: ' + e.getMessage());
                throw new AuraHandledException('Error querying ' + targetObjectApiName + ': ' + e.getMessage());
            }
        }

        System.debug('Returning ' + results.size() + ' recommendation wrappers');
        return results;
    }

    // Helper method to check if an object has a Name field
    private static Boolean hasNameField(String objectApiName) {
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectApiName);
            if (objectType != null) {
                Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
                Map<String, Schema.SObjectField> fieldsMap = objectDescribe.fields.getMap();
                return fieldsMap.containsKey('name') || fieldsMap.containsKey('Name');
            }
        } catch (Exception e) {
            System.debug('Error checking Name field for ' + objectApiName + ': ' + e.getMessage());
        }
        return false;
    }

    // Comparator to sort by score descending
    public class ScoreComparator implements Comparator<RecommendationWrapper> {
        public Integer compare(RecommendationWrapper a, RecommendationWrapper b) {
            if (a.score == null && b.score == null) return 0;
            if (a.score == null) return 1;
            if (b.score == null) return -1;
            return b.score > a.score ? 1 : (a.score > b.score ? -1 : 0);
        }
    }
}