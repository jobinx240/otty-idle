#!/usr/bin/env bash
# Prepare OpenHarmony community debug signing materials for this project.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIGN="$ROOT/signing"
LIB="${OHOS_SDK_LIB:-/home/ubuntu/harmonyos/command-line-tools-26/sdk/default/openharmony/toolchains/lib}"
JAR="$LIB/hap-sign-tool.jar"
BUNDLE="${BUNDLE_NAME:-app.personal.immich.ohos}"

mkdir -p "$SIGN"
cp -f "$LIB/OpenHarmony.p12" "$SIGN/"
cp -f "$LIB/OpenHarmonyProfileDebug.pem" "$SIGN/"
cp -f "$LIB/UnsgnedDebugProfileTemplate.json" "$SIGN/"

# Split community profile PEM into Root / CA / Profile Debug (file order).
python3 - "$SIGN" <<'PY'
import sys, time, uuid, json
from pathlib import Path
sign = Path(sys.argv[1])
pem = (sign / "OpenHarmonyProfileDebug.pem").read_text()
parts = []
buf = []
for line in pem.splitlines():
    buf.append(line)
    if line.startswith("-----END CERTIFICATE-----"):
        parts.append("\n".join(buf) + "\n")
        buf = []
assert len(parts) == 3, f"expected 3 certs, got {len(parts)}"
root, ca, leaf = parts
(sign / "root_ca.cer").write_text(root)
(sign / "app_ca.cer").write_text(ca)
(sign / "profile_debug_leaf.cer").write_text(leaf)
(sign / "profile_chain_from_pem.cer").write_text(leaf + ca + root)
PY

# Development cert embedded in the unsigned profile template (matches release key).
python3 - "$SIGN" "$BUNDLE" <<'PY'
import json, sys, time, uuid
from pathlib import Path
sign = Path(sys.argv[1])
bundle = sys.argv[2]
tpl = json.loads((sign / "UnsgnedDebugProfileTemplate.json").read_text())
now = int(time.time())
tpl["uuid"] = str(uuid.uuid4())
tpl["type"] = "debug"
tpl["bundle-info"]["bundle-name"] = bundle
tpl["validity"] = {"not-before": now - 86400, "not-after": now + 3650 * 86400}
(sign / "profile_unsigned.json").write_text(json.dumps(tpl, indent=2))
dev = tpl["bundle-info"]["development-certificate"]
(sign / "dev_cert_from_profile.cer").write_text(dev)
ca = (sign / "app_ca.cer").read_text()
root = (sign / "root_ca.cer").read_text()
(sign / "app_cert_chain.cer").write_text(dev + ca + root)
print(f"bundle={bundle} uuid={tpl['uuid']}")
PY

java -jar "$JAR" sign-profile \
  -mode localSign \
  -keyAlias "openharmony application profile debug" \
  -keyPwd 123456 \
  -profileCertFile "$SIGN/profile_chain_from_pem.cer" \
  -inFile "$SIGN/profile_unsigned.json" \
  -signAlg SHA256withECDSA \
  -keystoreFile "$SIGN/OpenHarmony.p12" \
  -keystorePwd 123456 \
  -outFile "$SIGN/app_debug.p7b"

echo "ready: $SIGN/app_debug.p7b"
