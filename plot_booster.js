// アクティブステップを管理
let currentStep = 0;
const totalSteps = 8;

// ローディング表示用
function showLoading(container, message = '読み込み中...') {
  container.innerHTML = `
    <div class="flex items-center justify-center p-4">
      <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      <span>${message}</span>
    </div>
  `;
}

// ステップ表示管理
function showStep(step) {
  if (step < 0 || step >= totalSteps) return;

  // 現在のステップを非表示
  document.querySelectorAll('.step-content').forEach(el => {
    el.classList.remove('active');
  });

  // 指定されたステップを表示
  document.getElementById(`step${step}`).classList.add('active');

  // インジケーターの更新
  document.querySelectorAll('.step-indicator').forEach((el, index) => {
    if (index === step) {
      el.classList.remove('bg-gray-200', 'dark:bg-gray-700', 'text-gray-700', 'dark:text-gray-300');
      el.classList.add('bg-primary', 'text-white');
    } else {
      el.classList.remove('bg-primary', 'text-white');
      el.classList.add('bg-gray-200', 'dark:bg-gray-700', 'text-gray-700', 'dark:text-gray-300');
    }
  });

  currentStep = step;

  // ページ上部へスクロール
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  });
}

// 次のステップへ
function nextStep() {
  if (currentStep < totalSteps - 1) {
    showStep(currentStep + 1);
  }
}

// 前のステップへ
function prevStep() {
  if (currentStep > 0) {
    showStep(currentStep - 1);
  }
}

