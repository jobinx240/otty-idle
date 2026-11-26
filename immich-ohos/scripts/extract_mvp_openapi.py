#!/usr/bin/env python3
"""Extract Immich OpenAPI paths used by the HarmonyOS client and pin the upstream version."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = Path("/home/ubuntu/immich/open-api/immich-openapi-specs.json")
OUT = ROOT / "docs" / "openapi-mvp.json"
PIN = ROOT / "docs" / "OPENAPI_PIN.md"
UPSTREAM_REF = ROOT / ".immich-upstream-ref"

KEEP_PATHS = {
    "/server/ping",
    "/server/about",
    "/server/version",
    "/auth/login",
    "/auth/logout",
    "/auth/validateToken",
    "/auth/status",
    "/users/me",
    "/timeline/buckets",
    "/timeline/bucket",
    "/assets",
    "/albums",
    "/albums/{id}",
    "/albums/{id}/assets",
    "/search/metadata",
    "/search/smart",
    "/people",
    "/trash/empty",
    "/trash/restore",
    "/trash/restore/assets",
    "/tags",
    "/tags/{id}/assets",
    "/shared-links",
    "/shared-links/{id}",
}

PREFIX_KEEP = (
    "/assets/",
)


def main() -> None:
    spec = json.loads(UPSTREAM.read_text())
    paths = {k: v for k, v in spec["paths"].items() if k in KEEP_PATHS}
    for key, value in spec["paths"].items():
        if any(key.startswith(p) for p in PREFIX_KEEP):
            paths[key] = value

    info_version = spec.get("info", {}).get("version", "unknown")
    slim = {
        "openapi": spec.get("openapi"),
        "info": {
            "title": "Immich OH client API subset",
            "version": info_version,
        },
        "paths": paths,
        "components": {"schemas": {}},
    }

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

    upstream_ref = UPSTREAM_REF.read_text().strip() if UPSTREAM_REF.exists() else "unknown"
    PIN.write_text(
        "\n".join(
            [
                "# Immich OpenAPI pin",
                "",
                f"- Upstream git ref (`.immich-upstream-ref`): `{upstream_ref}`",
                f"- OpenAPI `info.version`: `{info_version}`",
                f"- Extracted paths: `{len(paths)}`",
                f"- Extracted schemas: `{len(slim['components']['schemas'])}`",
                f"- Artifact: `docs/openapi-mvp.json` (regenerate with `scripts/extract_mvp_openapi.py`)",
                "",
                "This HarmonyOS client is written against the pinned subset above.",
                "Re-run the extract script after bumping `.immich-upstream-ref`.",
                "",
            ]
        )
    )
    print(f"Wrote {OUT} with {len(paths)} paths and {len(slim['components']['schemas'])} schemas")
    print(f"Wrote {PIN}")


if __name__ == "__main__":
    main()
