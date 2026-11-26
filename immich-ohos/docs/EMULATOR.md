# Emulator status on this cloud agent

## Installed

| Component | Path / version |
| --- | --- |
| Command Line Tools | `/home/ubuntu/harmonyos/command-line-tools-26` — **26.0.0.821** |
| Emulator binary | `…/emulator/Emulator` |
| Phone system image | HarmonyOS **7.0.0(26.0.0)** under `emulator/images/` (~4.6G) |
| AVD name | `immichPhone` |

Older CLT 6.1.1 remains at `/home/ubuntu/harmonyos/command-line-tools` (optional).

## What works here

- `Emulator -license accept`
- `Emulator -imageList` / `-install` (phone image download OK)
- `Emulator -create` / `-start` (KVM accessible after `/dev/kvm` chmod)
- App **HAP builds** with SDK 26 (`hvigorw assembleHap` → unsigned HAP)
- **Debug signing** via OpenHarmony community materials:
  - `bash scripts/prepare_debug_signing.sh`
  - `bash scripts/sign_hap.sh`
  - Output: `entry/build/default/outputs/default/entry-default-signed.hap`
- Immich **API E2E** against public demo (`SKIP_UPLOAD=1`) and against **local Docker Immich** (full upload):

```bash
# Local Immich (host network — Docker bridge is broken on this VM)
cd /home/ubuntu/immich/docker
sudo dockerd >/tmp/dockerd.log 2>&1 &
sudo docker compose -f docker-compose.yml -f docker-compose.host.yml up -d

IMMICH_URL=http://127.0.0.1:2283 \
IMMICH_EMAIL=admin@local.test \
IMMICH_PASSWORD=Admin12345 \
node /home/ubuntu/immich-ohos/scripts/e2e_client_flow.mjs
```

## Working boot recipe (this VM)

`-noWindow` cold boots still hit a sceneboard/sysrq kernel panic around 60s.
**GUI boot** with Qt/`DISPLAY=:1`, **2 GB RAM** AVD, and `bootMode reset` stays up:

```bash
./Emulator -create immichPhoneLowMem -deviceType phone \
  -osVersion 'HarmonyOS 7.0.0(26.0.0)' \
  -instancePath "$EMU/instances" -imageRoot "$EMU/images" \
  -memory 2 -storage 4 -hotBoot false

export DISPLAY=:1 QT_QPA_PLATFORM=xcb XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
./Emulator -start immichPhoneLowMem -instancePath "$EMU/instances" \
  -imageRoot "$EMU/images" -hdcport 11112 -bootMode reset
```

Verified on this VM:

- `hdc` target `127.0.0.1:11112`
- signed HAP install + launch
- Login (long-press title for local debug prefill) → Timeline with thumbnails
- Albums / Search / Backup navigation reachable
- Local Immich via emulator: `http://10.0.2.2:2283`


## Commands (when retrying)

```bash
export EMU=/home/ubuntu/harmonyos/command-line-tools-26/emulator
export DISPLAY=:1 QT_QPA_PLATFORM=xcb XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
sudo chmod 666 /dev/kvm   # if needed

cd "$EMU"
./Emulator -start immichPhone -instancePath "$EMU/instances" \
  -imageRoot "$EMU/images" -hdcport 11111 -noWindow

# After a healthy boot:
export PATH=/home/ubuntu/harmonyos/command-line-tools-26/sdk/default/openharmony/toolchains:$PATH
hdc list targets
hdc install /home/ubuntu/immich-ohos/entry/build/default/outputs/default/entry-default-signed.hap
```

## Recommendation

Run UI verification on **DevEco Studio + local emulator/device**, or provide a stable host with non-nested KVM. Keep using `scripts/e2e_client_flow.mjs` against your self-hosted Immich for API-level confidence.
