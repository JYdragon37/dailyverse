#!/bin/bash
# ─────────────────────────────────────────────────────────────
# morning manna — 이미지 업로드 (design_test/ → Firebase)
#
# 전제: Claude Code에서 "design_test 검수해줘" 를 먼저 실행하여
#       이미지가 bg_* / img_* 파일명으로 리네임된 상태여야 합니다.
#
# 자동으로:
#   1. design_test/ 폴더 스캔 (bg_* / img_* 파일만)
#   2. 미리보기 출력 (dry-run)
#   3. 사용자 확인 후 업로드 실행
#   4. Firebase Storage + Google Sheets + Firestore 반영
#   5. 업로드 완료 파일 삭제
# ─────────────────────────────────────────────────────────────

SCRIPTS_DIR="$(dirname "$0")/scripts"
DESIGN_TEST="$(dirname "$0")/design_test"

echo ""
echo "🖼️  morning manna 이미지 업로드"
echo "═══════════════════════════════════════════════"
echo ""

# ── 파일 확인 ────────────────────────────────────────────────

BG_COUNT=$(find "$DESIGN_TEST" -maxdepth 1 -name "bg_*.jpg" -o -name "bg_*.jpeg" -o -name "bg_*.png" 2>/dev/null | wc -l | tr -d ' ')
IMG_COUNT=$(find "$DESIGN_TEST" -maxdepth 1 -name "img_*.png" -o -name "img_*.jpg" 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$((BG_COUNT + IMG_COUNT))

# 미검수 파일 체크
RAW_COUNT=$(find "$DESIGN_TEST" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) \
  ! -name "bg_*" ! -name "img_*" 2>/dev/null | grep -v DS_Store | wc -l | tr -d ' ')

if [ "$TOTAL" -eq 0 ]; then
  echo "❌ 업로드할 파일이 없습니다."
  echo ""
  echo "   먼저 검수를 완료하세요:"
  echo "   → 🔍 이미지 검수.command 더블클릭"
  echo "   → Claude Code에서 \"design_test 검수해줘\""
  echo ""
  read -p "엔터를 누르면 창이 닫힙니다..." _
  exit 0
fi

if [ "$RAW_COUNT" -gt 0 ]; then
  echo "⚠️  검수되지 않은 파일 ${RAW_COUNT}개가 있습니다."
  echo "   (bg_* / img_* 로 시작하지 않는 파일)"
  echo ""
  echo "   먼저 검수를 완료하면 해당 파일도 처리됩니다:"
  echo "   → Claude Code에서 \"design_test 검수해줘\""
  echo ""
  echo "   검수된 파일(${TOTAL}개)만 계속 업로드하려면 계속 진행하세요."
  echo ""
fi

echo "📂 업로드 대상: Zone 배경 ${BG_COUNT}개 | 감성 이미지 ${IMG_COUNT}개 (총 ${TOTAL}개)"
echo ""

# ── Dry-run 미리보기 ─────────────────────────────────────────

echo "── 미리보기 ────────────────────────────────────"
cd "$SCRIPTS_DIR" && NODE_TLS_REJECT_UNAUTHORIZED=0 node upload_design_test.js --dry-run 2>/dev/null
echo "────────────────────────────────────────────────"
echo ""

# ── 사용자 확인 ──────────────────────────────────────────────

read -p "위 내용으로 업로드하시겠습니까? (y/n): " CONFIRM
echo ""

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "취소되었습니다."
  echo ""
  read -p "엔터를 누르면 창이 닫힙니다..." _
  exit 0
fi

# ── 업로드 실행 ──────────────────────────────────────────────

echo "🚀 업로드 시작..."
echo ""
cd "$SCRIPTS_DIR" && NODE_TLS_REJECT_UNAUTHORIZED=0 node upload_design_test.js 2>/dev/null
UPLOAD_RESULT=$?

echo ""

if [ $UPLOAD_RESULT -eq 0 ]; then
  echo "✅ 업로드 완료!"
  echo ""

  # ── 업로드 완료 파일 삭제 ─────────────────────────────────
  echo "🗑️  업로드된 파일 정리 중..."
  find "$DESIGN_TEST" -maxdepth 1 \( -name "bg_*.jpg" -o -name "bg_*.jpeg" -o -name "bg_*.png" \
    -o -name "img_*.png" -o -name "img_*.jpg" \) -delete 2>/dev/null
  echo "   design_test/ 파일 삭제 완료"
  echo ""
  echo "───────────────────────────────────────────────"
  echo "✨ 모든 작업이 완료되었습니다!"
  echo ""
  echo "   앱 재실행 시 새 이미지가 자동으로 반영됩니다."

  # 미검수 파일 안내
  if [ "$RAW_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  미검수 파일 ${RAW_COUNT}개는 design_test/ 에 남아있습니다."
    echo "   → Claude Code에서 \"design_test 검수해줘\" 로 처리하세요."
  fi
else
  echo "❌ 업로드 중 오류가 발생했습니다."
  echo "   스크립트 출력을 확인하세요."
fi

echo ""
read -p "엔터를 누르면 창이 닫힙니다..." _
