import 'package:flutter/material.dart';
import '../services/claude_ai_service.dart';
import '../services/ai_service_interface.dart';
import '../services/service_locator.dart';

/// Claude AI Serviceの使用例
class ClaudeAIServiceExample extends StatefulWidget {
  const ClaudeAIServiceExample({Key? key}) : super(key: key);

  @override
  State<ClaudeAIServiceExample> createState() => _ClaudeAIServiceExampleState();
}

class _ClaudeAIServiceExampleState extends State<ClaudeAIServiceExample> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _continuations = [];
  bool _isLoading = false;
  String _expandedText = '';

  // Claude AI Serviceのインスタンス
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();

    // Claude AI Serviceの初期化
    // 注: 実際の使用時には、適切なURLに置き換えてください
    _aiService = ClaudeAIService(
      claudeGatewayUrl:
          'https://[project-id].functions.supabase.co/claude-gateway',
    );

    // または、サービスロケーターを使用する場合:
    // _aiService = serviceLocator<AIService>();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 続きの候補を生成
  Future<void> _generateContinuations() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _continuations.clear();
    });

    try {
      final continuations =
          await _aiService.generateContinuations(_textController.text);

      setState(() {
        _continuations.addAll(continuations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  // 選択した候補を展開
  Future<void> _expandSuggestion(String suggestion) async {
    setState(() {
      _isLoading = true;
      _expandedText = '';
    });

    try {
      final expanded =
          await _aiService.expandSuggestion(_textController.text, suggestion);

      setState(() {
        _expandedText = expanded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude AI Service Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '小説のテキストを入力してください...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateContinuations,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('続きの候補を生成'),
            ),
            const SizedBox(height: 16),
            const Text('続きの候補:', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: _continuations.isEmpty
                  ? const Center(child: Text('候補はまだありません'))
                  : ListView.builder(
                      itemCount: _continuations.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(_continuations[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.expand_more),
                              onPressed: () =>
                                  _expandSuggestion(_continuations[index]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_expandedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('展開された文章:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_expandedText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// サービスロケーターの設定例
void setupClaudeAIService() {
  // サービスロケーターにClaudeAIServiceを登録
  serviceLocator.registerSingleton<AIService>(
    ClaudeAIService(
      claudeGatewayUrl:
          'https://[project-id].functions.supabase.co/claude-gateway',
    ),
  );
}
