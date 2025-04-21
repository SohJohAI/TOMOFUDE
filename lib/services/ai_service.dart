import 'dart:math';
import 'ai_service_interface.dart';
import '../models/emotion.dart';

class DummyAIService implements AIService {
  final Random _random = Random();

  // ストーリーの続きの候補を生成するためのテンプレート
  final List<String> _continuationTemplates = [
    "そのとき、突然の音が響き渡った。[CHARACTER]は振り返り、目の前に立っていたのは[OBJECT]を持った見知らぬ人物だった。",
    "[CHARACTER]は深く息を吸い込み、決意を固めた。これが最後のチャンスだと分かっていた。",
    "雨が激しく降り始めた。[CHARACTER]は雨宿りのために近くの[PLACE]に駆け込んだ。そこで思いがけない出会いが待っていた。",
    "時計は午前3時を指していた。[CHARACTER]の頭の中で、ある考えが明確になっていった。",
    "遠くから聞こえてくる足音。[CHARACTER]は身を隠し、状況を見極めることにした。",
    "「もうこれ以上逃げられない」[CHARACTER]はついに向き合う時が来たことを悟った。",
    "風が強まり、空は暗雲に覆われていた。[CHARACTER]は嵐の前の静けさを感じながら、次の一手を考えていた。",
    "古い手紙が[CHARACTER]の手元に届いた。差出人は[CHARACTER]が長年会っていない[RELATION]からだった。",
    "「私が知っていることを話そう」[CHARACTER]は重い口を開いた。部屋の空気が一気に緊張感に包まれた。",
    "夢の中で[CHARACTER]は何度も同じ光景を見ていた。それは未来への警告なのか、あるいは過去の記憶なのか。",
  ];

  // 登場人物の候補
  final List<String> _characters = [
    "主人公",
    "彼",
    "彼女",
    "老人",
    "少女",
    "少年",
    "教授",
    "探偵",
    "旅人",
    "医師",
    "作家",
    "兵士",
    "騎士",
    "魔法使い",
    "王子",
    "姫",
    "商人",
    "船乗り",
    "盗賊",
    "農民",
    "村長",
    "学生",
    "先生"
  ];

  // 物や道具の候補
  final List<String> _objects = [
    "剣",
    "本",
    "手紙",
    "鍵",
    "地図",
    "懐中時計",
    "指輪",
    "ペンダント",
    "杖",
    "花",
    "薬",
    "宝石",
    "古い写真",
    "日記",
    "壺",
    "箱",
    "鏡",
    "ランプ",
    "フード",
    "ロープ",
    "ナイフ",
    "コイン",
    "ブローチ"
  ];

  // 場所の候補
  final List<String> _places = [
    "洞窟",
    "森",
    "古城",
    "廃墟",
    "図書館",
    "塔",
    "小屋",
    "港",
    "船",
    "市場",
    "神殿",
    "宿屋",
    "墓地",
    "橋",
    "庭園",
    "地下室",
    "屋根裏",
    "迷路",
    "砂浜",
    "湖",
    "山頂",
    "谷",
    "滝"
  ];

  // 関係性の候補
  final List<String> _relations = [
    "父",
    "母",
    "兄",
    "姉",
    "弟",
    "妹",
    "祖父",
    "祖母",
    "叔父",
    "叔母",
    "従兄弟",
    "幼なじみ",
    "恩師",
    "親友",
    "恋人",
    "婚約者",
    "夫",
    "妻",
    "子供",
    "孫",
    "弟子",
    "主人",
    "部下"
  ];

  // レビューの候補
  final List<Map<String, String>> _reviews = [
    {
      "reader": "登場人物の心情描写が丁寧で、物語に引き込まれました。展開にも意外性があり、次の展開が気になります。",
      "editor": "起承転結のバランスが良く、特に伏線の張り方が上手です。キャラクターの言動に一貫性があり、読者を惹きつける力があります。",
      "jury": "社会性のあるテーマを巧みに物語に織り込んでおり、読者に考えさせる深みがあります。文体も洗練されています。"
    },
    {
      "reader": "主人公の成長過程が共感できて、感情移入しやすい物語です。もう少し緊張感のある場面があればさらに良くなるでしょう。",
      "editor": "描写が豊かで世界観の構築が見事です。ダイアログの使い方も自然で読みやすいですが、全体のペースが少し遅いかもしれません。",
      "jury": "独自の視点で題材に切り込んでおり、既存の作品との差別化に成功しています。比喩表現の使い方にも独創性が見られます。"
    },
    {
      "reader": "謎解き要素が面白く、最後まで一気に読みました。キャラクター同士の関係性も魅力的で愛着が湧きます。",
      "editor":
          "伏線の回収が巧みで、読者を裏切らない展開が秀逸です。ただ、一部の説明的な文章は会話やアクションに置き換えるとより没入感が増すでしょう。",
      "jury": "精神的な成長や人間関係の機微を繊細に描き出しており、普遍的なテーマを持ちながらも新鮮さを感じさせる作品です。"
    },
  ];

