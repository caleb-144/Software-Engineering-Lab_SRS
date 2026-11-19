import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Manager view of staff attendance and working hours (FR-08 / P1).
class StaffOverviewTab extends StatelessWidget {
  const StaffOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final recent = s.attendance.take(30).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (s.pendingStaff.isNotEmpty) ...[
            const SectionHeader('Waiting for your approval'),
            for (final u in s.pendingStaff)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                            Text(u.email,
                                style: const TextStyle(color: Brand.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Reject',
                        icon: const Icon(Icons.close, color: Brand.danger),
                        onPressed: () async {
                          final err = await context.read<AppState>().rejectStaff(u.id);
                          if (err != null && context.mounted) toast(context, err);
                        },
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        icon: const Icon(Icons.check_circle, color: Brand.success),
                        onPressed: () async {
                          final err = await context.read<AppState>().approveStaff(u.id);
                          if (!context.mounted) return;
                          toast(context, err ?? '${u.name} can now log in as staff');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          for (final u in s.staffUsers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Brand.primary,
                      child: Text(u.name.isEmpty ? '?' : u.name[0],
                          style: const TextStyle(
                              color: Brand.white, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('This week: ${fmtDuration(s.hoursThisWeek(u.id))}',
                              style: const TextStyle(color: Brand.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    s.openShiftFor(u.id) != null
                        ? const Tag('Checked in', filled: true, color: Brand.success)
                        : const Tag('Off', color: Brand.grey),
                  ],
                ),
              ),
            ),
          const SectionHeader('Recent records'),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No attendance records yet.',
                      style: TextStyle(color: Brand.grey))),
            ),
          for (final r in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.staffName,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          '${fmtDay(r.checkIn)}  ${fmtTime(r.checkIn)} - ${r.checkOut == null ? 'now' : fmtTime(r.checkOut!)}',
                          style: const TextStyle(color: Brand.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(fmtDuration(r.duration),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
