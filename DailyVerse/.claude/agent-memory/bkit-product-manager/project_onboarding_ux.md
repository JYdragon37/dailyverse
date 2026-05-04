---
name: DailyVerse 온보딩 UX 검토 맥락
description: 4화면 온보딩 구현 완료 상태에서 PM 관점 검토 결과 — 순서/배경톤/CTA 차단 3가지 구조적 문제 식별
type: project
---

현재 구현된 온보딩 4화면: 공감(ONBIntroView) → 닉네임(ONBNicknameView) → 체험(ONBExperienceView) → 알람설정(ONBAlarmPermissionView)

**Why:** 구현은 완료되었으나 "가치 먼저, 마찰 나중" 원칙 위반 + 디자인 에이전트 피드백 반영 필요

**How to apply:**
- 3가지 구조적 문제: (1) 닉네임이 체험 앞에 위치 (2) After 배경 쿨톤 — 따뜻함 미전달 (3) 닉네임 미입력 시 CTA 차단
- P0(즉시): After 배경 웜톤 전환 + 닉네임 CTA 항상 활성화
- P1(이번): blur bloom + 슬로건 순차 페이드인 + 완료 후 확인 메시지
- P2(다음): 화면 순서 변경 — 공감→체험→닉네임→알람설정
- Plan 문서 경로: `docs/01-plan/features/onboarding-ux-review.plan.md`
