import { api, LightningElement, track, wire } from "lwc";
import QUILL from "@salesforce/resourceUrl/quill";
import { loadScript, loadStyle } from "lightning/platformResourceLoader";
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

  quillInitialized = false;
  @track editor;

  @track showModal = false;
  @track selectedField = "";
  @track savedCursorPosition = null;

  mergeFieldOptions = [];

  onChangeObjects(event) {
    this.selectedObject = event.target.value;
    console.log(this.selectedObject);
    this.callFieldObject();
  }

  async callFieldObject() {
    await getFieldList({ SObjectName: this.selectedObject })
      .then((result) => {
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
    } else if (error) {
      console.error(error);
    }
  }

  renderedCallback() {
    if (this.quillInitialized) return;
    this.quillInitialized = true;
    Promise.all([
      loadScript(this, QUILL + "/quill/quill.min.js"),
      loadStyle(this, QUILL + "/quill/quill.snow.css")
    ])
      .then(() => {
        this.initializeQuill();
        this.callFieldObject();
      })
      .catch((error) => {
        console.error("Error loading Quill assets", error);
      });
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

    if (this.content.length > 0) {
      fields[Field_BODY.fieldApiName] = this.content;
    }
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

  initializeQuill() {
    const container = this.template.querySelector(".quill-editor");

    const toolbarOptions = [
      ["bold", "italic", "underline", "strike"],
      [{ header: 1 }, { header: 2 }],
      [{ list: "ordered" }, { list: "bullet" }],
      [{ indent: "-1" }, { indent: "+1" }],
      [{ direction: "rtl" }],
      [{ size: ["small", false, "large", "huge"] }],
      [{ header: [1, 2, 3, 4, 5, 6, false] }],
      [{ color: [] }, { background: [] }],
      [{ font: [] }],
      [{ align: [] }],
      ["clean"],
      ["customMerge"]
    ];

    this.editor = new Quill(container, {
      theme: "snow",
      modules: {
        toolbar: {
          container: toolbarOptions,
          handlers: {
            customMerge: () => {
              this.showModal = true;
              this.savedCursorPosition = this.editor.getSelection();
              this.callFieldObject();
            }
          }
        }
      },
      placeholder: "Write something cool..."
    });

    // Set initial content
    const delta = this.editor.clipboard.convert(this.content || "");
    this.editor.setContents(delta);

    // Track changes
    this.editor.on("text-change", () => {
      this.content = this.editor.root.innerHTML;
    });

    setTimeout(() => {
      const btn = this.template.querySelector(".ql-customMerge");
      if (btn) {
        btn.innerHTML = "{ }";
        btn.title = "Insert Merge Field";
      }
    }, 0);
  }

  // ✅ Allow parent to set content
  @api
  setContent(html) {
    this.content = html;
    if (this.editor) {
      const delta = this.editor.clipboard.convert(html);
      this.editor.setContents(delta);
    }
  }

  // ✅ Allow parent to get content
  @api
  getContent() {
    return this.content;
  }

  handleFieldChange(event) {
    this.selectedField = event.detail.value;
  }

  insertSelectedField() {
    if (!this.selectedField) return;

    // Restore cursor if needed
    if (this.savedCursorPosition) {
      this.editor.setSelection(
        this.savedCursorPosition.index,
        this.savedCursorPosition.length || 0
      );
    }
    this.insertMergeFields.push(`${this.selectedField.replace("Record.", "")}`);

    const cursor = this.editor.getSelection();
    if (cursor) {
      this.editor.insertText(cursor.index, `{!${this.selectedField}}`);
    }

    this.showModal = false;
    this.selectedField = "";
    this.savedCursorPosition = null;

    console.log(JSON.stringify(this.insertMergeFields));
  }

  closeModal() {
    this.showModal = false;
  }

  handleRecord(event) {
    this.selectedRecordId = event.detail.recordId;
  }
}