  // 感情の種類
  final List<Map<String, dynamic>> _emotions = [
    {"name": "喜び", "code": "#FFD700", "baseValue": 70},
    {"name": "悲しみ", "code": "#4169E1", "baseValue": 60},
    {"name": "怒り", "code": "#FF4500", "baseValue": 65},
    {"name": "恐怖", "code": "#800080", "baseValue": 55},
    {"name": "驚き", "code": "#32CD32", "baseValue": 75},
    {"name": "期待", "code": "#FF69B4", "baseValue": 65},
    {"name": "不安", "code": "#708090", "baseValue": 60},
    {"name": "安心", "code": "#20B2AA", "baseValue": 70}
  ];

  // 設定情報の例
  @override
  Map<String, dynamic> generateSettings(String content) {
    // 文章が短い場合は基本的な設定を返す
    if (content.length < 100) {
      return {
        "characters": [
          {"name": "主人公", "description": "まだ詳しい情報がありません。"}
        ],
        "organizations": [],
        "terminology": [],
        "setting": "まだ詳しい情報がありません。",
        "genre": "未定"
      };
    }

    // 文章の長さに応じて設定情報を増やす
    final charCount = _random.nextInt(3) + 1;
    final characters = List.generate(charCount, (index) {
      final name = _getRandomElement(_characters);
      final desc = _generateCharacterDescription(name);
      return {"name": name, "description": desc};
    });

    final orgCount = _random.nextInt(2);
    final organizations = List.generate(orgCount, (index) {
      final name = "○○${_getRandomElement(['協会', '組合', '団', '組織', '軍', '党'])}";
      final desc = _generateOrganizationDescription(name);
      return {"name": name, "description": desc};
    });

    final termCount = _random.nextInt(3);
    final terminology = List.generate(termCount, (index) {
      final term = "「${_generateRandomWord()}」";
      final def = _generateTermDefinition(term);
      return {"term": term, "definition": def};
    });

    // 文章内容から雰囲気を読み取って設定
    final atmosphere = _detectAtmosphere(content);
    final setting = _generateSetting(atmosphere);
    final genre = _determineGenre(atmosphere, content);

    return {
      "characters": characters,
      "organizations": organizations,
      "terminology": terminology,
      "setting": setting,
      "genre": genre
    };
  }

  // プロット情報の生成
  @override
  Map<String, dynamic> generatePlotAnalysis(String content) {
    final stage = _getRandomElement(
        ['導入', '展開', '盛り上がり', 'クライマックスに向かう途中', 'クライマックス', '結末']);

    return {
      "introduction":
          "主人公が日常から非日常へと導かれる様子が描かれています。${_generateRandomSentence()}",
      "mainEvents": [
        _generateRandomEventSentence(),
        _generateRandomEventSentence(),
        _generateRandomEventSentence(),
      ],
      "turningPoints": [
        _generateRandomEventSentence(),
        _generateRandomEventSentence(),
      ],
      "currentStage": stage,
      "unresolvedIssues": [
        _generateRandomIssueSentence(),
        _generateRandomIssueSentence(),
      ],
      "possibleDevelopments": [
        _generateRandomDevelopmentSentence(),
        _generateRandomDevelopmentSentence(),
        _generateRandomDevelopmentSentence(),
      ]
    };
  }

