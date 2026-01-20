import { LightningElement, api, wire } from "lwc";
import getOrderStatus from "@salesforce/apex/OnboardingOrderController.getOrderStatus";

export default class OnboardingOrderStatusViewer extends LightningElement {
  @api recordId;
  orders = [];
  error;

  columns = [
    {
      label: "Order Number",
      fieldName: "orderUrl",
      type: "url",
      typeAttributes: { label: { fieldName: "orderNumber" }, target: "_blank" }
    },
    { label: "Status", fieldName: "status", type: "text" },
    {
      label: "Effective Date",
      fieldName: "effectiveDateFormatted",
      type: "text"
    },
    {
      label: "Activated Date",
      fieldName: "activatedDateFormatted",
      type: "text"
    }
  ];

  @wire(getOrderStatus, { onboardingId: "$recordId" })
  wiredOrders({ data, error }) {
    if (data) {
      this.orders = data.map((order) => {
        const row = {};
        row.orderId = order.orderId;

        if (order.orderNumber && order.orderId) {
          row.orderUrl = `/lightning/r/Order/${order.orderId}/view`;
          row.orderNumber = order.orderNumber;
        }

        if (order.status) row.status = order.status;

        if (order.effectiveDate) {
          row.effectiveDateFormatted = new Date(
            order.effectiveDate
          ).toLocaleDateString();
        }

        if (order.activatedDate) {
          row.activatedDateFormatted = new Date(
            order.activatedDate
          ).toLocaleDateString();
        }

        return row;
      });

      this.error = undefined;
    } else if (error) {
      this.error = "Error retrieving order data";
      this.orders = [];
    }
  }

  get hasOrders() {
    return this.orders && this.orders.length > 0;
  }
}
