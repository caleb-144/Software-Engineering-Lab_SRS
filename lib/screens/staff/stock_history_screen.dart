import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txns = context.watch<AppState>().stockTxns;
    return Scaffold(
      appBar: AppBar(title: const Text('Stock history')),
      body: txns.isEmpty
          ? const EmptyState(Icons.history, 'No stock movements yet')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: txns.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (_, i) {
                final t = txns[i];
                return Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.isIn ? Brand.successSoft : Brand.dangerSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(t.isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          size: 20, color: t.isIn ? Brand.success : Brand.danger),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.itemName,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${t.reason}  -  ${t.byName}',
                              style: const TextStyle(color: Brand.grey, fontSize: 12)),
                          Text(fmtDateTime(t.at),
                              style: const TextStyle(color: Brand.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text('${t.isIn ? '+' : '-'}${t.qty}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                );
              },
            ),
    );
  }
}
