import { api } from "lwc";
import LightningModal from "lightning/modal";
export default class PreviewDynamicPDF extends LightningModal {
  @api content;

  get url() {
    return `/apex/dynamicTemplate?templateId=${this.content.templateId}&recordId=${this.content.recordId}`;
  }

  handleClose() {
    this.close("okay");
  }
}