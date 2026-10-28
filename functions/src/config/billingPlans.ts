export type PremiumTier = "lite" | "pro";
export type BillingKind = "one_time" | "subscription";

export interface BillingPlanDefinition {
  id: string;
  name: string;
  tier: PremiumTier;
  kind: BillingKind;
  amountPaise: number;
  period: "weekly" | "monthly" | "yearly";
  accessDays?: number;
  trialDays: number | null;
  maxTotalCount?: number;
  legacy?: boolean;
}

export const BILLING_PLANS: Record<string, BillingPlanDefinition> = {
  lite_weekly: {
    id: "lite_weekly",
    name: "Slipe AI Lite Weekly",
    tier: "lite",
    kind: "one_time",
    amountPaise: 4900,
    period: "weekly",
    accessDays: 7,
    trialDays: 0,
  },
  lite_monthly: {
    id: "lite_monthly",
    name: "Slipe AI Lite Monthly",
    tier: "lite",
    kind: "subscription",
    amountPaise: 9900,
    period: "monthly",
    trialDays: 0,
    maxTotalCount: 360,
  },
  lite_yearly: {
    id: "lite_yearly",
    name: "Slipe AI Lite Yearly",
    tier: "lite",
    kind: "subscription",
    amountPaise: 89900,
    period: "yearly",
    trialDays: 0,
    maxTotalCount: 30,
  },
  pro_monthly: {
    id: "pro_monthly",
    name: "Slipe AI Pro Monthly",
    tier: "pro",
    kind: "subscription",
    amountPaise: 59900,
    period: "monthly",
    trialDays: 0,
    maxTotalCount: 360,
  },
  pro_yearly: {
    id: "pro_yearly",
    name: "Slipe AI Pro Yearly",
    tier: "pro",
    kind: "subscription",
    amountPaise: 179900,
    period: "yearly",
    trialDays: 0,
    maxTotalCount: 30,
  },

  // Keep released app versions working while users migrate to the new plans.
  monthly: {
    id: "monthly",
    name: "Slipe AI Pro Monthly (legacy)",
    tier: "pro",
    kind: "subscription",
    amountPaise: 9900,
    period: "monthly",
    trialDays: null,
    maxTotalCount: 360,
    legacy: true,
  },
  max: {
    id: "max",
    name: "Slipe AI Pro Yearly (legacy)",
    tier: "pro",
    kind: "subscription",
    amountPaise: 49900,
    period: "yearly",
    trialDays: null,
    maxTotalCount: 30,
    legacy: true,
  },
};

export function billingPlan(value: unknown): BillingPlanDefinition | null {
  if (typeof value !== "string") return null;
  return BILLING_PLANS[value] ?? null;
}

export function premiumTierForPlan(value: unknown): PremiumTier | null {
  if (typeof value !== "string") return null;
  return BILLING_PLANS[value]?.tier ?? null;
}
