import { createFileRoute } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { analyzeBill, testBackendConnection, type BillReport } from "@/lib/analyze-bill";
import { SAMPLE_BILL } from "@/lib/sample-bill";
import {
  Shield,
  ShieldAlert,
  Sparkles,
  Loader2,
  AlertTriangle,
  Copy,
  Check,
  FileText,
  Building2,
  DollarSign,
  Calendar,
  HelpCircle,
  Mail,
  ListChecks,
} from "lucide-react";

export const Route = createFileRoute("/")({
  component: Index,
  head: () => ({
    meta: [
      { title: "BillShield AI — Understand the bill before you pay it." },
      {
        name: "description",
        content:
          "Paste any medical, utility, phone, insurance, or service bill and get a plain-English analysis, risk score, and a draft email to billing support.",
      },
      { property: "og:title", content: "BillShield AI" },
      { property: "og:description", content: "Understand the bill before you pay it." },
    ],
  }),
});

function riskTone(level: string, score: number) {
  const l = (level || "").toLowerCase();
  if (l.includes("high") || score >= 70) return { label: "High risk", cls: "bg-[color:var(--danger)]/10 text-[color:var(--danger)] border-[color:var(--danger)]/30" };
  if (l.includes("med") || score >= 40) return { label: "Medium risk", cls: "bg-[color:var(--warning)]/10 text-[color:var(--warning)] border-[color:var(--warning)]/30" };
  return { label: "Low risk", cls: "bg-[color:var(--success)]/10 text-[color:var(--success)] border-[color:var(--success)]/30" };
}

