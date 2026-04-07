#!/bin/bash
# ───────────────────────────────────────────────
# DailyVerse — 배경 이미지 업로드
# background_images_to_upload/ 폴더 → Firebase Storage + Firestore
# ───────────────────────────────────────────────

cd "$(dirname "$0")/scripts"

echo ""
echo "🌅 DailyVerse 배경 이미지 업로드"
echo "═══════════════════════════════════"
echo ""
echo "📁 이미지 폴더: scripts/background_images_to_upload/"
echo ""
echo "파일명 규칙:"
echo "  bg_deep_dark.jpg     🌑 00–03시"
echo "  bg_first_light.jpg   🌒 03–06시"
echo "  bg_rise_ignite.jpg   🌅 06–09시"
echo "  bg_peak_mode.jpg     ⚡ 09–12시"
echo "  bg_recharge.jpg      ☀️  12–15시"
echo "  bg_second_wind.jpg   🌤 15–18시"
echo "  bg_golden_hour.jpg   🌇 18–21시"
echo "  bg_wind_down.jpg     🌙 21–24시"
echo ""
echo "───────────────────────────────────"
echo "업로드 시작..."
echo ""

node upload_backgrounds.js

echo ""
echo "───────────────────────────────"
echo "✅ 완료! 이 창을 닫아도 됩니다."
echo "───────────────────────────────"
read -p "엔터를 누르면 창이 닫힙니다..." _
