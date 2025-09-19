import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/openai_client.dart';

class NutritionalLookupPage extends StatefulWidget {
  const NutritionalLookupPage({super.key});

  @override
  State<NutritionalLookupPage> createState() => _NutritionalLookupPageState();
}

class _NutritionalLookupPageState extends State<NutritionalLookupPage> {
  static const String _envKey = String.fromEnvironment('OPENAI_KEY', defaultValue: '');
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _storage = const FlutterSecureStorage();

  final List<_Msg> _messages = [
    _Msg('system', 'You are a nutrition assistant. When asked about foods or meals, provide concise carb estimates per serving and note assumptions. If the user requests, include protein, fat, and fiber. Use U.S. units by default unless the user requests otherwise.'),
  ];

  String? _apiKey;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    // Prefer compile-time provided key if present
    if (_envKey.isNotEmpty) {
      setState(() => _apiKey = _envKey);
      return;
    }
    final key = await _storage.read(key: 'openai_api_key');
    setState(() => _apiKey = key);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setApiKeyDialog() async {
    final controller = TextEditingController(text: _apiKey ?? '');
    final saved = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OpenAI API Key'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'sk-... key',
            hintText: 'Paste your OpenAI API key',
            border: OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (saved != null) {
      await _storage.write(key: 'openai_api_key', value: saved);
      setState(() => _apiKey = saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key saved locally.')));
      }
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      await _setApiKeyDialog();
      if (_apiKey == null || _apiKey!.isEmpty) return;
    }
    setState(() {
      _sending = true;
      _messages.add(_Msg('user', text));
      _inputController.clear();
    });
    _scrollToBottomLater();

    try {
      final client = OpenAIClient(apiKey: _apiKey!);
      final resp = await client.chatCompletion(
        messages: _messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
        model: 'gpt-4o-mini',
        temperature: 0.2,
        maxTokens: 600,
      );
      setState(() => _messages.add(_Msg('assistant', resp)));
      _scrollToBottomLater();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OpenAI error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottomLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutritional Lookup'),
        actions: [
          IconButton(
            tooltip: _apiKey == null ? 'Set API key' : 'Update API key',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: _envKey.isNotEmpty ? null : _setApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      color: isUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ask about food nutrition…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String role; // 'system' | 'user' | 'assistant'
  final String content;
  _Msg(this.role, this.content);
}