function Index() {
  const [billText, setBillText] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [report, setReport] = useState<BillReport | null>(null);
  const [rawResponse, setRawResponse] = useState<unknown>(null);
  const [copied, setCopied] = useState(false);
  const [backendUrl, setBackendUrl] = useState("");
  const [testResult, setTestResult] = useState<string | null>(null);
  const [testing, setTesting] = useState(false);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("jac_backend_url") || "";
      setBackendUrl(saved);
    }
  }, []);

  function saveBackendUrl(v: string) {
    setBackendUrl(v);
    if (typeof window !== "undefined") {
      if (v.trim()) localStorage.setItem("jac_backend_url", v.trim());
      else localStorage.removeItem("jac_backend_url");
    }
  }

  async function onTestConnection() {
    setTesting(true);
    setTestResult(null);
    try {
      const r = await testBackendConnection();
      setTestResult(
        `${r.ok ? "Reachable" : "Unreachable"} (${r.status}) — ${r.url}${r.body ? ` · ${r.body.slice(0, 200)}` : ""}`,
      );
    } catch (e) {
      setTestResult(e instanceof Error ? e.message : "Connection failed.");
    } finally {
      setTesting(false);
    }
  }

  async function onAnalyze() {
    if (!billText.trim()) {
      setError("Paste a bill first, or try a sample.");
      return;
    }
    setLoading(true);
    setError(null);
    setReport(null);
    setRawResponse(null);
    try {
      const { report: r, raw } = await analyzeBill(billText);
      setReport(r);
      setRawResponse(raw);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong.");
    } finally {
      setLoading(false);
    }
  }

  async function copyEmail() {
    if (!report?.draft_email) return;
    await navigator.clipboard.writeText(report.draft_email);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  }

  return (
    <div className="min-h-screen" style={{ background: "var(--gradient-soft)" }}>
      {/* Header */}
      <header className="border-b border-border/60 backdrop-blur bg-background/60 sticky top-0 z-10">
        <div className="mx-auto max-w-6xl px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div
              className="h-9 w-9 rounded-xl flex items-center justify-center text-primary-foreground shadow"
              style={{ background: "var(--gradient-brand)" }}
            >
              <Shield className="h-5 w-5" />
            </div>
            <span className="font-semibold tracking-tight">BillShield AI</span>
          </div>
          <Badge variant="outline" className="gap-1.5">
            <Sparkles className="h-3 w-3" /> Hackathon demo
          </Badge>
        </div>
      </header>

      {/* Hero */}
      <section className="mx-auto max-w-4xl px-6 pt-16 pb-10 text-center">
        <h1 className="text-5xl md:text-6xl font-bold tracking-tight bg-clip-text text-transparent" style={{ backgroundImage: "var(--gradient-brand)" }}>
          BillShield AI
        </h1>
        <p className="mt-4 text-lg md:text-xl text-muted-foreground">
          Understand the bill before you pay it.
        </p>
        <p className="mt-2 text-sm text-muted-foreground/80 max-w-xl mx-auto">
          Paste any medical, utility, phone, insurance, or service bill. We'll flag suspicious
          charges, score the risk, and draft an email to billing support.
        </p>
      </section>

      {/* Input card */}
      <section className="mx-auto max-w-4xl px-6 pb-10">
        <div
          className="rounded-2xl bg-card border border-border p-6 md:p-8"
          style={{ boxShadow: "var(--shadow-soft)" }}
        >
          <label className="text-sm font-medium text-foreground">Paste your bill text</label>
          <Textarea
            value={billText}
            onChange={(e) => setBillText(e.target.value)}
            placeholder="Paste the full text of your bill here — line items, totals, due date, provider…"
            className="mt-2 min-h-56 resize-y font-mono text-sm"
          />

          <div className="mt-4 flex flex-col sm:flex-row gap-3 sm:items-center sm:justify-between">
            <Button
              type="button"
              variant="outline"
              onClick={() => {
                setBillText(SAMPLE_BILL);
                setError(null);
              }}
            >
              <FileText className="h-4 w-4" /> Load Sample Bill
            </Button>
            <Button
              type="button"
              size="lg"
              onClick={onAnalyze}
              disabled={loading}
              className="text-primary-foreground border-0"
              style={{ background: "var(--gradient-brand)" }}
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" /> Analyzing…
                </>
              ) : (
                <>
                  <ShieldAlert className="h-4 w-4" /> Analyze Bill
                </>
              )}
            </Button>
          </div>

          <p className="mt-3 text-xs text-muted-foreground/70 font-mono">
            Calling Jac backend: /function/analyze_bill
          </p>

          {error && (
            <div className="mt-4 flex items-start gap-2 rounded-lg border border-[color:var(--danger)]/30 bg-[color:var(--danger)]/5 p-3 text-sm text-[color:var(--danger)]">
              <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}
        </div>
      </section>

      {/* Loading skeleton */}
      {loading && (
        <section className="mx-auto max-w-5xl px-6 pb-20">
          <div className="grid gap-4 md:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-28 rounded-2xl bg-card border border-border animate-pulse" />
            ))}
          </div>
          <div className="mt-4 h-48 rounded-2xl bg-card border border-border animate-pulse" />
        </section>
      )}

      {/* Results */}
      {report && !loading && <Dashboard report={report} onCopyEmail={copyEmail} copied={copied} rawResponse={rawResponse} />}

      {/* Developer settings */}
      <section className="mx-auto max-w-4xl px-6 pb-10">
        <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
          <h2 className="text-sm font-semibold">Developer settings</h2>
          <label className="mt-3 block text-xs text-muted-foreground">Jac Backend URL</label>
          <Input
            value={backendUrl}
            onChange={(e) => saveBackendUrl(e.target.value)}
            placeholder="https://jac-sbx-....jaseci.org"
            className="mt-1 font-mono text-xs"
          />
          <div className="mt-3 flex items-center gap-3">
            <Button type="button" variant="outline" size="sm" onClick={onTestConnection} disabled={testing || !backendUrl}>
              {testing ? <><Loader2 className="h-3 w-3 animate-spin" /> Testing…</> : "Test Backend Connection"}
            </Button>
            {testResult && <span className="text-xs text-muted-foreground">{testResult}</span>}
          </div>
        </div>
      </section>

      <footer className="py-10 text-center text-xs text-muted-foreground">
        Powered by a Jac backend walker · <code className="font-mono">analyze_bill</code>
      </footer>
    </div>
  );
}

