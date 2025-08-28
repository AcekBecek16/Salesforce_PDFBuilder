@IsTest
public class sampleQuoteControllerTest {
  @TestSetup
  static void setupTestData() {
    // Create Account
    Account acc = new Account(
      Name = 'Test Account',
      BillingStreet = '123 Test Street',
      BillingCity = 'Jakarta',
      BillingState = 'DKI'
    );
    insert acc;

    // Create Contact
    Contact con = new Contact(
      FirstName = 'Test',
      LastName = 'Contact',
      Salutation = 'Mr.',
      AccountId = acc.Id
    );
    insert con;

    // Create Campaign
    Campaign camp = new Campaign(
      Name = 'Test Campaign',
      StartDate = Date.today()
    );
    insert camp;

    // Create Campaign Member
    CampaignMember cm = new CampaignMember(
      CampaignId = camp.Id,
      ContactId = con.Id,
      Status = 'Sent'
    );
    insert cm;
  }

  @IsTest
  static void testControllerWithCampaignMemberId() {
    // Get Campaign Member Id
    CampaignMember cm = [SELECT Id FROM CampaignMember LIMIT 1];

    // Simulate page parameter
    Test.startTest();
    PageReference pageRef = Page.sampleQuoteTemplate; // <-- replace with your actual VF page name
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('campaignMemberId', cm.Id);

    // Instantiate controller
    sampleQuoteController controller = new sampleQuoteController();
    Test.stopTest();

    // Assertions
    System.assertNotEquals(
      null,
      controller.campaignMember,
      'CampaignMember should not be null'
    );
    System.assertEquals(
      cm.Id,
      controller.campaignMember.Id,
      'Controller should load the correct CampaignMember'
    );
  }

  @IsTest
  static void testControllerWithoutCampaignMemberId() {
    Test.startTest();
    PageReference pageRef = Page.sampleQuoteTemplate; // <-- replace with your actual VF page name
    Test.setCurrentPage(pageRef);
    // no parameter passed
    sampleQuoteController controller = new sampleQuoteController();
    Test.stopTest();

    // Assertions
    System.assertEquals(
      null,
      controller.campaignMember,
      'CampaignMember should be null when no Id provided'
    );
  }
}