  // ランダムな要素を選択
  String _getRandomElement(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  // 文章からキャラクター名を抽出する試み（単純な実装）
  String _extractCharacter(String content) {
    // 文章に登場する人物名を抽出する処理（実際はもっと複雑）
    // ここでは単純化のため、ランダムに選択
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.contains('「') && line.contains('」')) {
        // セリフがある行から話者を抽出する試み
        final speakerMatch = RegExp(r'(.+?)「').firstMatch(line);
        if (speakerMatch != null) {
          return speakerMatch.group(1)?.trim() ??
              _getRandomElement(_characters);
        }
      }
    }
    return _getRandomElement(_characters);
  }

  // 文章の分析（ダミー実装）
  Map<String, dynamic> _analyzeContent(String content) {
    // 実際のAIなら文章を分析して情報を抽出するが、ここではダミー実装
    return {
      'character': _extractCharacter(content),
      'object': _getRandomElement(_objects),
      'place': _getRandomElement(_places),
      'relation': _getRandomElement(_relations),
      'theme': _random.nextBool() ? '冒険' : '人間関係',
      'tone': _random.nextBool() ? '明るい' : '暗い',
    };
  }

  // AIレビューを生成
  @override
  Map<String, String> generateReview() {
    return _reviews[_random.nextInt(_reviews.length)];
  }

  // 複数の続きの候補を生成
  @override
  Future<List<String>> generateContinuations(String content) async {
    if (content.isEmpty) {
      return [
        "物語は始まったばかりだ。最初の一文を書いてみよう。",
        "白紙のキャンバスには無限の可能性がある。あなたの物語はどんな一文から始まるだろう？",
        "「すべての物語には始まりがある」彼はペンを手に取り、最初の一文を書き始めた。"
      ];
    }

    final analysis = _analyzeContent(content);
    final character = analysis['character'];

    // 3つの異なる続きを生成
    List<String> continuations = [];
    Set<int> usedTemplateIndices = {};

    while (continuations.length < 3) {
      int index = _random.nextInt(_continuationTemplates.length);
      if (usedTemplateIndices.contains(index)) continue;

      usedTemplateIndices.add(index);
      String template = _continuationTemplates[index];

      // テンプレートの変数を置換
      String continuation = template
          .replaceAll('[CHARACTER]', character)
          .replaceAll('[OBJECT]', analysis['object'])
          .replaceAll('[PLACE]', analysis['place'])
          .replaceAll('[RELATION]', analysis['relation']);

      continuations.add(continuation);
    }

    // AIの「思考」時間をシミュレート
    await Future.delayed(const Duration(seconds: 1));
    return continuations;
  }

  // 処理の遅延をシミュレート（実際のAI呼び出しのような遅延を演出）
  Future<List<String>> generateContinuationsAsync(String content) async {
    return generateContinuations(content);
  }

  // 展開候補を採用して拡張する
  @override
  Future<String> expandSuggestion(String content, String suggestion) async {
    // AIの「思考」時間をシミュレート
    await Future.delayed(const Duration(seconds: 1));

    // 選ばれた提案に基づいて展開を拡張
    final analysis = _analyzeContent(content);
    final character = analysis['character'];

    String expansion = suggestion + "\n\n";
    // 提案に基づいて2〜3文の展開を追加
    expansion += _generateExpansionParagraph(suggestion, character, analysis);

    return expansion;
  }

  // 提案を展開した段落を生成
  String _generateExpansionParagraph(
      String suggestion, String character, Map<String, dynamic> analysis) {
    // 提案に基づいて2〜3文の段落を生成
    List<String> sentences = [];

    // 最初の文は提案に関連する直接的な描写
    sentences.add(_elaborateSuggestion(suggestion, character));

    // 2文目は内的描写や感情
    sentences.add(_generateEmotionalResponse(character, analysis['tone']));

    // 3文目はさらなる展開の示唆
    if (_random.nextBool()) {
      sentences.add(_generateForeshadowing(analysis));
    }

    return sentences.join(' ');
  }

  // 感情分析メソッド
  @override
  Future<Map<String, dynamic>> analyzeEmotion(String content,
      {String? aiDocs}) async {
    // 分析処理をシミュレート
    await Future.delayed(const Duration(milliseconds: 1200));

    // モックデータ生成
    final segments = _generateMockEmotionSegments(content);

    return {
      "segments": segments,
      "summary": "物語全体を通して${_getRandomElement([
            '希望',
            '不安',
            '緊張',
            '喜び',
            '悲しみ'
          ])}の感情が主流となっており、${_getRandomElement([
            '中盤',
            '終盤',
            '序盤'
          ])}で感情の高まりが見られます。"
    };
  }

  // モック感情セグメントの生成
  List<Map<String, dynamic>> _generateMockEmotionSegments(String content) {
    // テキストの長さに基づいてセグメント数を決定
    final segmentCount = min(max(content.length ~/ 200, 3), 8);

    List<Map<String, dynamic>> segments = [];

    // 物語の流れを模したデータ生成（起承転結のような感情の流れ）
    for (int i = 0; i < segmentCount; i++) {
      final emotion = _emotions[_random.nextInt(_emotions.length)];
      final segmentPosition = i / (segmentCount - 1); // 0.0 から 1.0 の値

      // 物語の位置に応じた感情値と盛り上がり度の調整
      int emotionValue = _adjustValueBasedOnPosition(
          emotion["baseValue"] as int, segmentPosition);

      // 盛り上がり度は物語の中盤から終盤にかけて上昇するパターン
      int excitement = _generateExcitementValue(segmentPosition);

      segments.add({
        "name": "セグメント ${i + 1}",
        "dominantEmotion": emotion["name"],
        "emotionCode": emotion["code"],
        "emotionValue": emotionValue,
        "excitement": excitement,
        "description":
            _generateEmotionDescription(emotion["name"] as String, emotionValue)
      });
    }

    return segments;
  }

  // 物語の位置に基づいて感情値を調整
  int _adjustValueBasedOnPosition(int baseValue, double position) {
    // 物語の中盤で感情が高まり、終盤で解決に向かうようなパターン
    if (position < 0.3) {
      // 序盤: 基準値からやや低め
      return (baseValue - 10 + _random.nextInt(20)).clamp(40, 90);
    } else if (position < 0.7) {
      // 中盤: 基準値から高め
      return (baseValue + 5 + _random.nextInt(25)).clamp(50, 95);
    } else {
      // 終盤: 基準値に収束
      return (baseValue + _random.nextInt(20)).clamp(45, 90);
    }
  }

  // 盛り上がり度の生成
  int _generateExcitementValue(double position) {
    // 物語の進行に合わせて盛り上がりが変化するパターン
    if (position < 0.2) {
      // 序盤: 低め
      return 30 + _random.nextInt(20);
    } else if (position < 0.4) {
      // 序盤から中盤: 徐々に上昇
      return 40 + _random.nextInt(25);
    } else if (position < 0.7) {
      // 中盤: 高め
      return 60 + _random.nextInt(30);
    } else if (position < 0.9) {
      // クライマックス: 最高潮
      return 75 + _random.nextInt(25);
    } else {
      // 終盤: 収束
      return 50 + _random.nextInt(30);
    }
  }

  // 感情の説明文生成
  String _generateEmotionDescription(String emotion, int value) {
    final intensity = value > 80
        ? "強い"
        : value > 60
            ? "中程度の"
            : "弱い";

    final descriptions = {
      "喜び": [
        "$intensity喜びが表現されています。登場人物の幸福感が読者に伝わります。",
        "明るい雰囲気の中で$intensity喜びが描かれています。",
        "達成感や満足感による$intensity喜びが中心となっています。"
      ],
      "悲しみ": [
        "$intensity悲しみが漂っています。喪失感や別れの感情が表現されています。",
        "物悲しい雰囲気の中で$intensity悲しみが描かれています。",
        "内省的な$intensity悲しみが読者の共感を誘います。"
      ],
      "怒り": [
        "$intensity怒りや憤りが表現されています。対立や葛藤が描かれています。",
        "不満や不公平に対する$intensity怒りが中心となっています。",
        "抑制された$intensity怒りが緊張感を生み出しています。"
      ],
      "恐怖": [
        "$intensity恐怖や不安が描かれています。未知のものへの恐れが表現されています。",
        "差し迫った危険による$intensity恐怖感が中心です。",
        "漠然とした$intensity恐怖が雰囲気を支配しています。"
      ],
      "驚き": [
        "$intensity驚きや衝撃が表現されています。予想外の展開が描かれています。",
        "新たな発見による$intensity驚きが中心となっています。",
        "登場人物の$intensity驚きが読者の興味を引きます。"
      ],
      "期待": [
        "$intensity期待や希望が描かれています。未来への展望が表現されています。",
        "新たな可能性への$intensity期待感が中心です。",
        "変化を求める$intensity期待が物語を動かしています。"
      ],
      "不安": [
        "$intensity不安や懸念が表現されています。不確かな状況が描かれています。",
        "将来への$intensity不安感が中心となっています。",
        "内面的な$intensity不安が繊細に描写されています。"
      ],
      "安心": [
        "$intensity安心感や安堵が描かれています。危機からの解放が表現されています。",
        "信頼関係による$intensity安心感が中心です。",
        "平穏な状況での$intensity安心感が雰囲気を作り出しています。"
      ]
    };

    final descList = descriptions[emotion] ?? ["$emotion の感情が表現されています。"];
    return _getRandomElement(descList);
  }

  // AI資料生成メソッド
  @override
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo}) async {
    // 処理をシミュレート
    await Future.delayed(const Duration(milliseconds: 1500));

    // 基本情報
    String docs = "# 執筆支援資料\n\n";

    // 作品概要
    docs += "## 1. 作品概要\n";
    docs += "- **ジャンル**: ${_getRandomElement([
          'ファンタジー',
          'SF',
          'ミステリー',
          '恋愛',
          '青春',
          'ホラー'
        ])}\n";
    docs += "- **テーマ**: ${_getRandomElement([
          '成長',
          '葛藤',
          '愛',
          '冒険',
          '喪失',
          '再生',
          '対立'
        ])}\n";
    docs += "- **雰囲気**: ${_getRandomElement([
          '明るい',
          '暗い',
          '神秘的',
          '緊張感がある',
          '穏やか',
          '不安定'
        ])}\n";
    docs += "- **筋書き**: ${_generateRandomSentence()}\n\n";

    // 登場人物
    docs += "## 2. 登場人物\n";
    docs += "### 主人公\n";
    docs +=
        "- **人物像**: ${_generateCharacterDescription(_getRandomElement(_characters))}\n";
    docs += "- **動機**: ${_getRandomElement([
          '失われたものを取り戻す',
          '真実を知る',
          '誰かを守る',
          '復讐を果たす',
          '自分を証明する'
        ])}\n";
    docs += "- **成長の軌跡**: ${_getRandomElement([
          '自信を得る',
          '過去のトラウマを乗り越える',
          '他者との絆を深める',
          '自分の限界を超える'
        ])}\n\n";

    // 世界設定
    docs += "## 3. 世界設定\n";
    docs += _generateSetting(_detectAtmosphere(content)) + "\n\n";

    // 物語構造
    docs += "## 4. 物語構造\n";
    docs += "- **現在の段階**: ${_getRandomElement([
          '導入',
          '展開',
          '盛り上がり',
          'クライマックスに向かう途中',
          'クライマックス',
          '結末'
        ])}\n";
    docs += "- **重要な出来事**: ${_generateRandomEventSentence()}\n";
    docs += "- **物語のペース**: ${_getRandomElement([
          'ゆっくりと展開する',
          '急速に展開する',
          '緩急のメリハリがある'
        ])}\n\n";

    // 文体と語り口
    docs += "## 5. 文体と語り口\n";
    docs += "- **視点**: ${_getRandomElement(['一人称', '三人称限定', '三人称全知'])}\n";
    docs += "- **時制**: ${_getRandomElement(['現在形', '過去形', '現在形と過去形の混在'])}\n";
    docs += "- **特徴**: ${_getRandomElement([
          '簡潔な文体',
          '詩的な表現',
          '会話が多い',
          '内面描写が豊か',
          '情景描写が細かい'
        ])}\n\n";

    // 伏線と謎
    docs += "## 6. 重要な伏線と未解決の謎\n";
    docs += "- ${_generateRandomIssueSentence()}\n";
    docs += "- ${_generateRandomIssueSentence()}\n\n";

    // 今後の展開に向けた注意点
    docs += "## 7. 今後の展開に向けた注意点\n";
    docs += "- ${_getRandomElement([
          'キャラクターの動機に一貫性を持たせる',
          '伏線の回収を忘れない',
          '世界観の法則性を守る',
          '感情の起伏を大切にする'
        ])}\n";
    docs += "- ${_getRandomElement([
          '読者の期待を裏切る展開を検討する',
          '五感を使った描写を増やす',
          'キャラクターの内面と外面のギャップを表現する',
          'サブプロットを主要プロットと絡める'
        ])}\n";

    return docs;
  }

  // 提案文を詳細に展開
  String _elaborateSuggestion(String suggestion, String character) {
    final elaborations = [
      "$characterはじっと動きを止め、周囲の変化に注意を向けた。",
      "息を呑むような緊張感が$characterを包み込んだ。",
      "$characterの心臓は早鐘を打ち始めた。",
      "一瞬の迷いが$characterの心をよぎったが、すぐに決意を固めた。",
      "$characterの目に、新たな光が宿った。",
    ];

    return _getRandomElement(elaborations);
  }

  // 感情的な反応を生成
  String _generateEmotionalResponse(String character, String tone) {
    final positive = [
      "希望の光が胸に灯った。",
      "これが正しい道だと確信した。",
      "初めて感じる高揚感に身を委ねた。",
      "思わず微笑みがこぼれた。",
      "心が軽くなるのを感じた。",
    ];

    final negative = [
      "冷たい恐怖が背筋を走った。",
      "後悔の念が押し寄せてきた。",
      "不安が胸を締め付けた。",
      "言いようのない喪失感に襲われた。",
      "暗い予感が心の片隅でささやいた。",
    ];

    return "$character" +
        _getRandomElement(tone == '明るい' ? positive : negative);
  }

  // 伏線的な文を生成
  String _generateForeshadowing(Map<String, dynamic> analysis) {
    final foreshadowing = [
      "だが、それは始まりに過ぎなかった。",
      "しかし、${analysis['place']}の奥から聞こえる音が、新たな危険を予告していた。",
      "そのとき、遠くで${analysis['object']}の存在を思い出した。",
      "${analysis['relation']}との約束を果たすには、まだ長い道のりがあった。",
      "これから先にある試練に比べれば、これは序章に過ぎないのだろう。",
    ];

    return _getRandomElement(foreshadowing);
  }

  // キャラクター説明の生成
  String _generateCharacterDescription(String name) {
    final personalities = [
      "明るい",
      "内向的な",
      "冷静な",
      "感情的な",
      "勇敢な",
      "慎重な",
      "直感的な",
      "論理的な"
    ];
    final roles = ["主人公", "相棒", "助言者", "対抗者", "行動者", "情報提供者", "愉快犯"];
    final backgrounds = [
      "貧しい家庭で育った過去を持つ",
      "名家の出身で特権的な教育を受けてきた",
      "謎めいた過去を持つ",
      "悲劇的な出来事を経験している",
      "特殊な能力や才能を持っている",
      "普通の生活を送ってきたが突然の出来事で人生が変わった"
    ];

    return "$name は${_getRandomElement(personalities)}性格の${_getRandomElement(roles)}です。${_getRandomElement(backgrounds)}背景があります。";
  }

  // 組織説明の生成
  String _generateOrganizationDescription(String name) {
    final purposes = [
      "世界平和のため",
      "科学研究",
      "古代の秘密を探求",
      "革命",
      "秩序維持",
      "利益追求",
      "伝統保護"
    ];
    final features = [
      "秘密主義的",
      "開放的",
      "厳格な階級制度を持つ",
      "民主的な",
      "腐敗した",
      "革新的な",
      "保守的な"
    ];

    return "$name は${_getRandomElement(purposes)}に活動する${_getRandomElement(features)}組織です。";
  }

  // 用語定義の生成
  String _generateTermDefinition(String term) {
    final definitions = [
      "この世界に存在する特殊な能力",
      "古代から伝わる儀式",
      "特定の場所を示す言葉",
      "社会的な制度や階級",
      "重要な歴史的出来事",
      "この物語独自の概念"
    ];

    return "$term は${_getRandomElement(definitions)}を指します。";
  }

  // ランダムな単語生成
  String _generateRandomWord() {
    final prefixes = ["ア", "カ", "サ", "タ", "マ", "ヤ", "ラ", "ワ"];
    final centers = [
      "イ",
      "キ",
      "シ",
      "チ",
      "ミ",
      "リ",
      "ウ",
      "ク",
      "ス",
      "ツ",
      "ム",
      "ユ",
      "ル"
    ];
    final suffixes = ["ン", "ム", "ル", "ト", "ク", "ス", "ア", "リ", "ウ"];

    return "${_getRandomElement(prefixes)}${_getRandomElement(centers)}${_getRandomElement(suffixes)}";
  }

  // 雰囲気の検出
  String _detectAtmosphere(String content) {
    final atmospheres = [
      "現代的",
      "歴史的",
      "SF的",
      "ファンタジー",
      "ミステリアス",
      "日常的",
      "冒険的",
      "ホラー"
    ];
    return _getRandomElement(atmospheres);
  }

  // 設定情報の生成
  String _generateSetting(String atmosphere) {
    final settings = {
      "現代的": "現代の都市部が舞台。技術が発達しつつも人間関係の機微は変わらない。",
      "歴史的": "過去の特定の時代を舞台にした物語。歴史的背景が重要な役割を果たす。",
      "SF的": "未来または高度な技術が存在する世界。科学とそれがもたらす影響が描かれる。",
      "ファンタジー": "魔法や超自然的な要素が存在する架空の世界。独自の法則や種族が存在。",
      "ミステリアス": "謎や秘密が中心となる舞台。真実の解明が物語の主軸となる。",
      "日常的": "現実世界の日常を舞台に、小さな出来事や人間関係が描かれる。",
      "冒険的": "広大な世界を舞台に、旅や探索が行われる。新たな発見や冒険が中心。",
      "ホラー": "恐怖や不安を引き起こす要素が存在する世界。安全が脅かされる状況が描かれる。",
    };

    return settings[atmosphere] ?? "詳細不明の舞台設定。物語が進むにつれて明らかになっていく。";
  }

  // ジャンルの判断
  String _determineGenre(String atmosphere, String content) {
    final genreMap = {
      "現代的": ["現代小説", "恋愛小説", "社会派小説"],
      "歴史的": ["歴史小説", "時代小説", "歴史ファンタジー"],
      "SF的": ["SF", "ディストピア", "サイバーパンク"],
      "ファンタジー": ["ハイファンタジー", "ダークファンタジー", "現代ファンタジー"],
      "ミステリアス": ["ミステリー", "サスペンス", "心理サスペンス"],
      "日常的": ["日常系", "ほのぼの小説", "青春小説"],
      "冒険的": ["冒険小説", "アクション", "探検記"],
      "ホラー": ["ホラー", "怪奇小説", "ダークファンタジー"],
    };

    final genreList = genreMap[atmosphere] ?? ["未分類"];
    return _getRandomElement(genreList);
  }

  // ランダムな文を生成
  String _generateRandomSentence() {
    final subjects = ["主人公", "物語", "世界", "状況", "舞台"];
    final verbs = ["描かれる", "展開する", "見えてくる", "明らかになる", "変化する"];
    final objects = ["内面", "真実", "背景", "関係性", "過去"];

    return "${_getRandomElement(subjects)}の${_getRandomElement(objects)}が${_getRandomElement(verbs)}。";
  }

  // ランダムなイベント文を生成
  String _generateRandomEventSentence() {
    final subjects = ["主人公", "重要人物", "敵対者", "協力者", "組織"];
    final actions = ["発見する", "対決する", "協力する", "裏切る", "逃亡する", "達成する"];
    final objects = ["重要な情報", "隠された真実", "強力な武器", "貴重なアイテム", "重要な場所", "長年の目標"];

    return "${_getRandomElement(subjects)}が${_getRandomElement(objects)}を${_getRandomElement(actions)}。";
  }

  // ランダムな問題文を生成
  String _generateRandomIssueSentence() {
    final issues = [
      "主人公の過去に関する謎",
      "敵対者の真の目的",
      "組織の秘密",
      "重要なアイテムの行方",
      "重要人物との関係性",
      "予言や伝説の真意",
      "裏切り者の正体"
    ];

    return _getRandomElement(issues);
  }

  // ランダムな展開予測文を生成
  String _generateRandomDevelopmentSentence() {
    final developments = [
      "主人公が隠された能力に目覚める",
      "敵対者の真の姿が明らかになる",
      "重要な同盟関係が形成される",
      "大きな試練や危機が訪れる",
      "重要な選択を迫られる岐路に立つ",
      "思わぬ協力者が現れる",
      "新たな敵の出現"
    ];

    return _getRandomElement(developments);
  }
}

enum SettingType {
  text,
  character,
  organization,
  terminology,
}
