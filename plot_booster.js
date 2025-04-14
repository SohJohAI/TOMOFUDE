// プロットブースター JavaScript

// 現在のステップ
let currentStep = 0;
const totalSteps = 8;

// ページ読み込み時の初期化
document.addEventListener('DOMContentLoaded', function () {
  // ダークモードトグルの設定
  setupDarkModeToggle();

  // ジャンルと作風の選択イベント
  setupGenreStyleEvents();

  // テーマボタンのクリックイベント
  setupThemeButtons();

  // 章の追加ボタンのイベント
  setupChapterEvents();

  // プロットカード生成ボタンのイベント
  setupPlotCardGeneration();

  // 執筆支援資料生成ボタンのイベント
  setupDocsGeneration();

  // リスタートボタンのイベント
  setupRestartButton();

  // AIヘルプボタンのイベント
  setupAIHelpButtons();

  // 初期ステップを表示
  showStep(0);
});

// ダークモードトグルの設定
function setupDarkModeToggle() {
  const darkModeToggle = document.getElementById('darkModeToggle');

  darkModeToggle.addEventListener('click', function () {
    document.documentElement.classList.toggle('dark');

    // ローカルストレージに設定を保存
    if (document.documentElement.classList.contains('dark')) {
      localStorage.setItem('darkMode', 'true');
    } else {
      localStorage.setItem('darkMode', 'false');
    }
  });
}

// ジャンルと作風の選択イベント
function setupGenreStyleEvents() {
  const genre = document.getElementById('genre');
  const style = document.getElementById('style');
  const customGenre = document.getElementById('customGenre');
  const customStyle = document.getElementById('customStyle');
  const otherGenreStyle = document.getElementById('other-genre-style');

  genre.addEventListener('change', function () {
    if (this.value === 'フリー入力') {
      customGenre.classList.remove('hidden');
    } else {
      customGenre.classList.add('hidden');
    }

    toggleOtherField();
  });

  style.addEventListener('change', function () {
    if (this.value === 'フリー入力') {
      customStyle.classList.remove('hidden');
    } else {
      customStyle.classList.add('hidden');
    }

    toggleOtherField();
  });

  function toggleOtherField() {
    if (genre.value === 'その他' || style.value === 'その他') {
      otherGenreStyle.classList.remove('hidden');
    } else {
      otherGenreStyle.classList.add('hidden');
    }
  }
}

// テーマボタンのクリックイベント
function setupThemeButtons() {
  const themeButtons = document.querySelectorAll('.theme-btn');
  const themesInput = document.getElementById('themes');

  themeButtons.forEach(btn => {
    btn.addEventListener('click', function () {
      // ボタンの選択状態をトグル
      this.classList.toggle('selected');

      // 選択されたテーマを取得
      const selectedThemes = [];
      document.querySelectorAll('.theme-btn.selected').forEach(selectedBtn => {
        selectedThemes.push(selectedBtn.textContent);
      });

      // テキストエリアに反映
      themesInput.value = selectedThemes.join('、');
    });
  });
}

// 章の追加と削除のイベント設定
function setupChapterEvents() {
  const addChapterBtn = document.getElementById('addChapterBtn');

  if (addChapterBtn) {
    addChapterBtn.addEventListener('click', function () {
      addNewChapter();
    });
  }

  // 既存の削除ボタンにイベントを設定
  setupDeleteChapterButtons();
}

// 新しい章を追加
function addNewChapter() {
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

  // 新しく追加した削除ボタンにイベントを設定
  setupDeleteChapterButtons();
}

// 章の削除ボタンにイベントを設定
function setupDeleteChapterButtons() {
  document.querySelectorAll('.delete-chapter-btn').forEach(btn => {
    btn.addEventListener('click', function () {
      if (confirm('この章を削除してもよろしいですか？')) {
        const chapterItem = this.closest('.chapter-item');
        chapterItem.remove();

        // 章番号を振り直す
        updateChapterNumbers();
      }
    });
  });
}

// 章番号を振り直す
function updateChapterNumbers() {
  document.querySelectorAll('.chapter-item').forEach((item, index) => {
    const chapterNumber = item.querySelector('.chapter-number');
    chapterNumber.textContent = `第${index + 1}章`;
  });
}

