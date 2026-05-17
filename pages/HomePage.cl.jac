sv import from ..services.billService { analyze_bill }

def:pub page() -> JsxElement {
    has bill_text: str = "";
    has analysis: dict[str, object] | None = None;
    has loading: bool = False;
    has error: str = "";
    has analyze_trigger: int = 0;
    has sample_text: str = "CITY GENERAL HOSPITAL\nPatient: John Smith\nAccount #: 4892-1023\n\nDate of Service: March 15, 2024\nDue Date: 04/30/2024\n\nCharges:\n  Emergency Room Visit (Facility Fee)    $1,850.00\n  Physician Services (Out of Network)    $620.00\n  Lab Work - Blood Panel                 $340.00\n  Radiology - X-Ray                      $280.00\n  Administrative Fee                     $75.00\n  Late Fee (Previous Balance)            $45.00\n\nSubtotal:                                $3,210.00\nInsurance Payment:                       -$1,200.00\n\nTotal Amount Due:                        $2,010.00\n\nPlease pay by 04/30/2024 to avoid additional penalties.\nFor billing questions call: 1-800-555-0199";

    async can with [analyze_trigger] entry {
        if analyze_trigger > 0 {
            loading = True;
            error = "";
            analysis = None;
            try {
                raw = await analyze_bill(bill_text);
                analysis = raw;
            } except Exception as ex {
                error = "Analysis failed: " + str(ex);
            }
            loading = False;
        }
    }

    risk_bg: str = "risk-card-low";
    risk_circle: str = "risk-score-circle-low";
    risk_badge: str = "risk-level-low";

    risk_score: str = "0";
    risk_level: str = "Low";
    recommended_action: str = "";
    bill_type: str = "";
    provider: str = "";
    amount_due: str = "";
    due_date: str = "";
    summary: str = "";
    draft_email: str = "";
    charges: object = [];
    questions: object = [];

    if analysis is not None {
        risk_score = str(analysis["risk_score"]);
        risk_level = str(analysis["risk_level"]);
        recommended_action = str(analysis["recommended_action"]);
        bill_type = str(analysis["bill_type"]);
        provider = str(analysis["provider_or_company"]);
        amount_due = str(analysis["amount_due"]);
        due_date = str(analysis["due_date"]);
        summary = str(analysis["plain_english_summary"]);
        draft_email = str(analysis["draft_email"]);
        charges = analysis["suspicious_charges"];
        questions = analysis["questions_to_ask"];

        if risk_level == "High" {
            risk_bg = "risk-card-high";
            risk_circle = "risk-score-circle-high";
            risk_badge = "risk-level-high";
        } elif risk_level == "Medium" {
            risk_bg = "risk-card-medium";
            risk_circle = "risk-score-circle-medium";
            risk_badge = "risk-level-medium";
        }
    }

    level_prefix: str = "🟢 " if risk_level == "Low" else ("🟡 " if risk_level == "Medium" else "🔴 ");

    return (
        <div className="page">
            <header className="header">
                <div className="container">
                    <div className="header-inner">
                        <div className="header-logo">{"B"}</div>
                        <span className="header-title">{"BillShield AI"}</span>
                        <span className="header-subtitle">{"Understand your bills before you pay"}</span>
                    </div>
                </div>
            </header>

            <main>
                <div className="container">
                    <section className="hero">
                        <div className="hero-badge">
                            <span>{"🛡️"}</span>
                            <span>{"AI-Powered Bill Analysis"}</span>
                        </div>
                        <h1 className="hero-title">
                            {"Stop Overpaying on "}
                            <span>{"Confusing Bills"}</span>
                        </h1>
                        <p className="hero-desc">
                            {"Paste any bill — medical, utility, phone, insurance, or service invoice — and get an instant plain-English analysis with risk scoring and action steps."}
                        </p>
                    </section>

                    <div className="input-card">
                        <label className="input-label">{"Paste your bill text below"}</label>
                        <textarea
                            className="bill-textarea"
                            value={bill_text}
                            onChange={lambda(e: ChangeEvent) -> None { bill_text = e.target.value; }}
                            placeholder={"Paste the full text of your bill here...\n\nTip: Copy all text from your bill (PDF, email, or paper scan) and paste it here for the most accurate analysis."}
                        />
                        <div className="input-actions">
                            <button
                                className="btn btn-primary btn-lg"
                                disabled={loading}
                                onClick={lambda(e: MouseEvent) -> None { analyze_trigger = analyze_trigger + 1; }}
                            >
                                {<span>{"⚡ Analyzing..."}</span> if loading else <span>{"🔍 Analyze Bill"}</span>}
                            </button>
                            <button
                                className="btn btn-outline"
                                onClick={lambda(e: MouseEvent) -> None { bill_text = sample_text; }}
                            >
                                {"📄 Load Sample Bill"}
                            </button>
                            {error and <span style={{"color": "#ef4444", "fontSize": "0.875rem", "alignSelf": "center"}}>{error}</span>}
                        </div>
                    </div>

                    {loading and
                        <div className="loading-state">
                            <div className="spinner"></div>
                            <p>{"Analyzing your bill..."}</p>
                        </div>
                    }

                    {analysis is not None and
                        <div className="results-section">
                            <div className="results-header">
                                <span style={{"fontSize": "1.5rem"}}>{"📊"}</span>
                                <h2 className="results-title">{"Analysis Results"}</h2>
                            </div>

                            <div className={"risk-card " + risk_bg}>
                                <div className={"risk-score-circle " + risk_circle}>
                                    <span className="risk-score-num">{risk_score}</span>
                                    <span className="risk-score-label">{"RISK"}</span>
                                </div>
                                <div className="risk-info">
                                    <div className={"risk-level-badge " + risk_badge}>
                                        {level_prefix + risk_level + " Risk"}
                                    </div>
                                    <div className="risk-action">{recommended_action}</div>
                                </div>
                            </div>

                            <div className="info-grid">
                                <div className="info-tile">
                                    <div className="info-tile-label">{"Bill Type"}</div>
                                    <div className="info-tile-value">{bill_type}</div>
                                </div>
                                <div className="info-tile">
                                    <div className="info-tile-label">{"Provider"}</div>
                                    <div className="info-tile-value">{provider}</div>
                                </div>
                                <div className="info-tile">
                                    <div className="info-tile-label">{"Amount Due"}</div>
                                    <div className="info-tile-value" style={{"color": "#2563eb"}}>{amount_due}</div>
                                </div>
                                <div className="info-tile">
                                    <div className="info-tile-label">{"Due Date"}</div>
                                    <div className="info-tile-value">{due_date}</div>
                                </div>
                            </div>

                            <div className="detail-card">
                                <div className="detail-card-title">
                                    <div className="detail-card-icon" style={{"background": "#dbeafe"}}>{"📝"}</div>
                                    {"Plain-English Summary"}
                                </div>
                                <p className="summary-text">{summary}</p>
                            </div>

                            <div className="detail-card">
                                <div className="detail-card-title">
                                    <div className="detail-card-icon" style={{"background": "#fef3c7"}}>{"⚠️"}</div>
                                    {"Suspicious Charges"}
                                </div>
                                <ul className="charge-list">
                                    {charges and [<li className="charge-item">
                                        <span className="charge-dot"></span>
                                        <span>{str(item)}</span>
                                    </li> for item in charges]}
                                </ul>
                            </div>

                            <div className="detail-card">
                                <div className="detail-card-title">
                                    <div className="detail-card-icon" style={{"background": "#dcfce7"}}>{"❓"}</div>
                                    {"Questions to Ask Billing Support"}
                                </div>
                                <ul className="question-list">
                                    {questions and [<li className="question-item">
                                        <span className="question-num">{"•"}</span>
                                        <span>{str(item)}</span>
                                    </li> for item in questions]}
                                </ul>
                            </div>

                            <div className="detail-card">
                                <div className="detail-card-title">
                                    <div className="detail-card-icon" style={{"background": "#ede9fe"}}>{"✉️"}</div>
                                    {"Draft Clarification Email"}
                                </div>
                                <p style={{"fontSize": "0.8rem", "color": "#64748b", "marginBottom": "0.5rem"}}>
                                    {"Select all text below and copy to use this email template:"}
                                </p>
                                <textarea
                                    className="email-box"
                                    readOnly={True}
                                    value={draft_email}
                                    style={{"width": "100%", "minHeight": "200px", "resize": "vertical"}}
                                />
                            </div>
                        </div>
                    }

                    <div className="features-strip">
                        <div className="feature-item">
                            <span className="feature-icon">{"🔒"}</span>
                            <span>{"Private & Secure"}</span>
                        </div>
                        <div className="feature-item">
                            <span className="feature-icon">{"⚡"}</span>
                            <span>{"Instant Analysis"}</span>
                        </div>
                        <div className="feature-item">
                            <span className="feature-icon">{"📋"}</span>
                            <span>{"All Bill Types"}</span>
                        </div>
                        <div className="feature-item">
                            <span className="feature-icon">{"✉️"}</span>
                            <span>{"Draft Email Included"}</span>
                        </div>
                    </div>
                </div>
            </main>

            <footer className="footer">
                {"BillShield AI — Helping you understand every bill. Not legal or financial advice."}
            </footer>
        </div>
    );
}
