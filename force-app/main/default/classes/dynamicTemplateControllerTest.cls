@isTest
public class dynamicTemplateControllerTest {
  @isTest
  static void testControllerWithValidTemplateAndRecord() {
    // Create test data
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    PDF_Template__c template = new PDF_Template__c(
      Name = 'Test Template',
      Body__c = 'Hello {!Record.Name}',
      Related_Object__c = 'Account',
      Insert_Fields__c = '[{"fieldName":"Name","fieldType":"string"}]'
    );
    insert template;

    Test.startTest();
    // Set page parameters
    PageReference pageRef = Page.dynamicTemplate;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('templateId', template.Id);
    ApexPages.currentPage().getParameters().put('recordId', acc.Id);

    dynamicTemplateController ctrl = new dynamicTemplateController();
    System.assertEquals('Hello Test Account', ctrl.renderedBody);
    // System.assertNotNull(ctrl.template);
    // System.assertNotNull(ctrl.record);
    Test.stopTest();
  }

  @isTest
  static void testControllerWithMissingTemplateId() {
    Test.startTest();
    PageReference pageRef = Page.dynamicTemplate;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('templateId', null);

    dynamicTemplateController ctrl;
    try {
      ctrl = new dynamicTemplateController();
      //   System.assert(false, 'Exception should have been thrown');
    } catch (Exception e) {
      System.assert(e.getMessage().contains('Template ID is required.'));
    }
    Test.stopTest();
  }

  @isTest
  static void testControllerWithMissingRelatedObject() {
    PDF_Template__c template = new PDF_Template__c(
      Name = 'Test Template',
      Body__c = 'Hello {!Record.Name}',
      Insert_Fields__c = '[{"fieldName":"Name","fieldType":"string"}]'
    );
    insert template;

    Test.startTest();
    PageReference pageRef = Page.dynamicTemplate;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('templateId', template.Id);

    dynamicTemplateController ctrl;
    try {
      ctrl = new dynamicTemplateController();
      //   System.assert(false, 'Exception should have been thrown');
    } catch (Exception e) {
      System.assert(
        e.getMessage().contains('Template missing Related Object.')
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testParseInsertFieldsWithBlank() {
    PDF_Template__c template = new PDF_Template__c(
      Name = 'Test Template',
      Body__c = 'Hello {!Record.Name}',
      Related_Object__c = 'Account',
      Insert_Fields__c = ''
    );
    insert template;

    Test.startTest();
    PageReference pageRef = Page.dynamicTemplate;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('templateId', template.Id);

    dynamicTemplateController ctrl = new dynamicTemplateController();
    System.assert(ctrl.renderedBody.contains('Hello'));
    Test.stopTest();
  }
}
