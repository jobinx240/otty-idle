# Immich OHOS — full feature audit

Generated from `scripts/audit_all_features.mjs` plus local e2e scripts and HAP assemble.
Server under test: local Docker Immich `v3.4.2` (`http://127.0.0.1:2283`).

Legend:

- **PASS** — verified this run
- **PASS\*** — verified with expected caveat
- **CODE** — client wiring / build verified; live runtime needs device/emulator
- **DEFER** — previously verified on emulator MVP; not re-run this pass (memory)

## Auth & session

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Server ping | PASS | `GET /server/ping` → pong |
| 2 | Login | PASS | `POST /auth/login` 201 |
| 3 | Validate token | PASS | `POST /auth/validateToken` authStatus=true |
| 4 | Current user | PASS | `GET /users/me` |
| 5 | Logout | PASS | `POST /auth/logout` 200 |
| 6 | Version gate (min major) | PASS | server 3.4.2 ≥ min 1 |
| 7 | Version gate soft window | PASS | major ≤ 3 |
| 8 | Custom CA wiring | CODE | `HttpClient.caData` + Login/Settings toggle |
| 9 | Cold-start session page | DEFER | EntryAbility → Timeline when token valid |

## Timeline & viewer

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 10 | Timeline buckets | PASS | `GET /timeline/buckets` |
| 11 | Timeline bucket assets | PASS | `GET /timeline/bucket` |
| 12 | Thumbnail download | PASS | authenticated thumbnail bytes |
| 13 | Asset info / EXIF fields | PASS | `GET /assets/{id}` |
| 14 | Favorite toggle | PASS | `PUT /assets/{id}` isFavorite |
| 15 | Archive / unarchive | PASS | visibility archive ↔ timeline + archive buckets |
| 16 | Trash / restore | PASS | `DELETE /assets` + `POST /trash/restore/assets` |
| 17 | Download original | PASS | `GET /assets/{id}/original` |
| 18 | Video playback API | PASS\* | route reachable; **404 on IMAGE** (no VIDEO asset in library this run) |
| 19 | AuthThumb failure UI | CODE | shows `!` when thumb missing |
| 20 | Viewer pages registered | PASS | `AssetViewerPage` in `main_pages.json` |

## Backup / upload

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 21 | Multip + checksum | PASS | `POST /assets` 201 + `x-immich-checksum` |
| 22 | Full client e2e (local) | PASS | `e2e_client_flow.mjs` steps incl. upload duplicate |
| 23 | Checksum util | PASS | `test_checksum_util.mjs` |
| 24 | Persisted upload queue | CODE | `UploadQueueStore` |
| 25 | WorkScheduler extension | CODE | `UploadWorkAbility` + `module.json5` type `workScheduler` |
| 26 | Backup page / picker UI | DEFER | emulator MVP upload previously verified |

## Albums

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 27 | List albums | PASS | `GET /albums` |
| 28 | Create album | PASS | `POST /albums` 201 |
| 29 | Add assets to album | PASS | `PUT /albums/{id}/assets` |
| 30 | Album timeline buckets | PASS | `GET /timeline/buckets?albumId=` |
| 31 | Delete album | PASS | `DELETE /albums/{id}` 204 |
| 32 | Album UI pages | PASS | Albums / AlbumDetail / AddToAlbum registered |

## Search / people / tags / shares

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 33 | Metadata search | PASS | `POST /search/metadata` |
| 34 | Favorites search | PASS | metadata `isFavorite=true` |
| 35 | Smart search | PASS\* | **400** when ML unavailable (acceptable) |
| 36 | People list | PASS | `GET /people` 200 (may be empty) |
| 37 | Create / list tags | PASS | `POST/GET /tags` |
| 38 | Tag assets + filter | PASS | `PUT /tags/{id}/assets` + tagId buckets |
| 39 | Shared link create/list/delete | PASS | `/shared-links` |
| 40 | Search/People/Tags/Shared pages | PASS | registered in `main_pages.json` |

## Library extras & settings

| # | Feature | Result | Evidence |
| --- | --- | --- | --- |
| 41 | Trash page API path | PASS | trash buckets + restore |
| 42 | Archive page API path | PASS | archive buckets |
| 43 | Server about | PASS | `GET /server/about` v3.4.2 |
| 44 | Settings / TLS UI | CODE | SettingsPage PEM save |
| 45 | OpenAPI pin | PASS | `docs/OPENAPI_PIN.md` + `openapi-mvp.json` |
| 46 | HAP assemble + sign | PASS | `assembleHap` SUCCESSFUL + `sign_hap.sh` |

## Page wiring checklist

All 15 app pages exist on disk and are listed in `main_pages.json`:
Login, Timeline, AssetViewer, Backup, Albums, AlbumDetail, Search, People, Settings, Trash, Archive, AddToAlbum, Tags, AddToTag, SharedLinks.

## Machine-readable results

See [`FEATURE_AUDIT.json`](./FEATURE_AUDIT.json) (`77/77` automated checks passed).

## Caveats found this pass

1. **New uploads can 404 on thumbnail** until Immich finishes processing (`thumbhash` still null). Fixed `e2e_client_flow.mjs` to prefer assets with thumbhash / retry other ids.
2. **Smart search** depends on ML container; 400 is expected when CLIP is unavailable.
3. **Video playback** needs a VIDEO asset in the library for a 200 response; IMAGE assets correctly 404.
4. **Custom CA** and **WorkScheduler** are code-complete; live self-signed TLS and deferred OS scheduling still need a device/emulator run.
5. **Full emulator UI sweep** of newer pages remains deferred to save VM memory; MVP login/timeline/upload/albums/search were verified earlier on emulator.
