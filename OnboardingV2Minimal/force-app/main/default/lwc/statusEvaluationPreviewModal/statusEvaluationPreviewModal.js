import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { extractErrorMessage } from "c/utils";
import previewStatusEvaluation from "@salesforce/apex/OnboardingStatusRulesEngineController.previewStatusEvaluation";

export default class StatusEvaluationPreviewModal extends LightningElement {
  @api recordId;
  @api isOpen = false;

  @track traceData = [];
  @track filteredTraceData = [];
  @track isLoading = false;
  @track internalIsOpen = false;

  @track filters = {
    groupName: "",
    engineName: "",
    ruleNumber: ""
  };

  columns = [
    { label: "Order", fieldName: "ruleOrder", type: "number", sortable: true },
    { label: "Group", fieldName: "groupName", type: "text", sortable: true },
    { label: "Engine", fieldName: "engineName", type: "text", sortable: true },
    {
      label: "Rule #",
      fieldName: "ruleNumber",
      type: "number",
      sortable: true
    },
    { label: "Requirement", fieldName: "requirementName", type: "text" },
    { label: "Expected Status", fieldName: "expectedStatus", type: "text" },
    { label: "Passed", fieldName: "passed", type: "boolean", sortable: true },
    { label: "Evaluation Logic", fieldName: "evaluationLogic", type: "text" },
    { label: "Resulting Status", fieldName: "resultingStatus", type: "text" },
    {
      label: "Reason",
      fieldName: "shortCircuitReason",
      type: "text",
      wrapText: true
    }
  ];

  get hasTraceData() {
    return this.filteredTraceData && this.filteredTraceData.length > 0;
  }

  get canExport() {
    return this.hasTraceData;
  }

  get isExportDisabled() {
    return !this.canExport;
  }

  @wire(previewStatusEvaluation, {
    onboardingId: "$recordId",
    asOfDateTime: null,
    rulesEngineIds: null
  })
  wiredPreview({ error, data }) {
    if (data !== undefined) {
      this.isLoading = false;
      if (data && data.length > 0) {
        // Add unique key for datatable
        this.traceData = (data || []).map((trace, index) => ({
          ...trace,
          key: trace.engineId + "-" + (trace.ruleNumber || "") + "-" + index
        }));
        this.applyFilters();
      } else {
        this.traceData = [];
        this.filteredTraceData = [];
      }
    } else if (error) {
      this.isLoading = false;
      this.showToast(
        "Error",
        extractErrorMessage(error, "Failed to load evaluation preview."),
        "error"
      );
      this.traceData = [];
      this.filteredTraceData = [];
    } else {
      // Wire adapter is loading
      if (this.recordId && this.isOpen) {
        this.isLoading = true;
      }
    }
  }

  connectedCallback() {
    this.internalIsOpen = this.isOpen;
  }

  renderedCallback() {
    // Sync internal state with @api property
    if (this.internalIsOpen !== this.isOpen) {
      this.internalIsOpen = this.isOpen;
    }
  }

  handleFilterChange(event) {
    const field = event.target.dataset.field;
    const value = event.target.value;
    this.filters[field] = value;
    this.applyFilters();
  }

  applyFilters() {
    let filtered = [...this.traceData];

    if (this.filters.groupName) {
      const groupFilter = this.filters.groupName.toLowerCase();
      filtered = filtered.filter(
        (trace) =>
          trace.groupName && trace.groupName.toLowerCase().includes(groupFilter)
      );
    }

    if (this.filters.engineName) {
      const engineFilter = this.filters.engineName.toLowerCase();
      filtered = filtered.filter(
        (trace) =>
          trace.engineName &&
          trace.engineName.toLowerCase().includes(engineFilter)
      );
    }

    if (this.filters.ruleNumber) {
      const ruleFilter = this.filters.ruleNumber;
      filtered = filtered.filter(
        (trace) =>
          trace.ruleNumber && String(trace.ruleNumber).includes(ruleFilter)
      );
    }

    this.filteredTraceData = filtered;
  }

  handleExportCSV() {
    if (!this.hasTraceData) {
      return;
    }

    // Build CSV content
    const headers = [
      "Order",
      "Group",
      "Engine",
      "Rule #",
      "Requirement",
      "Expected Status",
      "Passed",
      "Evaluation Logic",
      "Resulting Status",
      "Reason"
    ];
    const rows = this.filteredTraceData.map((trace) => [
      trace.ruleOrder || "",
      trace.groupName || "",
      trace.engineName || "",
      trace.ruleNumber || "",
      trace.requirementName || "",
      trace.expectedStatus || "",
      trace.passed ? "Yes" : "No",
      trace.evaluationLogic || "",
      trace.resultingStatus || "",
      trace.shortCircuitReason || ""
    ]);

    const csvContent = [
      headers.join(","),
      ...rows.map((row) =>
        row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(",")
      )
    ].join("\n");

    // Create download link
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", `evaluation-preview-${Date.now()}.csv`);
    link.style.visibility = "hidden";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  handleClose() {
    this.internalIsOpen = false;
    this.dispatchEvent(new CustomEvent("close"));
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant
      })
    );
  }
}
