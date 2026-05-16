"""
BillShield AI — main entry point.
"""

import from services.billService { BillAnalysis, analyze_bill }

cl import ".styles.global.css";

to cl:
import from .index { ClientApp }

def:pub app() -> JsxElement {
    return <ClientApp />;
}
