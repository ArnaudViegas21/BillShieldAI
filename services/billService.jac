"""
BillShield AI — bill analysis service.
Mock analysis logic for immediate use; swap in LLM later.
"""

import re;

obj BillAnalysis {
    has bill_type: str;
    has provider: str;
    has amount_due: str;
    has due_date: str;
    has risk_score: int;
    has risk_level: str;
    has recommended_action: str;
    has suspicious_charges: list[str];
    has summary: str;
    has questions_to_ask: list[str];
    has draft_email: str;
}

def detect_bill_type(text: str) -> str {
    lower = text.lower();
    if "hospital" in lower or "diagnosis" in lower or "patient" in lower {
        return "Medical Bill";
    }
    if "medical" in lower and "claim" in lower {
        return "Medical Bill";
    }
    if "kwh" in lower or "electricity" in lower or "utility" in lower {
        return "Utility Bill";
    }
    if "wireless" in lower or "mobile" in lower or "phone bill" in lower {
        return "Phone Bill";
    }
    if "premium" in lower or "deductible" in lower or "coverage" in lower {
        return "Insurance Bill";
    }
    if "invoice" in lower or "subscription" in lower {
        return "Service Invoice";
    }
    return "General Bill";
}

def extract_amount(text: str) -> str {
    amounts_raw = re.findall(r'\$[\d,]+\.?\d*', text);
    if len(amounts_raw) == 0 {
        return "Not found";
    }
    best = 0.0;
    for raw in amounts_raw {
        cleaned: str = str(raw).replace('$', '').replace(',', '');
        if cleaned.replace('.','').isdigit() {
            val: float = float(cleaned);
            if val > best {
                best = val;
            }
        }
    }
    if best == 0.0 {
        return "Not found";
    }
    if best == float(int(best)) {
        return "$" + str(int(best));
    }
    cents: int = int(best * 100);
    dollars: int = cents // 100;
    rem: int = cents % 100;
    rem_str: str = str(rem) if rem >= 10 else "0" + str(rem);
    return "$" + str(dollars) + "." + rem_str;
}

def extract_due_date(text: str) -> str {
    lower = text.lower();
    date_pat = re.search(r'due\s+(?:date[:\s]+)?(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', lower);
    if date_pat {
        return date_pat.group(1);
    }
    date_pat2 = re.search(r'pay\s+by\s+(\w+\s+\d{1,2},?\s+\d{4})', lower);
    if date_pat2 {
        return date_pat2.group(1);
    }
    date_pat3 = re.search(r'(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})', text);
    if date_pat3 {
        return date_pat3.group(1);
    }
    return "Not specified";
}

def extract_provider(text: str) -> str {
    lower = text.lower();
    providers = [
        "AT&T", "Verizon", "T-Mobile", "Sprint",
        "Blue Cross", "Aetna", "Cigna", "UnitedHealth", "Humana",
        "PG&E", "Con Edison", "Duke Energy", "Xcel Energy",
        "Amazon", "Netflix", "Comcast", "Spectrum",
        "Mayo Clinic", "Cleveland Clinic", "Kaiser",
    ];
    for p in providers {
        if p.lower() in lower {
            return p;
        }
    }
    first_line = text.strip().split('\n')[0].strip();
    if len(first_line) > 2 and len(first_line) < 60 {
        return first_line;
    }
    return "Unknown Provider";
}

def compute_risk_score(text: str, bill_type: str) -> int {
    lower = text.lower();
    score = 20;
    red_flags = [
        "late fee", "penalty", "overdue", "past due", "collection",
        "interest charge", "finance charge", "reconnection fee",
        "duplicate", "administrative fee",
        "facility fee", "processing fee", "convenience fee",
    ];
    for flag in red_flags {
        if flag in lower {
            score = score + 15;
        }
    }
    if bill_type == "Medical Bill" {
        score = score + 20;
        if "out of network" in lower {
            score = score + 15;
        }
        if "itemized" not in lower {
            score = score + 10;
        }
    }
    if score > 100 {
        score = 100;
    }
    return score;
}

def score_to_level(score: int) -> str {
    if score >= 70 {
        return "High";
    }
    if score >= 40 {
        return "Medium";
    }
    return "Low";
}

def get_suspicious_charges(text: str, bill_type: str) -> list[str] {
    lower = text.lower();
    charges: list[str] = [];
    if "late fee" in lower or "penalty" in lower {
        charges.append("Late fee or penalty detected — verify if legitimately owed");
    }
    if "duplicate" in lower {
        charges.append("Possible duplicate charge — request itemized statement");
    }
    if "administrative fee" in lower or "processing fee" in lower {
        charges.append("Administrative/processing fee — often negotiable or waivable");
    }
    if "facility fee" in lower {
        charges.append("Facility fee — ask if this was disclosed before service");
    }
    if bill_type == "Medical Bill" {
        if "out of network" in lower {
            charges.append("Out-of-network charge — verify your coverage and appeal if needed");
        }
        if "itemized" not in lower {
            charges.append("No itemized breakdown — always request a detailed itemized bill");
        }
        charges.append("Verify all procedure codes (CPT codes) match services received");
    }
    if bill_type == "Phone Bill" {
        if "roaming" in lower {
            charges.append("Roaming charges detected — verify if expected");
        }
        charges.append("Check for unauthorized third-party charges (cramming)");
    }
    if bill_type == "Utility Bill" {
        charges.append("Compare usage to same period last year for anomalies");
    }
    if len(charges) == 0 {
        charges.append("No obvious suspicious charges detected — bill appears standard");
    }
    return charges;
}