function Dashboard({
  report,
  onCopyEmail,
  copied,
  rawResponse,
}: {
  report: BillReport;
  onCopyEmail: () => void;
  copied: boolean;
  rawResponse?: unknown;
}) {
  const [showRaw, setShowRaw] = useState(false);
  const tone = riskTone(report.risk_level, report.risk_score);
  const score = Math.max(0, Math.min(100, Number(report.risk_score) || 0));

  return (
    <section className="mx-auto max-w-5xl px-6 pb-20 space-y-6">
      {/* Top metrics */}
      <div className="grid gap-4 md:grid-cols-4">
        <MetricCard icon={<FileText className="h-4 w-4" />} label="Bill type" value={report.bill_type || "—"} />
        <MetricCard icon={<Building2 className="h-4 w-4" />} label="Provider" value={report.provider_or_company || "—"} />
        <MetricCard icon={<DollarSign className="h-4 w-4" />} label="Amount due" value={report.amount_due || "—"} />
        <MetricCard icon={<Calendar className="h-4 w-4" />} label="Due date" value={report.due_date || "—"} />
      </div>

      {/* Risk + recommendation */}
      <div className="grid gap-4 md:grid-cols-3">
        <div className="rounded-2xl bg-card border border-border p-6 md:col-span-1" style={{ boxShadow: "var(--shadow-soft)" }}>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Risk score</span>
            <span className={`text-xs px-2 py-1 rounded-full border ${tone.cls}`}>{report.risk_level || tone.label}</span>
          </div>
          <div className="mt-3 flex items-baseline gap-1">
            <span className="text-5xl font-bold tracking-tight">{score}</span>
            <span className="text-muted-foreground">/100</span>
          </div>
          <div className="mt-4 h-2 rounded-full bg-muted overflow-hidden">
            <div
              className="h-full rounded-full transition-all"
              style={{
                width: `${score}%`,
                background:
                  score >= 70
                    ? "var(--danger)"
                    : score >= 40
                    ? "var(--warning)"
                    : "var(--success)",
              }}
            />
          </div>
        </div>

        <div className="rounded-2xl bg-card border border-border p-6 md:col-span-2" style={{ boxShadow: "var(--shadow-soft)" }}>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <ShieldAlert className="h-4 w-4" /> Recommended action
          </div>
          <p className="mt-2 text-lg font-medium">{report.recommended_action || "—"}</p>
        </div>
      </div>

      {/* Plain-English Summary */}
      {report.plain_english_summary && (
        <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
          <h2 className="font-semibold">Plain-English Summary</h2>
          <p className="mt-2 text-sm text-muted-foreground leading-relaxed">
            {report.plain_english_summary}
          </p>
        </div>
      )}

      {report.suspicious_charges.length > 0 && (
        <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
          <h2 className="font-semibold flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 text-[color:var(--warning)]" /> Charges to Verify
          </h2>
          <div className="mt-4 divide-y divide-border">
            {report.suspicious_charges.map((c, i) => (
              <div key={i} className="py-4 grid gap-2 md:grid-cols-[1fr_auto]">
                <div>
                  <div className="font-medium">{c.charge || "Charge"}</div>
                  <div className="text-sm text-muted-foreground mt-1">{c.reason}</div>
                  {c.question_to_ask && (
                    <div className="mt-2 text-sm text-foreground/80 italic">
                      Ask: "{c.question_to_ask}"
                    </div>
                  )}
                </div>
                <div className="text-right font-mono text-sm md:text-base self-start">
                  {c.amount}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Questions + missing info */}
      <div className="grid gap-4 md:grid-cols-2">
        {report.questions_to_ask.length > 0 && (
          <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
            <h2 className="font-semibold flex items-center gap-2">
              <HelpCircle className="h-4 w-4 text-primary" /> Questions to ask billing
            </h2>
            <ul className="mt-3 space-y-2 text-sm">
              {report.questions_to_ask.map((q, i) => (
                <li key={i} className="flex gap-2">
                  <span className="text-primary">·</span>
                  <span>{q}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
        {report.missing_information.length > 0 && (
          <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
            <h2 className="font-semibold flex items-center gap-2">
              <ListChecks className="h-4 w-4 text-primary" /> Missing information
            </h2>
            <ul className="mt-3 space-y-2 text-sm">
              {report.missing_information.map((m, i) => (
                <li key={i} className="flex gap-2">
                  <span className="text-muted-foreground">·</span>
                  <span>{m}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {/* Draft email */}
      {report.draft_email && (
        <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
          <div className="flex items-center justify-between">
            <h2 className="font-semibold flex items-center gap-2">
              <Mail className="h-4 w-4 text-primary" /> Draft email to billing support
            </h2>
            <Button size="sm" variant="outline" onClick={onCopyEmail}>
              {copied ? (
                <>
                  <Check className="h-4 w-4" /> Copied
                </>
              ) : (
                <>
                  <Copy className="h-4 w-4" /> Copy email
                </>
              )}
            </Button>
          </div>
          <pre className="mt-4 whitespace-pre-wrap text-sm leading-relaxed bg-muted/50 rounded-lg p-4 border border-border">
{report.draft_email}
          </pre>
        </div>
      )}

      {/* Raw response debug */}
      <div className="rounded-2xl bg-card border border-border p-6" style={{ boxShadow: "var(--shadow-soft)" }}>
        <button
          type="button"
          onClick={() => setShowRaw((v) => !v)}
          className="text-sm font-medium text-primary hover:underline"
        >
          {showRaw ? "Hide raw response" : "Show raw response"}
        </button>
        {showRaw && rawResponse !== null && (
          <pre className="mt-4 overflow-auto text-xs bg-muted/50 rounded-lg p-4 border border-border max-h-96">
            {JSON.stringify(rawResponse, null, 2)}
          </pre>
        )}
      </div>
    </section>
  );
}

function MetricCard({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-2xl bg-card border border-border p-5" style={{ boxShadow: "var(--shadow-soft)" }}>
      <div className="flex items-center gap-2 text-xs uppercase tracking-wide text-muted-foreground">
        {icon} {label}
      </div>
      <div className="mt-2 text-lg font-semibold truncate" title={value}>
        {value}
      </div>
    </div>
  );
}
