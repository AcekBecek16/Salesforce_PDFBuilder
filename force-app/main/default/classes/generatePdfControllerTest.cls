@isTest
private class generatePdfControllerTest {
  @TestSetup
  static void setupData() {
    // Create test email templates

    User adminUser = [
      SELECT Id
      FROM User
      WHERE Profile.Name = 'System Administrator'
      LIMIT 1
    ];
    List<EmailTemplate> templates = new List<EmailTemplate>();
    templates.add(
      new EmailTemplate(
        Name = 'Test Template 1',
        DeveloperName = 'TestTemplate1',
        Subject = 'Test Subject 1',
        FolderId = adminUser.Id,
        TemplateType = 'text',
        HtmlValue = '<p>Test Email Template 1</p>'
      )
    );
    templates.add(
      new EmailTemplate(
        Name = 'Test Template 2',
        DeveloperName = 'TestTemplate2',
        Subject = 'Test Subject 2',
        FolderId = adminUser.Id,
        TemplateType = 'text',
        HtmlValue = '<p>Test Email Template 2</p>'
      )
    );
    insert templates;

    // Create test OrgWideEmailAddress
    OrgWideEmailAddress owd = [
      SELECT Id, Address, DisplayName
      FROM OrgWideEmailAddress
      WHERE DisplayName = 'No-Reply Cikarang Listrindo'
      LIMIT 1
    ];
  }

  @isTest
  static void testGetEmailTemplate() {
    // Get all email templates
    List<EmailTemplate> templates = generatePdfController.getEmailTemplate(
      'Contact'
    );

    // Assert that we get results
    System.assertNotEquals(
      0,
      templates.size(),
      'Email templates should be returned'
    );

    // Verify fields are populated
    for (EmailTemplate template : templates) {
      System.assertNotEquals(
        null,
        template.Id,
        'Template ID should not be null'
      );
    }
  }

  @isTest
  static void testGetSingleTemplate() {
    // Get a template ID from setup data
    EmailTemplate template = [SELECT Id FROM EmailTemplate LIMIT 1];

    // Get the single template
    EmailTemplate retrievedTemplate = generatePdfController.getSingleTemplate(
      template.Id
    );

    // Assert that we get the correct template
    System.assertEquals(
      template.Id,
      retrievedTemplate.Id,
      'Template ID should match'
    );
    System.assertNotEquals(
      null,
      retrievedTemplate.Name,
      'Template Name should not be null'
    );
    System.assertNotEquals(
      '',
      retrievedTemplate.Name,
      'Template Name should not be empty'
    );
    System.assertNotEquals(
      null,
      retrievedTemplate.Subject,
      'Template Subject should not be null'
    );
    System.assertNotEquals(
      '',
      retrievedTemplate.Subject,
      'Template Subject should not be empty'
    );
  }

