public without sharing class pdfBuilderController {
  // Cache for field definitions to improve performance
  private static Map<String, List<FieldDefinition>> fieldCache = new Map<String, List<FieldDefinition>>();

  /**
   * Retrieves field definitions for a given SObject
   * @param sObjectName API name of the SObject
   * @return List of FieldDefinition records
   */
  @AuraEnabled
  public static List<FieldDefinition> getFieldList(String sObjectName) {
    // Validate input
    if (String.isBlank(sObjectName)) {
      throw new AuraHandledException('Object name is required');
    }

    try {
      // Check cache first
      if (fieldCache.containsKey(sObjectName)) {
        return fieldCache.get(sObjectName);
      }

      // Validate that the object exists and is accessible
      if (!isValidSObjectType(sObjectName)) {
        throw new AuraHandledException(
          'Invalid or inaccessible object: ' + sObjectName
        );
      }

      List<FieldDefinition> fields = [
        SELECT
          QualifiedApiName,
          Label,
          DataType,
          EntityDefinition.QualifiedApiName,
          ValueType.DeveloperName
        FROM FieldDefinition
        WHERE EntityDefinition.QualifiedApiName = :sObjectName
        ORDER BY Label ASC
      ];

      // Cache the results
      fieldCache.put(sObjectName, fields);

      return fields;
    } catch (QueryException qe) {
      throw new AuraHandledException(
        'Failed to retrieve field definitions: ' + qe.getMessage()
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'An unexpected error occurred: ' + e.getMessage()
      );
    }
  }

  /**
   * Searches records based on search term
   * @param objectApiName API name of the SObject to search
   * @param searchField Field to search within
   * @param searchTerm Text to search for
   * @param limitSize Maximum number of results to return
   * @return List of matching SObjects
   */
  @AuraEnabled(cacheable=true)
  public static List<SObject> searchRecords(
    String objectApiName,
    String searchField,
    String searchTerm,
    Integer limitSize
  ) {
    // Input validation
    if (String.isBlank(objectApiName)) {
      throw new AuraHandledException('Object API name is required');
    }

    if (String.isBlank(searchField)) {
      throw new AuraHandledException('Search field is required');
    }

    if (String.isBlank(searchTerm)) {
      return new List<SObject>(); // Return empty list for blank search
    }

    // Set default limit if not provided or invalid
    Integer effectiveLimit = getEffectiveLimit(limitSize);

    try {
      // Validate inputs
      validateSearchInputs(objectApiName, searchField, searchTerm);

      // Build safe SOQL query
      String query = buildSearchQuery(
        objectApiName,
        searchField,
        searchTerm,
        effectiveLimit
      );

      return Database.query(query);
    } catch (QueryException qe) {
      throw new AuraHandledException('Search failed: ' + qe.getMessage());
    } catch (Exception e) {
      throw new AuraHandledException(
        'An unexpected error occurred during search: ' + e.getMessage()
      );
    }
  }

  /**
   * Enhanced search with multiple fields support
   * @param objectApiName API name of the SObject to search
   * @param searchFields List of fields to search within
   * @param searchTerm Text to search for
   * @param limitSize Maximum number of results to return
   * @return List of matching SObjects
   */
  @AuraEnabled
  public static List<SObject> searchRecordsMultiField(
    String objectApiName,
    List<String> searchFields,
    String searchTerm,
    Integer limitSize
  ) {
    // Input validation
    if (String.isBlank(objectApiName)) {
      throw new AuraHandledException('Object API name is required');
    }

    if (searchFields == null || searchFields.isEmpty()) {
      throw new AuraHandledException('At least one search field is required');
    }

    if (String.isBlank(searchTerm)) {
      return new List<SObject>();
    }

    Integer effectiveLimit = getEffectiveLimit(limitSize);

    try {
      validateSearchInputs(objectApiName, searchFields[0], searchTerm);

      String query = buildMultiFieldSearchQuery(
        objectApiName,
        searchFields,
        searchTerm,
        effectiveLimit
      );

      return Database.query(query);
    } catch (QueryException qe) {
      throw new AuraHandledException(
        'Multi-field search failed: ' + qe.getMessage()
      );
    } catch (Exception e) {
      throw new AuraHandledException(
        'An unexpected error occurred during multi-field search: ' +
        e.getMessage()
      );
    }
  }

  /**
   * Clears the field cache - useful for testing or when schemas change
   */
  @TestVisible
  private static void clearFieldCache() {
    fieldCache.clear();
  }

  // ========================================================================
  // PRIVATE HELPER METHODS
  // ========================================================================

  /**
   * Validates that the SObject type exists and is accessible
   */
  private static Boolean isValidSObjectType(String objectApiName) {
    try {
      Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
        .get(objectApiName);
      return sObjectType != null && sObjectType.getDescribe().isAccessible();
    } catch (Exception e) {
      return false;
    }
  }

  /**
   * Validates search inputs for security and correctness
   */
  private static void validateSearchInputs(
    String objectApiName,
    String searchField,
    String searchTerm
  ) {
    // Validate object exists
    if (!isValidSObjectType(objectApiName)) {
      throw new AuraHandledException(
        'Invalid or inaccessible object: ' + objectApiName
      );
    }

    // Validate field exists and is accessible
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
      .get(objectApiName);
    if (sObjectType == null) {
      throw new AuraHandledException('Object not found: ' + objectApiName);
    }

    Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
    Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();

    if (!fields.containsKey(searchField.toLowerCase())) {
      throw new AuraHandledException('Field not found: ' + searchField);
    }

    Schema.SObjectField field = fields.get(searchField.toLowerCase());
    if (!field.getDescribe().isAccessible()) {
      throw new AuraHandledException('Field is not accessible: ' + searchField);
    }

    // Validate field type is searchable
    Schema.DisplayType fieldType = field.getDescribe().getType();
    if (!isSearchableFieldType(fieldType)) {
      throw new AuraHandledException(
        'Field type not searchable: ' + searchField
      );
    }
  }

  /**
   * Checks if field type is suitable for text search
   */
  private static Boolean isSearchableFieldType(Schema.DisplayType fieldType) {
    Set<Schema.DisplayType> searchableTypes = new Set<Schema.DisplayType>{
      Schema.DisplayType.STRING,
      Schema.DisplayType.TEXTAREA,
      Schema.DisplayType.EMAIL,
      Schema.DisplayType.PHONE,
      Schema.DisplayType.URL,
      Schema.DisplayType.PICKLIST,
      Schema.DisplayType.MULTIPICKLIST
    };

    return searchableTypes.contains(fieldType);
  }

  /**
   * Builds safe SOQL query for single field search
   */
  private static String buildSearchQuery(
    String objectApiName,
    String searchField,
    String searchTerm,
    Integer limitSize
  ) {
    // Sanitize search term - escape wildcards and quotes
    String sanitizedSearchTerm = sanitizeSearchTerm(searchTerm);

    return 'SELECT Id, ' +
      searchField +
      ' ' +
      'FROM ' +
      objectApiName +
      ' ' +
      'WHERE ' +
      searchField +
      ' LIKE \'%' +
      sanitizedSearchTerm +
      '%\' ' +
      'ORDER BY ' +
      searchField +
      ' ' +
      'LIMIT ' +
      limitSize;
  }

  /**
   * Builds safe SOQL query for multi-field search
   */
  private static String buildMultiFieldSearchQuery(
    String objectApiName,
    List<String> searchFields,
    String searchTerm,
    Integer limitSize
  ) {
    String sanitizedSearchTerm = sanitizeSearchTerm(searchTerm);

    List<String> whereConditions = new List<String>();
    Set<String> uniqueFields = new Set<String>();

    // Add Name field by default and deduplicate
    uniqueFields.add('Name');
    for (String field : searchFields) {
      uniqueFields.add(field);
    }

    for (String field : uniqueFields) {
      whereConditions.add(field + ' LIKE \'%' + sanitizedSearchTerm + '%\'');
    }

    String selectFields = String.join(new List<String>(uniqueFields), ', ');

    return 'SELECT ' +
      selectFields +
      ' ' +
      'FROM ' +
      objectApiName +
      ' ' +
      'WHERE (' +
      String.join(whereConditions, ' OR ') +
      ') ' +
      'ORDER BY Name ' +
      'LIMIT ' +
      limitSize;
  }

  /**
   * Sanitizes search term for safe SOQL usage
   */
  private static String sanitizeSearchTerm(String searchTerm) {
    if (String.isBlank(searchTerm)) {
      return '';
    }

    // Remove or escape problematic characters
    String sanitized = searchTerm.replaceAll('[\\\\%_]', '\\\\$0');
    return sanitized;
  }

  /**
   * Gets effective limit with bounds checking
   */
  private static Integer getEffectiveLimit(Integer requestedLimit) {
    Integer defaultLimit = 50;
    Integer maxLimit = 200;

    if (requestedLimit == null || requestedLimit <= 0) {
      return defaultLimit;
    }

    return Math.min(requestedLimit, maxLimit);
  }
}
