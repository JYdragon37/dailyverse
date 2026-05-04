---
name: Firestore 연결 방식
description: 현재 개발 환경에서 Firebase Admin SDK gRPC가 차단됨 — REST API로 우회해야 함
type: feedback
---

현재 환경(회사 SSL 인스펙션 추정)에서 Firebase Admin SDK의 gRPC 기반 Firestore 연결이 타임아웃됨.

**Why:** NODE_TLS_REJECT_UNAUTHORIZED=0 으로 HTTPS는 우회 가능하지만 gRPC는 다른 TLS 스택을 사용하므로 우회 불가.

**How to apply:** Firestore 문서 추가/수정 시 Firebase Admin SDK 대신 Firestore REST API(HTTPS)를 사용할 것.
- 토큰 발급: googleapis의 GoogleAuth로 datastore 스코프 토큰 획득
- 엔드포인트: `https://firestore.googleapis.com/v1/projects/{projectId}/databases/(default)/documents/{collection}/{docId}`
- 메서드: PATCH (upsert), GET (읽기)
- NODE_TLS_REJECT_UNAUTHORIZED=0 + https 요청 옵션 rejectUnauthorized: false 조합으로 동작함
- Google Sheets API(REST)도 동일한 방식으로 동작함 (이미 확인)
