/**
 * patch_interpretation_batch.js
 *
 * interpretation 필드 일괄 수정 스크립트
 * 대상: v_050, v_046, v_048, v_082, v_069, v_093, v_063, v_179, v_178,
 *       v_103, v_105, v_102, v_121, v_172, v_119, v_147, v_052, v_068,
 *       v_129, v_176, v_104, v_109, v_141, v_122, v_124, v_113, v_154,
 *       v_135, v_115, v_125, v_107, v_139, v_148, v_111, v_130, v_144,
 *       v_155, v_138, v_145, v_143, v_142, v_132, v_136, v_151, v_153,
 *       v_152, v_149
 *
 * 실행: node scripts/patch_interpretation_batch.js
 */

const admin = require('firebase-admin');
const { google } = require('googleapis');
const path = require('path');

const SERVICE_ACCOUNT_PATH = path.resolve(__dirname, './serviceAccountKey.json');
const SHEET_ID = '1seUUYgtPf3iDSSl5cZrdNH63-uM9kR24QQ4FzOmLtig';
const SHEET_NAME = 'VERSES';

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(require(SERVICE_ACCOUNT_PATH)) });
}
const db = admin.firestore();

// ── 수정 데이터 정의 ────────────────────────────────────────────────────────
const PATCHES = [
  {
    id: 'v_050',
    field: 'interpretation',
    newValue: `바울은 로마서 12장에서 세상을 본받지 말고 변화를 받으라고 해. 이 변화는 나비처럼 형태 자체가 달라지는 완전한 전환이야. 그런데 그 변환이 외부 행동이 아니라 마음이 새로워지는 것에서 시작된다고 해. 세상의 패턴에 자동으로 반응하던 걸 잠깐 멈추는 것, 그게 변화의 첫 걸음이야.`
  },
  {
    id: 'v_046',
    field: 'interpretation',
    newValue: `바울이 코린트 교회에 보낸 편지에서 하나님을 '위로의 하나님'이라고 불러. 이 위로는 멀리서 지켜보는 게 아니라 곁에 와서 함께 서주는 거야. 그 위로를 받은 사람은 나중에 같은 자리에 있는 사람 곁에 설 수 있어. 고통도 의미가 되는 거야.`
  },
  {
    id: 'v_048',
    field: 'interpretation',
    newValue: `요한복음 15장에서 예수님은 마지막 밤 제자들에게 포도나무 비유를 하셔. '머문다'는 건 그냥 있는 게 아니라 계속 연결된 상태를 유지하는 거야. 가지가 나무에서 끊어지면 시들 듯, 예수님과 연결된 삶에서만 진짜 열매가 나와. 바쁜 하루에도 그 연결을 잃지 않도록 해봐.`
  },
  {
    id: 'v_082',
    field: 'interpretation',
    newValue: `바울은 에베소서 2장에서 우리가 은혜로 구원받았다고 한 뒤 이 말을 덧붙여. 우리는 하나님의 '걸작품'이야 — 예술가가 심혈을 기울여 만든 작품처럼. 그리고 그 걸작에는 목적이 있어, 미리 예비된 선한 일이야. 오늘 네 하루가 그 걸음 중 하나야.`
  },
  {
    id: 'v_069',
    field: 'interpretation',
    newValue: `이 구절의 '인내'는 단순한 기다림이 아니야. 짓눌려도 아래서 버티는 것, 쓰러지지 않고 서있는 거야. 마라톤처럼 포기하지 않는 끈기야. 하나님의 약속은 이루어져 — 그 사이에 필요한 건 딱 하나, 버티는 거야.`
  },
  {
    id: 'v_093',
    field: 'interpretation',
    newValue: `갈라디아 교회는 지쳐있었어. 선을 행하면서도 결과가 보이지 않아 낙심했어. 바울은 농부의 언어를 써. 씨를 뿌리면 수확의 때가 있어. 오후에 지쳐 '이게 의미 있나?' 싶을 때, 이 말이 필요해.`
  },
  {
    id: 'v_063',
    field: 'interpretation',
    newValue: `바울은 고린도 교인들이 우상 문제로 혼란을 겪는 상황에서 이 말씀을 썼어. 시험이 사라지는 게 아니라, 그 안에서 빠져나갈 길이 있다는 약속이야. 지금 너무 벅차다면, 아직 출구를 못 찾은 것일 수 있어. 다시 주위를 살펴봐.`
  },
  {
    id: 'v_179',
    field: 'interpretation',
    newValue: `시편 23편은 다윗이 목자가 되시는 하나님을 노래한 고백이야. '선하심과 인자하심이 따른다'는 건 네가 의식하든 안 하든 뒤에서 쫓아온다는 뜻이야. 오늘 하루를 돌아보면 어디선가 그 흔적이 보일 거야.`
  },
  {
    id: 'v_178',
    field: 'interpretation',
    newValue: `시편 126편은 바벨론 포로에서 돌아온 이스라엘이 부른 감사의 노래야. 눈물로 씨를 뿌린 것이 기쁨의 수확으로 돌아온다는 건 이미 경험한 자들의 고백이야. 오늘 밤 힘들었다면, 씨앗을 뿌리는 중인 거야.`
  },
  {
    id: 'v_103',
    field: 'interpretation',
    newValue: `다윗이 아침 제사를 드리며 쓴 시편이야. '바라리이다'는 망대에서 적을 살피는 파수꾼의 자세를 뜻해. 원하는 것을 던져놓고 잊는 기도가 아니라, 응답을 기대하며 주의를 기울이는 행위야. 아침에 알람이 울리면 그 기도의 자세로 시작해봐.`
  },
  {
    id: 'v_105',
    field: 'interpretation',
    newValue: `산상수훈에서 예수님이 염려에 대해 가르치신 말씀의 마지막 구절이야. '내일 일은 내일이 염려하리라'는 무책임이 아니라 오늘에 충실하라는 초청이야. 저녁에 알람을 맞추는 건 내일을 준비하면서 동시에 오늘을 닫는 행위야.`
  },
  {
    id: 'v_102',
    field: 'interpretation',
    newValue: `이사야 43장은 출애굽의 기억을 상기시키며 그것보다 더 큰 새 일을 예고해. '이제 나타낼 것이라'는 현재진행형 선언이야. 내일 아침 알람이 울릴 때 그 하루는 이미 전날과 다른 새 날이야. 변화는 매일 아침 눈을 뜨는 것에서 시작돼.`
  },
  {
    id: 'v_121',
    field: 'interpretation',
    newValue: `잠언은 '일을 주께 맡기라'고 해. 이 '맡김'은 신뢰의 행위이지 성공 보장이 아니야. 당시 지혜 전통에서 '맡기다'는 단순한 부탁이 아니라 전적인 위탁을 의미했어. 내 계획을 내려놓을 때 오히려 하나님의 길이 열려.`
  },
  {
    id: 'v_172',
    field: 'interpretation',
    newValue: `바울은 로마서 8장에서 고난과 성령 안의 삶을 함께 다뤄. '하나님이 우리를 위하시면'은 소망이 아니라 이미 확인된 사실이야. 고난이 사라진다는 말이 아니라 그 모든 것 위에 하나님이 계신다는 고백이야. 오늘 저녁, 그 든든함을 기억해봐.`
  },
  {
    id: 'v_119',
    field: 'interpretation',
    newValue: `솔로몬의 노래로, 하나님 없는 수고는 헛되다는 고백이야. '사랑하시는 자에게 잠을 주신다'는 건 억지로 쟁취하는 게 아니라 선물로 받는 안식을 뜻해. 지금 이 밤, 결과를 그분께 맡기고 편히 쉬어도 괜찮아.`
  },
  {
    id: 'v_147',
    field: 'interpretation',
    newValue: `시편 119편 기자는 새벽이 오기 전, 해가 뜨기도 전에 이미 하나님께 부르짖었어. 이 '기다림'은 소극적인 기대가 아니라 말씀을 붙잡고 버티는 적극적인 자세야. 아직 어둠이 가시지 않은 이 새벽, 그 간절함이 하루의 첫 자리야.`
  },
  {
    id: 'v_052',
    field: 'interpretation',
    newValue: `히브리서는 핍박받는 공동체를 향한 편지야. '결코 버리지 않겠다'는 약속은 여호수아에게도 동일하게 주어진 말씀이야. 상황이 가장 무너질 것 같은 순간에 주어진 선언이거든. 새벽 이 시간, 고독하게 느껴진다면 그 약속을 붙잡아봐.`
  },
  {
    id: 'v_068',
    field: 'interpretation',
    newValue: `이사야 40장은 바벨론에 오랫동안 갇혀 지쳐 있던 이스라엘 백성을 향한 위로야. 힘을 주신다는 대상이 강한 자가 아니라 피곤한 자, 기력이 다한 자야. 새벽 이 피로 속에, 그 능력이 지금 네게 향해 있어.`
  },
  {
    id: 'v_129',
    field: 'interpretation',
    newValue: `겟세마네, 예수님이 체포되기 전날 밤 지친 제자들에게 하신 말씀이야. '육체의 연약함'은 실패가 아니라 솔직한 현실이야. 오늘도 지쳐 있는 게 당연해. 그래서 잠들기 전 짧은 기도 하나가 필요한 거야.`
  },
  {
    id: 'v_176',
    field: 'interpretation',
    newValue: `시편 121편은 성전을 향해 올라가던 순례자가 광야 길의 위험 속에서 부른 노래야. '주무시지 않는다'는 말은 당시 신상이 잠든 사이 재앙이 온다는 두려움을 배경으로 한 강력한 선언이야. 이 밤, 지키시는 그분께 오늘을 맡겨봐.`
  },
  {
    id: 'v_104',
    field: 'interpretation',
    newValue: `잠언 16편은 인간의 계획과 하나님의 주권 사이를 말하는 지혜야. '맡기다'는 짐을 굴려서 내 손에서 떼어내는 동작이야. 열심히 준비하되 결과를 붙들지 않는 것, 그게 하나님과 동행하는 지혜야. 내일 계획이 있다면 오늘 밤 그 결과를 내려놔봐.`
  },
  {
    id: 'v_109',
    field: 'interpretation',
    newValue: `모세가 가나안 입성을 앞두고 두려워하는 여호수아에게 한 말이야. '앞에서 가신다'는 건 하나님이 이미 내일 먼저 들어가 계신다는 뜻이야. 오늘 밤 알람을 맞추며 내일을 준비할 때, 먼저 거기 계신 그분을 떠올려봐.`
  },
  {
    id: 'v_141',
    field: 'interpretation',
    newValue: `요한복음 14장은 예수님이 십자가 전날 밤 두려움에 떠는 제자들과 나눈 마지막 대화야. '미리 말하는 이유는 일어날 때 믿게 하려'는 앞날을 아시면서 함께하시겠다는 선언이야. 이 새벽, 결말을 아시는 그분이 지금 여기 계셔.`
  },
  {
    id: 'v_122',
    field: 'interpretation',
    newValue: `시편 143편은 다윗이 원수에게 쫓기며 사방이 막힌 상황에서 드린 기도야. '아침에 주의 인자한 말씀을 듣게 해달라'는 살아남기 위한 간절한 고백이야. 말씀이 하루를 살아낼 힘이 된다는 걸 알았던 거야. 이 새벽, 그 갈망으로 하루를 열어봐.`
  },
  {
    id: 'v_124',
    field: 'interpretation',
    newValue: `시편 92편은 안식일 예배용 찬양시야. '아침의 인자하심'과 '밤마다의 성실하심'을 노래하며 하루 전체가 찬양의 공간임을 선포해. 이 인자하심은 단순한 친절이 아니라 언약에 근거한 변함없는 사랑이야. 이 새벽, 그 사랑이 지금 새로 시작돼.`
  },
  {
    id: 'v_113',
    field: 'interpretation',
    newValue: `예루살렘이 바벨론에 무너진 직후 예레미야가 잿더미 위에서 쓴 노래야. 그 절망의 한가운데서 '아침마다 새롭다'고 고백한 거야. 상황이 바뀐 게 아니라 하나님의 신실하심이 매일 다시 시작되는 거야. 이 새벽에도, 그 신실하심이 지금 와.`
  },
  {
    id: 'v_154',
    field: 'interpretation',
    newValue: `초기 교회에서 세례식에 불렀던 찬송으로 알려진 구절이야. '잠자는 자여 깨어라'는 영적 각성의 선언이지, 단순한 기상이 아니야. 세례가 죽음에서 새 생명으로 건너가는 상징이었듯, 매일 아침 눈 뜨는 건 그 새 생명을 다시 살아내는 거야.`
  },
  {
    id: 'v_135',
    field: 'interpretation',
    newValue: `시편 90편은 모세가 인간의 유한함과 하나님의 영원함을 대비하며 드린 기도야. '인자하심으로 배부르게 하사'는 하루의 첫 끼니처럼 사랑으로 속을 채워달라는 간구야. 이 새벽 하루의 첫 자리를 그 사랑이 차지하길 기도해봐.`
  },
  {
    id: 'v_115',
    field: 'interpretation',
    newValue: `이사야 60장은 바벨론 포로에서 돌아온 이스라엘을 향한 선포야. '빛을 발하라'는 명령은 스스로 빛을 만들라는 게 아니야. 하나님의 영광이 먼저 임할 때 자연스럽게 반사되는 빛이야. 이 새벽, 그 빛이 이미 너에게 임했어. 일어나봐.`
  },
  {
    id: 'v_125',
    field: 'interpretation',
    newValue: `시편 4편은 다윗이 모반과 핍박 속에서 드린 저녁 기도야. 소란하고 두려운 상황에서도 하나님 안에서 안전하게 눕는다고 고백해. '안전히 눕는다'는 건 보호받는다는 뜻이 아니라 맡긴다는 의미야. 오늘 밤 그 평안으로 눈을 감아봐.`
  },
  {
    id: 'v_107',
    field: 'interpretation',
    newValue: `바울이 감옥 안에서 빌립보 교회에 쓴 편지야. 그럼에도 '염려하지 말라'고 말할 수 있는 건 기도라는 통로가 있기 때문이야. 저녁 알람을 맞추는 건 내일 일정을 하나님께 맡기는 첫 행동이야. 염려를 기도로 전환하는 거야.`
  },
  {
    id: 'v_139',
    field: 'interpretation',
    newValue: `시편 30편은 다윗이 죽음의 위기에서 건짐받은 뒤 드린 감사 찬양이야. '저녁에는 울음이요 아침에는 기쁨'은 신학적 위로가 아니라 실제 고난을 통과한 체험의 고백이야. 눈물의 밤이 영원하지 않다는 다윗의 증언이야. 오늘 밤이 힘들어도 아침이 와.`
  },
  {
    id: 'v_148',
    field: 'interpretation',
    newValue: `바울은 로마서 8장에서 고난 중에도 성령과 함께하는 삶을 선포해. '하나님이 우리를 위하시면'은 소망이 아니라 이미 확인된 사실이야. 이 위하심은 고난이 없다는 말이 아니라 고난 속에서도 하나님이 우리 편이라는 선언이야.`
  },
  {
    id: 'v_111',
    field: 'interpretation',
    newValue: `하박국 선지자는 혼란스러운 세상을 보며 언제 응답하시냐고 물었어. 하나님의 대답은 '때가 있다'는 거야. 내가 설정한 알람도 정해진 시간에 울리듯, 하나님의 약속에도 정해진 때가 있어. 그 때를 기다리는 게 믿음이야.`
  },
  {
    id: 'v_130',
    field: 'interpretation',
    newValue: `바울이 디모데에게 보낸 편지에서 하나님이 창조하신 것은 모두 선하다고 선언해. 당시 금욕주의자들이 특정 음식이나 결혼을 금했던 것에 대한 반론이야. 하나님이 주신 오늘 하루도 그 선함 안에 있어. 감사로 받으면 그 날이 달라져.`
  },
  {
    id: 'v_144',
    field: 'interpretation',
    newValue: `잠언은 사람의 마음에는 많은 계획이 있어도 결국 하나님의 뜻만 선다고 말해. 이건 체념이 아니라 자유야 — 모든 계획의 무게를 혼자 질 필요가 없다는 거야. 오늘 하루 계획대로 안 된 게 있어도 괜찮아. 그 뒤에 더 큰 그림이 있거든.`
  },
  {
    id: 'v_155',
    field: 'interpretation',
    newValue: `다윗이 광야에서 도망 중에 쓴 시편이야. 위협 속에서도 '날개 그늘 아래 피한다'고 노래한 거야. 이 그늘은 물리적 피신처가 아니라 하나님과 가까이 있는 상태를 뜻해. 그 안에서 기쁨이 솟아나고, 오늘 아침도 그 보호 아래서 시작할 수 있어.`
  },
  {
    id: 'v_138',
    field: 'interpretation',
    newValue: `이사야 26장은 하나님의 나라를 기다리는 백성의 기도야. '밤에 내 영혼이 주를 사모한다'는 말은 낮의 혼잡이 가라앉은 뒤 진짜 갈망이 드러나는 순간이야. 고요한 이 밤, 하나님을 향한 그 마음이 내일 아침의 시작이 되어.`
  },
  {
    id: 'v_145',
    field: 'interpretation',
    newValue: `다윗이 아침 제사를 드리며 쓴 시편이야. 하루의 첫 말을 하나님께 올려드리는 거야. 이 아침 기도는 할 일 목록보다, 어떤 피드보다 먼저 하나님과 나누는 첫 대화야. 이 새벽, 그 대화로 하루를 열어봐.`
  },
  {
    id: 'v_143',
    field: 'interpretation',
    newValue: `에스겔 36장에서 하나님이 바벨론에 포로로 잡혀간 이스라엘에게 하신 말씀이야. 돌처럼 굳어진 마음을 살아 있는 마음으로 바꿔주시겠다는 약속이야. 습관처럼 맞추는 알람이지만, 내일 아침은 다를 수 있어. 그 새 마음을 기대해봐.`
  },
  {
    id: 'v_142',
    field: 'interpretation',
    newValue: `이사야 40-41장은 바벨론 포로 생활로 지쳐 있던 이스라엘 백성을 향한 위로야. '두려워하지 말라'는 말은 두려움이 없다는 게 아니라, 그 두려움 한가운데서도 내가 함께한다는 선언이야. 오늘 밤 그 약속을 붙잡고 눈을 감아봐.`
  },
  {
    id: 'v_132',
    field: 'interpretation',
    newValue: `다윗이 원수에게 쫓기며 마음이 무너지려 할 때 쓴 기도야. '땅 끝에서 부르짖는다'는 말은 극한의 상황에서 드리는 간절한 기도야. 하나님은 그 소리에 귀를 기울이셔. 오늘 하루 무거웠던 것들, 그냥 안고 자지 않아도 돼.`
  },
  {
    id: 'v_136',
    field: 'interpretation',
    newValue: `예수님이 산상수훈에서 하신 말씀이야. '내일 일은 내일 걱정하라'는 건 무책임이 아니라 오늘에 충실하라는 초청이야. 내일의 짐을 오늘 밤까지 끌고 올 필요 없어. 알람을 맞춰두고 이제 쉬어도 괜찮아.`
  },
  {
    id: 'v_151',
    field: 'interpretation',
    newValue: `바울은 세례를 그리스도와 함께 죽고 다시 살아나는 상징으로 설명해. 옛 삶은 묻혔고, 새 생명으로 걷기 시작한 거야. 어제의 실수가 오늘을 정의하지 않아. 이 새벽, 그리스도 안에서 오늘은 진짜 새 출발이야.`
  },
  {
    id: 'v_153',
    field: 'interpretation',
    newValue: `마가복음 1장에서 예수님은 수많은 병자를 고친 바로 그다음 날 새벽, 아직 어두울 때 한적한 곳으로 가셨어. 가장 바쁜 날의 전날 새벽에도 하나님과 먼저 연결되셨던 거야. 이 새벽 시간이 하루의 진짜 출발점이야.`
  },
  {
    id: 'v_152',
    field: 'interpretation',
    newValue: `잠언 8장에서 지혜가 직접 말해. '나를 사랑하는 자를 나도 사랑하고, 나를 간절히 찾는 자가 나를 만날 것이라'고. 찾는 만큼 만나는 게 하나님의 방식이야. 오늘 밤 알람을 맞추는 이 마음도 그분을 향한 찾음이야.`
  },
  {
    id: 'v_149',
    field: 'interpretation',
    newValue: `잠언 4장은 아버지가 아들에게 지혜의 길을 가르치는 장면이야. 의인의 길은 처음부터 완성된 게 아니라 아침 햇살처럼 점점 밝아지는 거야. 지금 이 새벽에 걷는 한 걸음이 그 빛을 더 밝게 해. 오늘보다 내일이 더 빛날 거야.`
  },
];

