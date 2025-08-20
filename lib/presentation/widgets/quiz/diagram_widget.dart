import 'package:flutter/material.dart';

class DiagramWidget extends StatelessWidget {
  final String imageAssetPath;

  const DiagramWidget({
    super.key,
    required this.imageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      panEnabled: true, // Enable panning
      minScale: 0.5,    // Minimum zoom out level
      maxScale: 4.0,    // Maximum zoom in level
      child: Image.asset(
        imageAssetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}