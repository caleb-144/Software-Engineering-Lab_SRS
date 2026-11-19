import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// FR-05: customer <-> manager conversation. The same screen is used by the
/// customer (own thread) and by the manager (a selected customer's thread).
class ThreadScreen extends StatefulWidget {
  final String customerId;
  final String? title;
  final String? prefill;
  const ThreadScreen({required this.customerId, this.title, this.prefill});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  late final TextEditingController _c =
      TextEditingController(text: widget.prefill ?? '');
  final _scroll = ScrollController();

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final s = context.read<AppState>();
    final text = _c.text;
    if (text.trim().isEmpty) return;
    if (s.user!.role == Role.manager) {
      s.sendManagerReply(widget.customerId, text);
    } else {
      final err = s.sendCustomerMessage(text);
      if (err != null) {
        toast(context, err);
        return;
      }
    }
    _c.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isManager = s.user!.role == Role.manager;
    final msgs = s.thread(widget.customerId);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? (isManager ? 'Customer' : 'Message manager'))),
      body: Column(
        children: [
          Expanded(
            child: msgs.isEmpty
                ? EmptyState(
                    Icons.chat_bubble_outline,
                    isManager ? 'No messages yet' : 'Ask the manager anything',
                    subtitle: isManager
                        ? null
                        : 'Your message goes straight to the manager and they will reply here.',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final mine = isManager ? m.fromManager : !m.fromManager;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? Brand.primary : Brand.white,
                            border: mine ? null : Border.all(color: Brand.line),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.text,
                                  style: TextStyle(
                                      color: mine ? Brand.white : Brand.ink, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(fmtDateTime(m.at),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: mine ? Colors.white70 : Brand.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _c,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isManager ? 'Reply to customer...' : 'Type your message...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Brand.primary, foregroundColor: Brand.white),
                    onPressed: _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