// プロットカード生成ボタンのイベント
function setupPlotCardGeneration() {
  const generateCardsBtn = document.getElementById('generateCardsBtn');

  if (generateCardsBtn) {
    generateCardsBtn.addEventListener('click', function () {
      generatePlotCards();
    });
  }
}

// プロットカードを生成
function generatePlotCards() {
  const plotCardsContainer = document.getElementById('plotCardsContainer');
  plotCardsContainer.innerHTML = '';

  // 物語の情報を収集
  const genre = getGenreValue();
  const style = getStyleValue();
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

  // 生成完了のトースト表示
  showToast('プロットカードを生成しました！');
}

// 執筆支援資料生成ボタンのイベント
function setupDocsGeneration() {
  const generateDocsBtn = document.getElementById('generateDocsBtn');
  const copyDocsBtn = document.getElementById('copyDocsBtn');

  if (generateDocsBtn) {
    generateDocsBtn.addEventListener('click', function () {
      generateDocs();
    });
  }

  if (copyDocsBtn) {
    copyDocsBtn.addEventListener('click', function () {
      copyDocsContent();
    });
  }
}

// 執筆支援資料を生成
function generateDocs() {
  const docsContainer = document.getElementById('docsContainer');
  const docsContent = document.getElementById('docsContent');

  docsContainer.classList.remove('hidden');

  // ローディング表示
  docsContent.innerHTML = `
        <div class="flex items-center justify-center p-4">
            <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            <span>執筆支援資料を作成中...</span>
        </div>
    `;

  // 物語の情報を収集
  const genre = getGenreValue();
  const style = getStyleValue();
  const logline = document.getElementById('logline').value;
  const themes = document.getElementById('themes').value;
  const worldSetting = document.getElementById('worldSetting').value;
  const keySetting = document.getElementById('keySetting').value;
  const protagonist = document.getElementById('protagonist').value;
  const antagonist = document.getElementById('antagonist').value;

  // 章の情報を収集
  const chapters = [];
  document.querySelectorAll('.chapter-item').forEach(item => {
    const title = item.querySelector('.chapter-title').value || `第${chapters.length + 1}章`;
    const content = item.querySelector('.chapter-content').value || '内容未設定';
    chapters.push({ title, content });
  });

  // 執筆支援資料のマークダウンを生成
  let markdown = `# ${genre} × ${style} 執筆支援資料

## 物語の概要
${logline || '物語の要約が未設定です'}

## テーマ・モチーフ
${themes || '未設定'}

## 世界観設定
${worldSetting || '未設定'}

## キー設定
${keySetting || '未設定'}

## 登場人物

### 主人公
${protagonist || '未設定'}

### 敵対者/障害
${antagonist || '未設定'}

## 章構成
`;

  chapters.forEach((chapter, index) => {
    markdown += `
### 第${index + 1}章: ${chapter.title}
${chapter.content}
`;
  });

  markdown += `
## 執筆のポイント
- 主人公の成長曲線を意識する
- 伏線を適切に張り、回収する
- 世界観の一貫性を保つ
- 読者の期待を裏切りつつも満足させる展開を心がける
- キャラクターの動機を明確にする

## 参考資料
- 同ジャンルの人気作品を研究する
- 実際の歴史や科学的背景を調査する（リアリティのため）
- キャラクターの心理描写の参考書を読む
`;

  // マークダウンをHTMLに変換して表示
  docsContent.innerHTML = marked.parse(markdown);

  // 生成完了のトースト表示
  showToast('執筆支援資料を生成しました！');
}

// 執筆支援資料をコピー
function copyDocsContent() {
  const docsContent = document.getElementById('docsContent');
  const textToCopy = docsContent.innerText;

  // クリップボードにコピー
  navigator.clipboard.writeText(textToCopy)
    .then(() => {
      // コピー成功の表示
      const copyBtn = document.getElementById('copyDocsBtn');
      const originalText = copyBtn.innerHTML;
      copyBtn.innerHTML = `
                <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                </svg>
                コピーしました
            `;

      // 元に戻す
      setTimeout(() => {
        copyBtn.innerHTML = originalText;
      }, 2000);

      // トースト表示
      showToast('執筆支援資料をコピーしました！');
    })
    .catch(err => {
      console.error('クリップボードへのコピーに失敗しました:', err);
      showToast('コピーに失敗しました。', true);
    });
}

