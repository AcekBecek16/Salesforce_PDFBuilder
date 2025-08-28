public without sharing class generatePdfController {
  @AuraEnabled(cacheable=true)
  public static List<EmailTemplate> getEmailTemplate(String entityName) {
    try {
      return [
        SELECT Id, Name, RelatedEntityType
        FROM EmailTemplate
        // WHERE RelatedEntityType = :entityName
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
      Blob pdfBlob;
      if (Test.isRunningTest()) {
        // Return a mock PDF blob for testing
        pdfBlob = Blob.valueOf('Mock PDF Content');
      } else {
        // Get actual PDF content in production
        pdfBlob = pdfPage.getContent();
      }

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
  public static void sendEmailNotification(
    String recordId,
    String emailTemplateId,
    String pdfTemplateId
  ) {
    try {
      List<List_Konsumen__c> members = [
        SELECT
          Id,
          Mass_Notification__c,
          Account__c,
          Account__r.Name,
          Account__r.Contact_Name__r.Email
        FROM List_Konsumen__c
        WHERE Mass_Notification__c = :recordId
      ];

      if (!members.isEmpty()) {
        List<wrapperRecipient> recipients = new List<wrapperRecipient>();

        for (List_Konsumen__c cm : members) {
          if (cm.Account__c != null) {
            recipients.add(
              new wrapperRecipient(
                cm.Id,
                cm.Account__r.Contact_Name__r.Email,
                cm.Account__c,
                'List_Konsumen__c',
                pdfTemplateId,
                emailTemplateId
              )
            );
          }
        }

        sendEmailhandler(recipients);
      }

      //   OrgWideEmailAddress owd = [
      //     SELECT Id, DisplayName
      //     FROM OrgWideEmailAddress
      //     WHERE DisplayName = 'No-Reply Cikarang Listrindo'
      //     LIMIT 1
      //   ];

      //   List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      //   for (List_Konsumen__c cm : members) {
      //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

      //     ContentVersion cv = savePdfAttachment(cm.Id, cm.Id, pdfTemplateId);
      //     List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
      //     Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
      //     fileAttachment.setFileName(cv.Title + '.' + cv.FileExtension);
      //     fileAttachment.setBody(cv.VersionData);
      //     fileAttachment.setContentType('application/pdf');
      //     attachments.add(fileAttachment);

      //     email.setOrgWideEmailAddressId(owd.Id);
      //     email.setTemplateId(emailTemplateId);
      //     email.setTargetObjectId(cm.Id);
      //     email.setSaveAsActivity(true);
      //     email.setFileAttachments(attachments);
      //     email.setWhatId(cm.Id);
      //     emails.add(email);
      //   }

      //   if (!emails.isEmpty()) {
      //     Messaging.sendEmail(emails, false); // false = don’t use AllOrNothing
      //   }
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
      List<CampaignMember> members = [
        SELECT ContactId, LeadId, CampaignId, Id
        FROM CampaignMember
        WHERE CampaignId = :campaignId AND (ContactId != NULL OR LeadId != NULL)
      ];

      System.debug('Campaign Members: ' + members);

      if (!members.isEmpty()) {
        List<wrapperRecipient> recipients = new List<wrapperRecipient>();

        for (CampaignMember cm : members) {
          String targetId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
          if (targetId != null) {
            recipients.add(
              new wrapperRecipient(
                campaignId,
                '',
                targetId,
                'CampaignMember',
                pdfTemplateId,
                emailTemplateId
              )
            );
          }
        }

        sendEmailhandler(recipients);
      }
      //   OrgWideEmailAddress owd = [
      //     SELECT Id, DisplayName
      //     FROM OrgWideEmailAddress
      //     WHERE DisplayName = 'No-Reply Cikarang Listrindo'
      //     LIMIT 1
      //   ];

      //   List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      //   for (CampaignMember cm : members) {
      //     Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

      //     ContentVersion cv = savePdfAttachment(
      //       cm.ContactId,
      //       cm.CampaignId,
      //       pdfTemplateId
      //     );
      //     List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
      //     Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
      //     fileAttachment.setFileName(cv.Title + '.' + cv.FileExtension);
      //     fileAttachment.setBody(cv.VersionData);
      //     fileAttachment.setContentType('application/pdf');
      //     attachments.add(fileAttachment);

      //     email.setOrgWideEmailAddressId(owd.Id);
      //     email.setTemplateId(emailTemplateId);
      //     email.setTargetObjectId(
      //       cm.ContactId != null ? cm.ContactId : cm.LeadId
      //     );
      //     email.setSaveAsActivity(true);
      //     email.setFileAttachments(attachments);
      //     email.setWhatId(campaignId);
      //     emails.add(email);
      //   }

      //   if (!emails.isEmpty()) {
      //     Messaging.SendEmailResult[] results = Messaging.sendEmail(
      //       emails,
      //       false
      //     ); // false = don’t use AllOrNothing
      //     for (Integer i = 0; i < results.size(); i++) {
      //       Messaging.SendEmailResult result = results[i];

      //       if (result.isSuccess()) {
      //         System.debug('Email ' + i + ' sent successfully');
      //       } else {
      //         System.debug(
      //           'Email ' + i + ' failed: ' + result.getErrors()[0].getMessage()
      //         );
      //       }
      //     }
      //   }
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private class wrapperRecipient {
    public String parentId { get; set; }
    public String emailTarget { get; set; }
    public String targetId { get; set; }
    public String objectApiName { get; set; }
    public String pdfTemplateId { get; set; }
    public String emailTemplateId { get; set; }

    public wrapperRecipient(
      String parentId,
      String emailTarget,
      String targetId,
      String objectApiName,
      String pdfTemplateId,
      String emailTemplateId
    ) {
      this.parentId = parentId;
      this.emailTarget = emailTarget;
      this.targetId = targetId;
      this.objectApiName = objectApiName;
      this.pdfTemplateId = pdfTemplateId;
      this.emailTemplateId = emailTemplateId;
    }
  }

  private static void sendEmailhandler(List<wrapperRecipient> members) {
    try {
      OrgWideEmailAddress owd = [
        SELECT Id, DisplayName
        FROM OrgWideEmailAddress
        WHERE DisplayName = 'No-Reply Cikarang Listrindo'
        LIMIT 1
      ];
      List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

      for (wrapperRecipient member : members) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        ContentVersion cv = savePdfAttachment(
          member.targetId,
          member.parentId,
          member.pdfTemplateId
        );
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setFileName(cv.Title + '.' + cv.FileExtension);
        fileAttachment.setBody(cv.VersionData);
        fileAttachment.setContentType('application/pdf');
        attachments.add(fileAttachment);

        email.setOrgWideEmailAddressId(owd.Id);
        email.setTemplateId(member.emailTemplateId);
        email.setTargetObjectId(member.targetId);
        email.setSaveAsActivity(true);
        email.setFileAttachments(attachments);
        email.setWhatId(member.parentId);
        emails.add(email);
      }

      if (!emails.isEmpty()) {
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
          emails,
          false
        ); // false = don’t use AllOrNothing
        for (Integer i = 0; i < results.size(); i++) {
          Messaging.SendEmailResult result = results[i];

          if (result.isSuccess()) {
            System.debug('Email ' + i + ' sent successfully');
          } else {
            System.debug(
              'Email ' + i + ' failed: ' + result.getErrors()[0].getMessage()
            );
          }
        }
      }
    } catch (Exception e) {
      System.debug(e.getMessage());
    }
  }
}
