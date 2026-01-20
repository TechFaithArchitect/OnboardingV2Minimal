import { LightningElement, api, track } from "lwc";

export default class OnboardingStatusRuleForm extends LightningElement {
  @api recordId;
  @track showCustomLogic = false;

  handleEvalLogicChange(event) {
    this.showCustomLogic = event.detail.value === "CUSTOM";
  }

  handleSuccess() {
    this.dispatchEvent(
      new CustomEvent("refresh", { detail: { id: this.recordId } })
    );
  }

  handleSubmit(event) {
    this.showCustomLogic = event.target.value === "CUSTOM";
  }
}
