import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../models.dart';
import '../services/cloudinary_service.dart';
import '../theme.dart';
import 'common.dart';

/// ZUS-style banner: one event at a time, slides to the next by itself, with dots.
/// Each event can have a photo or a short video as its banner.
class EventBanner extends StatefulWidget {
  final List<CampusEvent> events;
  const EventBanner({required this.events, super.key});

  @override
  State<EventBanner> createState() => _EventBannerState();
}

class _EventBannerState extends State<EventBanner> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _next());
  }

  void _next() {
    if (!mounted || _touching || widget.events.length < 2 || !_controller.hasClients) return;
    final n = (_page + 1) % widget.events.length;
    _controller.animateToPage(n,
        duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _details(CampusEvent e) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.event, size: 18, color: Brand.primary),
            const SizedBox(width: 6),
            Text(fmtDateTime(e.date), style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          if (e.where.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 18, color: Brand.primary),
              const SizedBox(width: 6),
              Flexible(child: Text(e.where)),
            ]),
          ],
          if (e.blurb.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(e.blurb, style: const TextStyle(color: Brand.grey, fontSize: 15)),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    return Column(children: [
      SizedBox(
        height: 200,
        child: Listener(
          onPointerDown: (_) => _touching = true,
          onPointerUp: (_) => _touching = false,
          onPointerCancel: (_) => _touching = false,
          child: PageView.builder(
            controller: _controller,
            itemCount: events.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => AnimatedScale(
              scale: i == _page ? 1 : 0.94,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: GestureDetector(
                  onTap: () => _details(events[i]),
                  child: _Slide(event: events[i], active: i == _page),
                ),
              ),
            ),
          ),
        ),
      ),
      if (events.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < events.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? Brand.primary : Brand.line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ]),
        ),
    ]);
  }
}

class _Slide extends StatelessWidget {
  final CampusEvent event;
  final bool active;
  const _Slide({required this.event, required this.active});

  @override
  Widget build(BuildContext context) {
    final e = event;
    Widget bg;
    if (e.media.isEmpty) {
      bg = Container(
        decoration: const BoxDecoration(gradient: Brand.gradient),
      );
    } else if (e.isVideo) {
      bg = _VideoBg(url: CloudinaryService.videoMp4(e.media), play: active);
    } else {
      bg = Image.network(
        CloudinaryService.banner(e.media),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Brand.ink),
        loadingBuilder: (_, child, p) =>
            p == null ? child : Container(color: Brand.primarySoft),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(fit: StackFit.expand, children: [
        bg,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xB3000000)],
                begin: Alignment.center,
                end: Alignment.bottomCenter),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Brand.white, borderRadius: BorderRadius.circular(20)),
            child: Text(fmtDateTime(e.date),
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: Brand.primaryDark)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(e.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Brand.white,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900)),
            if (e.where.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(e.where,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Muted, looping video that plays only while its slide is on screen.
class _VideoBg extends StatefulWidget {
  final String url;
  final bool play;
  const _VideoBg({required this.url, required this.play});

  @override
  State<_VideoBg> createState() => _VideoBgState();
}

class _VideoBgState extends State<_VideoBg> {
  VideoPlayerController? _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _c = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c
        ..setVolume(0)
        ..setLooping(true);
      if (widget.play) c.play();
      setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  void didUpdateWidget(covariant _VideoBg old) {
    super.didUpdateWidget(old);
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    widget.play ? c.play() : c.pause();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_failed || c == null || !c.value.isInitialized) {
      return Container(
          color: Brand.ink,
          child: _failed
              ? const Center(child: Icon(Icons.videocam_off_outlined, color: Colors.white54))
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
          width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
    );
  }
}
