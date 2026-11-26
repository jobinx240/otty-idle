# Immich HarmonyOS Client — Development Plan

Personal-use client only. Server stays stock Immich (Docker / existing deploy).
Upstream reference: Immich `main` @ see `.immich-upstream-ref`.

## Goal

Ship a HarmonyOS NEXT (ArkTS / ArkUI) app that talks to a self-hosted Immich server:

1. Configure server URL + email/password login
2. Browse the photo timeline (buckets + thumbnails)
3. Upload / backup from device gallery
4. Later: albums, search, people (optional)

## Decisions

| Topic | Choice | Why |
| --- | --- | --- |
| Scope | Client only | Server already works; AGPL self-use is fine |
| Stack | Native ArkTS (HarmonyOS NEXT) | No official Flutter-OH path in Immich; native is the stable long-term bet |
| API | Immich OpenAPI (`/auth`, `/timeline`, `/assets`, …) | Same contract as official mobile |
| Local store | Preferences + later relational DB | Start simple; add RDB when offline sync is needed |
| Auth | Access token in Preferences | Matches Immich mobile `accessToken` header flow |
| Thumbnails | Authenticated HTTP → PixelMap cache | `Image(url)` cannot send Immich auth headers |
| Upload | PhotoViewPicker + multipart `/assets` | Foreground queue first; background later |
| Out of scope (v1) | OAuth, Passkey, widgets, Cast, ML on device | Personal MVP first |

## Phases

### P0 — Skeleton

- [x] Repo layout for DevEco Studio
- [x] Architecture notes + this plan
- [x] Core HTTP client + DTO stubs
- [x] Login / Timeline page shells
- [x] MVP OpenAPI extract script (`scripts/extract_mvp_openapi.py`)
- [x] Open / build with Command Line Tools 26 (HAP succeeds)
- [x] Stable emulator UI run (GUI + 2GB AVD; see `docs/EMULATOR.md`)

### P1 — Auth

- [x] `GET /server/ping` to validate base URL
- [x] `POST /auth/login` → store `accessToken` + server URL
- [x] `POST /auth/validateToken` on cold start
- [x] `GET /users/me` for profile header
- [x] Logout clears token
- [x] API verification via `scripts/e2e_client_flow.mjs` (demo + local Immich)
- [x] On-device UI verification (emulator Login → Timeline)

### P2 — Timeline

- [x] `GET /timeline/buckets`
- [x] `GET /timeline/bucket?timeBucket=…`
- [x] Thumbnail via authenticated download + PixelMap cache (`ThumbnailLoader` / `AuthThumb`)
- [x] 3-column Grid UI
- [x] Full-screen preview viewer (`AssetViewerPage`, preview size)
- [x] API verification (buckets + authenticated thumb bytes)
- [x] On-device grid verification (real thumbnails on emulator)
- [x] Video download & play in AssetViewer (`/assets/{id}/video/playback` → cache file)

### P3 — Backup / Upload

- [x] PhotoViewPicker selection UI (`BackupPage`)
- [x] `POST /assets` multipart upload (`AssetApi`)
- [x] Sequential foreground queue with status rows
- [x] Upload API check against **self-hosted** Immich (`e2e_client_flow.mjs` + local Docker)
- [x] On-device upload verification (long-press Backup title → debug rawfile → Upload)
- [x] Checksum header (`x-immich-checksum` SHA-1 Base64 via `ChecksumUtil`)
- [ ] Background upload (WorkScheduler)

### P4 — Albums & search

- [x] Albums list (`AlbumsPage` + `AlbumApi`)
- [x] Album detail via timeline buckets filtered by `albumId`
- [x] Metadata search (`SearchPage` + `POST /search/metadata`)
- [x] API verification (albums + search) on demo / local
- [x] Smart search (`POST /search/smart`) + Favorites filter
- [x] People list (`PeoplePage`) → person asset search
- [x] On-device UI verification (Albums list + Search results on emulator)

### P5 — Hardening (personal)

- [ ] Self-signed TLS option (dev only)
- [x] Settings page (server/about/version, clear thumb cache, sign out)
- [x] Asset viewer actions (favorite / trash / archive / EXIF / download original)
- [x] Trash page (browse / restore one / restore all / empty)
- [x] Archive page (browse / unarchive)
- [x] Create album + add asset to album (`AlbumsPage`, `AddToAlbumPage`)
- [ ] Version gate (app ↔ server major/minor)
- [ ] Pin Immich OpenAPI version used for generation
- [ ] Background upload (WorkScheduler) — still optional

## Module map

```
entry/src/main/ets/
  common/       constants, URL helpers, checksum
  components/   AuthThumb (favorite / video badges)
  model/        DTOs aligned with OpenAPI
  service/      HttpClient, Auth/Timeline/Asset/Album/Search/People/Server APIs
  viewmodel/    Login / Timeline / Backup / Search / People state
  pages/        Login, Timeline, AssetViewer, Backup, Albums, Search, People,
                Settings, Trash, Archive, AddToAlbum
  entryability/ app entry
```

## Immich API used

| Feature | Method | Path |
| --- | --- | --- |
| Ping | GET | `/server/ping` |
| Login | POST | `/auth/login` |
| Validate | POST | `/auth/validateToken` |
| Logout | POST | `/auth/logout` |
| Me | GET | `/users/me` |
| Buckets | GET | `/timeline/buckets` |
| Bucket | GET | `/timeline/bucket` |
| Upload | POST | `/assets` |
| Thumb | GET | `/assets/{id}/thumbnail` |
| Asset info | GET | `/assets/{id}` |
| Favorite / archive | PUT | `/assets/{id}` |
| Trash | DELETE | `/assets` |
| Restore trash | POST | `/trash/restore/assets` |
| Empty trash | POST | `/trash/empty` |
| Original | GET | `/assets/{id}/original` |
| Video | GET | `/assets/{id}/video/playback` |
| Albums | GET | `/albums` |
| Create album | POST | `/albums` |
| Add to album | PUT | `/albums/{id}/assets` |
| Search | POST | `/search/metadata` |
| Smart search | POST | `/search/smart` |
| People | GET | `/people` |
| Server about | GET | `/server/about` |
| Server version | GET | `/server/version` |

Base URL: user-entered origin + `/api` (same as official clients).

## Build / run (on your machine)

1. Install DevEco Studio (HarmonyOS NEXT / API 12+).
2. Open `/home/ubuntu/immich-ohos` (or copy to your PC).
3. File → Sync / ohpm install.
4. Run `entry` on emulator or device.
5. Point the login form at your Immich URL, e.g. `https://immich.example.com`.
6. Follow [DEVICE_TEST.md](DEVICE_TEST.md).

This cloud environment has **no** HarmonyOS SDK — compile/run happens on your DevEco host.

## Risk list

| Risk | Mitigation |
| --- | --- |
| API drift vs Immich releases | Pin OpenAPI JSON; document tested server version |
| Thumbnail auth headers | Download with Bearer / `x-immich-user-token`, decode PixelMap |
| Large library performance | Cap first load (120 assets); in-memory thumb cache |
| Upload duplicates | Send `deviceAssetId` + accept `duplicate` status |
| Background limits on NEXT | Ship foreground upload first |
| Photo URI access | Use PhotoViewPicker URIs with multipart `filePath` |

## Success criteria (personal MVP)

- Cold start restores session when token still valid
- Timeline shows remote photos from your server
- Can upload at least one photo from gallery and see it after refresh
