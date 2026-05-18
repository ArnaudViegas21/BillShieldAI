# BillShield AI

BillShield AI helps users understand confusing bills before they pay. Users paste bill text from a medical bill, utility bill, phone bill, insurance bill, or service invoice, and the app returns a plain-English breakdown, risk score, charges to verify, questions to ask billing support, and a draft clarification email.

Built for JacHacks as an agentic bill-analysis assistant.

## Demo

- Live frontend: add your Lovable published URL here
- Jac backend endpoint: `/function/analyze_bill`

## What It Does

BillShield AI turns messy bill text into an actionable report:

- Detects bill type
- Extracts provider/company
- Extracts amount due and due date
- Generates a risk score and risk level
- Explains the bill in plain English
- Flags charges to verify
- Suggests questions to ask billing support
- Drafts a clarification email

## Tech Stack

| Layer | Tool |
|---|---|
| Frontend | Lovable |
| Backend / Agent | Jac AI / Jaseci |
| AI Model | Featherless |
| Model API | OpenAI-compatible Featherless chat completions |

## Architecture

```txt
User pastes bill text
        ↓
Lovable frontend
        ↓
Jac backend endpoint: /function/analyze_bill
        ↓
Featherless AI model
        ↓
Structured JSON response
        ↓
BillShield dashboard


How Jac Is Used

Jac powers the backend agent layer. The backend receives bill text, calls Featherless, normalizes the model output into a flat response object, and returns structured analysis to the frontend.

The backend also includes fallback behavior so the demo still works if the model call fails.

How Featherless Is Used

Featherless provides the LLM reasoning layer. The Jac backend sends bill text to Featherless using an OpenAI-compatible chat completion request. Featherless extracts fields, identifies charges to verify, scores risk, and drafts the billing-support email.