# 한우 체중 측정 — 현장 장비 배포 (IONTEC)

㈜아이온텍 한우 AX 체중 측정 장비(Raspberry Pi 5)용 **배포 전용 저장소**입니다.
소스 코드는 포함되어 있지 않으며, Releases 에 서명된 실행 패키지만 올라갑니다.

## 최초 설치 (Raspberry Pi OS 64bit, Python 3.13)

```bash
curl -fsSLO https://raw.githubusercontent.com/BlessingQ/weight_mesuring-release/main/install.sh && bash install.sh
sudo ~/iontec/weight/current/install_root.sh && sudo reboot     # 최초 1회 (한글 폰트·NTP)
```

아이온텍 관리 서버 연결은 프로그램에 내장되어 있습니다 (처음 실행하면 장비 ID 를 만들고 대시보드에 '승인 대기'로 나타남).
설치 후 점검: `~/iontec/weight/current/scripts/field_check.sh`

설치 스크립트는 최신 릴리스의 패키지를 받아 **SHA-256 과 아이온텍 서명(ed25519)을 확인한 뒤** 설치합니다.
서명이 맞지 않으면 설치하지 않습니다. 검증용 공개키: [`release_pubkey.pem`](release_pubkey.pem)

## 업데이트

설치된 장비의 업데이트 에이전트가 1시간마다 아래 주소에서 새 버전을 확인하고, 화면에 알립니다.

```
https://github.com/BlessingQ/weight_mesuring-release/releases/latest/download/manifest.json
```

| 파일 | 내용 |
|---|---|
| `manifest.json` | 장치 종류(weight)·아키텍처(arm64)·버전·패키지 주소·SHA-256·서명 |
| `weight-arm64-v<버전>.tar.gz` | 실행 패키지 (컴파일된 코드) |

문의: ㈜아이온텍
