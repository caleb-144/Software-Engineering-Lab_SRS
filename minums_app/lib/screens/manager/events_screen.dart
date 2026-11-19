import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../services/cloudinary_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Manager: add and remove the campus events shown on the customer home page.
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = [...s.events]..sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Campus events')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: list.isEmpty
          ? const EmptyState(Icons.event_outlined, 'No events yet',
              subtitle: 'Tap "Add event" to show one on the customer home page.')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (_, i) {
                final e = list[i];
                final past = e.date.isBefore(DateTime.now());
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: past ? Brand.grey : null)),
                  leading: Icon(e.media.isEmpty
                      ? Icons.event_outlined
                      : (e.isVideo ? Icons.movie_outlined : Icons.image_outlined)),
                  subtitle: Text('${fmtDateTime(e.date)} - ${e.where}'
                      '${past ? '  (finished, hidden from customers)' : ''}'),
                  onTap: () => _edit(context, existing: e),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Brand.danger),
                    onPressed: () async {
                      final ok = await confirmDialog(
                          context, 'Delete this event?', e.title,
                          confirm: 'Delete', danger: true);
                      if (ok) s.deleteEvent(e.id);
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _edit(BuildContext context, {CampusEvent? existing}) async {
    final s = context.read<AppState>();
    final title = TextEditingController(text: existing?.title ?? '');
    final where = TextEditingController(text: existing?.where ?? '');
    final blurb = TextEditingController(text: existing?.blurb ?? '');
    var date = existing?.date ?? DateTime.now().add(const Duration(days: 1));
    var media = existing?.media ?? '';
    var isVideo = existing?.isVideo ?? false;
    var uploading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Event name')),
            const SizedBox(height: 12),
            TextField(controller: where, decoration: const InputDecoration(labelText: 'Where')),
            const SizedBox(height: 12),
            TextField(
                controller: blurb,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Short description')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(fmtDateTime(date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: date,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (d == null || !ctx.mounted) return;
                final t = await showTimePicker(
                    context: ctx, initialTime: TimeOfDay.fromDateTime(date));
                if (t == null) return;
                setSheet(() => date = DateTime(d.year, d.month, d.day, t.hour, t.minute));
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('Banner photo'),
                  onPressed: uploading
                      ? null
                      : () async {
                          if (!CloudinaryService.isConfigured) {
                            return toast(ctx, 'Set up Cloudinary first (see the guide).');
                          }
                          setSheet(() => uploading = true);
                          try {
                            final x = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1400,
                                imageQuality: 80);
                            if (x != null) {
                              final url =
                                  await CloudinaryService.uploadImage(await x.readAsBytes());
                              setSheet(() {
                                media = url;
                                isVideo = false;
                              });
                            }
                          } on String catch (m) {
                            if (ctx.mounted) toast(ctx, m);
                          } catch (_) {
                            if (ctx.mounted) toast(ctx, 'Could not open the photo.');
                          } finally {
                            setSheet(() => uploading = false);
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Banner video'),
                  onPressed: uploading
                      ? null
                      : () async {
                          if (!CloudinaryService.isConfigured) {
                            return toast(ctx, 'Set up Cloudinary first (see the guide).');
                          }
                          setSheet(() => uploading = true);
                          try {
                            final x = await ImagePicker().pickVideo(
                                source: ImageSource.gallery,
                                maxDuration: const Duration(seconds: 30));
                            if (x != null) {
                              final url =
                                  await CloudinaryService.uploadVideo(await x.readAsBytes());
                              setSheet(() {
                                media = url;
                                isVideo = true;
                              });
                            }
                          } on String catch (m) {
                            if (ctx.mounted) toast(ctx, m);
                          } catch (_) {
                            if (ctx.mounted) toast(ctx, 'Could not open the video.');
                          } finally {
                            setSheet(() => uploading = false);
                          }
                        },
                ),
              ),
            ]),
            if (uploading)
              const Padding(
                  padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            if (media.isNotEmpty && !uploading)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(isVideo ? Icons.movie_outlined : Icons.image_outlined,
                    color: Brand.success),
                title: Text(isVideo ? 'Video banner added' : 'Photo banner added'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setSheet(() {
                    media = '';
                    isVideo = false;
                  }),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: uploading ? null : () {
                  if (title.text.trim().isEmpty) return toast(ctx, 'Enter the event name');
                  s.saveEvent(CampusEvent(existing?.id ?? s.newEventId(), title.text.trim(),
                      date, where.text.trim(), blurb.text.trim(),
                      media: media, isVideo: isVideo));
                  Navigator.pop(ctx);
                },
                child: const Text('Save event'),
              ),
            ),
          ])),
        ),
      ),
    );
    title.dispose();
    where.dispose();
    blurb.dispose();
  }
}