// テーマボタンのクリックイベント
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.theme-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      const themesInput = document.getElementById('themes');
      const currentThemes = themesInput.value.trim();
      const selectedTheme = this.textContent;

      // 選択状態の視覚的フィードバック
      document.querySelectorAll('.theme-btn').forEach(b => {
        b.classList.remove('selected');
      });
      this.classList.add('selected');

      if (currentThemes === '') {
        themesInput.value = selectedTheme;
      } else if (!currentThemes.includes(selectedTheme)) {
        themesInput.value = currentThemes + '、' + selectedTheme;
      }
    });
  });

  // 章を追加するボタンのイベント
  document.getElementById('addChapterBtn').addEventListener('click', function () {
    const chaptersContainer = document.getElementById('chaptersContainer');
    const chapterCount = chaptersContainer.querySelectorAll('.chapter-item').length;

    const newChapter = document.createElement('div');
    newChapter.className = 'chapter-item';
    newChapter.innerHTML = `
      <div class="flex items-center mb-2">
        <span class="chapter-number font-semibold">第${chapterCount + 1}章</span>
        <input type="text" class="chapter-title ml-2 flex-grow px-3 py-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" placeholder="章のタイトル">
        <button class="delete-chapter-btn ml-2 text-red-500 hover:text-red-700">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
          </svg>
        </button>
      </div>
      <textarea class="chapter-content w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" rows="3" placeholder="この章で起こる出来事の概要"></textarea>
    `;

    chaptersContainer.appendChild(newChapter);

    // 削除ボタンのイベントリスナーを追加
    newChapter.querySelector('.delete-chapter-btn').addEventListener('click', function () {
      if (confirm('この章を削除してもよろしいですか？')) {
        newChapter.remove();
        updateChapterNumbers();
      }
    });
  });

  // 既存の章の削除ボタンにイベントリスナーを追加
  document.querySelectorAll('.delete-chapter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      const chapterItem = this.closest('.chapter-item');
      if (confirm('この章を削除してもよろしいですか？')) {
        chapterItem.remove();
        updateChapterNumbers();
      }
    });
  });

  // プロットカード生成ボタンのイベント
  document.getElementById('generateCardsBtn').addEventListener('click', function () {
    const plotCardsContainer = document.getElementById('plotCardsContainer');
    plotCardsContainer.innerHTML = '';

    // 物語の情報を収集
    const genre = document.getElementById('genre').value;
    const style = document.getElementById('style').value;
    const logline = document.getElementById('logline').value;
    const themes = document.getElementById('themes').value;

    // 章の情報を収集
    const chapters = [];
    document.querySelectorAll('.chapter-item').forEach(item => {
      const title = item.querySelector('.chapter-title').value || `第${chapters.length + 1}章`;
      const content = item.querySelector('.chapter-content').value || '内容未設定';
      chapters.push({ title, content });
    });

    // カラーパレットをランダムに選択（ダークモード対応）
    const isDarkMode = document.documentElement.classList.contains('dark');
    const colorPalettes = isDarkMode ? [
      { bg: 'bg-indigo-900', border: 'border-indigo-700', text: 'text-indigo-100' },
      { bg: 'bg-purple-900', border: 'border-purple-700', text: 'text-purple-100' },
      { bg: 'bg-blue-900', border: 'border-blue-700', text: 'text-blue-100' },
      { bg: 'bg-green-900', border: 'border-green-700', text: 'text-green-100' },
      { bg: 'bg-amber-900', border: 'border-amber-700', text: 'text-amber-100' }
    ] : [
      { bg: 'bg-indigo-100', border: 'border-indigo-300', text: 'text-indigo-900' },
      { bg: 'bg-purple-100', border: 'border-purple-300', text: 'text-purple-900' },
      { bg: 'bg-blue-100', border: 'border-blue-300', text: 'text-blue-900' },
      { bg: 'bg-green-100', border: 'border-green-300', text: 'text-green-900' },
      { bg: 'bg-amber-100', border: 'border-amber-300', text: 'text-amber-900' }
    ];

    // カバーカード
    const coverPalette = colorPalettes[Math.floor(Math.random() * colorPalettes.length)];
    const coverCard = document.createElement('div');
    coverCard.className = `plot-card ${coverPalette.bg} ${coverPalette.border} ${coverPalette.text} p-6 rounded-lg shadow-md border-2 relative min-h-[200px]`;
    coverCard.innerHTML = `
      <div class="plot-card-inner">
        <div class="plot-card-front h-full flex flex-col justify-between">
          <div>
            <h3 class="text-xl font-bold mb-2">${genre || '未設定'} × ${style || '未設定'}</h3>
            <p class="text-md italic">${logline || '物語の要約が未設定です'}</p>
          </div>
          <div class="mt-4">
            <p class="text-sm">テーマ: ${themes || '未設定'}</p>
          </div>
        </div>
      </div>
    `;
    plotCardsContainer.appendChild(coverCard);

    // 章ごとにカードを生成
    chapters.forEach((chapter, index) => {
      const palette = colorPalettes[index % colorPalettes.length];
      const card = document.createElement('div');
      card.className = `plot-card ${palette.bg} ${palette.border} ${palette.text} p-6 rounded-lg shadow-md border-2 relative min-h-[200px]`;
      card.innerHTML = `
        <div class="plot-card-inner">
          <div class="plot-card-front h-full flex flex-col justify-between">
            <div>
              <span class="text-sm font-medium">第${index + 1}章</span>
              <h3 class="text-xl font-bold mb-2">${chapter.title}</h3>
              <p class="text-md">${chapter.content}</p>
            </div>
          </div>
        </div>
      `;
      plotCardsContainer.appendChild(card);
    });

    // 成功メッセージを表示
    showToast('プロットカードを生成しました');

    // カードコンテナまでスクロール
    plotCardsContainer.scrollIntoView({ behavior: 'smooth' });
  });

  // 執筆支援資料生成ボタンのイベント
  document.getElementById('generateDocsBtn').addEventListener('click', function () {
    // コンテナを表示
    const docsContainer = document.getElementById('docsContainer');
    const docsContent = document.getElementById('docsContent');
    docsContainer.classList.remove('hidden');

    // ローディング表示
    showLoading(docsContent, '執筆支援資料を作成中...');

    // 全ステップの情報を収集
    const allInfo = getAllStepInfo();

    // 章構成の情報を収集
    const chapters = [];
    document.querySelectorAll('.chapter-item').forEach(item => {
      const title = item.querySelector('.chapter-title').value || '';
      const content = item.querySelector('.chapter-content').value || '';
      if (title || content) {
        chapters.push({ title, content });
      }
    });

    // 執筆支援資料を生成
    setTimeout(() => {
      generateWritingGuide(allInfo, chapters, docsContent);

      // 成功メッセージを表示
      showToast('執筆支援資料を生成しました');

      // ドキュメントコンテナまでスクロール
      docsContainer.scrollIntoView({ behavior: 'smooth' });
    }, 1000);
  });

  // コピーボタンの設定
  document.getElementById('copyDocsBtn').addEventListener('click', function () {
    const docsContent = document.getElementById('docsContent');
    const textToCopy = docsContent.innerText;

    // クリップボードにコピー
    navigator.clipboard.writeText(textToCopy)
      .then(() => {
        // コピー成功の表示
        const originalText = this.innerHTML;
        this.innerHTML = `
          <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          コピーしました
        `;

        // 元に戻す
        setTimeout(() => {
          this.innerHTML = originalText;
        }, 2000);

        // トースト表示
        showToast('クリップボードにコピーしました');
      })
      .catch(err => {
        console.error('クリップボードへのコピーに失敗しました:', err);
        showToast('コピーに失敗しました', true);
      });
  });

  // その他選択時の追加入力欄表示制御
  document.getElementById('genre').addEventListener('change', toggleOtherFields);
  document.getElementById('style').addEventListener('change', toggleOtherFields);

  // リスタートボタンのイベント
  document.getElementById('restartBtn').addEventListener('click', function () {
    if (confirm('最初からやり直しますか？入力内容はリセットされます。')) {
      // フォームをリセット
      document.querySelectorAll('input, textarea, select').forEach(el => {
        el.value = '';
      });

      // AI応答をクリア
      document.querySelectorAll('.ai-response').forEach(el => {
        el.innerHTML = '';
        el.classList.remove('show');
      });

      // テーマボタンの選択状態をリセット
      document.querySelectorAll('.theme-btn').forEach(btn => {
        btn.classList.remove('selected');
      });

      // 章を初期状態に戻す
      const chaptersContainer = document.getElementById('chaptersContainer');
      chaptersContainer.innerHTML = `
        <div class="chapter-item">
          <div class="flex items-center mb-2">
            <span class="chapter-number font-semibold">第1章</span>
            <input type="text" class="chapter-title ml-2 flex-grow px-3 py-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" placeholder="章のタイトル">
            <button class="delete-chapter-btn ml-2 text-red-500 hover:text-red-700">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </button>
          </div>
          <textarea class="chapter-content w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" rows="3" placeholder="この章で起こる出来事の概要"></textarea>
        </div>
        <div class="chapter-item">
          <div class="flex items-center mb-2">
            <span class="chapter-number font-semibold">第2章</span>
            <input type="text" class="chapter-title ml-2 flex-grow px-3 py-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" placeholder="章のタイトル">
            <button class="delete-chapter-btn ml-2 text-red-500 hover:text-red-700">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </button>
          </div>
          <textarea class="chapter-content w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" rows="3" placeholder="この章で起こる出来事の概要"></textarea>
        </div>
        <div class="chapter-item">
          <div class="flex items-center mb-2">
            <span class="chapter-number font-semibold">第3章</span>
            <input type="text" class="chapter-title ml-2 flex-grow px-3 py-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" placeholder="章のタイトル">
            <button class="delete-chapter-btn ml-2 text-red-500 hover:text-red-700">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </button>
          </div>
          <textarea class="chapter-content w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-base" rows="3" placeholder="この章で起こる出来事の概要"></textarea>
        </div>
      `;

      // 削除ボタンのイベントリスナーを再設定
      document.querySelectorAll('.delete-chapter-btn').forEach(btn => {
        btn.addEventListener('click', function () {
          const chapterItem = this.closest('.chapter-item');
          if (confirm('この章を削除してもよろしいですか？')) {
            chapterItem.remove();
            updateChapterNumbers();
          }
        });
      });

      // プロットカードをクリア
      document.getElementById('plotCardsContainer').innerHTML = '';

      // 執筆支援資料をクリア
      document.getElementById('docsContainer').classList.add('hidden');

      // 最初のステップに戻る
      showStep(0);

      // 成功メッセージを表示
      showToast('入力内容をリセットしました');
    }
  });

  // ダークモードトグルの設定
  document.getElementById('darkModeToggle').addEventListener('click', function () {
    const html = document.documentElement;
    const isDark = html.classList.contains('dark');

    if (isDark) {
      html.classList.remove('dark');
      localStorage.setItem('darkMode', 'false');
    } else {
      html.classList.add('dark');
      localStorage.setItem('darkMode', 'true');
    }
  });

  // AIヘルプボタンの設定
  for (let i = 0; i <= 6; i++) {
    setupAIHelp(i);
  }

  // 初期表示
  showStep(0);
});

