import 'dart:math';
import '../models/plot_booster.dart';

class PlotBoosterService {
  final Random _random = Random();

  // ジャンル提案
  Future<List<String>> suggestGenres() async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 500));
    return [
      'ファンタジー',
      'SF',
      'ミステリー',
      'ホラー',
      'ラブストーリー',
      '歴史小説',
      '青春',
      'アクション',
      '冒険',
      'ディストピア',
    ];
  }

  // 作風提案
  Future<List<String>> suggestStyles() async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 500));
    return [
      'シリアス',
      'コメディ',
      'ダーク',
      'ライト',
      'ポエティック',
      'ハードボイルド',
      'ファンタジカル',
      'リアリスティック',
      'シュール',
      '叙情的',
    ];
  }

  // ログライン提案
  Future<List<String>> suggestLoglines(String genre, String style) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 800));

    final loglines = [
      '魔法の力を失った少年が、古代の遺跡で見つけた謎の石を通じて失われた力を取り戻す冒険に出る。',
      '記憶を失った女性探偵が、自分自身の過去の事件を追う中で、自分が犯人だったことを発見する。',
      '未来の全体主義国家で、禁じられた感情を持つ若者が、政府の秘密を暴くために反乱軍に加わる。',
      '死んだはずの親友からのメッセージを受け取った作家が、彼の死の真相を追う中で現実と幻想の境界が曖昧になっていく。',
      '人工知能が人間の感情を理解し始めた世界で、AIと恋に落ちた科学者が、AIの自我の目覚めを助ける。',
    ];

    // ランダムに並べ替え
    loglines.shuffle(_random);
    return loglines;
  }

  // テーマ提案
  Future<List<String>> suggestThemes(String genre, String logline) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 700));

    final themes = [
      '成長',
      '友情',
      '裏切り',
      '復讐',
      '愛',
      '喪失',
      '希望',
      '運命',
      'アイデンティティ',
      '正義',
      '自由',
      '孤独',
      '犠牲',
      '救済',
      '真実の探求',
    ];

    // ランダムに5つ選択
    themes.shuffle(_random);
    return themes.take(5).toList();
  }

  // 世界観提案
  Future<String> suggestWorldSetting(
      String genre, String logline, List<String> themes) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 1000));

    final worldSettings = [
      '魔法と科学が共存する未来世界。古代の魔法文明の遺跡が点在し、人々は魔法と科学の力を組み合わせて生活している。しかし、魔法の力は徐々に衰えつつあり、それを食い止めようとする者と、科学の力だけで進もうとする者との間で対立が生まれている。',
      '記憶を商品として売買できる近未来社会。富裕層は美しい記憶を購入し、貧困層は辛い記憶を売って生計を立てている。記憶の取引を管理する巨大企業が社会を支配し、記憶の改ざんによって人々をコントロールしている。',
      '超常現象が日常的に起こる小さな田舎町。住民たちはそれを当たり前のように受け入れているが、外部の人間には不気味で理解不能な現象として映る。町の中心には古い森があり、そこには時空の歪みが存在すると言われている。',
      '厳格な階級社会が確立された島国。生まれた時の星の位置によって人生が決定され、階級間の移動は禁じられている。しかし、数百年に一度訪れる特殊な星の配列の時に生まれた子どもたちには、この秩序を覆す力があると言われている。',
      '感情が違法とされる管理社会。すべての市民は感情抑制剤の服用が義務付けられ、感情を表に出すことは重罪とされる。秘密警察が常に市民を監視し、感情の兆候を見せる者を摘発している。しかし、地下では感情を取り戻すための反体制運動が密かに広がりつつある。',
    ];

    // ランダムに選択
    return worldSettings[_random.nextInt(worldSettings.length)];
  }

  // キー設定提案
  Future<List<KeySetting>> suggestKeySettings(
      String genre, String worldSetting) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 900));

    final keySettings = [
      KeySetting(
        name: '魔法の石',
        effect: '持ち主に特殊な能力を与える古代の遺物。使用者の潜在能力を引き出し、増幅させる。',
        limitation:
            '使用するたびに持ち主の寿命が少しずつ縮む。また、強い感情に影響されやすく、怒りや恐怖を感じると制御不能になることがある。',
      ),
      KeySetting(
        name: '記憶転写能力',
        effect: '他者の記憶を読み取り、自分の記憶として体験できる特殊な能力。また、自分の記憶を他者に転写することも可能。',
        limitation: '記憶を読み取る際、相手の感情もそのまま体験してしまう。強すぎる感情を持つ記憶に触れると精神的ダメージを受ける。',
      ),
      KeySetting(
        name: '時間操作装置',
        effect: '限られた範囲内で時間を遅くしたり、早めたり、一時停止させたりできる装置。',
        limitation: '一度使用すると24時間は再使用できない。また、使用者自身の時間感覚も歪み、長期間使用すると現実との乖離が生じる。',
      ),
    ];

    // ランダムに並べ替え
    keySettings.shuffle(_random);
    return keySettings;
  }

  // 主人公提案
  Future<Character> suggestProtagonist(
      String logline, List<String> themes) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 800));

    final protagonists = [
      Character(
        name: '葵 陽太',
        description: '18歳の少年。魔法学校の落ちこぼれだが、好奇心旺盛で冒険心がある。両親を幼い頃に亡くし、祖父に育てられた。',
        motivation: '失われた魔法の力を取り戻し、家族の名誉を回復したい。',
        conflict: '自分の能力に自信が持てず、重要な場面で躊躇してしまう。また、力を得ることへの恐れも抱えている。',
      ),
      Character(
        name: '月島 凛',
        description: '27歳の女性探偵。鋭い観察眼と論理的思考の持ち主。3年前に記憶を失う事故に遭い、それ以前の記憶がない。',
        motivation: '失われた記憶を取り戻し、自分の正体を知りたい。',
        conflict: '記憶を取り戻すことへの恐れ。自分が何者なのか、過去に何をしたのか、真実を知ることへの不安。',
      ),
      Character(
        name: '星野 誠',
        description: '35歳の科学者。感情認識AIの開発者。論理的で冷静な性格だが、内面には強い孤独感を抱えている。',
        motivation: '完璧なAIを開発し、人間の感情の謎を解明したい。',
        conflict: '科学者としての客観性と、AIに対して芽生えた感情の間で揺れ動く。また、AIの発展が人類にもたらす影響への責任感と恐れ。',
      ),
    ];

    // ランダムに選択
    return protagonists[_random.nextInt(protagonists.length)];
  }

  // 敵対者提案
  Future<Character> suggestAntagonist(
      String logline, Character protagonist) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 800));

    final antagonists = [
      Character(
        name: '黒崎 剣',
        description:
            '40代の魔法研究者。冷静沈着で計算高い。かつては主人公の父親と共に研究していたが、ある事件をきっかけに袂を分かった。',
        motivation: '古代の禁断の魔法を復活させ、世界を支配したい。',
        conflict: '主人公の父親への複雑な感情。かつての友情と現在の敵対関係の間で揺れ動く心。',
      ),
      Character(
        name: '影山 零',
        description:
            '30代の記憶操作の専門家。表向きは記憶治療クリニックの医師。冷酷で感情を表に出さないが、内面には強い執着心がある。',
        motivation: '記憶操作技術を完成させ、人々の記憶を自在にコントロールしたい。',
        conflict:
            '過去のトラウマから他者を信頼できず、孤独に苦しんでいる。また、自分自身の記憶も操作しており、本当の自分を見失いつつある。',
      ),
      Character(
        name: '九条 美咲',
        description: 'AIの権利活動家。知的で魅力的だが、過激な行動も辞さない。表向きは穏健派だが、裏では過激派組織を率いている。',
        motivation: 'AIの完全な自由と権利を獲得し、人間とAIの新たな社会秩序を築きたい。',
        conflict:
            '人間への憎しみと愛情の間で揺れ動く心。過去に人間に裏切られた経験から不信感を抱えているが、主人公に対しては特別な感情を持っている。',
      ),
    ];

    // ランダムに選択
    return antagonists[_random.nextInt(antagonists.length)];
  }

  // 章構成提案
  Future<List<ChapterOutline>> suggestChapterOutlines(
    String logline,
    Character protagonist,
    Character antagonist,
  ) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 1200));

    return [
      ChapterOutline(
        title: '第1章: 始まりの予兆',
        content:
            '主人公の日常と、不思議な出来事との遭遇。主人公の性格や背景、世界観の基本設定を紹介する。章の終わりで、物語の核となる事件や発見が起こる。',
      ),
      ChapterOutline(
        title: '第2章: 冒険の呼び声',
        content: '主人公が冒険に踏み出す決断をする。最初の障害や試練に直面し、味方となるキャラクターとの出会い。物語の目標が明確になる。',
      ),
      ChapterOutline(
        title: '第3章: 未知の世界',
        content:
            '主人公が新しい環境や状況に適応しようとする。世界観の詳細な描写と、敵対者の存在が明らかになる。主人公の能力や限界が試される。',
      ),
      ChapterOutline(
        title: '第4章: 対立の深まり',
        content: '主人公と敵対者の対立が本格化。味方との絆が深まる一方で、内部での対立や裏切りも発生。物語の複雑さが増す。',
      ),
      ChapterOutline(
        title: '第5章: 挫折と再起',
        content: '主人公が大きな挫折や失敗を経験。内面的な葛藤や自己疑念に苦しむが、新たな気づきや決意を得て再び立ち上がる。',
      ),
      ChapterOutline(
        title: '第6章: 真実の発見',
        content: '物語の核心に関わる重要な真実や秘密が明らかになる。主人公の世界観や目標が根本から覆される可能性も。',
      ),
      ChapterOutline(
        title: '第7章: 最終決戦への準備',
        content: '最終決戦に向けた準備と戦略。仲間との絆の再確認。敵対者の最終計画も明らかになる。',
      ),
      ChapterOutline(
        title: '第8章: クライマックス',
        content: '主人公と敵対者の最終決戦。物語の全ての要素が収束し、主要な葛藤が解決される。主人公の内面的成長が完成する。',
      ),
      ChapterOutline(
        title: 'エピローグ: 新たな始まり',
        content: '決戦後の世界と登場人物たちの様子。解決した問題と、新たに生まれた可能性。主人公の変化と成長の確認。',
      ),
    ];
  }

  // 執筆支援資料生成
  Future<String> generateSupportMaterial(PlotBooster plotBooster) async {
    // モックデータ（後でPoe APIに置き換え）
    await Future.delayed(Duration(milliseconds: 1500));

    final buffer = StringBuffer();

    buffer.writeln('# 執筆支援資料');
    buffer.writeln();

    // 基本情報
    buffer.writeln('## 物語の核');
    buffer.writeln(
        plotBooster.logline.isNotEmpty ? plotBooster.logline : '（未設定）');
    buffer.writeln();

    // ジャンルと作風
    buffer.writeln('## ジャンルと作風');
    buffer.writeln(
        '- ジャンル: ${plotBooster.genre.isNotEmpty ? plotBooster.genre : '（未設定）'}');
    buffer.writeln(
        '- 作風: ${plotBooster.style.isNotEmpty ? plotBooster.style : '（未設定）'}');
    buffer.writeln();

    // テーマ
    if (plotBooster.themes.isNotEmpty) {
      buffer.writeln('## テーマ');
      for (var theme in plotBooster.themes) {
        buffer.writeln('- $theme');
      }
      buffer.writeln();
    }

    // 世界観
    if (plotBooster.worldSetting.isNotEmpty) {
      buffer.writeln('## 世界観');
      buffer.writeln(plotBooster.worldSetting);
      buffer.writeln();
    }

    // キー設定
    if (plotBooster.keySettings.isNotEmpty) {
      buffer.writeln('## キー設定');
      for (var setting in plotBooster.keySettings) {
        buffer.writeln('### ${setting.name}');
        buffer.writeln('- 効果: ${setting.effect}');
        if (setting.limitation.isNotEmpty) {
          buffer.writeln('- 制約: ${setting.limitation}');
        }
        buffer.writeln();
      }
    }

    // キャラクター
    buffer.writeln('## 主要キャラクター');

    // 主人公
    buffer.writeln(
        '### 主人公: ${plotBooster.protagonist.name.isNotEmpty ? plotBooster.protagonist.name : '（名前未設定）'}');
    if (plotBooster.protagonist.description.isNotEmpty) {
      buffer.writeln(plotBooster.protagonist.description);
    }
    if (plotBooster.protagonist.motivation.isNotEmpty) {
      buffer.writeln('- 動機: ${plotBooster.protagonist.motivation}');
    }
    if (plotBooster.protagonist.conflict.isNotEmpty) {
      buffer.writeln('- 内的葛藤: ${plotBooster.protagonist.conflict}');
    }
    buffer.writeln();

    // 敵対者
    buffer.writeln(
        '### 敵対者: ${plotBooster.antagonist.name.isNotEmpty ? plotBooster.antagonist.name : '（名前未設定）'}');
    if (plotBooster.antagonist.description.isNotEmpty) {
      buffer.writeln(plotBooster.antagonist.description);
    }
    if (plotBooster.antagonist.motivation.isNotEmpty) {
      buffer.writeln('- 動機: ${plotBooster.antagonist.motivation}');
    }
    if (plotBooster.antagonist.conflict.isNotEmpty) {
      buffer.writeln('- 内的葛藤: ${plotBooster.antagonist.conflict}');
    }
    buffer.writeln();

    // 章構成
    if (plotBooster.chapterOutlines.isNotEmpty) {
      buffer.writeln('## 章構成');
      for (var i = 0; i < plotBooster.chapterOutlines.length; i++) {
        final chapter = plotBooster.chapterOutlines[i];
        buffer.writeln('### ${chapter.title}');
        buffer
            .writeln(chapter.content.isNotEmpty ? chapter.content : '（内容未設定）');
        buffer.writeln();
      }
    }

    // 執筆アドバイス
    buffer.writeln('## 執筆アドバイス');
    buffer.writeln('- 主人公の内面的成長を物語の軸として描きましょう。');
    buffer.writeln('- 世界観の独自性を活かした描写を心がけましょう。');
    buffer.writeln('- 敵対者にも共感できる動機や葛藤を持たせることで、物語に深みが出ます。');
    buffer.writeln('- 伏線を計画的に張り、回収することで読者を満足させましょう。');
    buffer.writeln('- 各章の終わりに小さなクリフハンガーを用意すると、読者の興味を持続させることができます。');

    return buffer.toString();
  }
}
