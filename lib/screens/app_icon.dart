import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that safely renders either an SVG or a standard image file based on the provided [iconPath].
class AppIcon extends StatelessWidget {
  final String? iconPath;
  final double size;

  const AppIcon({super.key, required this.iconPath, required this.size});

  @override
  Widget build(BuildContext context) {
    if (iconPath == null || iconPath!.isEmpty) {
      return Icon(Icons.apps, size: size);
    }
    if (iconPath!.endsWith('.svg')) {
      return SvgPicture.file(File(iconPath!), width: size, height: size);
    }
    return Image.file(File(iconPath!), width: size, height: size);
  }
}
