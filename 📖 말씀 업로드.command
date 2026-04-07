#!/bin/bash
# ───────────────────────────────────────────────
# DailyVerse — 말씀 업로드
# 구글 시트 VERSES 탭 → Firestore 자동 동기화
# ───────────────────────────────────────────────

cd "$(dirname "$0")/scripts"

echo ""
echo "📖 DailyVerse 말씀 업로드"
echo "═══════════════════════════"
echo "구글 시트 → Firestore 동기화 중..."
echo ""

node sync_sheets_to_firestore.js

echo ""
echo "───────────────────────────────"
echo "✅ 완료! 이 창을 닫아도 됩니다."
echo "───────────────────────────────"
read -p "엔터를 누르면 창이 닫힙니다..." _
