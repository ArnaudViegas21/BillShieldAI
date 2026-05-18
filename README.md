# BillShield AI

BillShield AI is an agentic bill-analysis assistant that helps users understand confusing bills before they pay. Users paste bill text from a medical bill, utility bill, phone bill, insurance bill, or service invoice, and the app returns a structured breakdown with key details, a risk score, charges to verify, plain-English guidance, billing questions, and a draft clarification email.

Built for **JacHacks** using **Lovable**, **Jac AI / Jaseci**, and **Featherless**.

---

## Live Demo

- **Frontend:** https://lovable.dev/projects/b96861ec-7c51-4e71-a072-5150476d958d
- **Backend Endpoint:** `/function/analyze_bill`

---

## Problem

Bills are often confusing, vague, and stressful. People may see facility fees, administrative fees, roaming charges, late fees, out-of-network charges, or unclear service fees without knowing what they mean or whether they should ask questions before paying.

BillShield AI turns messy billing language into clear next steps.

---

## What It Does

BillShield AI analyzes pasted bill text and returns an actionable report:

- Detects the bill type
- Extracts the provider or company
- Extracts amount due and due date
- Identifies important line items
- Flags charges worth verifying
- Generates a risk score and risk level
- Explains the bill in plain English
- Suggests questions to ask billing support
- Drafts a clarification email the user can send

---

## Example Use Case

A user receives a bill with unclear charges such as:

- Facility fee
- Administrative fee
- Late fee
- Out-of-network service
- International roaming charge
- Service or processing fee

Instead of blindly paying or ignoring the bill, the user pastes it into BillShield AI and receives a clear explanation, questions to ask, and a professional email draft.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Frontend | Lovable |
| Backend / Agent | Jac AI / Jaseci |
| AI Model Provider | Featherless |
| Model API | OpenAI-compatible Featherless Chat Completions |
| Deployment | Lovable frontend + Jac sandbox backend |

---

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