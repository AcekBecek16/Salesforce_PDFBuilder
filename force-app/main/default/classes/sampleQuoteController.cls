public without sharing class sampleQuoteController {
  public CampaignMember campaignMember { get; set; }
  public String formattedStartDate { get; set; }

  public sampleQuoteController() {
    String campaignMemberId = ApexPages.currentPage()
      .getParameters()
      .get('campaignMemberId');

    if (String.isNotBlank(campaignMemberId)) {
      List<CampaignMember> results = [
        SELECT
          Id,
          Campaign.StartDate,
          Contact.Account.Name,
          Contact.Account.BillingStreet,
          Contact.Account.BillingCity,
          Contact.Account.BillingState,
          Name,
          Salutation
        FROM CampaignMember
        WHERE Id = :campaignMemberId
        LIMIT 1
      ];

      if (!results.isEmpty()) {
        campaignMember = results[0];
      }
    }
  }
}