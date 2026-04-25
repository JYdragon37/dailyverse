#!/bin/bash
# ─────────────────────────────────────────────────────────
# morning manna — 이미지 검수 준비
#
# 이 파일을 더블클릭하면:
#   1. design_test/ 폴더의 이미지 목록을 보여줍니다
#   2. Claude Code에 붙여넣을 검수 명령어를 클립보드에 복사합니다
# ─────────────────────────────────────────────────────────

DESIGN_TEST="$(dirname "$0")/design_test"
PROMPT="design_test 검수해줘"

echo ""
echo "🔍  morning manna 이미지 검수 준비"
echo "═══════════════════════════════════════"
echo ""

# 이미지 파일 수 확인
IMG_COUNT=$(find "$DESIGN_TEST" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) 2>/dev/null | grep -v DS_Store | wc -l | tr -d ' ')

if [ "$IMG_COUNT" -eq 0 ]; then
  echo "❌ design_test/ 폴더에 이미지가 없습니다."
  echo ""
  echo "   젠스파크에서 생성한 이미지를 아래 폴더에 넣으세요:"
  echo "   $(realpath "$DESIGN_TEST" 2>/dev/null || echo "$DESIGN_TEST")"
  echo ""
  read -p "엔터를 누르면 창이 닫힙니다..." _
  exit 0
fi

echo "📂 design_test/ 폴더 이미지 목록 (${IMG_COUNT}개)"
echo "───────────────────────────────────────"
find "$DESIGN_TEST" -maxdepth 1 \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) 2>/dev/null \
  | grep -v DS_Store \
  | sort \
  | while read -r f; do
      BASENAME=$(basename "$f")
      # 이미 리네임된 파일인지 확인
      if [[ "$BASENAME" == bg_* ]] || [[ "$BASENAME" == img_* ]]; then
        echo "  ✓ $BASENAME  (검수 완료)"
      else
        echo "  · $BASENAME"
      fi
    done

echo ""
echo "═══════════════════════════════════════"
echo ""

# 클립보드 복사
echo -n "$PROMPT" | pbcopy

echo "✅ 클립보드에 복사됨!"
echo ""
echo "  → Claude Code를 열고 Cmd+V 로 붙여넣기하세요:"
echo ""
echo "  ┌─────────────────────────────┐"
echo "  │  design_test 검수해줘       │"
echo "  └─────────────────────────────┘"
echo ""
echo "검수 완료 후: 🖼️ 이미지 업로드.command 를 더블클릭하세요."
echo ""
read -p "엔터를 누르면 창이 닫힙니다..." _
