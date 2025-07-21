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
    return `/apex/${this.content.pdfTemplateId}?pdfReport=pdf&campaignId=${this.content.recordId}`;
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
    await sendEmail({
      campaignId: this.content.recordId,
      emailTemplateId: this.content.templateId
    })
      .then((result) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Email Succesfully Sent",
            variant: "success"
          })
        );
        this.close(result);
      })
      .catch((error) => {
        console.error("Email failed", error);
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error",
            message: "Email failed to send: " + error.body.message + " ",
            variant: "error"
          })
        );
      });
  }
}