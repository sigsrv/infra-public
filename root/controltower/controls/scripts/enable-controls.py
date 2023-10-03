import json
from dataclasses import dataclass
from typing import Literal

import boto3
from mypy_boto3_controltower import ControlTowerClient
from mypy_boto3_organizations import OrganizationsClient
from mypy_boto3_sts import STSClient

from guardrails_from_js import guardrails as guardrails_js
from guardrails_from_api import guardrails as guardrails_api

boto3.setup_default_session(profile_name="ecmaxp-root")
sts: STSClient = boto3.client("sts")
organizations: OrganizationsClient = boto3.client("organizations")
controltower: ControlTowerClient = boto3.client("controltower")


@dataclass
class Guardrail:
    identifier: str
    name: str
    behavior: Literal["PROACTIVE", "PREVENTIVE", "DETECTIVE"]
    implementationTypes: str
    services: str
    frameworks: str
    frameworksIds: str
    controlObjectives: str
    releaseDate: str
    description: str
    resourceTypes: str
    controlOwner: Literal["AWS Security Hub", "AWS Control Tower"]
    guidance: Literal["Strongly-Recommended", "Elective", "Mandatory"]
    severity: Literal["CRITICAL", "MEDIUM", "LOW", "HIGH"]


available_guardrails = set(guardrail.Name for guardrail in guardrails_api)
guardrails = [
    Guardrail(**guardrail)
    for guardrail in guardrails_js
    if guardrail["identifier"] in available_guardrails
]
assert len(guardrails) == 426, ("2023-09-27", len(guardrails))

account_id = "788437082016"
aws_region = "ap-northeast-2"

guardrail_arn_prefix = f"arn:aws:controltower:{aws_region}::control/"
selected_guardrails = set()
for guardrail in guardrails:
    if guardrail.guidance == "Mandatory":
        continue
    elif (
        guardrail.guidance == "Strongly-Recommended" or guardrail.severity == "CRITICAL"
    ):
        selected_guardrails.add(f"{guardrail_arn_prefix}{guardrail.identifier}")


workload_ou_id = "ou-uziz-nvxbvm6a"
workload_ou_name = "Workloads"
workload_ou = organizations.describe_organizational_unit(
    OrganizationalUnitId=workload_ou_id
)["OrganizationalUnit"]
assert workload_ou["Name"] == workload_ou_name
workload_ou_arn = workload_ou["Arn"]

enabled_controls = set()
for page in controltower.get_paginator("list_enabled_controls").paginate(
    targetIdentifier=workload_ou_arn
):
    for control in page["enabledControls"]:
        enabled_controls.add(control["controlIdentifier"])

assert enabled_controls & enabled_controls, "2023-09-27"
print(
    json.dumps(
        sorted(
            guardrail_arn.removeprefix(guardrail_arn_prefix)
            for guardrail_arn in selected_guardrails
        ),
        indent=4,
    )
)