// リスタートボタンのイベント
function setupRestartButton() {
  const restartBtn = document.getElementById('restartBtn');

  if (restartBtn) {
    restartBtn.addEventListener('click', function () {
      if (confirm('最初からやり直しますか？入力内容はリセットされます。')) {
        resetAllInputs();
        showStep(0);
        showToast('入力内容をリセットしました');
      }
    });
  }
}

// 全ての入力をリセット
function resetAllInputs() {
  // フォームをリセット
  document.querySelectorAll('input, textarea, select').forEach(el => {
    el.value = '';
  });

  // テーマボタンの選択状態をリセット
  document.querySelectorAll('.theme-btn').forEach(btn => {
    btn.classList.remove('selected');
  });

  // AI応答をクリア
  document.querySelectorAll('.ai-response').forEach(el => {
    el.innerHTML = '';
    el.classList.remove('show');
  });

  // 章を初期状態に戻す
  const chaptersContainer = document.getElementById('chaptersContainer');
  if (chaptersContainer) {
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

    // 削除ボタンにイベントを設定
    setupDeleteChapterButtons();
  }

  // プロットカードをクリア
  const plotCardsContainer = document.getElementById('plotCardsContainer');
  if (plotCardsContainer) {
    plotCardsContainer.innerHTML = '';
  }

  // 執筆支援資料をクリア
  const docsContainer = document.getElementById('docsContainer');
  if (docsContainer) {
    docsContainer.classList.add('hidden');
  }
}

// AIヘルプボタンのイベント
function setupAIHelpButtons() {
  for (let i = 0; i <= 6; i++) {
    const aiHelpBtn = document.getElementById(`aiHelpBtn${i}`);
    const aiResponse = document.getElementById(`aiResponse${i}`);

    if (aiHelpBtn && aiResponse) {
      aiHelpBtn.addEventListener('click', function () {
        // AIの応答を表示
        aiResponse.classList.add('show');

        // ローディング表示
        aiResponse.innerHTML = `
                    <div class="flex items-center justify-center p-4">
                        <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-amber-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>AIが考え中...</span>
                    </div>
                `;

        // 各ステップに応じたAI応答を生成
        setTimeout(() => {
          generateAIResponse(i, aiResponse);
        }, 1500);
      });
    }
  }
}

