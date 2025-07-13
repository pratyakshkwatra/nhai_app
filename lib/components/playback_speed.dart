import 'package:auto_size_text/auto_size_text.dart';
import 'package:better_player_enhanced/better_player.dart';
import 'package:flutter/material.dart';

class PlaybackSpeedSelector extends StatefulWidget {
  final BetterPlayerController controller;

  const PlaybackSpeedSelector({super.key, required this.controller});

  @override
  State<PlaybackSpeedSelector> createState() => _PlaybackSpeedSelectorState();
}

class _PlaybackSpeedSelectorState extends State<PlaybackSpeedSelector> {
  final List<double> speeds = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2];
  double selectedSpeed = 1;

  @override
  void initState() {
    if (widget.controller.isVideoInitialized() ?? false) {
      selectedSpeed = widget.controller.videoPlayerController!.value.speed;
    }

    super.initState();
  }

  void _changeSpeed(double speed) {
    widget.controller.setSpeed(speed);
    setState(() => selectedSpeed = speed);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      splashRadius: 0,
      elevation: 10,
      initialValue: selectedSpeed,
      onSelected: _changeSpeed,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => speeds
          .map((speed) => PopupMenuItem<double>(
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                value: speed,
                child: Text(
                  '${speed}x',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: AutoSizeText(
          '${selectedSpeed}x',
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
