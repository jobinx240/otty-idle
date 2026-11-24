# Device test checklist (personal MVP)

Run in DevEco Studio against your Immich server.

## Prep

1. Immich server reachable from the phone/emulator network.
2. Known login email/password.
3. At least a few photos already on the server (for timeline).

## Cases

| # | Steps | Expected |
| --- | --- | --- |
| 1 | Launch app with empty prefs | Login page |
| 2 | Bad URL → Sign in | Ping / login error message |
| 3 | Valid URL + credentials | Lands on Timeline |
| 4 | Kill app and relaunch | Skips login if token still valid |
| 5 | Timeline grid | Thumbnails load (not only ids) |
| 6 | Tap a cell | Preview viewer opens |
| 7 | Backup → Pick photos → Upload | Rows show `done` or `duplicate` |
| 8 | Refresh timeline / check Immich web | New photo visible |
| 9 | Sign out | Returns to Login; relaunch stays on Login |

## Notes

- Emulator must use a URL the emulator can reach (`10.0.2.2` is Android-style; HarmonyOS emulator networking may differ — prefer a LAN IP or public HTTPS).
- Self-signed HTTPS may fail until P5 TLS bypass is added; use a trusted cert for first tests.


## Local Immich (this agent)

Docker Compose with **host networking** (bridge networking drops inter-container traffic on this VM):

- Compose override: `/home/ubuntu/immich/docker/docker-compose.host.yml`
- URL: `http://127.0.0.1:2283`
- Admin (created by E2E / signup): `admin@local.test` / `Admin12345`
- Full client API flow: `IMMICH_URL=http://127.0.0.1:2283 IMMICH_EMAIL=admin@local.test IMMICH_PASSWORD=Admin12345 node scripts/e2e_client_flow.mjs`
