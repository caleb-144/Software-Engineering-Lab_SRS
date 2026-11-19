import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// FR-08: check in / check out. Two taps (button + confirm) - within the 3-step target.
class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggle(AppState s, bool onShift) async {
    final ok = await confirmDialog(
      context,
      onShift ? 'Check out now?' : 'Check in now?',
      onShift
          ? 'Your shift will end at ${fmtTime(DateTime.now())}.'
          : 'Your shift will start at ${fmtTime(DateTime.now())}.',
      confirm: onShift ? 'Check out' : 'Check in',
      danger: onShift,
    );
    if (!ok) return;
    final err = onShift ? await s.checkOut() : await s.checkIn();
    if (!mounted) return;
    toast(context, err ?? (onShift ? 'Checked out. See you next time!' : 'Checked in. Have a great shift!'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final uid = s.user!.id;
    final open = s.openShiftFor(uid);
    final onShift = open != null;
    final records = s.recordsFor(uid);
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _toggle(s, onShift),
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: onShift ? Brand.danger : Brand.success,
                  boxShadow: [
                    BoxShadow(
                        color: (onShift ? Brand.danger : Brand.success).withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(onShift ? Icons.logout : Icons.login,
                        size: 42, color: Brand.white),
                    const SizedBox(height: 8),
                    Text(onShift ? 'Check out' : 'Check in',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Brand.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: onShift ? Brand.successSoft : Brand.dangerSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(onShift ? Icons.check_circle : Icons.cancel,
                    size: 18, color: onShift ? Brand.success : Brand.danger),
                const SizedBox(width: 8),
                Text(
                  onShift
                      ? 'Checked in since ${fmtTime(open.checkIn)}  (${fmtDuration(open.duration)})'
                      : 'You are not checked in',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: onShift ? Brand.success : Brand.danger),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: StatTile('This week', fmtDuration(s.hoursThisWeek(uid)))),
            const SizedBox(width: 12),
            Expanded(child: StatTile('Shifts logged', '${records.length}', dark: true)),
          ]),
          const SectionHeader('History'),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('No attendance records yet.',
                      style: TextStyle(color: Brand.grey))),
            ),
          for (final r in records)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmtDay(r.checkIn),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '${fmtTime(r.checkIn)} - ${r.checkOut == null ? 'now' : fmtTime(r.checkOut!)}',
                            style: const TextStyle(color: Brand.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text(fmtDuration(r.duration),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
