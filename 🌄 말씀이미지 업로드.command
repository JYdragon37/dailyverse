#!/bin/bash
# ───────────────────────────────────────────────────────────────
# morning manna — 말씀 배경 이미지 업로드
#
# 사용법:
#   1. scripts/verse-images/ 폴더에 이미지 파일(JPG/PNG) 넣기
#      (하위 폴더 포함 OK: verse-images/events/img_christmas.jpg)
#   2. 이 파일 더블클릭
#
# 자동으로:
#   - Firebase Storage 업로드 (CDN URL 생성)
#   - Firestore images/ 컬렉션 메타데이터 등록
#   - 구글 시트 IMAGES 탭에 행 추가
#   - 이미 업로드된 파일은 자동 건너뜀 (중복 없음)
# ───────────────────────────────────────────────────────────────

cd "$(dirname "$0")/scripts"

echo ""
echo "🌄  morning manna 말씀 배경 이미지 업로드"
echo "═══════════════════════════════════════════════"
echo "verse-images/ 폴더 재귀 탐색 중..."
echo "(하위 폴더 포함, 신규 파일만 업로드)"
echo ""

# verse-images 폴더 없으면 안내
if [ ! -d "verse-images" ]; then
  echo "❌ verse-images/ 폴더가 없습니다."
  echo ""
  echo "  scripts/verse-images/ 폴더를 만들고"
  echo "  업로드할 이미지(JPG/PNG)를 넣은 후 다시 실행하세요."
  echo ""
  read -p "엔터를 누르면 창이 닫힙니다..." _
  exit 1
fi

# 이미지 파일 수 미리 확인
IMG_COUNT=$(find verse-images -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" 2>/dev/null | wc -l | tr -d ' ')
echo "발견된 이미지: ${IMG_COUNT}개"
echo ""

NODE_TLS_REJECT_UNAUTHORIZED=0 node upload_local_images.js

echo ""
echo "───────────────────────────────────────────────"
echo "✅ 완료! 이 창을 닫아도 됩니다."
echo "───────────────────────────────────────────────"
read -p "엔터를 누르면 창이 닫힙니다..." _
