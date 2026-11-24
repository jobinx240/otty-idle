# Immich HarmonyOS Client (personal)

ArkTS client for a self-hosted [Immich](https://immich.app) server. **Client only** — do not replace the Immich server with this repo.

Upstream Immich commit used as API reference: see `.immich-upstream-ref`.

## Status

P0–P3 **code** for login, authenticated timeline thumbs, preview viewer, and foreground photo upload.
Device verification still required (no HarmonyOS SDK in this environment). See [docs/PLAN.md](docs/PLAN.md) and [docs/DEVICE_TEST.md](docs/DEVICE_TEST.md).

## Layout

- `entry/` — main application module (ArkTS)
- `docs/PLAN.md` — phased plan
- `docs/DEVICE_TEST.md` — personal MVP checklist
- `scripts/` — OpenAPI extract + small Node sanity checks

## License note

Immich itself is AGPL-3.0. This personal client is written against the public HTTP API and does not copy Immich Flutter/Kotlin sources. If you later distribute a derivative of Immich code, follow AGPL. For private self-use of an independent client, keep trademarks (do not brand as official Immich).
