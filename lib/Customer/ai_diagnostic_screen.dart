import 'package:flutter/material.dart';
import 'package:mechfixes/services/diagnostic_api_service.dart';

class AiDiagnosticScreen extends StatefulWidget {
  const AiDiagnosticScreen({super.key});

  @override
  State<AiDiagnosticScreen> createState() => _AiDiagnosticScreenState();
}

class _AiDiagnosticScreenState extends State<AiDiagnosticScreen> {
  static const _primary = Color(0xFF1F3FAF);
  static const _offlineMessage =
      'Sorry, the AI mechanic is currently offline. Please check your connection.';

  final DiagnosticApiService _api = DiagnosticApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final FocusNode _inputFocus = FocusNode();

  bool _isLoading = false;
  bool _showRomanUrdu = true;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage.ai(
        predictedFault: null,
        adviceEnglish:
            'Assalam-o-Alaikum! I am your AI mechanic. Describe your car symptoms '
            'in detail — such as engine vibration, check engine light, or strange '
            'noise — and I will provide a diagnosis and professional DIY advice.',
        adviceRomanUrdu:
            'Assalam-o-Alaikum! Main aapka AI mechanic hoon. Apni gaari ke symptoms '
            'detail mein likhein — jaise engine vibration, check engine light, ya '
            'ajeeb awaaz — aur main diagnosis aur professional DIY advice dunga.',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _api.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage.user(text));
      _isLoading = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final result = await _api.diagnose(text);
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage.ai(
            predictedFault: result.predictedFault,
            adviceEnglish: result.aiAdviceEnglish,
            adviceRomanUrdu: result.aiAdviceRomanUrdu,
          ),
        );
        _isLoading = false;
      });
    } on DiagnosticApiException catch (error, stackTrace) {
      debugPrint('[AiDiagnostic] API error: ${error.message}');
      debugPrint('[AiDiagnostic] $stackTrace');
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage.error(error.message));
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[AiDiagnostic] Unexpected error: $error');
      debugPrint('[AiDiagnostic] $stackTrace');
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage.error(
          error.toString().isNotEmpty ? error.toString() : _offlineMessage,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Mechanic',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Online • Diagnostic Assistant',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading
                ? null
                : () => setState(() => _showRomanUrdu = !_showRomanUrdu),
            icon: const Icon(Icons.translate, color: Colors.white, size: 18),
            label: Text(
              _showRomanUrdu ? 'English' : 'Roman Urdu',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(
                  message: _messages[index],
                  showRomanUrdu: _showRomanUrdu,
                );
              },
            ),
          ),
          _ChatInputBar(
            controller: _inputController,
            focusNode: _inputFocus,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ─── Message model ──────────────────────────────────────────────────────────

enum _MessageKind { user, ai, error }

class _ChatMessage {
  const _ChatMessage._({
    required this.kind,
    required this.text,
    this.predictedFault,
    this.adviceEnglish,
    this.adviceRomanUrdu,
  });

  const _ChatMessage.user(String text)
      : this._(kind: _MessageKind.user, text: text);

  const _ChatMessage.ai({
    required String? predictedFault,
    required String adviceEnglish,
    required String adviceRomanUrdu,
  }) : this._(
          kind: _MessageKind.ai,
          text: adviceEnglish,
          predictedFault: predictedFault,
          adviceEnglish: adviceEnglish,
          adviceRomanUrdu: adviceRomanUrdu,
        );

  const _ChatMessage.error(String text)
      : this._(kind: _MessageKind.error, text: text);

  final _MessageKind kind;
  final String text;
  final String? predictedFault;
  final String? adviceEnglish;
  final String? adviceRomanUrdu;

  String displayAdvice({required bool showRomanUrdu}) {
    if (kind != _MessageKind.ai) return text;

    final romanUrdu = adviceRomanUrdu?.trim() ?? '';
    final english = adviceEnglish?.trim() ?? '';

    if (showRomanUrdu) {
      return romanUrdu.isNotEmpty ? romanUrdu : (english.isNotEmpty ? english : text);
    }
    return english.isNotEmpty ? english : (romanUrdu.isNotEmpty ? romanUrdu : text);
  }
}

// ─── Chat bubbles ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showRomanUrdu,
  });

  final _ChatMessage message;
  final bool showRomanUrdu;

  @override
  Widget build(BuildContext context) {
    final isUser = message.kind == _MessageKind.user;
    final isError = message.kind == _MessageKind.error;

    final bubbleColor = isUser
        ? const Color(0xFF1F3FAF)
        : isError
            ? const Color(0xFFFFEBEE)
            : Colors.white;

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: borderRadius,
          border: isError
              ? Border.all(color: const Color(0xFFFFCDD2))
              : null,
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                ),
              )
            : isError
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: Color(0xFFC62828),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  )
                : _AiBubbleContent(
                    predictedFault: message.predictedFault,
                    advice: message.displayAdvice(showRomanUrdu: showRomanUrdu),
                    languageLabel: showRomanUrdu ? 'Roman Urdu' : 'English',
                  ),
      ),
    );
  }
}

class _AiBubbleContent extends StatelessWidget {
  const _AiBubbleContent({
    required this.predictedFault,
    required this.advice,
    required this.languageLabel,
  });

  final String? predictedFault;
  final String advice;
  final String languageLabel;

  @override
  Widget build(BuildContext context) {
    final hasFault =
        predictedFault != null && predictedFault!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasFault) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1F3FAF).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Predicted Fault',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  predictedFault!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F3FAF),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Repair Advice ($languageLabel)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          advice,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Typing',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final delay = index * 0.2;
                  final value = (_controller.value - delay).clamp(0.0, 1.0);
                  final opacity = (value < 0.5 ? value * 2 : (1 - value) * 2)
                      .clamp(0.3, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F3FAF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isLoading,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Describe your car symptoms…',
                    hintStyle: const TextStyle(
                      color: Color(0xFF98A2B3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: const Color(0xFF1F3FAF),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: isLoading ? null : onSend,
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
