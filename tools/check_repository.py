#!/usr/bin/env python3
"""Check local registry, entry files, active MATLAB paths and document links.

No MATLAB, network, or third-party Python package is needed. --source-only
allows intentionally omitted saved evidence/results and external paper assets.
This checks repository consistency; run_all_tests checks MATLAB behavior.
"""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
from urllib.parse import unquote


def check(root, source_only=False):
    errors, optional = [], []
    registry = json.loads((root / "registry/reproductions.json").read_text())
    algorithms = json.loads((root / "registry/algorithms.json").read_text())["algorithms"]
    papers = json.loads((root / "registry/papers.json").read_text())["papers"]
    modules = json.loads((root / "registry/modules.json").read_text())["modules"]
    methods = registry["methods"]
    project = json.loads((root / "registry/project.json").read_text())
    citation = dict(line.split(":", 1) for line in (root / "CITATION.cff").read_text().splitlines()
                    if line.startswith(("version:", "license:")))
    for key in ("version", "license"):
        if citation.get(key, "").strip().strip("\"'") != project[key]:
            errors.append("Citation and project metadata disagree: " + key)
    if project["license"] != "pending" and not (root / "LICENSE").is_file():
        errors.append("Declared software license has no LICENSE file")
    current_records = [m["evidence"] for m in [registry["baseline"]] + methods]
    current_records += [registry["integration_evidence"], registry["integration_source_hashes"]]
    current_records += registry["entry_validation_evidence"]
    for rel in current_records:
        if not (root / rel).is_file():
            errors.append("Missing current evidence record: " + rel)
    ids = [registry["baseline"]["id"]] + [m["id"] for m in methods]
    if len(ids) != len(set(ids)):
        errors.append("Duplicate method IDs in registry/reproductions.json")
    algorithm_ids, paper_ids = {a["id"] for a in algorithms}, {p["id"] for p in papers}
    for method in methods:
        folder = root / method["directory"]
        for rel in [method["directory"] + "/" + method["entry_point"] + ".m", method["fulltext_card"]]:
            if not (root / rel).is_file():
                errors.append("Missing registered entry/card: " + rel)
        if method["algorithm_id"] not in algorithm_ids or method["paper_id"] not in paper_ids:
            errors.append("Unresolved algorithm/paper ID: " + method["id"])
        paper = next((p for p in papers if p["id"] == method["paper_id"]), {})
        if paper.get("implementation_directory") != method["directory"]:
            errors.append("Paper and implementation directory disagree: " + method["id"])
        if not isinstance(method.get("runs_neural_training"), bool) or not isinstance(method.get("required_products"), list):
            errors.append("Missing training/dependency declaration: " + method["id"])
        if method.get("recorded_tests", 0) and not list(folder.glob("test*.m")):
            errors.append("Recorded tests have no test file: " + method["id"])
        if not (folder / "README.md").is_file():
            errors.append("Missing method README: " + method["id"])
    archived = {"evidence", "results", "runs"}
    sources = [p for p in root.rglob("*.m") if not archived.intersection(p.relative_to(root).parts)]
    public_names = defaultdict(list)
    for path in sources:
        rel = path.relative_to(root)
        if not any(part.startswith("+") for part in rel.parts):
            public_names[path.stem].append(str(rel))
        text = path.read_text()
        # Tests include deliberately invalid absolute-path fixtures.
        if not path.name.startswith("test") and re.search(r"['\"](?:/Users/|/Applications/|[A-Z]:\\)", text):
            errors.append("Machine-specific path in active MATLAB file: " + str(rel))
        if not path.name.startswith("test") and re.search(r"fullfile\([^\n]*'(?:evidence|results)'", text):
            errors.append("New run routed into frozen history: " + str(rel))
    for name, files in public_names.items():
        if len(files) > 1:
            errors.append("Active function name collision: " + name + ": " + ", ".join(files))
    # Old logs, source snapshots and bibliographic retrieval notes remain
    # historical records. Check the maintained user-facing pages instead.
    docs = list(root.glob("*.md")) + [
        p for p in (root / "docs").rglob("*.md") if "literature" not in p.parts
    ] + [p for p in (root / "reproductions").rglob("*.md") if not archived.intersection(p.relative_to(root).parts)]
    for doc in docs:
        content = re.sub(r"```.*?```|~~~.*?~~~", "", doc.read_text(), flags=re.S)
        for target in re.findall(r"\]\((<[^>]+>|[^)\n]+)\)", content):
            target = target.strip("<>").split("#", 1)[0]
            if not target or re.match(r"[a-zA-Z][\w+.-]*:", target):
                continue
            path = (doc.parent / unquote(target)).resolve()
            if path.exists():
                continue
            try:
                rel = path.relative_to(root.resolve())
            except ValueError:
                optional.append({"document": str(doc.relative_to(root)), "external_asset": target})
                continue
            if source_only and archived.intersection(rel.parts):
                optional.append({"document": str(doc.relative_to(root)), "saved_evidence": target})
            else:
                errors.append(f"Broken local link in {doc.relative_to(root)}: {target}")
    return {
        "scope": "source_only" if source_only else "full_directory",
        "methods_including_baseline": len(ids), "active_matlab_files": len(sources),
        "algorithms": dict(Counter(a["status"] for a in algorithms)),
        "modules": dict(Counter(m["status"] for m in modules)),
        "errors": errors, "optional_or_external_assets": optional,
        "passed": not errors,
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--source-only", action="store_true")
    parser.add_argument("--json", type=Path, help="Optional output record; otherwise print only")
    args = parser.parse_args()
    report = check(args.root.resolve(), args.source_only)
    text = json.dumps(report, ensure_ascii=False, indent=2)
    print(text)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(text + "\n")
    raise SystemExit(0 if report["passed"] else 1)