// ── Google Sheets 컬럼 인덱스를 알파벳으로 변환 ─────────────────────────────
function colLetter(n) {
  let s = '';
  let x = n + 1;
  while (x > 0) {
    s = String.fromCharCode(65 + ((x - 1) % 26)) + s;
    x = Math.floor((x - 1) / 26);
  }
  return s;
}

// ── Google Sheets 업데이트 ───────────────────────────────────────────────────
async function updateSheet(patches, rowMap, headers) {
  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const intCol = headers.indexOf('interpretation');
  const appCol = headers.indexOf('application');

  if (intCol === -1) {
    console.error('  interpretation 컬럼을 헤더에서 찾을 수 없음');
    return;
  }

  const batchData = [];
  for (const p of patches) {
    const rowNum = rowMap[p.id];
    if (!rowNum) {
      console.warn(`  경고: ${p.id} 행 번호 없음 (시트에 미존재)`);
      continue;
    }
    const col = p.field === 'interpretation' ? intCol : appCol;
    const colL = colLetter(col);
    batchData.push({
      range: `${SHEET_NAME}!${colL}${rowNum}`,
      values: [[p.newValue]]
    });
  }

  if (batchData.length === 0) {
    console.log('  시트: 업데이트할 항목 없음');
    return;
  }

  await sheets.spreadsheets.values.batchUpdate({
    spreadsheetId: SHEET_ID,
    requestBody: { valueInputOption: 'RAW', data: batchData }
  });
  console.log(`  시트 ${batchData.length}개 셀 업데이트 완료`);
}

