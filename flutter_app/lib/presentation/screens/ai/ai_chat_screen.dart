import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/voice_service.dart';
import '../../providers/ai_provider.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final SpeechToText _stt = SpeechToText();
  bool _includeData = false;
  bool _hasSpeech = false;
  bool _agentMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIProvider>().loadSettings();
      _initSpeech();
    });
  }

  void _initSpeech() async {
    _hasSpeech = await _stt.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _stt.stop();
    super.dispose();
  }

  void _send() {
    if (_msgCtrl.text.trim().isEmpty) return;
    final ai = context.read<AIProvider>();
    if (_agentMode) {
      ai.sendAgentMessage(_msgCtrl.text.trim());
    } else {
      ai.sendMessage(_msgCtrl.text.trim(), includeData: _includeData);
    }
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickAndUploadFiles() async {
    final ai = context.read<AIProvider>();
    final result = await ai.pickAndUploadFiles();
    if (result != null) {
      setState(() => _agentMode = true);
      _scrollToBottom();
    }
  }

  Future<void> _startListening() async {
    if (!_hasSpeech) return;
    final ai = context.read<AIProvider>();
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            if (_agentMode) {
              ai.sendAgentMessage(text);
            } else {
              ai.sendMessage(text, includeData: _includeData);
            }
            _scrollToBottom();
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_IN",
    );
  }

  void _stopListening() {
    _stt.stop();
  }

  void _speakMessage(String text) {
    final voiceService = context.read<VoiceService>();
    if (voiceService.isSpeaking) {
      voiceService.stop();
    } else {
      voiceService.speak(text);
    }
  }

  Future<void> _confirmAction(AgentAction action) async {
    final ai = context.read<AIProvider>();
    await ai.confirmAction(action.action, action.params);
    _scrollToBottom();
  }

  void _denyAction() {
    final ai = context.read<AIProvider>();
    ai.clearMessages();
    setState(() => _agentMode = false);
  }

  IconData _getMicIcon() {
    if (_stt.isListening) return Icons.mic;
    if (!_hasSpeech) return Icons.mic_off;
    return Icons.mic_none;
  }

  Color _getMicColor() {
    if (_stt.isListening) return AppTheme.errorColor;
    if (!_hasSpeech) return Colors.grey;
    return AppTheme.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();
    final voice = context.watch<VoiceService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_agentMode ? 'AI Agent' : 'AI Assistant'),
        actions: [
          IconButton(
            icon: Icon(_agentMode ? Icons.smart_toy : Icons.chat),
            tooltip: _agentMode ? 'Switch to Chat' : 'Switch to Agent',
            onPressed: () => setState(() => _agentMode = !_agentMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.aiSettings),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ai.clearMessages();
              setState(() => _agentMode = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_agentMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: AppTheme.accentColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.smart_toy, size: 16, color: AppTheme.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Agent mode - I can perform tasks for you',
                    style: TextStyle(fontSize: 12, color: AppTheme.accentColor),
                  ),
                ],
              ),
            ),
          if (ai.settings == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.warningColor.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI not configured',
                      style: TextStyle(color: AppTheme.warningColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.aiSettings),
                    child: const Text('Configure'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ai.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: ai.messages.length,
                    itemBuilder: (_, i) {
                      final msg = ai.messages[i];
                      final isUser = msg.role == 'user';

                      if (msg.actions != null && msg.actions!.isNotEmpty) {
                        return _buildActionProposal(msg);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment:
                                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (msg.files != null && msg.files!.isNotEmpty)
                                ...msg.files!.map((f) => _buildFileChip(f)),
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                                    bottomLeft: !isUser ? Radius.zero : const Radius.circular(16),
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                                ),
                                child: Text(msg.content),
                              ),
                              if (!isUser && ai.ttsSupported)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                                  child: SizedBox(
                                    height: 28,
                                    child: IconButton(
                                      icon: Icon(
                                        voice.isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () => _speakMessage(msg.content),
                                      tooltip: voice.isSpeaking ? 'Stop' : 'Listen',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (ai.uploading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Uploading files...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (ai.voiceProcessing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Processing voice...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (ai.isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (!_agentMode)
                        IconButton(
                          icon: Icon(
                            Icons.analytics,
                            color: _includeData ? AppTheme.accentColor : null,
                          ),
                          onPressed: () => setState(() => _includeData = !_includeData),
                          tooltip: 'Include business data',
                        ),
                      if (_agentMode)
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _pickAndUploadFiles,
                          tooltip: 'Attach files',
                        ),
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: _agentMode ? 'Tell me what to do...' : 'Ask Arynox...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      if (ai.sttSupported && _hasSpeech) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(_getMicIcon(), color: _getMicColor()),
                          onPressed: _stt.isListening ? _stopListening : _startListening,
                          tooltip: _stt.isListening ? 'Stop listening' : 'Voice input',
                        ),
                      ],
                      const SizedBox(width: 4),
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: _send,
                      ),
                    ],
                  ),
                  if (_stt.isListening)
                    const Text(
                      'Listening... Speak now',
                      style: TextStyle(fontSize: 11, color: AppTheme.errorColor),
                    ),
                  if (_includeData && !_agentMode)
                    Text(
                      'AI will access your business data',
                      style: TextStyle(fontSize: 11, color: AppTheme.accentColor),
                    ),
                  if (_agentMode)
                    Text(
                      'Agent can create, update & manage data',
                      style: TextStyle(fontSize: 11, color: AppTheme.accentColor),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionProposal(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smart_toy, size: 20, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Proposed Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg.content, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          ...msg.actions!.map((action) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          action.description,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  if (action.params.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...action.params.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 22, top: 2),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    )),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _denyAction,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Deny'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _confirmAction(action),
                        child: Text('Confirm'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFileChip(Map<String, dynamic> fileInfo) {
    final filename = fileInfo['filename'] as String? ?? 'Unknown';
    final size = fileInfo['size'] as int? ?? 0;
    final sizeStr = size > 1024 ? '${(size / 1024).toStringAsFixed(1)} KB' : '$size B';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, size: 14, color: AppTheme.accentColor),
          const SizedBox(width: 6),
          Text(filename, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(sizeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isAgent = _agentMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAgent ? Icons.smart_toy : Icons.support_agent,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isAgent ? 'How can I help you today?' : 'Ask me anything!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isAgent
                ? 'Upload files and tell me what to do'
                : 'Type, tap mic to speak, or try a suggestion',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 24),
          if (isAgent)
            _suggestedChip('Upload files', '📎', () => _pickAndUploadFiles())
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _suggestedChip(
                  'Explain accounting',
                  'What are the basic accounting principles for a small business?',
                ),
                _suggestedChip(
                  'Invoice draft',
                  'Create a professional invoice for a customer',
                ),
                _suggestedChip(
                  'Business tips',
                  'How can I improve my business profitability?',
                ),
                _suggestedChip(
                  'Analyze revenue',
                  'Analyze my revenue data',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _suggestedChip(String label, String message, [VoidCallback? customAction]) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        if (customAction != null) {
          customAction();
        } else {
          _msgCtrl.text = message;
          _includeData = message.contains('data');
          _send();
        }
      },
    );
  }
}
