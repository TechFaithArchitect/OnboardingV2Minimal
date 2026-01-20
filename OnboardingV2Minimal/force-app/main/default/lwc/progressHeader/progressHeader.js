import { LightningElement, api } from "lwc";

/**
 * ProgressHeader
 * - Displays overall onboarding progress and SLA/Risk badges for the Dealer
 * - Inputs are provided by parent via GraphQL/Apex
 */
export default class ProgressHeader extends LightningElement {
  @api progressPercent = 0; // 0..100
  @api riskBadge = "On Track"; // 'On Track' | 'At Risk' | 'Overdue'
  @api activePrograms = []; // [{ id, name }]

  get progressLabel() {
    const pct = Math.max(0, Math.min(100, Number(this.progressPercent || 0)));
    return `${pct}% Complete`;
  }

  get riskClass() {
    switch ((this.riskBadge || "").toLowerCase()) {
      case "overdue":
        return "risk risk--overdue";
      case "at risk":
        return "risk risk--atrisk";
      default:
        return "risk risk--ontrack";
    }
  }
}
