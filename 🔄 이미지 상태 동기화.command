#!/bin/bash
# ─────────────────────────────────────────────────────────────
# morning manna — 이미지 상태 동기화
# 구글 시트에서 inactive로 변경한 이미지를 Firestore에 반영
#
# 언제 실행하나?
#   시트에서 이미지 status를 active ↔ inactive로 변경했을 때
# ─────────────────────────────────────────────────────────────

cd "$(dirname "$0")/scripts"

echo ""
echo "🔄 morning manna 이미지 상태 동기화"
echo "══════════════════════════════════════"
echo "구글 시트 VERSE_IMAGES → Firestore 상태 반영 중..."
echo ""

NODE_TLS_REJECT_UNAUTHORIZED=0 node sync_verse_images.js

echo ""
echo "───────────────────────────────────"
echo "✅ 완료! 이 창을 닫아도 됩니다."
echo "───────────────────────────────────"
read -p "엔터를 누르면 창이 닫힙니다..." _
