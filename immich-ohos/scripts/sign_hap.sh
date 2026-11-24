#!/usr/bin/env bash
# Sign the unsigned debug HAP with OpenHarmony community materials.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIGN="$ROOT/signing"
LIB="${OHOS_SDK_LIB:-/home/ubuntu/harmonyos/command-line-tools-26/sdk/default/openharmony/toolchains/lib}"
JAR="$LIB/hap-sign-tool.jar"
IN="${1:-$ROOT/entry/build/default/outputs/default/entry-default-unsigned.hap}"
OUT="${2:-$ROOT/entry/build/default/outputs/default/entry-default-signed.hap}"

test -f "$IN" || { echo "missing unsigned HAP: $IN" >&2; exit 1; }
test -f "$SIGN/app_debug.p7b" || { echo "missing $SIGN/app_debug.p7b — run scripts/prepare_debug_signing.sh first" >&2; exit 1; }

java -jar "$JAR" sign-app \
  -mode localSign \
  -keyAlias "openharmony application release" \
  -keyPwd 123456 \
  -appCertFile "$SIGN/app_cert_chain.cer" \
  -profileFile "$SIGN/app_debug.p7b" \
  -inFile "$IN" \
  -signAlg SHA256withECDSA \
  -keystoreFile "$SIGN/OpenHarmony.p12" \
  -keystorePwd 123456 \
  -outFile "$OUT" \
  -compatibleVersion 12 \
  -signCode 1

echo "signed: $OUT"
