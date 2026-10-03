#!/bin/bash
# 한우 체중 측정 — 현장 Raspberry Pi 최초 설치 (sudo 불필요)
#
#   curl -fsSLO https://raw.githubusercontent.com/BlessingQ/weight_mesuring-release/main/install.sh && bash install.sh
#   bash install.sh --hub-agent ~/iontec-agent-0.1.0.tar.gz     # IoT 허브 에이전트도 함께 (관리 서버 연결)
#
# 최신 릴리스 manifest 확인 → 패키지 다운로드 → SHA-256 + 아이온텍 서명(ed25519) 검증 → ~/iontec 구조 설치
# 설치 후에는 업데이트 에이전트가 1시간마다 새 버전을 확인한다 (화면 [새 버전 — 눌러서 업데이트]).
# 이 파일은 비공개 소스 저장소의 deploy/bootstrap.sh 에서 tools/release.py --sync 로 만들어진다.
set -euo pipefail

REPO="BlessingQ/weight_mesuring-release"
MANIFEST_URL="https://github.com/$REPO/releases/latest/download/manifest.json"
DEVICE_TYPE="weight"
ARCH="arm64"
PUBKEY='-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAq9eE4BD09bOQvFFBsyltkSrw45rTH2yUEHgMWkmGSDE=
-----END PUBLIC KEY-----'

for c in curl python3 openssl tar sha256sum; do
  command -v "$c" >/dev/null || { echo "필요한 명령 없음: $c"; exit 1; }
done
if [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null || echo yes)" != "yes" ]; then
  echo "※ 시간 동기화 전입니다 — HTTPS 인증서 확인이 실패할 수 있습니다. 네트워크 연결 후 잠시 뒤 다시 실행하세요."
fi

export IONTEC_INSTALL_CWD="$PWD"                    # 옵션의 상대 경로 기준 (아래에서 작업 폴더로 이동)
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "== 최신 버전 확인: $MANIFEST_URL"
curl -fsSL "$MANIFEST_URL" -o manifest.json
eval "$(python3 - <<'PY'
import json, shlex
m = json.load(open("manifest.json"))
p = m["package"]
for k, v in (("VER", m["version"]), ("NAME", p["name"]), ("URL", p["url"]), ("SHA", p["sha256"].lower()),
             ("SIG", m["signature"]["value"]), ("M_DT", m["device_type"]), ("M_ARCH", m["arch"]),
             ("M_PY", m.get("python", ""))):
    print(f"{k}={shlex.quote(str(v))}")
PY
)"
[ "$M_DT" = "$DEVICE_TYPE" ] || { echo "장치 종류가 다릅니다: $M_DT"; exit 1; }
[ "$M_ARCH" = "$ARCH" ] || [ "$M_ARCH" = "any" ] || { echo "아키텍처가 다릅니다: $M_ARCH"; exit 1; }
PYV="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
if [ -n "$M_PY" ] && [ "$M_PY" != "$PYV" ]; then
  echo "이 장비의 파이썬 $PYV ≠ 패키지 $M_PY — 지원하지 않는 OS 버전입니다 (아이온텍에 문의)"
  exit 1
fi

echo "== v$VER 다운로드: $NAME"
curl -fsSL "$URL" -o "$NAME"
echo "$SHA  $NAME" | sha256sum -c --quiet - || { echo "SHA-256 불일치 — 설치 중단"; exit 1; }

printf '%s\n%s\n%s\n%s\n' "$DEVICE_TYPE" "$ARCH" "$VER" "$SHA" > msg
printf '%s' "$SIG" | base64 -d > sig
printf '%s\n' "$PUBKEY" > pub.pem
if ! openssl pkeyutl -verify -pubin -inkey pub.pem -rawin -in msg -sigfile sig >/dev/null 2>&1; then
  echo "서명 불일치 — 아이온텍이 서명한 패키지가 아닙니다. 설치 중단"
  exit 1
fi
echo "   SHA-256·서명 확인"

mkdir pkg
tar -xzf "$NAME" -C pkg
bash pkg/install.sh "$@"

echo
echo "== 다음 단계 (최초 1회, 비밀번호 필요): 한글 폰트·NTP 시간 동기화 설정"
echo "   sudo ~/iontec/weight/current/install_root.sh && sudo reboot"
