import 'package:flutter/material.dart';

class VisualizerControls extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isPlaying;
  final double playbackSpeed;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onReset;
  final ValueChanged<int> onSeek;
  final ValueChanged<double> onSpeedChange;

  const VisualizerControls({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.onReset,
    required this.onSeek,
    required this.onSpeedChange,
  });

  @override
  Widget build(BuildContext context) {
    final maxSteps = mathMax(1, totalSteps - 1);
    final sliderVal = currentStep.clamp(0, maxSteps).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step Slider Row
          Row(
            children: [
              Text(
                'Step ${currentStep + 1} / $totalSteps',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.indigo,
                    thumbColor: Colors.indigo,
                  ),
                  child: Slider(
                    value: sliderVal,
                    min: 0,
                    max: maxSteps.toDouble(),
                    divisions: maxSteps > 0 ? maxSteps : 1,
                    onChanged: (val) => onSeek(val.toInt()),
                  ),
                ),
              ),
              // Speed toggle pill
              PopupMenuButton<double>(
                tooltip: 'Playback Speed',
                initialValue: playbackSpeed,
                onSelected: onSpeedChange,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${playbackSpeed}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.speed_rounded, size: 16, color: Colors.indigo),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 0.5, child: Text('0.5x Speed')),
                  const PopupMenuItem(value: 1.0, child: Text('1.0x Speed')),
                  const PopupMenuItem(value: 2.0, child: Text('2.0x Speed')),
                ],
              ),
            ],
          ),

          // Control Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Reset',
                onPressed: onReset,
                icon: const Icon(Icons.replay_rounded),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Previous Step',
                onPressed: currentStep > 0 ? onPrev : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onPlayPause,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPlaying ? 'PAUSE' : 'PLAY',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Next Step',
                onPressed: currentStep < totalSteps - 1 ? onNext : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int mathMax(int a, int b) => a > b ? a : b;
}
