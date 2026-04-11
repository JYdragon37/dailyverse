/**
 * upload_contemplation_ko.js
 * verses 컬렉션에 contemplation_ko + contemplation_reference 업로드
 * 생성일: 2026-04-10
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}
const db = admin.firestore();

// ─── 배치 1: v_001 ~ v_034 ───────────────────────────────────────────────────
const batch1 = {
  "v_001": { contemplation_ko: "나는 어떠한 형편에 있든지 자족하기를 배웠노라. 내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라.", contemplation_reference: "빌립보서 4:11, 13" },
  "v_002": { contemplation_ko: "그가 나를 푸른 풀밭에 누이시며 쉴 만한 물 가로 인도하시는도다. 내 영혼을 소생시키시고 자기 이름을 위하여 의의 길로 인도하시는도다.", contemplation_reference: "시편 23:2-3" },
  "v_003": { contemplation_ko: "이것을 너희에게 이르는 것은 너희로 내 안에서 평안을 누리게 하려 함이라. 세상에서는 너희가 환난을 당하나 담대하라.", contemplation_reference: "요한복음 16:33" },
  "v_004": { contemplation_ko: "주의 말씀의 강령은 진리이오니 주의 의로운 모든 규례는 영원하리이다.", contemplation_reference: "시편 119:160" },
  "v_005": { contemplation_ko: "염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라. 그리하면 모든 지각에 뛰어난 하나님의 평강이 너희 마음과 생각을 지키시리라.", contemplation_reference: "빌립보서 4:6-7" },
  "v_006": { contemplation_ko: "나는 비천에 처할 줄도 알고 풍부에 처할 줄도 알아 모든 일 곧 배부름과 배고픔과 풍부와 궁핍에도 처할 줄 아는 일체의 비결을 배웠노라.", contemplation_reference: "빌립보서 4:12" },
  "v_007": { contemplation_ko: "항상 기뻐하라. 쉬지 말고 기도하라. 범사에 감사하라. 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라.", contemplation_reference: "데살로니가전서 5:16-18" },
  "v_008": { contemplation_ko: "너는 범사에 그를 인정하라. 그리하면 네 길을 지도하시리라. 너는 스스로 지혜롭게 여기지 말지어다.", contemplation_reference: "잠언 3:6-7" },
  "v_009": { contemplation_ko: "주님, 주의 손이 나를 인도하시며 주의 오른손이 나를 붙드시리이다. 내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주와 함께하리이다.", contemplation_reference: "시편 139:9-10" },
  "v_010": { contemplation_ko: "내가 하늘에 올라갈지라도 거기 계시며 스올에 내 자리를 펼지라도 거기 계시니이다. 내가 새벽 날개를 치며 바다 끝에 거할지라도 거기서도 주의 손이 나를 인도하시리이다.", contemplation_reference: "시편 139:8-10" },
  "v_011": { contemplation_ko: "그는 피곤한 자에게는 능력을 주시며 무능한 자에게는 힘을 더하시나니. 소년이라도 피곤하여 떨어지며 장정이라도 넘어지되 오직 여호와를 앙망하는 자는 새 힘을 얻으리니.", contemplation_reference: "이사야 40:29-31" },
  "v_012": { contemplation_ko: "누가 우리를 그리스도의 사랑에서 끊으리요. 환난이나 곤고나 박해나 기근이나 적신이나 위험이나 칼이랴. 이 모든 일에 우리를 사랑하시는 이로 말미암아 우리가 넉넉히 이기느니라.", contemplation_reference: "로마서 8:35, 37" },
  "v_013": { contemplation_ko: "두려워하지 말라. 내가 너를 구속하였고 내가 너를 지명하여 불렀나니 너는 내 것이라. 네가 물 가운데로 지날 때에 내가 너와 함께할 것이라.", contemplation_reference: "이사야 43:1-2" },
  "v_014": { contemplation_ko: "나의 멍에를 메고 내게 배우라. 나는 마음이 온유하고 겸손하니 너희 마음이 쉼을 얻으리니. 이는 내 멍에는 쉽고 내 짐은 가벼움이라.", contemplation_reference: "마태복음 11:29-30" },
  "v_015": { contemplation_ko: "하나님은 우리의 피난처시요 힘이시니 환난 중에 만날 큰 도움이시라. 그러므로 땅이 변하든지 산이 흔들려 바다 가운데에 빠지든지 우리는 두려워하지 아니하리로다.", contemplation_reference: "시편 46:1-2" },
  "v_016": { contemplation_ko: "그는 물 가에 심어진 나무가 그 뿌리를 강변에 뻗치고 더위가 올지라도 두려워하지 아니하며 그 잎이 청청하며 가뭄의 해에도 걱정이 없고 결실이 그치지 아니함 같으리라.", contemplation_reference: "예레미야 17:8" },
  "v_017": { contemplation_ko: "여호와의 이름은 견고한 망대라. 의인은 그리로 달려가서 안전함을 얻느니라.", contemplation_reference: "잠언 18:10" },
  "v_018": { contemplation_ko: "우리 주 예수 그리스도로 말미암아 하나님과 화평을 누리자. 그로 말미암아 우리가 믿음으로 서 있는 이 은혜에 들어감을 얻었으며 하나님의 영광을 바라고 즐거워하느니라.", contemplation_reference: "로마서 5:1-2" },
  "v_019": { contemplation_ko: "우리 가운데서 역사하시는 능력대로 우리가 구하거나 생각하는 모든 것에 더 넘치도록 능히 하실 이에게 교회 안에서와 그리스도 예수 안에서 영광이 세세토록 있으리로다.", contemplation_reference: "에베소서 3:20-21" },
  "v_020": { contemplation_ko: "무슨 일을 하든지 마음을 다하여 주께 하듯 하고 사람에게 하듯 하지 말라. 이는 기업의 상을 주께 받을 줄 알기 때문이라. 너희는 주 그리스도를 섬기느니라.", contemplation_reference: "골로새서 3:23-24" },
  "v_021": { contemplation_ko: "여호와는 너를 지키시는 이시라. 여호와께서 네 오른쪽에서 네 그늘이 되시나니. 낮의 해가 너를 상하게 하지 아니하며 밤의 달도 너를 해치지 아니하리로다.", contemplation_reference: "시편 121:5-6" },
  "v_022": { contemplation_ko: "주께서 심지가 견고한 자를 평강에 평강으로 지키시리니 이는 그가 주를 신뢰함이니이다. 너희는 여호와를 영원히 신뢰하라. 주 여호와는 영원한 반석이심이로다.", contemplation_reference: "이사야 26:3-4" },
  "v_023": { contemplation_ko: "우리에게 있는 대제사장은 우리의 연약함을 동정하지 못하실 이가 아니요 모든 일에 우리와 똑같이 시험을 받으신 이로되 죄는 없으시니라. 그러므로 우리는 담대히 은혜의 보좌 앞에 나아갈 것이니라.", contemplation_reference: "히브리서 4:15-16" },
  "v_024": { contemplation_ko: "하나님이 우리를 사랑하시는 사랑을 우리가 알고 믿었노니 하나님은 사랑이시라. 사랑 안에 거하는 자는 하나님 안에 거하고 하나님도 그의 안에 거하시느니라.", contemplation_reference: "요한일서 4:16" },
  "v_025": { contemplation_ko: "소망이 우리를 부끄럽게 하지 아니함은 우리에게 주신 성령으로 말미암아 하나님의 사랑이 우리 마음에 부은 바 됨이니.", contemplation_reference: "로마서 5:5" },
  "v_026": { contemplation_ko: "오직 성령의 열매는 사랑과 희락과 화평과 오래 참음과 자비와 양선과 충성과 온유와 절제니 이같은 것을 금지할 법이 없느니라.", contemplation_reference: "갈라디아서 5:22-23" },
  "v_027": { contemplation_ko: "여호와는 마음이 상한 자를 가까이 하시고 중심에 통회하는 자를 구원하시는도다. 의인은 고난이 많으나 여호와께서 그의 모든 고난에서 건지시는도다.", contemplation_reference: "시편 34:18-19" },
  "v_028": { contemplation_ko: "심령이 가난한 자는 복이 있나니 천국이 그들의 것임이요. 애통하는 자는 복이 있나니 그들이 위로를 받을 것임이요.", contemplation_reference: "마태복음 5:3-4" },
  "v_029": { contemplation_ko: "평안을 너희에게 끼치노니 곧 나의 평안을 너희에게 주노라. 내가 너희에게 주는 것은 세상이 주는 것과 같지 아니하니라. 너희는 마음에 근심하지도 말고 두려워하지도 말라.", contemplation_reference: "요한복음 14:27" },
  "v_030": { contemplation_ko: "나의 하나님, 주는 나의 피난처시라. 내가 주의 날개 아래에 피하리이다. 거기서 주께서 그를 위하여 행하신 것을 감사하며 주의 성도들과 함께 주 앞에서 기뻐하리이다.", contemplation_reference: "시편 63:7" },
  "v_031": { contemplation_ko: "너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라. 너는 범사에 그를 인정하라. 그리하면 네 길을 지도하시리라.", contemplation_reference: "잠언 3:5-6" },
  "v_032": { contemplation_ko: "믿음의 주요 또 온전하게 하시는 이인 예수를 바라보자. 그는 그 앞에 있는 기쁨을 위하여 십자가를 참으사 부끄러움을 개의치 아니하시더니 하나님 보좌 우편에 앉으셨느니라.", contemplation_reference: "히브리서 12:2" },
  "v_033": { contemplation_ko: "여호와를 기다리는 자들은 새 힘을 얻으리니. 너는 여호와를 바라라. 강하고 담대하라. 여호와를 바라라.", contemplation_reference: "이사야 40:31 / 시편 27:14" },
  "v_034": { contemplation_ko: "사랑은 오래 참고 사랑은 온유하며 시기하지 아니하며 자랑하지 아니하며 교만하지 아니하며 무례히 행하지 아니하며 자기의 유익을 구하지 아니하느니라.", contemplation_reference: "고린도전서 13:4-5" },
};

// ─── 배치 2: v_035 ~ v_068 ───────────────────────────────────────────────────
const batch2 = {
  "v_035": { contemplation_ko: "마귀는 우는 사자같이 두루 다니며 삼킬 자를 찾나니, 너희는 믿음을 굳건히 하여 그를 대적하라.", contemplation_reference: "베드로전서 5:8-9" },
  "v_036": { contemplation_ko: "너를 지키시는 이는 졸지도 아니하시고 주무시지도 아니하시리로다.", contemplation_reference: "시편 121:3-4" },
  "v_037": { contemplation_ko: "내 힘이 다 소진된 것 같을 때, 주님은 나의 반석이시요 요새이시라. 나의 하나님은 내가 피할 바위시라.", contemplation_reference: "시편 18:2" },
  "v_038": { contemplation_ko: "보이는 것은 잠깐이요, 보이지 않는 것은 영원함이라.", contemplation_reference: "고린도후서 4:18" },
  "v_039": { contemplation_ko: "땅이 변하고 산이 흔들려 바다 가운데 빠질지라도, 우리는 두려워하지 아니하리로다.", contemplation_reference: "시편 46:2" },
  "v_040": { contemplation_ko: "사랑은 하나님께 속한 것이니, 사랑하는 자마다 하나님으로부터 나서 하나님을 알고.", contemplation_reference: "요한일서 4:7" },
  "v_041": { contemplation_ko: "오직 여호와를 앙망하는 자는 새 힘을 얻으리니 독수리가 날개 치며 올라감 같을 것이요.", contemplation_reference: "이사야 40:31" },
  "v_042": { contemplation_ko: "여호와를 기다리는 자는 그를 바라는 자에게 선을 행하시는 줄 알거니와, 구하는 영혼에게 좋은 것으로 채우시는도다.", contemplation_reference: "예레미야 애가 3:25" },
  "v_043": { contemplation_ko: "아버지의 집에는 거할 곳이 많도다. 내가 너희를 위하여 거처를 예비하러 가노라.", contemplation_reference: "요한복음 14:2" },
  "v_044": { contemplation_ko: "나는 선한 목자라. 선한 목자는 양들을 위하여 목숨을 버리거니와.", contemplation_reference: "요한복음 10:11" },
  "v_045": { contemplation_ko: "내가 행하는 것을 네가 지금은 알지 못하나, 이 후에는 알리라.", contemplation_reference: "요한복음 13:7" },
  "v_046": { contemplation_ko: "너희를 고통받게 하는 자들에게서 잠시 환난을 받는 너희를, 우리와 함께 안식으로 갚으시는 것이 하나님의 공의니라.", contemplation_reference: "데살로니가후서 1:6-7" },
  "v_047": { contemplation_ko: "무릇 그리스도 예수와 합하여 세례를 받은 우리는 그의 죽으심과 합하여 세례를 받은 것이라. 그러므로 우리가 그의 죽으심과 합하여 세례를 받음으로 그와 함께 장사되었나니.", contemplation_reference: "로마서 6:3-4" },
  "v_048": { contemplation_ko: "내 안에 거하라. 나도 너희 안에 거하리라. 가지가 포도나무에 붙어 있지 아니하면 스스로 열매를 맺을 수 없음 같이, 너희도 내 안에 있지 아니하면 그러하리라.", contemplation_reference: "요한복음 15:4" },
  "v_049": { contemplation_ko: "하나님이 내 가까이 계심이 내게 복이라. 내가 주 여호와를 나의 피난처로 삼아 주의 모든 행적을 전파하리이다.", contemplation_reference: "시편 73:28" },
  "v_050": { contemplation_ko: "항상 기뻐하라, 쉬지 말고 기도하라, 범사에 감사하라. 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라.", contemplation_reference: "데살로니가전서 5:16-18" },
  "v_051": { contemplation_ko: "여호와는 나의 목자시니 내게 부족함이 없으리로다. 그가 나를 푸른 풀밭에 누이시며 쉴 만한 물 가로 인도하시는도다.", contemplation_reference: "시편 23:1-2" },
  "v_052": { contemplation_ko: "여호와께서 높은 곳에서 손을 내밀어 나를 붙드시며, 많은 물에서 나를 건져내셨도다.", contemplation_reference: "시편 18:16" },
  "v_053": { contemplation_ko: "무엇을 먹을까 무엇을 마실까 무엇을 입을까 염려하지 말라. 너희 하늘 아버지께서 이 모든 것이 너희에게 있어야 할 줄을 아시느니라.", contemplation_reference: "마태복음 6:31-32" },
  "v_054": { contemplation_ko: "아무 것도 염려하지 말고 다만 모든 일에 기도와 간구로, 너희 구할 것을 감사함으로 하나님께 아뢰라.", contemplation_reference: "빌립보서 4:6" },
  "v_055": { contemplation_ko: "나의 도움이 어디서 올꼬. 천지를 지으신 여호와에게서로다.", contemplation_reference: "시편 121:1-2" },
  "v_056": { contemplation_ko: "믿는 자에게는 능히 하지 못할 일이 없느니라.", contemplation_reference: "마가복음 9:23" },
  "v_057": { contemplation_ko: "여호와는 자비롭고 은혜로우시며 오래 참으시며 인자하심이 풍부하시도다. 항상 경쟁하지 아니하시며 노를 영원히 품지 아니하시리로다.", contemplation_reference: "시편 103:8-9" },
  "v_058": { contemplation_ko: "주께서 이 모든 것을 주셨사오니, 사모하는 자에게 좋은 것으로 배불리셨나이다.", contemplation_reference: "시편 107:8-9" },
  "v_059": { contemplation_ko: "성령도 우리의 연약함을 도우시나니, 하나님의 뜻대로 성도를 위하여 간구하시느니라.", contemplation_reference: "로마서 8:27" },
  "v_060": { contemplation_ko: "내가 곧 길이요 진리요 생명이니, 나로 말미암지 않고는 아버지께로 올 자가 없느니라.", contemplation_reference: "요한복음 14:6" },
  "v_061": { contemplation_ko: "내 평생에 여호와의 집에 살면서 여호와의 아름다움을 바라보며 그의 성전에서 사모하기를 원하노라.", contemplation_reference: "시편 27:4" },
  "v_062": { contemplation_ko: "우리가 지금은 거울로 보는 것 같이 희미하나 그때에는 얼굴과 얼굴을 대하여 볼 것이요. 지금은 내가 부분적으로 아나 그때에는 주께서 나를 아신 것 같이 내가 온전히 알리라.", contemplation_reference: "고린도전서 13:12" },
  "v_063": { contemplation_ko: "내가 주를 향하여 이 일을 행하였사오니, 주는 나의 도움이시라. 주의 날개 그늘 아래에 내가 즐거이 피하리이다.", contemplation_reference: "시편 57:1" },
  "v_064": { contemplation_ko: "때를 얻든지 못 얻든지 항상 힘쓰라. 범사에 오래 참음과 가르침으로 경책하며 경계하며 권하라.", contemplation_reference: "디모데후서 4:2" },
  "v_065": { contemplation_ko: "몸이 하나요 성령도 한 분이시니, 이와 같이 너희가 부르심의 한 소망 안에서 부르심을 받았느니라.", contemplation_reference: "에베소서 4:4" },
  "v_066": { contemplation_ko: "마음의 즐거움은 양약이라도, 심령의 근심은 뼈를 마르게 하느니라.", contemplation_reference: "잠언 17:22" },
  "v_067": { contemplation_ko: "나의 영혼이 잠잠히 하나님만 바람이여, 나의 구원이 그에게서 나는도다. 오직 그만이 나의 반석이시요 나의 구원이시요 나의 요새이시니.", contemplation_reference: "시편 62:1-2" },
  "v_068": { contemplation_ko: "젊은 자도 피곤하며 곤비하며 장정도 넘어지며 쓰러지되, 오직 여호와를 앙망하는 자는 새 힘을 얻으리니.", contemplation_reference: "이사야 40:30-31" },
};

// ─── 배치 3: v_069 ~ v_101 ───────────────────────────────────────────────────
const batch3 = {
  "v_069": { contemplation_ko: "그러므로 내가 그리스도를 위하여 약한 것들과 능욕과 궁핍과 핍박과 곤란을 기뻐하노니 이는 내가 약한 그 때에 강함이라", contemplation_reference: "고린도후서 12:10" },
  "v_070": { contemplation_ko: "여호와께서 그의 백성에게 강함을 주심이여 여호와께서 그의 백성에게 평강의 복을 주시리로다", contemplation_reference: "시편 29:11" },
  "v_071": { contemplation_ko: "여호와는 나의 목자시니 내게 부족함이 없으리로다", contemplation_reference: "시편 23:1" },
  "v_072": { contemplation_ko: "너희 염려를 다 주께 맡기라 이는 그가 너희를 돌보심이라", contemplation_reference: "베드로전서 5:7" },
  "v_073": { contemplation_ko: "이것이 내 고통 중의 위안이라 주의 말씀이 나를 살리셨음이니이다", contemplation_reference: "시편 119:50" },
  "v_074": { contemplation_ko: "나의 힘이신 여호와여 내가 주를 사랑하나이다", contemplation_reference: "시편 18:1" },
  "v_075": { contemplation_ko: "여호와를 경외하는 것이 지혜의 근본이요 거룩하신 자를 아는 것이 명철이니라", contemplation_reference: "잠언 9:10" },
  "v_076": { contemplation_ko: "내가 전심으로 주를 찾았사오니 주의 계명에서 떠나지 말게 하소서", contemplation_reference: "시편 119:10" },
  "v_077": { contemplation_ko: "나의 영혼이 잠잠히 하나님만 바람이여, 나의 구원이 그에게서 나는도다. 오직 그만이 나의 반석이시요 나의 구원이시요 나의 요새이시니.", contemplation_reference: "시편 62:1-2" },
  "v_078": { contemplation_ko: "이 여호와의 인자하심이 영원하며 그의 진실하심이 대대에 이르리로다", contemplation_reference: "시편 100:5" },
  "v_079": { contemplation_ko: "내가 평안히 눕고 자기도 하리니 나를 안전히 살게 하시는 이는 오직 여호와이시니이다", contemplation_reference: "시편 4:8" },
  "v_080": { contemplation_ko: "내 영혼이 하나님을 갈망함이 사슴이 시냇물을 찾기에 갈급함 같으니이다", contemplation_reference: "시편 42:1" },
  "v_081": { contemplation_ko: "보라 내가 새 일을 행하리니 이제 나타낼 것이라 너희가 그것을 알지 못하겠느냐 내가 광야에서 길을 사막에서 강을 내리니", contemplation_reference: "이사야 43:19" },
  "v_082": { contemplation_ko: "주께서 나를 지으신 것을 내가 알고 모든 기이한 주의 행사를 찬양하니이다", contemplation_reference: "시편 139:14" },
  "v_083": { contemplation_ko: "무슨 일을 하든지 마음을 다하여 주께 하듯 하고 사람에게 하듯 하지 말라", contemplation_reference: "골로새서 3:23" },
  "v_084": { contemplation_ko: "아무것도 염려하지 말고 다만 모든 일에 기도와 간구로 너희 구할 것을 감사함으로 하나님께 아뢰라", contemplation_reference: "빌립보서 4:6" },
  "v_085": { contemplation_ko: "믿음이 없이는 하나님을 기쁘시게 하지 못하나니 하나님께 나아가는 자는 반드시 그가 계신 것과 또한 그가 자기를 찾는 자들에게 상 주시는 이심을 믿어야 할지니라", contemplation_reference: "히브리서 11:6" },
  "v_086": { contemplation_ko: "오직 여호와를 앙망하는 자는 새 힘을 얻으리니 독수리가 날개치며 올라감 같을 것이요", contemplation_reference: "이사야 40:31" },
  "v_087": { contemplation_ko: "어찌하여 내 영혼아 낙심하며 어찌하여 내 속에서 불안해하는가 너는 하나님께 소망을 두라 그가 나타나 도우심으로 말미암아 내가 여전히 찬송하리로다", contemplation_reference: "시편 42:5" },
  "v_088": { contemplation_ko: "내가 주의 목소리를 들을 때에 내 기쁨이 넘치나이다", contemplation_reference: "시편 119:111" },
  "v_089": { contemplation_ko: "내 하나님이 그리스도 예수 안에서 영광 가운데 그 풍성한 대로 너희 모든 쓸 것을 채우시리라", contemplation_reference: "빌립보서 4:19" },
  "v_090": { contemplation_ko: "그러므로 형제들아 주의 강림하심까지 길이 참으라 보라 농부가 땅에서 나는 귀한 열매를 바라고 이른 비와 늦은 비를 기다리나니", contemplation_reference: "야고보서 5:7" },
  "v_091": { contemplation_ko: "나 여호와가 말하노라 너희를 향한 나의 생각을 내가 아나니 평안이요 재앙이 아니니라 너희에게 미래와 희망을 주는 것이니라", contemplation_reference: "예레미야 29:11" },
  "v_092": { contemplation_ko: "하나님의 나라는 먹는 것과 마시는 것이 아니요 오직 성령 안에 있는 의와 평강과 희락이라", contemplation_reference: "로마서 14:17" },
  "v_093": { contemplation_ko: "심는 자와 거두는 자가 함께 즐거워하게 하려 함이라", contemplation_reference: "요한복음 4:36" },
  "v_094": { contemplation_ko: "그런즉 믿음 소망 사랑 이 세 가지는 항상 있을 것인데 그 중의 제일은 사랑이라", contemplation_reference: "고린도전서 13:13" },
  "v_095": { contemplation_ko: "내가 세상을 이기었노라 하시니라", contemplation_reference: "요한복음 16:33" },
  "v_096": { contemplation_ko: "여호와는 나의 빛이요 나의 구원이시니 내가 누구를 두려워하리요 여호와는 내 생명의 능력이시니 내가 누구를 무서워하리요", contemplation_reference: "시편 27:1" },
  "v_097": { contemplation_ko: "새벽에 주께서 나의 기도 소리를 들으시리니 내가 아침에 주를 향하여 간구하고 바라리이다", contemplation_reference: "시편 5:3" },
  "v_098": { contemplation_ko: "나는 포도나무요 너희는 가지라 그가 내 안에 내가 그 안에 거하면 사람이 열매를 많이 맺나니 나를 떠나서는 너희가 아무것도 할 수 없음이라", contemplation_reference: "요한복음 15:5" },
  "v_099": { contemplation_ko: "주의 길을 내게 보이시고 주의 진리로 나를 가르치소서 주는 내 구원의 하나님이시니 내가 종일 주를 기다리나이다", contemplation_reference: "시편 25:4-5" },
  "v_100": { contemplation_ko: "나의 도움이 어디서 올까 나의 도움은 천지를 지으신 여호와에게서로다", contemplation_reference: "시편 121:1-2" },
  "v_101": { contemplation_ko: "모든 성도의 믿음이 온 천하에 전파됨을 내가 먼저 감사하는 것은 너희 믿음이 온 세상에 전파되기 때문이라", contemplation_reference: "로마서 1:8" },
};

// ─── 업로드 ──────────────────────────────────────────────────────────────────
async function main() {
  const all = { ...batch1, ...batch2, ...batch3 };
  const ids = Object.keys(all);
  let success = 0, errors = 0;

  console.log(`총 ${ids.length}개 contemplation_ko 업로드 시작...\n`);

  for (const id of ids) {
    try {
      await db.collection('verses').doc(id).update(all[id]);
      success++;
      if (success % 10 === 0) console.log(`  ${success}개 완료...`);
    } catch (e) {
      console.error(`  ❌ ${id}: ${e.message}`);
      errors++;
    }
  }

  console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 완료: ${success}개 업로드 / ❌ 오류: ${errors}개
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
  process.exit(0);
}

main();
