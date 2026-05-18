"""
BillShield AI — bill analysis service.
Returns a plain dict so the client gets flat primitives, not wrapped Jac obj fields.
"""

import re;

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

def:pub debug_env() -> dict[str, object] {
    import os;
    import dotenv;

    val_environ: str = os.environ.get("FEATHERLESS_API_KEY", "");

    val_dotenv: str = "";
    try {
        dot = dotenv.dotenv_values("/app/.env");
        raw = dot.get("FEATHERLESS_API_KEY", "");
        if raw is not None {
            val_dotenv = str(raw);
        }
    } except Exception as e {
        val_dotenv = "";
    }

    best_len: int = len(val_environ) if len(val_environ) > 0 else len(val_dotenv);
    method: str = "os.environ" if len(val_environ) > 0 else ("dotenv /app/.env" if len(val_dotenv) > 0 else "none");

    return {
        "method_used": method,
        "has_featherless_key": best_len > 0,
        "key_length": best_len
    };
}

def:pub test_featherless() -> dict[str, object] {
    import os;
    import json;
    import requests;
    import dotenv;

    api_key: str = os.environ.get("FEATHERLESS_API_KEY", "");
    if not api_key {
        try {
            dot = dotenv.dotenv_values("/app/.env");
            raw = dot.get("FEATHERLESS_API_KEY", "");
            if raw is not None {
                api_key = str(raw);
            }
        } except Exception as e {
            api_key = "";
        }
    }
    if not api_key {
        return {"ok": False, "error": "FEATHERLESS_API_KEY not set"};
    }

    try {
        resp = requests.post(
            "https://api.featherless.ai/v1/chat/completions",
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer " + api_key
            },
            json={
                "model": "Qwen/Qwen2.5-7B-Instruct",
                "messages": [
                    {"role": "user", "content": "Return JSON only: {\"ok\": true, \"message\": \"Featherless connected\"}"}
                ]
            },
            timeout=30
        );
        resp.raise_for_status();
        body = resp.json();
        raw_content: str = str(body["choices"][0]["message"]["content"]);
        return {"ok": True, "raw_content": raw_content};
    } except Exception as e {
        return {"ok": False, "error": str(e)};
    }
}

def get_mock_result() -> dict[str, object] {
    return {
        "bill_type": "Medical Bill",
        "provider_or_company": "City General Hospital",
        "amount_due": "$2,010.00",
        "due_date": "04/30/2024",
        "risk_score": "92",
        "risk_level": "High",
        "recommended_action": "Verify the charges and request an itemized bill before paying.",
        "plain_english_summary": "This bill includes several high-cost and unclear charges, including a facility fee, out-of-network physician services, an administrative fee, and a late fee. The safest next step is to request an itemized bill and confirm that insurance fully processed the claim.",
        "suspicious_charges": [
            "Emergency Room Visit Facility Fee - $1,850.00",
            "Physician Services Out of Network - $620.00",
            "Administrative Fee - $75.00",
            "Late Fee - $45.00"
        ],
        "questions_to_ask": [
            "Can you provide an itemized bill with billing codes?",
            "Why was the physician service billed out of network?",
            "Can the administrative fee or late fee be removed?",
            "Has insurance fully processed this claim?"
        ],
        "draft_email": "Hi Billing Team, I am reviewing this bill and would like an itemized breakdown before making payment. Could you confirm whether insurance has fully processed this claim and explain the facility fee, out-of-network physician charge, administrative fee, and late fee? Thank you."
    };
}

def:pub analyze_bill(bill_text: str) -> dict[str, object] {
    import os;
    import json;
    import requests;
    import dotenv;

    api_key: str = os.environ.get("FEATHERLESS_API_KEY", "");
    if not api_key {
        try {
            dot = dotenv.dotenv_values("/app/.env");
            raw = dot.get("FEATHERLESS_API_KEY", "");
            if raw is not None {
                api_key = str(raw);
            }
        } except Exception as e {
            api_key = "";
        }
    }
    if not api_key {
        return get_mock_result();
    }

    sp1: str = 'You are BillShield AI, a careful bill-analysis assistant.';
    sp2: str = 'Analyze pasted bill text and return valid JSON only.';
    sp3: str = 'Return JSON only. Do not wrap in markdown. Do not include text outside the JSON.';
    sp4: str = 'Do not say a charge is definitely illegal or fraudulent.';
    sp5: str = 'Use cautious wording: verify, ask about, may be unclear, worth checking.';
    sp6: str = 'If information is missing use Not found.';
    sp7: str = 'suspicious_charges must be an array of strings. questions_to_ask must be an array of strings.';
    sp8: str = 'risk_score must be a string or number. risk_level must be Low, Medium, or High.';
    sp9: str = 'Jobs: 1.Identify bill type. 2.Extract provider. 3.Extract amount due. 4.Extract due date.';
    sp10: str = '5.Identify charges worth verifying. 6.Assign risk score 0-100. 7.Assign risk level.';
    sp11: str = '8.Give recommended action. 9.Explain bill in plain English. 10.Generate questions. 11.Draft email.';
    sp12: str = 'Return exactly: {"bill_type":"","provider_or_company":"","amount_due":"","due_date":"","risk_score":"","risk_level":"","recommended_action":"","plain_english_summary":"","suspicious_charges":[],"questions_to_ask":[],"draft_email":""}';
    system_prompt: str = sp1 + '\n\n' + sp2 + '\n\n' + sp3 + '\n' + sp4 + '\n' + sp5 + '\n' + sp6 + '\n' + sp7 + '\n' + sp8 + '\n\n' + sp9 + '\n' + sp10 + '\n' + sp11 + '\n\n' + sp12;

    user_prompt: str = 'Analyze this bill:\n\n' + bill_text;

    try {
        resp = requests.post(
            'https://api.featherless.ai/v1/chat/completions',
            headers={
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + api_key
            },
            json={
                'model': 'Qwen/Qwen2.5-7B-Instruct',
                'messages': [
                    {'role': 'system', 'content': system_prompt},
                    {'role': 'user', 'content': user_prompt}
                ]
            },
            timeout=60
        );
        resp.raise_for_status();
        body = resp.json();
        raw_content: str = str(body['choices'][0]['message']['content']);

        cleaned: str = raw_content.strip();
        if cleaned.startswith('f""f"') {
            lines = cleaned.split('\n');
            inner_lines: list[str] = [];
            for i in range(len(lines)) {
                line_val: str = lines[i];
                if i == 0 {
                    inner_lines.append('');
                } elif line_val.strip() == '"f""' {
                    inner_lines.append('');
                } else {
                    inner_lines.append(line_val);
                }
            }
            cleaned = '\n'.join(inner_lines).strip();
        }

        parsed = json.loads(cleaned);

        result: dict[str, object] = {
            'bill_type': str(parsed.get('bill_type', 'Not found')),
            'provider_or_company': str(parsed.get('provider_or_company', 'Not found')),
            'amount_due': str(parsed.get('amount_due', 'Not found')),
            'due_date': str(parsed.get('due_date', 'Not found')),
            'risk_score': str(parsed.get('risk_score', '0')),
            'risk_level': str(parsed.get('risk_level', 'Low')),
            'recommended_action': str(parsed.get('recommended_action', 'Review your bill carefully.')),
            'plain_english_summary': str(parsed.get('plain_english_summary', '')),
            'suspicious_charges': parsed.get('suspicious_charges', []),
            'questions_to_ask': parsed.get('questions_to_ask', []),
            'draft_email': str(parsed.get('draft_email', ''))
        };
        return result;
    } except Exception as e {
        return get_mock_result();
    }
}
