import subprocess
from io import StringIO
from pathlib import Path
from pprint import pprint

js = eval(
    (
        Path("guardrails_from_js.js")
        .read_text()
        .replace("            ", '            "')
        .replace(": new Set", '": new Set')
        .replace(": new Map", '": new Map')
        .replace(": '", "\": '")
        .replace(': "', '": "')
        .replace("new Set,", "set(),")
        .replace("new Map,", "{},")
        .replace("new Set", "Set")
        .replace("new Map", "Map")
    ),
    {"__builtins__": "", "Set": set, "Map": dict},
)


Path("guardrails_from_js.py").write_text(
    "guardrails = "
    + subprocess.check_output(
        ["/opt/homebrew/bin/black", "--quiet", "-"],
        input=repr(js).replace("<class 'dict'>", "{}").encode("utf-8"),
    ).decode("utf-8")
)
