import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../thread_screen.dart';

/// Inbox of customer questions escalated from the AI chatbot (FR-05).
class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<AppState>().threads;
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threads.isEmpty
          ? const EmptyState(Icons.chat_bubble_outline, 'No customer messages',
              subtitle: 'Questions the AI assistant cannot answer will appear here.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, i) {
                final t = threads[i];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThreadScreen(
                          customerId: t.customerId, title: t.customerName),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: t.awaitingReply ? Brand.primary : Brand.soft,
                        child: Text(
                          t.customerName.isEmpty ? '?' : t.customerName[0].toUpperCase(),
                          style: TextStyle(
                              color: t.awaitingReply ? Brand.white : Brand.ink,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.customerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            if (t.last.viaBot)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text('From AI assistant',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Brand.primary)),
                              ),
                            Text(t.last.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: t.awaitingReply ? Brand.ink : Brand.grey,
                                    fontWeight:
                                        t.awaitingReply ? FontWeight.w600 : FontWeight.w400)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmtTime(t.last.at),
                              style: const TextStyle(fontSize: 11, color: Brand.grey)),
                          if (t.awaitingReply) const Tag('Needs reply', filled: true, color: Brand.danger),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
