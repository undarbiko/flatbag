import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:window_manager/window_manager.dart';
import '../models/flatpak_remote_app.dart';
import '../models/app_settings.dart';

/// A full-screen dialog for viewing, zooming, and navigating through application screenshots.
class ScreenshotViewerDialog extends StatefulWidget {
  final List<Screenshot> screenshots;
  final int initialIndex;

  const ScreenshotViewerDialog({super.key, required this.screenshots, required this.initialIndex});

  @override
  State<ScreenshotViewerDialog> createState() => _ScreenshotViewerDialogState();
}

class _ScreenshotViewerDialogState extends State<ScreenshotViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  bool _isFitToWindow = true;
  bool _isFullScreen = false;
  bool _wasFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
    _initFullScreenState();
  }

  Future<void> _initFullScreenState() async {
    _wasFullScreen = await windowManager.isFullScreen();
    _isFullScreen = _wasFullScreen;
    if (mounted) setState(() {});
  }

  Future<void> _toggleDisplayFullScreen() async {
    _isFullScreen = !_isFullScreen;
    await windowManager.setFullScreen(_isFullScreen);
    if (!_isFullScreen) {
      final textScale = AppTheme.textScale.value;
      await windowManager.setMinimumSize(Size(900 + (textScale - 1.0) * 300, 650 + (textScale - 1.0) * 300));
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Revert full screen state when dialog closes to maintain previous window sizing.
    if (_isFullScreen != _wasFullScreen) {
      windowManager.setFullScreen(_wasFullScreen);
      if (!_wasFullScreen) {
        final textScale = AppTheme.textScale.value;
        windowManager.setMinimumSize(Size(900 + (textScale - 1.0) * 300, 650 + (textScale - 1.0) * 300));
      }
    }
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _fitToWindow() {
    setState(() {
      _isFitToWindow = true;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _originalSize() {
    setState(() {
      _isFitToWindow = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _nextPage() {
    if (_currentIndex < widget.screenshots.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _zoom(double scale) {
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double newScale = (currentScale * scale).clamp(0.5, 4.0);
    final double zoomFactor = newScale / currentScale;

    if (zoomFactor == 1.0) return;

    final screenCenter = Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2);
    final scenePoint = _transformationController.toScene(screenCenter);

    final matrix = Matrix4.identity()
      ..translate(scenePoint.dx, scenePoint.dy)
      ..scale(zoomFactor, zoomFactor)
      ..translate(-scenePoint.dx, -scenePoint.dy);

    _transformationController.value = matrix * _transformationController.value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.black87,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white, size: 30),
                  onPressed: _toggleDisplayFullScreen,
                  tooltip: _isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: _currentIndex > 0
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                          onPressed: _previousPage,
                        )
                      : null,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.screenshots.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _transformationController.value = Matrix4.identity();
                        _isFitToWindow = true;
                      });
                    },
                    itemBuilder: (context, index) {
                      final url = widget.screenshots[index].imgDesktopUrl;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.1,
                            maxScale: 10.0,
                            constrained: _isFitToWindow,
                            child: Container(
                              constraints: BoxConstraints(
                                minWidth: _isFitToWindow ? 0.0 : constraints.maxWidth,
                                minHeight: _isFitToWindow ? 0.0 : constraints.maxHeight,
                              ),
                              alignment: Alignment.center,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: _isFitToWindow ? BoxFit.contain : BoxFit.none,
                                placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: _currentIndex < widget.screenshots.length - 1
                      ? IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                          onPressed: _nextPage,
                        )
                      : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fit_screen, color: Colors.white),
                    onPressed: _fitToWindow,
                    tooltip: 'Fit to Window',
                  ),
                  IconButton(
                    icon: const Icon(Icons.crop_original, color: Colors.white),
                    onPressed: _originalSize,
                    tooltip: 'Original Size',
                  ),
                  Container(width: 1, height: 24, color: Colors.white54, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Colors.white),
                    onPressed: () => _zoom(1 / 1.2),
                    tooltip: 'Zoom Out',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('${_currentIndex + 1} / ${widget.screenshots.length}', style: const TextStyle(color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white),
                    onPressed: () => _zoom(1.2),
                    tooltip: 'Zoom In',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