// その他選択時の追加入力欄表示制御
function toggleOtherFields() {
  const genre = document.getElementById('genre').value;
  const style = document.getElementById('style').value;
  const customGenre = document.getElementById('customGenre');
  const customStyle = document.getElementById('customStyle');
  const otherGenreStyleField = document.getElementById('other-genre-style');

  if (genre === 'フリー入力') {
    customGenre.classList.remove('hidden');
  } else {
    customGenre.classList.add('hidden');
  }

  if (style === 'フリー入力') {
    customStyle.classList.remove('hidden');
  } else {
    customStyle.classList.add('hidden');
  }

  if (genre === 'その他' || style === 'その他') {
    otherGenreStyleField.classList.remove('hidden');
  } else {
    otherGenreStyleField.classList.add('hidden');
  }
}

// 章番号を更新する関数
function updateChapterNumbers() {
  document.querySelectorAll('.chapter-item').forEach((item, index) => {
    item.querySelector('.chapter-number').textContent = `第${index + 1}章`;
  });
}

// 全ステップの情報を収集する関数
function getAllStepInfo() {
  // STEP 0: ジャンルと作風
  let genre = document.getElementById('genre').value;
  const customGenre = document.getElementById('customGenre').value;
  let style = document.getElementById('style').value;
  const customStyle = document.getElementById('customStyle').value;
  const otherGenreStyle = document.getElementById('otherGenreStyle').value;

  // フリー入力の場合はそちらを優先
  if (genre === 'フリー入力' && customGenre) {
    genre = customGenre;
  }
  if (style === 'フリー入力' && customStyle) {
    style = customStyle;
  }

  // その他の場合はその入力を使用
  if ((genre === 'その他' || style === 'その他') && otherGenreStyle) {
    if (genre === 'その他') genre = otherGenreStyle;
    if (style === 'その他') style = otherGenreStyle;
  }

  // STEP 1: ログライン
  const logline = document.getElementById('logline').value;

  // STEP 2: テーマ・モチーフ
  const themes = document.getElementById('themes').value;

  // STEP 3: 世界観
  const worldSetting = document.getElementById('worldSetting').value;

  // STEP 4: キー設定
  const keySetting = document.getElementById('keySetting').value;

  // STEP 5: 主人公と敵対者
  const protagonist = document.getElementById('protagonist').value;
  const antagonist = document.getElementById('antagonist').value;

  return {
    genre,
    style,
    logline,
    themes,
    worldSetting,
    keySetting,
    protagonist,
    antagonist
  };
}

