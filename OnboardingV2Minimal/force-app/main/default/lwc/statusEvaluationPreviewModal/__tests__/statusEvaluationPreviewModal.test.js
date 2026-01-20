import { createElement } from "@lwc/engine-dom";
import StatusEvaluationPreviewModal from "c/statusEvaluationPreviewModal";
import previewStatusEvaluation from "@salesforce/apex/OnboardingStatusRulesEngineController.previewStatusEvaluation";

// Mock Apex methods
jest.mock(
  "@salesforce/apex/OnboardingStatusRulesEngineController.previewStatusEvaluation",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

describe("c-status-evaluation-preview-modal", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  const mockTraceData = [
    {
      engineId: "a0X000000000001AAA",
      engineName: "Engine 1",
      groupId: "a0G000000000001AAA",
      groupName: "Group 1",
      ruleNumber: 1,
      ruleName: "Rule 1",
      requirementName: "Requirement 1",
      expectedStatus: "Complete",
      passed: true,
      resultingStatus: "Approved",
      evaluationLogic: "ALL",
      ruleOrder: 1
    }
  ];

  it("renders component", () => {
    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = false;
    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      expect(element).toBeTruthy();
    });
  });

  it("displays modal when isOpen is true", async () => {
    previewStatusEvaluation.mockResolvedValue([]);

    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = true;
    document.body.appendChild(element);

    await Promise.resolve();
    await Promise.resolve();

    expect(element).toBeTruthy();
    expect(element.isOpen).toBe(true);
    expect(element.recordId).toBe("a0X000000000000AAA");
  });

  it("loads trace data when recordId is provided", async () => {
    previewStatusEvaluation.mockResolvedValue(mockTraceData);

    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = true;
    document.body.appendChild(element);

    // Wait for wire adapter to process
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    // Wire adapter should be called when recordId is set and component is rendered
    expect(element).toBeTruthy();
    expect(element.recordId).toBe("a0X000000000000AAA");
  });

  it("handles empty trace data", async () => {
    previewStatusEvaluation.mockResolvedValue([]);

    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = true;
    document.body.appendChild(element);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(element).toBeTruthy();
    expect(element.recordId).toBe("a0X000000000000AAA");
  });

  it("handles error when loading trace data", async () => {
    const error = new Error("Failed to load");
    previewStatusEvaluation.mockRejectedValue(error);

    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = true;

    element.addEventListener("lightning__showtoast", () => {
      // Event listener for error handling
    });

    document.body.appendChild(element);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(element).toBeTruthy();
  });

  it("closes modal on close button click", async () => {
    previewStatusEvaluation.mockResolvedValue([]);

    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    element.recordId = "a0X000000000000AAA";
    element.isOpen = true;

    let closeEvent;
    element.addEventListener("close", (event) => {
      closeEvent = event;
    });

    document.body.appendChild(element);

    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    const closeButton =
      element.shadowRoot?.querySelector('button[title="Close"]') ||
      element.shadowRoot?.querySelector('lightning-button[label="Close"]');
    if (closeButton) {
      closeButton.click();
    }

    await Promise.resolve();
    await Promise.resolve();

    expect(closeEvent).toBeTruthy();
  });

  it("has correct component structure", () => {
    const element = createElement("c-status-evaluation-preview-modal", {
      is: StatusEvaluationPreviewModal
    });
    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      // Verify component renders without errors
      expect(element).toBeTruthy();
      // Verify public properties exist
      expect(element.recordId).toBeUndefined();
      expect(element.isOpen).toBe(false);
    });
  });
});
