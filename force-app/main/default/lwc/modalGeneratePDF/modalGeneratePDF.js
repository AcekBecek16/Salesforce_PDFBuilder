import { api, wire } from "lwc";
import LightningModal from "lightning/modal";
import getSingleTemplate from "@salesforce/apex/generatePdfController.getSingleTemplate";
// import savePdfAttachment from "@salesforce/apex/generatePdfController.savePdfAttachment";
import sendEmail from "@salesforce/apex/generatePdfController.sendEmail";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ModalGeneratePDF extends LightningModal {
  @api content;
  subject;
  body;

  get url() {
    return `/apex/dynamicTemplate?templateId=${this.content.pdfTemplateId}&recordId=`;
  }

  @wire(getSingleTemplate, { templateId: "$content.templateId" })
  wiredTemplate({ error, data }) {
    if (data) {
      console.log(data);
      this.subject = data.Subject;
      this.body = data.HtmlValue;
    } else if (error) {
      console.log(error);
    }
  }

  handleClose() {
    this.close("okay");
  }

  async handleSendEmail() {
    try {
      await sendEmail({
        campaignId: this.content.recordId,
        emailTemplateId: this.content.templateId,
        pdfTemplateId: this.content.pdfTemplateId
      });

      this.close("success");
    } catch (error) {
      console.error("Email failed", error);
      this.close("error");
    }
  }
}