// AIの応答を生成
function generateAIResponse(stepNumber, responseElement) {
  // 物語の情報を収集
  const allInfo = getAllStepInfo();

  let response = '';

  switch (stepNumber) {
    case 0:
      response = `
                <h4 class="font-bold mb-2">ジャンルと作風のアイデア</h4>
                <ol class="list-decimal pl-5 space-y-2">
                    <li><strong>ダークファンタジー × 哲学的</strong> - 魔法と神話が存在する世界で、存在の意味や道徳的ジレンマを探求</li>
                    <li><strong>近未来SF × サスペンス</strong> - テクノロジーが発達した社会での陰謀と真実の追求</li>
                    <li><strong>歴史 × ミステリー</strong> - 実際の歴史的出来事を背景にした謎解き</li>
                    <li><strong>現代ドラマ × 叙情的</strong> - 日常の中の小さな感動と人間関係の機微を描く</li>
                    <li><strong>異世界ファンタジー × コメディ</strong> - 異世界転生や召喚を題材にしたユーモラスな冒険</li>
                </ol>
            `;
      break;

    case 1:
      response = `
                <h4 class="font-bold mb-2">ログラインのアイデア</h4>
                <ol class="list-decimal pl-5 space-y-2">
                    <li>「記憶を失った元暗殺者が、自分の過去と向き合いながら、かつての組織から家族を守るために戦う。」</li>
                    <li>「不思議な能力を持つ少女が、差別と偏見に満ちた世界で、自分の居場所と真の仲間を見つける旅に出る。」</li>
                    <li>「死んだはずの双子の兄から届いた手紙をきっかけに、妹は兄の失踪の真相を追う中で家族の隠された秘密に迫る。」</li>
                    <li>「人工知能に支配された未来世界で、最後の人類レジスタンスのリーダーが、機械と人間の共存の道を模索する。」</li>
                    <li>「古い屋敷を相続した作家が、そこに住む幽霊たちの未解決の物語を書き上げることで、彼らを成仏させようとする。」</li>
                </ol>
            `;
      break;

    case 2:
      response = `
                <h4 class="font-bold mb-2">テーマ・モチーフのアイデア</h4>
                <ol class="list-decimal pl-5 space-y-2">
                    <li><strong>贖罪と救済</strong> - 過去の罪や過ちからの精神的な回復と自己許容の旅</li>
                    <li><strong>アイデンティティの探求</strong> - 自分は何者なのか、どこに属するのかという問いへの答え探し</li>
                    <li><strong>選択と責任</strong> - 決断の重さとその結果に対する責任の取り方</li>
                    <li><strong>孤独と繋がり</strong> - 人間の根源的な孤独と、それでも誰かと繋がりたいという願望</li>
                    <li><strong>変化と適応</strong> - 避けられない変化に直面したときの人間の適応力と成長</li>
                </ol>
            `;
      break;

    case 3:
      response = `
                <h4 class="font-bold mb-2">世界観設定のアイデア</h4>
                <ol class="list-decimal pl-5 space-y-2">
                    <li><strong>時代背景</strong>: 産業革命期に魔法が発見された代替歴史世界。蒸気機関と魔法が融合した独自の技術革命が起きている。</li>
                    <li><strong>舞台</strong>: 巨大な浮遊大陸が点在する空の海。大陸間を行き来する飛行船が交通手段となっている。</li>
                    <li><strong>社会制度</strong>: 魔法の才能によって階級が決まる魔導貴族制。一般市民は技術で対抗しようとしている。</li>
                    <li><strong>独自ルール</strong>: 魔法は使うたびに使用者の寿命を少しずつ削る。強大な力には必ず代償が伴う。</li>
                </ol>
            `;
      break;

    case 4:
      response = `
                <h4 class="font-bold mb-2">キー設定のアイデア</h4>
                <ol class="list-decimal pl-5 space-y-2">
                    <li><strong>魂の共鳴（ソウルレゾナンス）</strong><br>
                    効果: 特定の条件下で、人と人、あるいは人と物の魂が共鳴し、特殊な能力を発現させる<br>
                    制約: 共鳴には強い感情的繋がりが必要で、否定的感情では暴走する</li>
                    
                    <li><strong>記憶の結晶（メモリークリスタル）</strong><br>
                    効果: 人の記憶を結晶化して保存したり、他者に移植したりできる<br>
                    制約: 記憶の移植は元の持ち主の記憶を失わせ、長期保存された記憶は劣化する</li>
                    
                    <li><strong>運命の糸（フェイトスレッド）</strong><br>
                    効果: 特定の人々の運命を視覚化し、限定的に操作できる能力<br>
                    制約: 運命を変えると必ず別の場所でバランスを取るように変化が起き、予期せぬ結果を招く</li>
                </ol>
            `;
      break;

    case 5:
      response = `
                <h4 class="font-bold mb-2">キャラクター設定のアイデア</h4>
                
                <h5 class="font-semibold mt-4">主人公案1</h5>
                <p>
                名前: レイン・ストームハート<br>
                年齢: 19歳<br>
                外見: 銀髪に青い瞳、左腕に不思議な紋様がある<br>
                性格: 好奇心旺盛だが慎重、他者を信じるまでに時間がかかる<br>
                能力: 雷を操る力を持つが、完全にはコントロールできていない<br>
                動機: 失踪した父親の行方を探している<br>
                弱点: 過去のトラウマから雷雨を極度に恐れる
                </p>
                
                <h5 class="font-semibold mt-4">主人公案2</h5>
                <p>
                名前: エコー・サイレンス<br>
                年齢: 24歳<br>
                外見: 黒髪のショートカット、常に手袋を着用<br>
                性格: 冷静沈着、論理的だが感情表現が苦手<br>
                能力: 触れたものの記憶を読み取れるが、強い感情が残る記憶に圧倒されることも<br>
                動機: 自分の出自の謎を解き明かしたい<br>
                弱点: 人との物理的接触を恐れる
                </p>
                
                <h5 class="font-semibold mt-4">敵対者案1</h5>
                <p>
                名前: ヴェイル・シャドウマスター<br>
                役割: 秘密結社の指導者<br>
                能力: 影を実体化させ、武器や分身として操る<br>
                動機: 世界を「理想的な秩序」で統一しようとしている<br>
                特徴: 表向きは慈善家として知られる実業家<br>
                弱点: 自分の計画の完璧さを過信している
                </p>
                
                <h5 class="font-semibold mt-4">敵対者案2/障害</h5>
                <p>
                名前: 「運命の歪み」<br>
                役割: 物理法則を超えた現象<br>
                特徴: 特定の場所で時間や空間が歪み、現実が不安定になる<br>
                影響: 人々の恐怖や欲望を具現化させる<br>
                起源: 古代の実験が失敗した結果<br>
                弱点: 特定の周波数の音や光に反応して弱まる
                </p>
            `;
      break;

    case 6:
      response = `
                <h4 class="font-bold mb-2">章構成のアイデア</h4>
                
                <h5 class="font-semibold mt-3">第1章: 日常の崩壊</h5>
                <p>主人公の平穏な日常が、突然の出来事によって崩れ去る。未知の力に目覚める/謎の人物との出会い/大切な人の喪失など、物語の発端となる事件が起こる。この章では主人公の性格や背景、世界観の基本設定を読者に示す。</p>
                
                <h5 class="font-semibold mt-3">第2章: 新たな世界</h5>
                <p>主人公が慣れ親しんだ環境を離れ、新たな世界や状況に適応しようとする。仲間との出会い、能力の発見、世界の真実の一端を知るなど、物語の舞台が広がる。主人公の目標が明確になる。</p>
                
                <h5 class="font-semibold mt-3">第3章: 試練と成長</h5>
                <p>主人公が最初の大きな試練に直面する。失敗や挫折を経験しながらも、新たな力や知恵を得て成長していく。敵の存在や目的がより明確になり、対立構造が浮き彫りになる。</p>
                
                <h5 class="font-semibold mt-3">第4章: 真実の発見</h5>
                <p>物語の核心に関わる重要な真実や秘密が明らかになる。主人公の認識が覆されたり、目標や動機が変化したりする転換点。信頼していた人物の裏切りや、敵との意外な共通点の発見など。</p>
                
                <h5 class="font-semibold mt-3">第5章: 最終決戦</h5>
                <p>主人公と敵対者の最終的な対決。物語全体で張られた伏線が回収され、主人公の成長が試される。犠牲や厳しい選択を伴いながらも、主人公は自分なりの答えにたどり着く。</p>
            `;
      break;

    default:
      response = `
                <p class="italic">このステップではAIアシスタントからの提案はまだ用意されていません。</p>
                <p>入力内容に基づいて、具体的なアイデアを提案します。</p>
            `;
  }

  // 応答を表示
  responseElement.innerHTML = response;
}

