import Razorpay from "razorpay";

export class RazorpayService {
  constructor(private readonly razorpay: Razorpay) {}

  async fetchPlan(planId: string) {
    return this.razorpay.plans.fetch(planId);
  }

  async createOrder(
    amountPaise: number,
    receipt: string,
    notes: Record<string, string>
  ) {
    return this.razorpay.orders.create({
      amount: amountPaise,
      currency: "INR",
      receipt,
      notes,
    });
  }

  async fetchOrder(orderId: string) {
    return this.razorpay.orders.fetch(orderId);
  }

  async fetchPayment(paymentId: string) {
    return this.razorpay.payments.fetch(paymentId);
  }

  async createSubscription(
    planId: string,
    totalCount: number,
    customerNotify: 0 | 1,
    startAt?: number,
    expireBy?: number,
    notes?: Record<string, string>
  ) {
    return this.razorpay.subscriptions.create({
      plan_id: planId,
      total_count: totalCount,
      customer_notify: customerNotify,
      ...(startAt ? { start_at: startAt } : {}),
      ...(expireBy ? {expire_by: expireBy} : {}),
      ...(notes ? { notes } : {}),
    });
  }

  async fetchSubscription(subscriptionId: string) {
    return this.razorpay.subscriptions.fetch(subscriptionId);
  }

  async cancelSubscription(
    subscriptionId: string,
    cancelAtCycleEnd: boolean
  ) {
    return this.razorpay.subscriptions.cancel(
      subscriptionId,
      cancelAtCycleEnd
    );
  }
}
