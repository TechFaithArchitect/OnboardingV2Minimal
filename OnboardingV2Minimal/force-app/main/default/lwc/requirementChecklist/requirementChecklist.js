import { LightningElement, api, wire, track } from "lwc";
import getRequirements from "@salesforce/apex/OnboardingRequirementsPanelController.getRequirements";

/**
 * requirementChecklist
 * - Dealer Experience component: renders requirements grouped by Stage
 * - Uses existing Apex service: OnboardingRequirementsPanelController.getRequirements()
 */
export default class RequirementChecklist extends LightningElement {
  @track loading = true;
  @track error;
  @track stages = []; // [{ name, requirements: [] }]
  @api recordId;
  @api parentId;

  get effectiveOnboardingId() {
    return this.parentId || this.recordId;
  }

  @wire(getRequirements, { onboardingId: "$effectiveOnboardingId" })
  wiredRequirements({ error, data }) {
    this.loading = false;
    if (error) {
      this.error = this._normalizeError(error);
      return;
    }
    if (data) {
      // Transform Apex DTOs to our view model
      this._transformToViewModel(data);
    }
  }

  // Transform Apex DTOs to our UI view model
  _transformToViewModel(requirements) {
    // Group by stage
    const stageMap = new Map();
    const stageOrder = [];

    requirements.forEach((req) => {
      const stageName = req.stageName || req.StageName || "Uncategorized";
      const requirementId = req.id || req.Id;
      const requirementName = req.name || req.Name;
      const status = req.status || req.Status;
      const dueDate = req.dueDate || req.DueDate || req.Due_Date__c;
      const riskScore = req.riskScore || req.RiskScore || req.Risk_Score__c;
      const lockReason = req.lockReason || req.LockReason || req.Lock_Reason__c;
      const relatedProgramIds =
        req.relatedProgramIds ||
        req.RelatedProgramIds ||
        req.Related_Program_Ids__c;
      if (!stageMap.has(stageName)) {
        stageMap.set(stageName, []);
        stageOrder.push(stageName);
      }
      stageMap.get(stageName).push({
        requirementId: requirementId,
        requirementName: requirementName,
        stageName: stageName,
        dueDate: dueDate,
        status: status,
        riskScore: riskScore,
        lockReason: lockReason,
        relatedProgramIds: relatedProgramIds
      });
    });

    this.stages = stageOrder.map((name) => ({
      name: name,
      requirements: stageMap.get(name)
    }));
  }

  handleOpenForm(event) {
    const requirementId =
      event.detail?.requirementId || event.currentTarget?.dataset?.id;
    if (!requirementId) {
      return;
    }
    this.dispatchEvent(
      new CustomEvent("openform", { detail: { requirementId } })
    );
  }

  _normalizeError(e) {
    if (Array.isArray(e?.body)) {
      return e.body.map((x) => x.message).join(", ");
    }
    return e?.body?.message || e?.message || "Unknown error";
  }
}
