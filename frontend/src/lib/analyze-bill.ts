export interface SuspiciousCharge {
  charge: string;
  amount: string;
  reason: string;
  question_to_ask: string;
}

export interface BillReport {
  bill_type: string;
  provider_or_company: string;
  amount_due: string;
  due_date: string;
  risk_score: number;
  risk_level: string;
  recommended_action: string;
  plain_english_summary: string;
  suspicious_charges: SuspiciousCharge[];
  questions_to_ask: string[];
  draft_email: string;
  missing_information: string[];
}

const EMPTY: BillReport = {
  bill_type: "",
  provider_or_company: "",
  amount_due: "",
  due_date: "",
  risk_score: 0,
  risk_level: "",
  recommended_action: "",
  plain_english_summary: "",
  suspicious_charges: [],
  questions_to_ask: [],
  draft_email: "",
  missing_information: [],
};



function looksLikeReport(o: unknown): o is Partial<BillReport> {
  return !!o && typeof o === "object" && ("bill_type" in o || "amount_due" in o || "risk_score" in o || "plain_english_summary" in o);
}

export function parseBillResponse(raw: unknown): BillReport {
  const data = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  const analysis =
    (data.data && typeof data.data === "object" && (data.data as Record<string, unknown>).result) ||
    data.result ||
    raw;

  if (!looksLikeReport(analysis)) {
    throw new Error("Could not parse bill report from backend response.");
  }

  const c = analysis as Partial<BillReport> & Record<string, unknown>;
  return {
    ...EMPTY,
    ...c,
    plain_english_summary:
      c.plain_english_summary ||
      (c.summary as string) ||
      (c.plainEnglishSummary as string) ||
      (c.explanation as string) ||
      "",
    suspicious_charges: Array.isArray(c.suspicious_charges) ? c.suspicious_charges : [],
    questions_to_ask: Array.isArray(c.questions_to_ask) ? c.questions_to_ask : [],
    missing_information: Array.isArray(c.missing_information) ? c.missing_information : [],
    risk_score: typeof c.risk_score === "number" ? c.risk_score : Number(c.risk_score) || 0,
  };
}

export async function analyzeBill(billText: string): Promise<{ report: BillReport; raw: unknown }> {
  const base = typeof window !== "undefined" ? localStorage.getItem("jac_backend_url") : null;
  if (!base) throw new Error("Jac backend URL is missing.");

  const res = await fetch(`/api/analyze-bill`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ bill_text: billText, backend_url: base }),
  });

  const text = await res.text();
  if (!res.ok) {
    try {
      const j = JSON.parse(text);
      throw new Error(j.error || `Proxy error ${res.status}`);
    } catch {
      throw new Error(`Proxy error ${res.status}: ${text || res.statusText}`);
    }
  }

  const json = JSON.parse(text);
  return { report: parseBillResponse(json), raw: json };
}

export async function testBackendConnection(): Promise<{ ok: boolean; status: number; body: string; url: string }> {
  const base = typeof window !== "undefined" ? localStorage.getItem("jac_backend_url") : null;
  if (!base) throw new Error("Jac backend URL is missing.");

  const res = await fetch(`/api/test-backend`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ backend_url: base }),
  });
  const json = (await res.json().catch(() => ({}))) as {
    ok?: boolean;
    status?: number;
    body?: string;
    url?: string;
    error?: string;
  };
  return {
    ok: !!json.ok,
    status: json.status ?? res.status,
    body: json.body ?? json.error ?? "",
    url: json.url ?? `${base.replace(/\/$/, "")}/function/debug_env`,
  };
}

