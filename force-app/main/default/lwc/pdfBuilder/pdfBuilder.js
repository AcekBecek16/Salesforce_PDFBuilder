import { api, LightningElement, track, wire } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Field_ID from "@salesforce/schema/PDF_Template__c.Id";
import Field_BODY from "@salesforce/schema/PDF_Template__c.Body__c";
import Field_RelatedObject from "@salesforce/schema/PDF_Template__c.Related_Object__c";
import Field_Insert_Fields__c from "@salesforce/schema/PDF_Template__c.Insert_Fields__c";
import MyModal from "c/previewDynamicPDF";
import getFieldList from "@salesforce/apex/pdfBuilderController.getFieldList";

export default class PdfBuilder extends LightningElement {
  @api recordId;
  @api objectApiName;
  @track selectedRecordId = "";
  @track content = "";

  @track selectedObject = "";
  @track insertMergeFields = [];

  @track showModal = false;
  @track selectedField = "";

  @track dataFieldList = [];

  mergeFieldOptions = [];
  showModal = false;

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

  onChangeObjects(event) {
    this.selectedObject = event.target.value;
    console.log(this.selectedObject);
    this.callFieldObject();
  }

  async callFieldObject() {
    await getFieldList({ SObjectName: this.selectedObject })
      .then((result) => {
        this.dataFieldList = result;
        this.mergeFieldOptions = result.map((field) => {
          const objectName =
            field.EntityDefinition?.QualifiedApiName || "Unknown";
          const fieldName = field.QualifiedApiName;
          const fieldLabel = field.Label;
          const value = `Record.${fieldName}`;
          //   const value = `${objectName}.${fieldName}`;
          const label = `${objectName} - ${fieldLabel}`;
          return { label, value };
        });
      })
      .catch((error) => {
        console.log(error);
      });
  }
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [Field_BODY, Field_RelatedObject, Field_Insert_Fields__c]
  })
  getTemplate({ error, data }) {
    if (data) {
      this.content = data.fields.Body__c.value;
      this.selectedObject = data.fields.Related_Object__c.value;
      this.insertMergeFields = data.fields.Insert_Fields__c.value
        ? JSON.parse(data.fields.Insert_Fields__c.value)
        : [];

      this.callFieldObject();
    } else if (error) {
      console.error(error);
    }
  }

  async handlePreview() {
    if (!this.selectedRecordId) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Attention",
          message: "Please choose a related record before previewing it.",
          variant: "warning"
        })
      );
      return;
    }

    await this.handleSave();

    const result = await MyModal.open({
      // `label` is not included here in this example.
      // it is set on lightning-modal-header instead
      size: "medium",
      description: "Accessible description of modal's purpose",
      content: {
        templateId: this.recordId,
        recordId: this.selectedRecordId
      }
    });
    // if modal closed with X button, promise returns result = 'undefined'
    // if modal closed with OK button, promise returns result = 'okay'
    console.log(result);
  }
  async handleSave() {
    const fields = {};

    fields[Field_BODY.fieldApiName] = this.content;

    if (this.selectedObject.length > 0) {
      fields[Field_RelatedObject.fieldApiName] = this.selectedObject;
    }
    if (this.insertMergeFields.length > 0) {
      fields[Field_Insert_Fields__c.fieldApiName] = JSON.stringify(
        this.insertMergeFields
      );
    }

    fields[Field_ID.fieldApiName] = this.recordId;

    const recordInput = { fields };

    console.log(JSON.stringify(recordInput));

    updateRecord(recordInput)
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Template Updated",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Error creating record",
            message: error.body.message,
            variant: "error"
          })
        );
      });
  }

  handleTextChange() {
    this.content = this.template.querySelector(
      "lightning-input-rich-text"
    ).value;
  }

  handleRecord(event) {
    this.selectedRecordId = event.detail.recordId;
  }
  handleInsertField() {
    if (!this.content) return;

    const fieldValue = `{!${this.selectedField}}`;

    // Replace cursor placeholder with merge field
    const updatedContent = this.content.replace("{{cursor}}", fieldValue);

    this.content = updatedContent;

    // update the value back into the input
    const rte = this.template.querySelector("lightning-input-rich-text");
    if (rte) {
      rte.value = this.content;
    }

    const fillteredFields = this.dataFieldList.filter(
      (fields) =>
        fields.QualifiedApiName === this.selectedField.replace("Record.", "")
    );
    // console.log(JSON.stringify(fillteredFields, false, 2));

    this.insertMergeFields = [
      ...this.insertMergeFields,
      ...fillteredFields.map((item) => {
        return {
          fieldName: item.QualifiedApiName,
          fieldType: item.ValueType.DeveloperName
        };
      })
    ];
    this.closeModal();
    // console.log(JSON.stringify(this.insertMergeFields, false, 2));
  }

  handleMarkCursor() {
    const rte = this.template.querySelector("lightning-input-rich-text");
    if (rte) {
      // Fokus editor dulu
      rte.focus();

      // Cek apakah ada selection aktif dan posisi cursor
      const selection = window.getSelection();
      if (selection.rangeCount === 0 || selection.isCollapsed === false) {
        // Tidak ada cursor aktif atau ada teks yang diseleksi
        // Insert placeholder di akhir konten sebagai fallback
        this.content = (rte.value || "") + "{{cursor}}";
        rte.value = this.content;

        // Fokus ulang agar cursor di akhir
        rte.focus();
      } else {
        // Ada cursor aktif, insert placeholder di posisi cursor
        document.execCommand("insertText", false, "{{cursor}}");
        this.content = rte.value;
      }
    }
  }
  handleChangeSelectedField() {
    this.selectedField =
      this.template.querySelector("lightning-combobox").value;
  }

  handleOpenModal() {
    this.showModal = true;
    this.handleMarkCursor();
  }

  closeModal() {
    this.showModal = false;
  }
}