def get_questions(bill_type: str, risk_level: str) -> list[str] {
    questions: list[str] = [
        "Can you provide a fully itemized breakdown of all charges?",
        "Are there any fees that can be waived or reduced?",
        "Is there a payment plan available if needed?",
    ];
    if bill_type == "Medical Bill" {
        questions.append("Can you verify my insurance was billed correctly?");
        questions.append("Are all procedure codes accurate for the services I received?");
        questions.append("Is there a financial assistance or charity care program?");
        questions.append("Can I speak with a patient advocate about this bill?");
    }
    if bill_type == "Phone Bill" {
        questions.append("Were all charges authorized by me or someone on my account?");
        questions.append("Can you explain any third-party charges on this bill?");
    }
    if bill_type == "Utility Bill" {
        questions.append("Was my meter read accurately this billing period?");
        questions.append("Are there any budget billing or assistance programs available?");
    }
    if bill_type == "Insurance Bill" {
        questions.append("Can you explain exactly what this premium covers?");
        questions.append("Why was this claim denied or only partially covered?");
    }
    if risk_level == "High" {
        questions.append("I believe there may be errors — can I speak with a billing supervisor?");
        questions.append("What is your formal dispute resolution process?");
    }
    return questions;
}

def build_draft_email(provider: str, bill_type: str, amount_due: str, suspicious_charges: list[str]) -> str {
    charges_text = "";
    for c in suspicious_charges {
        charges_text = charges_text + "  - " + c + "\n";
    }
    email = "Subject: Billing Inquiry — Request for Itemized Statement\n\n";
    email = email + "Dear " + provider + " Billing Department,\n\n";
    email = email + "I am writing regarding a recent " + bill_type + " totaling " + amount_due + ". ";
    email = email + "After reviewing the bill, I have identified several items I would like clarified before making payment:\n\n";
    email = email + charges_text + "\n";
    email = email + "I kindly request:\n";
    email = email + "1. A fully itemized statement of all charges\n";
    email = email + "2. Clarification on the items listed above\n";
    email = email + "3. Information on any available payment plans or hardship programs\n\n";
    email = email + "Please respond within 10 business days. I am happy to discuss this further by phone.\n\n";
    email = email + "Thank you for your assistance.\n\n";
    email = email + "Sincerely,\n[Your Name]\n[Your Account Number]\n[Your Contact Information]";
    return email;
}

def generate_summary(bill_type: str, provider: str, amount_due: str, risk_level: str, suspicious_charges: list[str]) -> str {
    summary = "This appears to be a " + bill_type + " from " + provider + " for " + amount_due + ". ";
    if risk_level == "Low" {
        summary = summary + "The bill looks relatively straightforward with no major red flags. ";
        summary = summary + "Still, it's always a good idea to request an itemized statement to verify all charges are accurate.";
    }
    if risk_level == "Medium" {
        summary = summary + "There are some items worth reviewing before you pay. ";
        summary = summary + "We found " + str(len(suspicious_charges)) + " potential concern(s) that you should clarify with the billing department. ";
        summary = summary + "Don't hesitate to call and ask questions — billing errors are common and often correctable.";
    }
    if risk_level == "High" {
        summary = summary + "This bill has several red flags that warrant careful review before payment. ";
        summary = summary + "We strongly recommend requesting a fully itemized statement, verifying all charges, and potentially disputing any errors. ";
        summary = summary + "You have the right to question any charge and request corrections.";
    }
    return summary;
}

def:pub analyze_bill(bill_text: str) -> BillAnalysis {
    if len(bill_text.strip()) == 0 {
        return BillAnalysis(
            bill_type="Unknown",
            provider="Unknown",
            amount_due="N/A",
            due_date="N/A",
            risk_score=0,
            risk_level="Low",
            recommended_action="Please paste bill text to analyze.",
            suspicious_charges=["No bill text provided"],
            summary="No bill text was provided for analysis.",
            questions_to_ask=["Please paste your bill text above and click Analyze Bill."],
            draft_email="No bill text provided."
        );
    }

    bill_type = detect_bill_type(bill_text);
    provider = extract_provider(bill_text);
    amount_due = extract_amount(bill_text);
    due_date = extract_due_date(bill_text);
    risk_score = compute_risk_score(bill_text, bill_type);
    risk_level = score_to_level(risk_score);
    suspicious_charges = get_suspicious_charges(bill_text, bill_type);
    questions = get_questions(bill_type, risk_level);
    summary = generate_summary(bill_type, provider, amount_due, risk_level, suspicious_charges);
    draft_email = build_draft_email(provider, bill_type, amount_due, suspicious_charges);

    action = "";
    if risk_level == "High" {
        action = "Do NOT pay yet. Request itemized statement, verify all charges, and consider filing a formal dispute.";
    } elif risk_level == "Medium" {
        action = "Review flagged items before paying. Call billing support to clarify suspicious charges.";
    } else {
        action = "Bill appears reasonable. Verify charges match services received, then pay by the due date.";
    }

    return BillAnalysis(
        bill_type=bill_type,
        provider=provider,
        amount_due=amount_due,
        due_date=due_date,
        risk_score=risk_score,
        risk_level=risk_level,
        recommended_action=action,
        suspicious_charges=suspicious_charges,
        summary=summary,
        questions_to_ask=questions,
        draft_email=draft_email
    );
}
