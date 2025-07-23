public without sharing class generatePdfController {
  @AuraEnabled(cacheable=true)
  public static List<EmailTemplate> getEmailTemplate(String entityName) {
    try {
      return [
        SELECT Id, Name, RelatedEntityType
        FROM EmailTemplate
        WHERE RelatedEntityType = :entityName
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static EmailTemplate getSingleTemplate(String templateId) {
    try {
      return [
        SELECT Id, Name, RelatedEntityType, HtmlValue, Subject
        FROM EmailTemplate
        WHERE Id = :templateId
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PDF_Template__c> getPDFTemplates() {
    try {
      return [
        SELECT Id, Name, Body__c, Related_Object__c, Insert_Fields__c
        FROM PDF_Template__c
      ];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public static ContentVersion savePdfAttachment(
    String recordId,
    String CampaignId,
    String TemplateId
  ) {
    try {
      PageReference pdfPage = Page.dynamicTemplate; // name of your VF page
      pdfPage.getParameters().put('templateId', TemplateId);
      pdfPage.getParameters().put('recordId', recordId);

      // Get the PDF blob
      Blob pdfBlob = pdfPage.getContent();

      // Save as Attachment (for classic objects)
      Attachment attachment = new Attachment();
      attachment.ParentId = CampaignId; // attach to a record like Contact, Opportunity, etc.
      attachment.Name = 'GeneratedPDF_' + DateTime.now().getTime() + '.pdf';
      attachment.ContentType = 'application/pdf';
      attachment.Body = pdfBlob;
      insert attachment;

      ContentVersion cv = new ContentVersion();
      cv.Title = 'GeneratedPDF_' + DateTime.now().getTime() + '.pdf';
      cv.PathOnClient = 'GeneratedPDF_' + DateTime.now().getTime() + '.pdf';
      cv.VersionData = pdfBlob;
      insert cv;

      return cv;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
  public static void sendEmail(
    String campaignId,
    String emailTemplateId,
    String pdfTemplateId
  ) {
    try {
      // Step 1: Get Campaign Members
      List<CampaignMember> members = [
        SELECT ContactId, LeadId, CampaignId, Id
        FROM CampaignMember
        WHERE CampaignId = :campaignId AND (ContactId != NULL OR LeadId != NULL)
      ];

      OrgWideEmailAddress owd = [
        SELECT Id, DisplayName
        FROM OrgWideEmailAddress
        WHERE DisplayName = 'acek becek'
        LIMIT 1
      ];
      // Step 2: Get PDF attachment from ContentVersion
      //   ContentVersion cv = [
      //     SELECT Title, VersionData, FileExtension
      //     FROM ContentVersion
      //     WHERE Id = :contentVersionId
      //     LIMIT 1
      //   ];

      // Step 3: Prepare and send emails
      List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      for (CampaignMember cm : members) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        ContentVersion cv = savePdfAttachment(
          cm.ContactId,
          cm.CampaignId,
          pdfTemplateId
        );
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setFileName(cv.Title + '.' + cv.FileExtension);
        fileAttachment.setBody(cv.VersionData);
        fileAttachment.setContentType('application/pdf');
        attachments.add(fileAttachment);

        // email.setSenderDisplayName(owd.DisplayName);
        email.setOrgWideEmailAddressId(owd.Id);
        email.setTemplateId(emailTemplateId);
        email.setTargetObjectId(
          cm.ContactId != null ? cm.ContactId : cm.LeadId
        );
        email.setSaveAsActivity(true);
        email.setFileAttachments(attachments);
        email.setWhatId(campaignId); // Optional: links template merge fields
        emails.add(email);
      }

      if (!emails.isEmpty()) {
        Messaging.sendEmail(emails, false); // false = don’t use AllOrNothing
      }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
