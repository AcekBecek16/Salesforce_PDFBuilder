import { api, LightningElement, track } from "lwc";

export default class RichTextEditor extends LightningElement {
  @track content = "";
  @api insertFields;

  @track selectedFields = "";

  start = 0;
  end = 0;
  selectMode = "end";

  allowedFormats = [
    "font",
    "size",
    "bold",
    "italic",
    "underline",
    "strike",
    "list",
    "indent",
    "align",
    "link",
    "image",
    "clean",
    "table",
    "header",
    "color",
    "background"
  ];

  handleChange() {
    this.content = this.template.querySelector(
      "lightning-input-rich-text"
    ).value;
    console.log(this.content);
  }

  handleClick() {
    const editor = this.template.querySelector("lightning-input-rich-text");
    editor.setRangeText("Some new text", this.start, this.end, this.selectMode);
  }
  handleFieldChange(event) {
    this.selectedField = event.detail.value;
  }
}
