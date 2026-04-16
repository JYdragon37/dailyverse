// overlay_helper.js
// DailyVerse — 오버레이 메타데이터 헬퍼
// metadata.json을 읽어 Firestore 업로드 페이로드에 오버레이 정보 병합

const fs = require('fs');
const path = require('path');

// overlay_intensity → SwiftUI 그라데이션 opacity 매핑
const OVERLAY_OPACITY = {
  light: 0.35,
  medium: 0.50,
  heavy: 0.65,
  null: 0.0
};

/**
 * 폴더의 metadata.json을 읽어 이미지별 오버레이 정보 반환
 * metadata.json이 없으면 파일명의 _ov 접미어로 판단
 */
function getOverlayInfo(folderPath, filename) {
  const metaPath = path.join(folderPath, 'metadata.json');

  // metadata.json 있으면 우선 사용
  if (fs.existsSync(metaPath)) {
    const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8'));
    const imageInfo = meta.images.find(img => img.filename === filename);
    if (imageInfo) {
      return {
        needs_overlay: imageInfo.needs_overlay,
        overlay_intensity: imageInfo.overlay_intensity,
        overlay_opacity: OVERLAY_OPACITY[imageInfo.overlay_intensity] || 0.0,
        issues: imageInfo.issues || []
      };
    }
  }

  // 폴백: 파일명에 _ov 있으면 medium으로 처리
  const hasOvSuffix = filename.includes('_ov.');
  return {
    needs_overlay: hasOvSuffix,
    overlay_intensity: hasOvSuffix ? 'medium' : null,
    overlay_opacity: hasOvSuffix ? OVERLAY_OPACITY.medium : 0.0,
    issues: []
  };
}

/**
 * Firestore 업로드 페이로드에 오버레이 정보 병합
 */
function enrichPayloadWithOverlay(payload, folderPath, filename) {
  const overlayInfo = getOverlayInfo(folderPath, filename);
  return {
    ...payload,
    needs_overlay: overlayInfo.needs_overlay,
    overlay_intensity: overlayInfo.overlay_intensity,  // "light" | "medium" | "heavy" | null
    overlay_opacity: overlayInfo.overlay_opacity,       // 0.0 ~ 0.65
    inspection_issues: overlayInfo.issues
  };
}

/**
 * 폴더 내 오버레이 필요 이미지 목록 출력 (디버깅용)
 */
function printOverlaySummary(folderPath) {
  const metaPath = path.join(folderPath, 'metadata.json');
  if (!fs.existsSync(metaPath)) {
    console.log(`[overlay] metadata.json 없음: ${folderPath}`);
    return;
  }

  const meta = JSON.parse(fs.readFileSync(metaPath, 'utf8'));
  const ovImages = meta.images.filter(img => img.needs_overlay);

  console.log(`\n[overlay] ${meta.folder} (${meta.concept})`);
  console.log(`  총 ${meta.total}장 중 오버레이 필요: ${meta.overlay_required}장`);
  ovImages.forEach(img => {
    console.log(`  ⚠️  ${img.filename} → intensity: ${img.overlay_intensity}, opacity: ${OVERLAY_OPACITY[img.overlay_intensity]}`);
  });
}

module.exports = { getOverlayInfo, enrichPayloadWithOverlay, printOverlaySummary, OVERLAY_OPACITY };