  @isTest
  static void testGetPDFTemplates() {
    // Create test PDF templates
    List<PDF_Template__c> pdfTemplates = new List<PDF_Template__c>();
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 1',
        Related_Object__c = 'Contact',
        Body__c = 'Test PDF Body 1',
        Insert_Fields__c = 'Name,Email'
      )
    );
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 2',
        Related_Object__c = 'Campaign',
        Body__c = 'Test PDF Body 2',
        Insert_Fields__c = 'Name,StartDate'
      )
    );
    insert pdfTemplates;
    // Get all PDF templates
    List<PDF_Template__c> templates = generatePdfController.getPDFTemplates();

    // Assert that we get results
    System.assertNotEquals(
      0,
      templates.size(),
      'PDF templates should be returned'
    );

    // Verify fields are populated
    for (PDF_Template__c template : templates) {
      System.assertNotEquals(
        null,
        template.Id,
        'Template ID should not be null'
      );
      System.assertNotEquals(
        '',
        template.Name,
        'Template Name should not be empty'
      );
      System.assertNotEquals(
        null,
        template.Body__c,
        'Template Body should not be null'
      );
      System.assertNotEquals(
        '',
        template.Body__c,
        'Template Body should not be empty'
      );
    }
  }

  @isTest
  static void testSendEmail() {
    // Create test PDF templates
    List<PDF_Template__c> pdfTemplates = new List<PDF_Template__c>();
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 1',
        Related_Object__c = 'Contact',
        Body__c = 'Test PDF Body 1',
        Insert_Fields__c = 'Name,Email'
      )
    );
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 2',
        Related_Object__c = 'Campaign',
        Body__c = 'Test PDF Body 2',
        Insert_Fields__c = 'Name,StartDate'
      )
    );
    insert pdfTemplates;

    // Create a test campaign
    Campaign testCampaign = new Campaign(Name = 'Test Campaign');
    insert testCampaign;

    // Create test contacts
    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < 2; i++) {
      contacts.add(
        new Contact(
          FirstName = 'Test' + i,
          LastName = 'Contact' + i,
          Email = 'test' + i + '@example.com'
        )
      );
    }
    insert contacts;

    // Create campaign members
    List<CampaignMember> members = new List<CampaignMember>();
    for (Contact c : contacts) {
      members.add(
        new CampaignMember(
          CampaignId = testCampaign.Id,
          ContactId = c.Id,
          Status = 'Sent'
        )
      );
    }
    insert members;

    // Get template IDs
    EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
    PDF_Template__c pdfTemplate = [SELECT Id FROM PDF_Template__c LIMIT 1];

    System.debug(
      'EmailTemplate Id: ' +
        emailTemplate.Id +
        ', PDFTemplate Id: ' +
        pdfTemplate.Id
    );
    // Test sending emails
    Test.startTest();
    generatePdfController.sendEmail(
      testCampaign.Id,
      emailTemplate.Id,
      pdfTemplate.Id
    );
    Test.stopTest();
  }

  @isTest
  static void testExceptionHandler() {
    // Create test PDF templates
    List<PDF_Template__c> pdfTemplates = new List<PDF_Template__c>();
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 1',
        Related_Object__c = 'Contact',
        Body__c = 'Test PDF Body 1',
        Insert_Fields__c = 'Name,Email'
      )
    );
    pdfTemplates.add(
      new PDF_Template__c(
        Name = 'Test PDF Template 2',
        Related_Object__c = 'Campaign',
        Body__c = 'Test PDF Body 2',
        Insert_Fields__c = 'Name,StartDate'
      )
    );
    insert pdfTemplates;

    // Test with invalid template ID to trigger exception handling
    Test.startTest();
    try {
      generatePdfController.getSingleTemplate('invalidId');
      System.assert(false, 'Expected exception was not thrown');
    } catch (AuraHandledException e) {
      System.assertNotEquals(
        null,
        e.getMessage(),
        'Exception message should not be null'
      );
    }
    Test.stopTest();
  }

  //   @isTest
  //   static void testSavePdfAttachment() {
  //     // Create test PDF templates
  //     List<PDF_Template__c> pdfTemplates = new List<PDF_Template__c>();
  //     pdfTemplates.add(
  //       new PDF_Template__c(
  //         Name = 'Test PDF Template 1',
  //         Related_Object__c = 'Contact',
  //         Body__c = 'Test PDF Body 1',
  //         Insert_Fields__c = 'Name,Email'
  //       )
  //     );
  //     pdfTemplates.add(
  //       new PDF_Template__c(
  //         Name = 'Test PDF Template 2',
  //         Related_Object__c = 'Campaign',
  //         Body__c = 'Test PDF Body 2',
  //         Insert_Fields__c = 'Name,StartDate'
  //       )
  //     );
  //     insert pdfTemplates;

  //     // Create test record for attachment
  //     Campaign testCampaign = new Campaign(Name = 'Test Campaign for PDF');
  //     insert testCampaign;

  //     // Get a PDF template
  //     PDF_Template__c pdfTemplate = [SELECT Id FROM PDF_Template__c LIMIT 1];

  //     Test.startTest();
  //     // Mock the page reference to avoid VF page dependency
  //     Test.setMock(HttpCalloutMock.class, new PageReferenceMock());

  //     // Save PDF attachment
  //     ContentVersion cv = generatePdfController.savePdfAttachment(
  //       '',
  //       testCampaign.Id,
  //       pdfTemplate.Id
  //     );
  //     Test.stopTest();

  //     // Verify ContentVersion was created
  //     System.assertNotEquals(null, cv.Id, 'ContentVersion ID should not be null');
  //     System.assert(
  //       cv.Title.contains('GeneratedPDF_'),
  //       'ContentVersion title should contain GeneratedPDF_'
  //     );
  //   }

  // Mock class for PageReference to avoid VF page dependency
  public class PageReferenceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HttpResponse response = new HttpResponse();
      response.setBody('Mock PDF Content');
      response.setStatusCode(200);
      return response;
    }
  }
}
