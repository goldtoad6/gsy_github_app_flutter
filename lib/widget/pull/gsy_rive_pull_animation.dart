import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

/// 2026-09-13: Replace the retired Flare runtime with the migrated vector asset.
/// Keep the historical pull curve and 2x refresh playback; migration provenance
/// and the independent Flare comparison live in docs/03-runbooks/flare-rive-migration.md.
class GSYRivePullAnimation extends StatefulWidget {
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final bool playAuto;

  const new({
    super.key,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    required this.playAuto,
  });

  @override
  State<GSYRivePullAnimation> createState() => _GSYRivePullAnimationState();
}

class _GSYRivePullAnimationState extends State<GSYRivePullAnimation> {
  final _painter = GSYRivePullPainter();
  rive.File? _file;
  rive.Artboard? _artboard;
  late final Future<void> _load;

  @override
  void initState() {
    super.initState();
    _updateProgress();
    _load = _loadAsset();
  }

  Future<void> _loadAsset() async {
    final file = await rive.File.asset(
      'static/file/loading_world_now.riv',
      riveFactory: rive.Factory.flutter,
    );
    if (!mounted) {
      file?.dispose();
      return;
    }
    if (file == null) throw StateError('Cannot decode loading_world_now.riv');
    final artboard = file.defaultArtboard();
    if (artboard == null) {
      file.dispose();
      throw StateError('Missing loading_world_now artboard');
    }
    _file = file;
    _artboard = artboard..frameOrigin = false;
  }

  void _updateProgress() => _painter.setProgress(
    widget.pulledExtent,
    widget.refreshTriggerPullDistance,
    widget.playAuto,
  );

  @override
  void didUpdateWidget(covariant GSYRivePullAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateProgress();
  }

  @override
  void dispose() {
    _painter.dispose();
    _artboard?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.hasError) return ErrorWidget(snapshot.error!);
      final artboard = _artboard;
      if (artboard == null) return const SizedBox.shrink();
      // FlareActor clipped its own bounds by default. RiveArtboardWidget
      // does not, so cover-fit content needs the same viewport clip.
      return ClipRect(
        child: rive.RiveArtboardWidget(artboard: artboard, painter: _painter),
      );
    },
  );
}

/// The progress mapping is independent of either animation file format.
double gsyRefreshAnimationTime(
  double duration,
  double pulledExtent,
  double trigger,
) {
  assert(trigger > 0);
  final extent = pulledExtent * 0.6;
  final adjusted = extent > trigger ? extent - trigger : extent;
  final position = adjusted / trigger;
  return duration * position * position;
}

final class GSYRivePullPainter extends rive.BasicArtboardPainter {
  new() : super(fit: rive.Fit.cover, alignment: Alignment.topCenter);

  rive.Animation? _animation;
  double _pulledExtent = 0;
  double _trigger = 140;
  double _time = 0;
  bool _playAuto = false;

  void setProgress(double extent, double trigger, bool playAuto) {
    if (_pulledExtent == extent &&
        _trigger == trigger &&
        _playAuto == playAuto) {
      return;
    }
    _pulledExtent = extent;
    _trigger = trigger;
    _playAuto = playAuto;
    scheduleRepaint();
  }

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _animation?.dispose();
    _animation = artboard.animationNamed('Earth Moving');
    if (_animation == null) throw StateError('Missing Earth Moving animation');
    scheduleRepaint();
  }

  @override
  bool advance(double elapsedSeconds) {
    final animation = _animation;
    if (animation == null) return false;
    _time = _playAuto
        ? (_time + elapsedSeconds * 2) % animation.duration
        : gsyRefreshAnimationTime(animation.duration, _pulledExtent, _trigger);
    // Keep the unbounded pull time for the transition into automatic playback,
    // just as Flare did; only the rendered pose clamps to the timeline ends.
    animation.time = _time.clamp(0, animation.duration);
    animation.apply();
    // The public painter resolves component dirt after applying a timeline.
    // Artboard.advance alone does not perform that update in rive_native 0.1.11.
    super.advance(0);
    return _playAuto;
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }
}
