import { api, LightningElement, track } from "lwc";
import searchRecords from "@salesforce/apex/pdfBuilderController.searchRecords";

export default class DynamicSearch extends LightningElement {
  @api searchField = "Name";
  @api limitSize = 5;
  @api selectedObject;

  @track noResults = false;

  @track searchTerm = "";
  @track selectedRecord = null;
  @track results = [];

  async search() {
    try {
      const data = await searchRecords({
        objectApiName: this.selectedObject,
        searchField: this.searchField,
        searchTerm: this.searchTerm,
        limitSize: this.limitSize
      });

      this.results = data.map((record) => ({
        ...record,
        displayLabel: record[this.searchField]
      }));

      this.noResults = this.results.length === 0;
    } catch (err) {
      console.error("Search error:", err);
      this.results = [];
      this.noResults = true;
    }
  }
  handleSelect(event) {
    const recordId = event.currentTarget.dataset.id;
    const record = this.results.find((r) => r.Id === recordId);
    this.selectedRecord = record;
    this.searchTerm = "";
    this.results = [];

    // Fire event to parent
    this.dispatchEvent(
      new CustomEvent("recordselect", {
        detail: { recordId: record.Id, record }
      })
    );
  }

  clearSelection() {
    this.selectedRecord = null;
    this.searchTerm = "";
    this.results = [];
  }

  handleInput(event) {
    this.searchTerm = event.target.value;

    if (this.searchTerm.length >= 2) {
      this.search();
    } else {
      this.results = [];
      this.noResults = false;
    }
  }
}