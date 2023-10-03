import json
from dataclasses import dataclass
from pathlib import Path
from typing import Literal


@dataclass
class Guardrail:
    Behavior: Literal["PREVENTIVE", "DETECTIVE", "PROACTIVE"]
    Category: Literal[
        "Audit Logs",
        "Monitoring",
        "Data Residency",
        "Control Tower Setup",
        "Operations",
        "Data Security",
        "IAM",
        "None",
        "Network",
    ]
    Description: str
    DisplayName: str
    Name: str
    Provider: Literal["Amazon"]
    RegionalPreference: Literal["GLOBAL", "REGIONAL", "HOME_REGION"]
    Type: Literal["Mandatory", "Elective", "Strongly-Recommended"]


raw_guardrails = json.loads(Path("guardrails_from_api.json").read_text())

guardrails = [
    Guardrail(**guardrail)
    for item in raw_guardrails
    for guardrail in item["GuardrailList"]
]

assert len(guardrails) == 426, "2023-09-27"
