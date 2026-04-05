import 'dart:async';

import 'package:flutter/material.dart';

class RoundProgressBar extends StatefulWidget {
  final int startedAtMs;
  final int targetSeconds;
  final int pausedAccumulatedMs;
  final int? pausedAtMs;

  const RoundProgressBar({
    super.key,
    required this.startedAtMs,
    required this.targetSeconds,
    required this.pausedAccumulatedMs,
    required this.pausedAtMs,
  });

  @override
  State<RoundProgressBar> createState() => _RoundProgressBarState();
}

class _RoundProgressBarState extends State<RoundProgressBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant RoundProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startedAtMs != widget.startedAtMs ||
        oldWidget.targetSeconds != widget.targetSeconds) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Se estiver pausado, o "agora" efectivo congela no momento da pausa.
    final effectiveNowMs = widget.pausedAtMs ?? nowMs;
    
    final elapsedMs = effectiveNowMs - widget.startedAtMs - widget.pausedAccumulatedMs;
    final elapsedSeconds = elapsedMs / 1000.0;

    final progress =
        (1 - (elapsedSeconds / widget.targetSeconds)).clamp(0.0, 1.0);

    final remainingSeconds =
        (widget.targetSeconds - elapsedSeconds).clamp(0, widget.targetSeconds);

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bónus de tempo',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${remainingSeconds.ceil()}s restantes',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}