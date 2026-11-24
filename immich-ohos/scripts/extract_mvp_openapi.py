#!/usr/bin/env python3
"""Extract Immich OpenAPI paths needed for the HarmonyOS MVP client."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = Path("/home/ubuntu/immich/open-api/immich-openapi-specs.json")
OUT = ROOT / "docs" / "openapi-mvp.json"

KEEP_PATHS = {
    "/server/ping",
    "/auth/login",
    "/auth/logout",
    "/auth/validateToken",
    "/auth/status",
    "/users/me",
    "/timeline/buckets",
    "/timeline/bucket",
    "/assets",
}


def main() -> None:
    spec = json.loads(UPSTREAM.read_text())
    paths = {k: v for k, v in spec["paths"].items() if k in KEEP_PATHS}
    # Also keep thumbnail path if present
    for key, value in spec["paths"].items():
        if key.startswith("/assets/") and "thumbnail" in key:
            paths[key] = value

    slim = {
        "openapi": spec.get("openapi"),
        "info": {
            "title": "Immich OH MVP",
            "version": spec.get("info", {}).get("version", "unknown"),
        },
        "paths": paths,
        "components": {"schemas": {}},
    }

    # Collect $ref schema names recursively (shallow pass repeated)
    refs: set[str] = set()

    def walk(node: object) -> None:
        if isinstance(node, dict):
            ref = node.get("$ref")
            if isinstance(ref, str) and ref.startswith("#/components/schemas/"):
                refs.add(ref.split("/")[-1])
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for item in node:
                walk(item)

    walk(paths)
    schemas = spec.get("components", {}).get("schemas", {})
    changed = True
    while changed:
        changed = False
        for name in list(refs):
            if name in slim["components"]["schemas"]:
                continue
            schema = schemas.get(name)
            if schema is None:
                continue
            slim["components"]["schemas"][name] = schema
            before = len(refs)
            walk(schema)
            changed = len(refs) > before or name not in slim["components"]["schemas"]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(slim, indent=2) + "\n")
    print(f"Wrote {OUT} with {len(paths)} paths and {len(slim['components']['schemas'])} schemas")


if __name__ == "__main__":
    main()
