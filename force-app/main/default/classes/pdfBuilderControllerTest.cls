@isTest
private class pdfBuilderControllerTest {
  @TestSetup
  static void setupTestData() {
    // Create test data if needed for search functionality
    List<Account> testAccounts = new List<Account>();
    for (Integer i = 0; i < 5; i++) {
      testAccounts.add(
        new Account(
          Name = 'Test Account ' + i,
          Phone = '555-1234-' + i,
          Website = 'www.test' + i + '.com'
        )
      );
    }
    insert testAccounts;
  }

  @isTest
  static void testGetFieldListValidObject() {
    // Test with a standard object
    List<FieldDefinition> fields = pdfBuilderController.getFieldList('Account');
    System.assertNotEquals(
      0,
      fields.size(),
      'Should return fields for Account object'
    );

    // Verify some expected fields are present
    Boolean hasNameField = false;
    for (FieldDefinition field : fields) {
      if (field.QualifiedApiName == 'Name') {
        hasNameField = true;
        break;
      }
    }
    System.assertEquals(true, hasNameField, 'Should contain Name field');
  }

  @isTest
  static void testGetFieldListBlankInput() {
    // Test with blank object name
    try {
      pdfBuilderController.getFieldList('');
      System.assert(
        false,
        'Should have thrown exception for blank object name'
      );
    } catch (AuraHandledException e) {
    }
  }

  @isTest
  static void testGetFieldListCache() {
    // Clear cache first
    Test.startTest();
    pdfBuilderController.clearFieldCache();

    // Call method twice to test caching
    List<FieldDefinition> fields1 = pdfBuilderController.getFieldList(
      'Account'
    );
    List<FieldDefinition> fields2 = pdfBuilderController.getFieldList(
      'Account'
    );
    Test.stopTest();

    System.assertEquals(
      fields1.size(),
      fields2.size(),
      'Cached results should match'
    );
  }

  @isTest
  static void testSearchRecordsValid() {
    Test.startTest();
    List<SObject> results = pdfBuilderController.searchRecords(
      'Account',
      'Name',
      'Test Account',
      10
    );
    Test.stopTest();

    System.assert(results.size() > 0, 'Should return matching accounts');
  }

  @isTest
  static void testSearchRecordsBlankSearch() {
    Test.startTest();
    List<SObject> results = pdfBuilderController.searchRecords(
      'Account',
      'Name',
      '',
      10
    );
    Test.stopTest();

    System.assertEquals(
      0,
      results.size(),
      'Should return empty list for blank search'
    );
  }

  @isTest
  static void testSearchRecordsMultiFieldValid() {
    Test.startTest();
    List<SObject> results = pdfBuilderController.searchRecordsMultiField(
      'Account',
      new List<String>{ 'Name', 'Phone' },
      'Test',
      10
    );
    Test.stopTest();

    System.assert(results.size() > 0, 'Should return matching accounts');
  }
  @isTest
  static void testSearchRecordsWithSpecialChars() {
    Test.startTest();
    List<SObject> results = pdfBuilderController.searchRecords(
      'Account',
      'Name',
      'Test Account 1%',
      10
    );
    Test.stopTest();

    System.assert(true, 'Should handle special characters without error');
  }
}
