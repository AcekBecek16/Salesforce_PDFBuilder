public without sharing class pdfBuilderController {
  @AuraEnabled
  public static List<FieldDefinition> getFieldList(String SObjectName) {
    try {
      return [
        SELECT QualifiedApiName, Label, EntityDefinition.QualifiedApiName
        FROM FieldDefinition
        WHERE EntityDefinition.QualifiedApiName = :SObjectName
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<SObject> searchRecords(
    String objectApiName,
    String searchField,
    String searchTerm,
    Integer limitSize
  ) {
    if (
      String.isBlank(objectApiName) ||
      String.isBlank(searchField) ||
      String.isBlank(searchTerm)
    ) {
      return new List<SObject>();
    }

    // Escape single quotes
    String safeSearchTerm = String.escapeSingleQuotes('%' + searchTerm + '%');

    String query =
      'SELECT Id, ' +
      searchField +
      ' FROM ' +
      objectApiName +
      ' WHERE ' +
      searchField +
      ' LIKE :safeSearchTerm LIMIT :limitSize';
    return Database.query(query);
  }
}