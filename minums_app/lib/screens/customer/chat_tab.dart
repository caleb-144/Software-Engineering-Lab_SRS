import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../seed.dart';
import '../../services/gemini_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../login_screen.dart';
import '../thread_screen.dart';
import 'item_sheet.dart';

class _Bubble {
  final String text;
  final bool mine;
  final bool escalate;
  final ChatSource? source;
  final String? question; // original question, used when sending to the manager
  final List<String> itemIds;
  final bool openThread;
  bool sent = false;
  _Bubble(this.text, this.mine,
      {this.escalate = false,
      this.source,
      this.question,
      this.itemIds = const [],
      this.openThread = false});
}

/// FR-04 AI assistant. FR-05: unanswered questions go to the manager's inbox.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _service = GeminiService();
  final _c = TextEditingController();
  final _scroll = ScrollController();
  final List<_Bubble> _msgs = [
    _Bubble(
        'Hi! I can recommend drinks, check prices and availability, and answer questions about the kiosk. Tap a quick question below or ask me anything.',
        false),
  ];
  bool _loading = false;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void dispose() {
    _slowTimer?.cancel();
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 160,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  List<ChatTurn> _history() {
    final turns = <ChatTurn>[
      for (final m in _msgs.skip(1))
        if (m.source != ChatSource.system) ChatTurn(m.text, fromUser: m.mine),
    ];
    final recent = turns.length > 6 ? turns.sublist(turns.length - 6) : turns;
    while (recent.isNotEmpty && !recent.first.fromUser) {
      recent.removeAt(0);
    }
    return recent;
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _loading) return;
    _c.clear();
    final state = context.read<AppState>();
    final history = _history();
    setState(() {
      _msgs.add(_Bubble(q, true));
      _loading = true;
      _slow = false;
    });
    _scrollDown();
    _slowTimer?.cancel();
    _slowTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _loading) {
        setState(() => _slow = true);
        _scrollDown();
      }
    });
    ChatReply reply;
    try {
      reply = await _service.ask(q, state.menu, hot: state.hotSelling(50), history: history);
    } catch (_) {
      reply = const ChatReply(
        'Sorry, something went wrong. Would you like me to send your question to the manager?',
        escalate: true,
        source: ChatSource.system,
      );
    }
    _slowTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _msgs.add(_Bubble(reply.text, false,
          escalate: reply.escalate, source: reply.source, question: q, itemIds: reply.itemIds));
      _loading = false;
      _slow = false;
    });
    _scrollDown();
  }

  /// Puts the question in the manager's inbox (guests are asked to log in first).
  Future<bool> _sendToManager(String question) async {
    final s = context.read<AppState>();
    if (s.user == null) {
      final ok = await requireLogin(context,
          reason: 'Log in so the manager can reply to your question.');
      if (!ok || !mounted) {
        if (mounted) {
          setState(() => _msgs.add(_Bubble(
              'No problem. Log in any time and I can pass your question to the manager.', false,
              source: ChatSource.system)));
          _scrollDown();
        }
        return false;
      }
    }
    final err = s.sendCustomerMessage(question, viaBot: true);
    if (!mounted) return false;
    setState(() => _msgs.add(_Bubble(
        err ??
            'Done! I sent your question to the manager. You will see their reply under Account > Message the manager.',
        false,
        source: ChatSource.system,
        openThread: err == null)));
    _scrollDown();
    return err == null;
  }

  Future<void> _tapFaq(FaqItem f) async {
    if (!f.toManager) return _send(f.question);
    if (_loading) return;
    setState(() => _msgs.add(_Bubble(f.question, true)));
    _scrollDown();
    await _sendToManager(f.question);
  }

  void _openThread() {
    final u = context.read<AppState>().user;
    if (u == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ThreadScreen(customerId: u.id)));
  }

  Future<void> _messageManager() async {
    final ok = await requireLogin(context, reason: 'Log in to message the manager.');
    if (ok && mounted) _openThread();
  }

  Widget _itemCards(List<String> ids) {
    final s = context.read<AppState>();
    final items = [for (final id in ids) if (s.itemById(id) != null) s.itemById(id)!];
    return Column(children: [
      for (final m in items)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppCard(
            padding: const EdgeInsets.all(8),
            onTap: () => showItemSheet(context, m),
            child: Row(children: [
              MenuImage(m, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(priceText(m),
                      style: const TextStyle(color: Brand.primary, fontWeight: FontWeight.w700)),
                ]),
              ),
              const Icon(Icons.add_circle, color: Brand.primary),
            ]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        actions: [
          IconButton(
              tooltip: 'Message manager',
              onPressed: _messageManager,
              icon: const Icon(Icons.support_agent_outlined)),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Brand.primary)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _slow
                              ? 'Taking longer than usual... you can also message the manager.'
                              : 'Thinking...',
                          style: const TextStyle(fontSize: 12, color: Brand.grey),
                        ),
                      ),
                    ]),
                  ),
                );
              }
              final m = _msgs[i];
              return Align(
                alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: m.mine ? Brand.primary : Brand.white,
                    border: m.mine ? null : Border.all(color: Brand.line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.text,
                        style: TextStyle(
                            color: m.mine ? Brand.white : Brand.ink, fontSize: 15, height: 1.35)),
                    if (m.itemIds.isNotEmpty) _itemCards(m.itemIds),
                    if (m.escalate) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: m.sent
                            ? null
                            : () async {
                                final ok = await _sendToManager(m.question ?? m.text);
                                if (ok && mounted) setState(() => m.sent = true);
                              },
                        icon: Icon(m.sent ? Icons.check : Icons.send_outlined, size: 18),
                        label: Text(m.sent ? 'Sent to manager' : 'Send to manager',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                    if (m.openThread) ...[
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                        onPressed: _openThread,
                        child: const Text('Open conversation', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                    if (!m.mine && i > 0 && m.source != null && m.source != ChatSource.system)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          m.source == ChatSource.ai
                              ? 'AI answer (Gemini) \u00b7 based on current menu'
                              : 'Menu assistant \u00b7 based on current menu',
                          style: const TextStyle(fontSize: 10, color: Brand.grey),
                        ),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final p in kAiPrompts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.auto_awesome, size: 16, color: Brand.primary),
                    label: Text(p),
                    backgroundColor: Brand.primarySoft,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () => _send(p),
                  ),
                ),
              for (final f in kFaqs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: f.toManager
                        ? const Icon(Icons.support_agent_outlined, size: 16, color: Brand.grey)
                        : null,
                    label: Text(f.question),
                    backgroundColor: Brand.white,
                    side: const BorderSide(color: Brand.line),
                    shape: const StadiumBorder(),
                    onPressed: () => _tapFaq(f),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _c,
                  onSubmitted: _send,
                  textInputAction: TextInputAction.send,
                  maxLength: GeminiService.maxQuestionChars,
                  decoration:
                      const InputDecoration(hintText: 'Ask about the menu...', counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                    backgroundColor: Brand.primary, foregroundColor: Brand.white),
                onPressed: _loading ? null : () => _send(_c.text),
                icon: const Icon(Icons.arrow_upward),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
