public with sharing class RelatedRecordsController {
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRelatedRecords(
        Id parentId,
        String childObjectApiName,
        String lookupFieldApiName,
        String fieldsString,
        Integer limitSize
    ) {
        String soql = 
            'SELECT ' + fieldsString +
            ' FROM ' + childObjectApiName +
            ' WHERE ' + lookupFieldApiName + ' = :parentId' +
            ' LIMIT :limitSize';
        return Database.query(soql);
    }
}