// ── 메인 ────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\nGoogle Sheets 행 번호 조회 중...');

  const auth = new google.auth.GoogleAuth({
    keyFile: SERVICE_ACCOUNT_PATH,
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({ version: 'v4', auth });

  const res = await sheets.spreadsheets.values.get({
    spreadsheetId: SHEET_ID,
    range: `${SHEET_NAME}!A:Z`
  });
  const rows = res.data.values || [];

  if (rows.length < 2) {
    console.error('시트 데이터 없음');
    process.exit(1);
  }

  // 헤더 정규화 (괄호 설명 제거)
  const headers = rows[0].map(h => {
    const s = String(h).trim();
    const p = s.indexOf('(');
    return p > 0 ? s.substring(0, p).trim() : s;
  });

  const idCol = headers.indexOf('verse_id');
  if (idCol === -1) {
    console.error('verse_id 컬럼 없음');
    process.exit(1);
  }

  // verse_id → 행 번호(1-based) 맵 생성
  const rowMap = {};
  for (let i = 1; i < rows.length; i++) {
    const vid = String(rows[i][idCol] || '').trim();
    if (vid) rowMap[vid] = i + 1;
  }

  // 대상 verse_id 행 번호 출력
  const targetIds = [...new Set(PATCHES.map(p => p.id))];
  console.log(`\n대상 ${targetIds.length}개 verse_id 행 번호:`);
  for (const id of targetIds) {
    console.log(`  ${id}: 행 ${rowMap[id] || '미발견'}`);
  }

  // ── Firestore 업데이트 ─────────────────────────────────────────────────
  console.log('\nFirestore 업데이트 중...');

  const firestoreUpdates = {};
  for (const p of PATCHES) {
    if (!firestoreUpdates[p.id]) firestoreUpdates[p.id] = {};
    firestoreUpdates[p.id][p.field] = p.newValue;
  }

  const batch = db.batch();
  for (const [id, fields] of Object.entries(firestoreUpdates)) {
    console.log(`  수정: ${id} (${Object.keys(fields).join(', ')})`);
    batch.update(db.collection('verses').doc(id), fields);
  }
  await batch.commit();
  console.log(`  Firestore ${Object.keys(firestoreUpdates).length}개 문서 업데이트 완료`);

  // ── Google Sheets 업데이트 ─────────────────────────────────────────────
  console.log('\nGoogle Sheets 업데이트 중...');
  await updateSheet(PATCHES, rowMap, headers);

  // ── 결과 요약 ──────────────────────────────────────────────────────────
  console.log('\n=== 수정 완료 ===');
  console.log(`총 ${targetIds.length}건 interpretation 필드 업데이트`);
  console.log('업데이트된 verse_id:');
  for (const id of targetIds) {
    console.log(`  - ${id}`);
  }

  process.exit(0);
}

main().catch(e => {
  console.error('오류:', e.message);
  console.error(e.stack);
  process.exit(1);
});