// ステップを表示
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

// ジャンル値を取得（カスタム入力対応）
function getGenreValue() {
  const genre = document.getElementById('genre');
  const customGenre = document.getElementById('customGenre');
  const otherGenreStyle = document.getElementById('otherGenreStyle');

  if (genre.value === 'フリー入力' && customGenre.value) {
    return customGenre.value;
  } else if (genre.value === 'その他' && otherGenreStyle.value) {
    return otherGenreStyle.value;
  } else {
    return genre.value;
  }
}

// 作風値を取得（カスタム入力対応）
function getStyleValue() {
  const style = document.getElementById('style');
  const customStyle = document.getElementById('customStyle');
  const otherGenreStyle = document.getElementById('otherGenreStyle');

  if (style.value === 'フリー入力' && customStyle.value) {
    return customStyle.value;
  } else if (style.value === 'その他' && otherGenreStyle.value) {
    return otherGenreStyle.value;
  } else {
    return style.value;
  }
}

// 全ステップの情報を収集する関数
function getAllStepInfo() {
  // STEP 0: ジャンルと作風
  const genre = getGenreValue();
  const style = getStyleValue();

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

  // STEP 6: 章構成
  const chapters = [];
  document.querySelectorAll('.chapter-item').forEach(item => {
    const title = item.querySelector('.chapter-title').value || '';
    const content = item.querySelector('.chapter-content').value || '';
    chapters.push({ title, content });
  });

  return {
    genre,
    style,
    logline,
    themes,
    worldSetting,
    keySetting,
    protagonist,
    antagonist,
    chapters
  };
}

// トースト通知を表示
function showToast(message, isError = false) {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = 'toast show';

  if (isError) {
    toast.style.backgroundColor = '#e53e3e';
  } else {
    toast.style.backgroundColor = '#333';
  }

  setTimeout(() => {
    toast.className = 'toast';
  }, 3000);
}