// AI支援ボタンの設定
function setupAIHelp(stepNumber) {
  const button = document.getElementById(`aiHelpBtn${stepNumber}`);
  const responseContainer = document.getElementById(`aiResponse${stepNumber}`);

  if (!button || !responseContainer) return;

  button.addEventListener('click', function () {
    // AI応答コンテナを表示
    responseContainer.classList.add('show');

    // ローディング表示
    showLoading(responseContainer);

    // 全ステップの情報を収集
    const allInfo = getAllStepInfo();

    // AIに送るプロンプトを準備
    let prompt = '';

    switch (stepNumber) {
      case 0:
        prompt = "小説のジャンルと作風のアイデアを5つほど提案してください。";
        break;
      case 1:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」の小説のログラインのアイデアを提案してください。`;
        break;
      case 2:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」、ログライン「${allInfo.logline}」の小説に適したテーマやモチーフを提案してください。`;
        break;
      case 3:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」、ログライン「${allInfo.logline}」、テーマ「${allInfo.themes}」の小説に適した世界観設定を提案してください。`;
        break;
      case 4:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」、ログライン「${allInfo.logline}」、テーマ「${allInfo.themes}」、世界観「${allInfo.worldSetting}」の小説に適したキー設定（特殊能力や魔法システムなど）を提案してください。`;
        break;
      case 5:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」、ログライン「${allInfo.logline}」、テーマ「${allInfo.themes}」、世界観「${allInfo.worldSetting}」、キー設定「${allInfo.keySetting}」の小説に適した主人公と敵対者/障害の設定を提案してください。`;
        break;
      case 6:
        prompt = `ジャンル「${allInfo.genre}」、作風「${allInfo.style}」、ログライン「${allInfo.logline}」、テーマ「${allInfo.themes}」、世界観「${allInfo.worldSetting}」、キー設定「${allInfo.keySetting}」、主人公「${allInfo.protagonist}」、敵対者「${allInfo.antagonist}」の小説に適した章構成（3～5章程度）を提案してください。`;
        break;
    }

    // 模擬的なAI応答を生成（実際のアプリではAI APIを呼び出す）
    setTimeout(() => {
      const response = generateMockAIResponse(stepNumber, allInfo);
      responseContainer.innerHTML = response;
      makeResponseClickable(responseContainer, stepNumber);
    }, 1500);
  });
}

// 模擬的なAI応答を生成する関数
function generateMockAIResponse(stepNumber, info) {
  switch (stepNumber) {
    case 0:
      return `
        <h3 class="font-bold mb-2">ジャンルと作風の提案</h3>
        <ol class="space-y-2">
          <li>ダークファンタジー × 哲学的</li>
          <li>近未来SF × サスペンス</li>
          <li>歴史 × 叙情的</li>
          <li>現代ドラマ × コメディ</li>
          <li>ミステリー × 青春</li>
        </ol>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 1:
      return `
        <h3 class="font-bold mb-2">ログラインの提案</h3>
        <ol class="space-y-2">
          <li>記憶を失った少年が、自分の正体を探る旅で、世界を滅ぼす鍵を握っていることを知る。</li>
          <li>不思議な能力を持つ少女が、自分を追う組織から逃れながら、その力の真実に迫る。</li>
          <li>二つの世界の狭間で生きる青年が、両方の世界を救うために自らの存在を賭ける。</li>
          <li>古い呪いに縛られた一族の末裔が、過去の罪を贖うために禁断の魔法に手を染める。</li>
          <li>孤独な天才科学者が作り出した人工知能が、創造主の想像を超えて進化し始める。</li>
        </ol>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 2:
      return `
        <h3 class="font-bold mb-2">テーマ・モチーフの提案</h3>
        <ol class="space-y-2">
          <li><strong>自己探求</strong>：自分の本当のアイデンティティを探る旅</li>
          <li><strong>運命と選択</strong>：定められた運命と自由意志の葛藤</li>
          <li><strong>喪失と再生</strong>：大切なものを失い、新たな意味を見出す</li>
          <li><strong>孤独</strong>：他者との繋がりを求める魂の叫び</li>
          <li><strong>真実の追求</strong>：隠された真実を明らかにする過程</li>
        </ol>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 3:
      return `
        <h3 class="font-bold mb-2">世界観設定の提案</h3>
        <ol class="space-y-2">
          <li>時代背景：記憶を操作する技術が発達した近未来社会</li>
          <li>舞台：巨大企業が支配する都市と、記憶改変から逃れた人々が住む辺境地域</li>
          <li>社会制度：記憶の純度によって階級が決まる管理社会</li>
          <li>独自ルール：「記憶の欠片」を集めることで失われた過去を取り戻せる</li>
        </ol>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 4:
      return `
        <h3 class="font-bold mb-2">キー設定の提案</h3>
        <ol class="space-y-2">
          <li>
            <strong>【名前】メモリーダイブ</strong><br>
            【効果】他者の記憶に入り込み、体験や情報を得ることができる<br>
            【制約】深く潜るほど自分の記憶を失うリスクが高まる
          </li>
          <li>
            <strong>【名前】エコーズ・オブ・パスト</strong><br>
            【効果】場所に残された感情の残響を感じ取り、過去の出来事を視覚化できる<br>
            【制約】強い感情が残る場所ほど使用者の精神を蝕む
          </li>
          <li>
            <strong>【名前】メモリーシール</strong><br>
            【効果】記憶を物体に封印し、後で再生したり他者と共有できる<br>
            【制約】一度封印した記憶は薄れていき、完全に消えることもある
          </li>
        </ol>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 5:
      return `
        <h3 class="font-bold mb-2">主人公と敵対者の提案</h3>
        <h4 class="font-semibold mt-3">主人公案1</h4>
        <p>
          【名前】レイ・ノーマン（22歳）<br>
          【外見】白髪と異色の瞳を持つ青年、額に不思議な模様がある<br>
          【性格】冷静沈着だが好奇心旺盛、他者を信じられない<br>
          【能力】強力なメモリーダイブ能力を持つが、制御が難しい<br>
          【動機】失われた自分の記憶と家族を取り戻すため<br>
          【弱点】深い記憶へのダイブ後に激しい頭痛と記憶の混乱に苦しむ
        </p>
        
        <h4 class="font-semibold mt-3">敵対者案1</h4>
        <p>
          【名前】ディレクター（本名不明）<br>
          【役割】記憶管理局の最高責任者<br>
          【能力】他者の記憶を完全に書き換える力を持つ<br>
          【動機】「完璧な社会」を作るため、不要な記憶や感情を排除しようとする<br>
          【特徴】常に穏やかな笑顔を浮かべ、冷酷な命令を下す<br>
          【主人公との関係】レイの失われた記憶の鍵を握っている
        </p>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
    case 6:
      return `
        <h3 class="font-bold mb-2">章構成の提案</h3>
        
        <h4 class="font-semibold mt-3">第1章：記憶の断片</h4>
        <p>
          レイが記憶を失った状態で目覚めるところから物語が始まる。彼の持つ不思議な能力が明らかになり、自分の過去を探る旅に出ることを決意する。途中、記憶管理局の追手から逃れながら、辺境地域へと向かう。
        </p>
        
        <h4 class="font-semibold mt-3">第2章：記憶の守護者</h4>
        <p>
          辺境地域で「記憶の守護者」と呼ばれる反体制組織と出会う。彼らの助けを借りて自分の能力を制御する方法を学び、断片的な記憶を取り戻し始める。同時に、ディレクターの「完璧な社会計画」の全容が明らかになる。
        </p>
        
        <h4 class="font-semibold mt-3">第3章：記憶の迷宮</h4>
        <p>
          仲間と共に記憶管理局の本部に潜入。ディレクターとの対決の中で、レイは自分が記憶操作の実験体だったこと、そして彼の記憶には世界の真実が隠されていることを知る。最終的な選択を迫られるレイ。
        </p>
        
        <h4 class="font-semibold mt-3">第4章：記憶の解放</h4>
        <p>
          ディレクターとの最終決戦。レイは自分の記憶を犠牲にして、すべての人々の記憶を解放するという選択をする。世界は混乱に陥るが、人々は真実を知る自由を得る。レイ自身は記憶を失うが、新たな旅立ちを迎える。
        </p>
        <p class="mt-4 text-sm">※クリックすると選択できます</p>
      `;
  }
  return '';
}

// トースト通知を表示する関数
function showToast(message, isError = false) {
  const toast = document.getElementById('toast');
  if (!toast) return;

  toast.textContent = message;
  toast.className = isError ?
    'toast show bg-red-500' :
    'toast show bg-gray-800 dark:bg-gray-700';

  setTimeout(() => {
    toast.classList.remove('show');
  }, 3000);
}

// AI応答をクリック可能にする関数
function makeResponseClickable(container, stepNumber) {
  // 実装は省略（実際のアプリでは必要に応じて実装）
}

// 執筆支援資料を生成する関数
function generateWritingGuide(info, chapters, container) {
  const content = `
    <h2 class="text-2xl font-bold mb-4">執筆支援資料</h2>
    
    <h3 class="text-xl font-semibold mt-6 mb-2">1. 作品概要</h3>
    <p><strong>ジャンル：</strong>${info.genre || '未設定'}</p>
    <p><strong>作風：</strong>${info.style || '未設定'}</p>
    <p><strong>ログライン：</strong>${info.logline || '未設定'}</p>
    <p><strong>テーマ：</strong>${info.themes || '未設定'}</p>
    
    <h3 class="text-xl font-semibold mt-6 mb-2">2. 世界観設定</h3>
    <div class="whitespace-pre-line">${info.worldSetting || '未設定'}</div>
    
    <h3 class="text-xl font-semibold mt-6 mb-2">3. キー設定</h3>
    <div class="whitespace-pre-line">${info.keySetting || '未設定'}</div>
    
    <h3 class="text-xl font-semibold mt-6 mb-2">4. 登場人物</h3>
    <h4 class="text-lg font-medium mt-4 mb-1">主人公</h4>
    <div class="whitespace-pre-line">${info.protagonist || '未設定'}</div>
    
    <h4 class="text-lg font-medium mt-4 mb-1">敵対者/障害</h4>
    <div class="whitespace-pre-line">${info.antagonist || '未設定'}</div>
    
    <h3 class="text-xl font-semibold mt-6 mb-2">5. 章構成</h3>
    ${chapters.length > 0 ?
      chapters.map((chapter, index) => `
            <div class="mt-4">
                <h4 class="text-lg font-medium">第${index + 1}章：${chapter.title || '無題'}</h4>
                <p class="whitespace-pre-line">${chapter.content || '内容未設定'}</p>
            </div>
        `).join('') :
      '<p>章構成が設定されていません</p>'
    }
    
    <h3 class="text-xl font-semibold mt-6 mb-2">6. 執筆のポイント</h3>
    <ul class="list-disc pl-5 space-y-2">
        <li>テーマ「${info.themes || '未設定'}」を物語全体を通して探求しましょう。</li>
        <li>主人公の内面的成長と外的な冒険のバランスを意識しましょう。</li>
        <li>世界観の独自性を活かした描写を心がけましょう。</li>
        <li>伏線を適切に張り、回収することで読者を引き込みましょう。</li>
        <li>キャラクターの動機と行動に一貫性を持たせましょう。</li>
    </ul>
    `;

  container.innerHTML = content;
}
