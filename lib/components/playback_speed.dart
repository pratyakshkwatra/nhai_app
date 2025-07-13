import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlaybackSpeedSelector extends StatefulWidget {
  final VideoPlayerController controller;

  const PlaybackSpeedSelector({super.key, required this.controller});

  @override
  State<PlaybackSpeedSelector> createState() => _PlaybackSpeedSelectorState();
}

class _PlaybackSpeedSelectorState extends State<PlaybackSpeedSelector> {
  final List<double> speeds = [0.25, 0.5, 1, 2, 4, 8];
  double selectedSpeed = 1;

  @override
  void initState() {
    super.initState();
    selectedSpeed = widget.controller.value.playbackSpeed;
  }

  void _changeSpeed(double speed) {
    widget.controller.setPlaybackSpeed(speed);
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
          .map((speed) => PopupMenuItem(
                value: speed,
                padding:  EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.025,),
                child: Container(
                  padding:
                       EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.00675, horizontal: MediaQuery.of(context).size.width * 0.0125,),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${speed}x",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding:  EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height * 0.00675, horizontal: MediaQuery.of(context).size.width * 0.0125,),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            )
          ],
        ),
        alignment: Alignment.center,
        child: AutoSizeText(
          "${selectedSpeed}x",
          maxLines: 1,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
