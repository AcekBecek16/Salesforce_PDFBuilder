import { LightningElement, api, track, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import getEmailTemplate from "@salesforce/apex/generatePdfController.getEmailTemplate";
import MyModal from "c/modalGeneratePDF";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class GeneratePdf extends LightningElement {
  @api recordId;
  @api objectApiName;
  @track emailValue;
  @track emailTemplateName;
  @track pdfValue;
  @track templateOptions;

  get url() {
    return "/apex/sampleQuoteTemplate?campaignId=" + this.recordId;
  }
  //   handlePreview() {
  //     console.log(
  //       JSON.stringify({
  //         email: this.emailValue,
  //         pdf: this.pdfValue,
  //         recordId: this.recordId
  //       })
  //     );
  //   }
  async handlePreview() {
    if (!this.emailValue || !this.pdfValue) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Attantion",
          message: "Please select Email Template and PDF",
          variant: "error"
        })
      );
      return;
    }
    const result = await MyModal.open({
      // `label` is not included here in this example.
      // it is set on lightning-modal-header instead
      size: "medium",
      description: "Accessible description of modal's purpose",
      content: {
        recordId: this.recordId,
        templateId: this.emailValue,
        templateName: this.emailTemplateName,
        pdfTemplateId: this.pdfValue
      }
    });
    // if modal closed with X button, promise returns result = 'undefined'
    // if modal closed with OK button, promise returns result = 'okay'
    console.log(result);
  }
  handleCancel(event) {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  get templatePdfOptions() {
    return [
      {
        label: "Surat Maintenance",
        value: "sampleQuoteTemplate"
      }
    ];
  }

  @wire(getEmailTemplate, { entityName: "$objectApiName" })
  wiredName({ error, data }) {
    if (data) {
      this.templateOptions = data.map((item) => {
        return {
          label: item.Name,
          value: item.Id
        };
      });
    } else if (error) {
      console.error(error);
    }
  }

  handleChangeTemplate(event) {
    this.emailValue = event.target.value;
  }

  handleChangePDF(event) {
    this.pdfValue = event.target.value;
  }
}