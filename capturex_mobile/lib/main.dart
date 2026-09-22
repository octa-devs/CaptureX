import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Entry Point ─────────────────────────────────────────────────────────────

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF07090E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  try {
    _cameras = await availableCameras();
  } catch (_) {
    _cameras = [];
  }
  runApp(const CaptureXApp());
}

// ─── Theme & Constants ────────────────────────────────────────────────────────

const kBg = Color(0xFF07090E);
const kSurface = Color(0xFF0F1219);
const kOrange = Color(0xFFFF9F0A);
const kOrangeDim = Color(0x44FF9F0A);
const kGlass = Color(0x22FFFFFF);
const kGlassBorder = Color(0x18FFFFFF);
const kRed = Color(0xFFFF3B30);
const kWhite = Colors.white;

// ─── App ─────────────────────────────────────────────────────────────────────

class CaptureXApp extends StatelessWidget {
  const CaptureXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaptureX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        primaryColor: kOrange,
        colorScheme: const ColorScheme.dark(
          primary: kOrange,
          surface: kSurface,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: kOrange,
          thumbColor: kOrange,
          inactiveTrackColor: Colors.white12,
          overlayColor: kOrangeDim,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const CameraHome(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: kOrange.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CaptureX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: kWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'PRO CAMERA & VIDEO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kOrange,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Capture Mode ────────────────────────────────────────────────────────────

enum CaptureMode { photo, video, portrait, slowmo }

extension CaptureModeLabel on CaptureMode {
  String get label {
    switch (this) {
      case CaptureMode.photo:
        return 'PHOTO';
      case CaptureMode.video:
        return 'VIDEO';
      case CaptureMode.portrait:
        return 'PORTRAIT';
      case CaptureMode.slowmo:
        return 'SLOW-MO';
    }
  }
}

// ─── Bottom Nav Tabs ──────────────────────────────────────────────────────────

enum NavTab { filters, camera, about }

// ─── Camera Home ─────────────────────────────────────────────────────────────

class CameraHome extends StatefulWidget {
  const CameraHome({super.key});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> with WidgetsBindingObserver {
  NavTab _tab = NavTab.camera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: IndexedStack(
        index: _tab.index,
        children: [
          const FiltersPage(),
          CameraPage(onTabChange: (t) => setState(() => _tab = t)),
          const AboutPage(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (t) => setState(() => _tab = t),
      ),
    );
  }
}

// ─── Glass Widget Helper ──────────────────────────────────────────────────────

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final Border? border;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.12,
    this.radius,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: radius,
            border: border ??
                Border.all(color: kGlassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final NavTab current;
  final ValueChanged<NavTab> onTap;

  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (NavTab.filters, Icons.auto_fix_high_rounded, 'Filters'),
      (NavTab.camera, Icons.camera_alt_rounded, 'Camera'),
      (NavTab.about, Icons.info_outline_rounded, 'About'),
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xDD07090E),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            children: items.map((item) {
              final (tab, icon, label) = item;
              final sel = current == tab;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(tab);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon,
                          color: sel ? kOrange : Colors.white38, size: 24),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            color: sel ? kOrange : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: sel ? 20 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Camera Page ──────────────────────────────────────────────────────────────

class CameraPage extends StatefulWidget {
  final ValueChanged<NavTab> onTabChange;

  const CameraPage({super.key, required this.onTabChange});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _isInitializing = true;
  int _cameraIndex = 0;

  CaptureMode _mode = CaptureMode.photo;
  bool _isRecording = false;
  bool _isCapturing = false;
  bool _isFlashing = false;
  FlashMode _flashMode = FlashMode.off;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 5.0;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Exposure / focus
  Offset? _focusPoint;
  bool _showFocusIndicator = false;

  // Controls panel
  bool _showControls = false;
  double _exposureOffset = 0.0;

  late AnimationController _shutterAnimCtrl;
  late Animation<double> _shutterScale;

  @override
  void initState() {
    super.initState();
    _shutterAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shutterScale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _shutterAnimCtrl, curve: Curves.easeInOut));
    _requestPermissionAndInit();
  }

  @override
  void dispose() {
    _shutterAnimCtrl.dispose();
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _requestPermissionAndInit() async {
    final camStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (camStatus.isDenied || camStatus.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
        _isInitializing = false;
      });
      return;
    }

    if (_cameras.isEmpty) {
      setState(() => _isInitializing = false);
      return;
    }

    await _initCamera(_cameras[_cameraIndex]);
  }

  Future<void> _initCamera(CameraDescription desc) async {
    setState(() => _isInitializing = true);

    final prev = _controller;
    _controller = null;
    await prev?.dispose();

    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await ctrl.initialize();
      if (!mounted) return;
      _minZoom = await ctrl.getMinZoomLevel();
      _maxZoom = await ctrl.getMaxZoomLevel();
      await ctrl.setFlashMode(_flashMode);
      setState(() {
        _controller = ctrl;
        _isInitializing = false;
        _zoomLevel = 1.0;
      });
    } catch (e) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    HapticFeedback.selectionClick();
    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final idx = modes.indexOf(_flashMode);
    _flashMode = modes[(idx + 1) % modes.length];
    await _controller?.setFlashMode(_flashMode);
    setState(() {});
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.torch:
        return Icons.highlight_rounded;
    }
  }

  Future<void> _onTapFocus(TapDownDetails details, BoxConstraints constraints) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    setState(() {
      _focusPoint = details.localPosition;
      _showFocusIndicator = true;
    });
    await _controller!.setFocusPoint(offset);
    await _controller!.setExposurePoint(offset);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFocusIndicator = false);
    });
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    HapticFeedback.heavyImpact();
    _shutterAnimCtrl.forward().then((_) => _shutterAnimCtrl.reverse());

    setState(() {
      _isCapturing = true;
      _isFlashing = true;
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _isFlashing = false);
    });

    try {
      final dir = await getTemporaryDirectory();
      final path = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final xFile = await _controller!.takePicture();
      await xFile.saveTo(path);
      if (mounted) _showCapturedPreview(path);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      // Stop
      HapticFeedback.heavyImpact();
      final xFile = await _controller!.stopVideoRecording();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });
      if (mounted) _showCapturedPreview(xFile.path, isVideo: true);
    } else {
      // Start
      HapticFeedback.heavyImpact();
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showCapturedPreview(String path, {bool isVideo = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CapturedPreviewSheet(path: path, isVideo: isVideo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_permissionDenied) return _buildPermissionDenied();
    if (_isInitializing) return _buildLoading();
    if (_cameras.isEmpty) return _buildNoCamera();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview — full screen
        _buildPreview(),

        // Top controls glass bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),

        // Focus indicator
        if (_showFocusIndicator && _focusPoint != null)
          Positioned(
            left: _focusPoint!.dx - 32,
            top: _focusPoint!.dy - 32,
            child: _FocusRing(),
          ),

        // Flash effect
        if (_isFlashing)
          Container(color: Colors.white.withOpacity(0.6)),

        // Mode selector + bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final ctrl = _controller!;
    return LayoutBuilder(builder: (context, constraints) {
      return GestureDetector(
        onTapDown: (d) => _onTapFocus(d, constraints),
        onScaleUpdate: (details) async {
          final newZoom = (_zoomLevel * details.scale)
              .clamp(_minZoom, _maxZoom);
          setState(() => _zoomLevel = newZoom);
          await _controller?.setZoomLevel(newZoom);
        },
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.previewSize?.height ?? 1,
              height: ctrl.value.previewSize?.width ?? 1,
              child: CameraPreview(ctrl),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassBox(
          radius: BorderRadius.circular(20),
          blur: 24,
          opacity: 0.15,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Flash
              _TopBarButton(
                icon: _flashIcon,
                color: _flashMode == FlashMode.off ? Colors.white60 : kOrange,
                onTap: _toggleFlash,
              ),

              const Spacer(),

              // App title
              const Text(
                'CaptureX',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),

              const Spacer(),

              // Recording timer / settings
              if (_isRecording)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: kRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _formatDuration(_recordingSeconds),
                      style: const TextStyle(
                        color: kRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                )
              else
                _TopBarButton(
                  icon: Icons.tune_rounded,
                  color: _showControls ? kOrange : Colors.white60,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showControls = !_showControls);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exposure slider (conditional)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _showControls
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassBox(
                      radius: BorderRadius.circular(18),
                      blur: 20,
                      opacity: 0.15,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('EXPOSURE',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5)),
                              Text(
                                _exposureOffset >= 0
                                    ? '+${_exposureOffset.toStringAsFixed(1)}'
                                    : _exposureOffset.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: kOrange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Slider(
                            value: _exposureOffset,
                            min: -2,
                            max: 2,
                            divisions: 40,
                            onChanged: (val) async {
                              setState(() => _exposureOffset = val);
                              await _controller?.setExposureOffset(val);
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 12),

          // Zoom level indicator
          if (_zoomLevel > 1.05)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_zoomLevel.toStringAsFixed(1)}×',
                style: const TextStyle(
                    color: kOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),

          // Mode selector
          _ModeSelector(
            current: _mode,
            onChanged: (m) => setState(() => _mode = m),
          ),

          const SizedBox(height: 20),

          // Shutter row: flip | shutter | gallery
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flip camera
                _CircleIconButton(
                  icon: Icons.flip_camera_ios_rounded,
                  size: 52,
                  onTap: _flipCamera,
                ),

                // SHUTTER — centered
                _ShutterButton(
                  mode: _mode,
                  isRecording: _isRecording,
                  scaleAnim: _shutterScale,
                  onTap: () {
                    if (_mode == CaptureMode.video) {
                      _toggleVideoRecording();
                    } else {
                      _capturePhoto();
                    }
                  },
                ),

                // Placeholder (gallery icon)
                _CircleIconButton(
                  icon: Icons.photo_library_outlined,
                  size: 52,
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: kOrange, strokeWidth: 2),
          SizedBox(height: 16),
          Text('Starting camera...',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoCamera() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.no_photography_outlined, color: Colors.white30, size: 64),
          SizedBox(height: 16),
          Text('No camera found',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white30, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                  color: kWhite, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'CaptureX needs camera and microphone access to shoot photos and record video.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: openAppSettings,
              child: const Text('Open Settings',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Focus Ring ───────────────────────────────────────────────────────────────

class _FocusRing extends StatefulWidget {
  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _size;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _size = Tween<double>(begin: 80, end: 64).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 1, end: 0.6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: SizedBox(
          width: _size.value,
          height: _size.value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: kOrange, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shutter Button ───────────────────────────────────────────────────────────

class _ShutterButton extends StatelessWidget {
  final CaptureMode mode;
  final bool isRecording;
  final Animation<double> scaleAnim;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.mode,
    required this.isRecording,
    required this.scaleAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = mode == CaptureMode.video;
    final Color ringColor = isVideo ? kRed : kWhite;

    return GestureDetector(
      onTap: onTap,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor.withOpacity(0.85),
              width: 3.5,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isRecording ? 28 : 62,
              height: isRecording ? 28 : 62,
              decoration: BoxDecoration(
                color: isVideo ? kRed : kWhite,
                borderRadius: BorderRadius.circular(isRecording ? 6 : 100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Circle Icon Button ───────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color? color;

  const _CircleIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: size * 0.44),
      ),
    );
  }
}

// ─── Top Bar Icon Button ──────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TopBarButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final CaptureMode current;
  final ValueChanged<CaptureMode> onChanged;

  const _ModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: CaptureMode.values.map((m) {
          final sel = m == current;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(m);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Text(
                    m.label,
                    style: TextStyle(
                      color: sel ? kOrange : Colors.white54,
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: sel ? 20 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Captured Preview Sheet ───────────────────────────────────────────────────

class _CapturedPreviewSheet extends StatelessWidget {
  final String path;
  final bool isVideo;

  const _CapturedPreviewSheet({required this.path, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      radius: const BorderRadius.vertical(top: Radius.circular(28)),
      blur: 30,
      opacity: 0.18,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black,
                border: Border.all(color: Colors.white12),
              ),
              clipBehavior: Clip.antiAlias,
              child: isVideo
                  ? const Center(
                      child: Icon(Icons.videocam_rounded,
                          color: Colors.white38, size: 60))
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(path), fit: BoxFit.cover),
                        // Watermark
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.white24),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Shot with CaptureX',
                                      style: TextStyle(
                                        color: kWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'capturex.app',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kWhite,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Discard'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Save to Gallery',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Filters Page ─────────────────────────────────────────────────────────────

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  int _selected = 0;
  double _exposure = 0;
  double _saturation = 0;
  double _temperature = 0;
  double _vignette = 0;
  double _grain = 0;

  final _filters = [
    _FilterPreset('Original', [kBg, kSurface], null),
    _FilterPreset('Moody', [const Color(0xFF1A1A2E), const Color(0xFF16213E)], kOrange),
    _FilterPreset('Dreamy', [const Color(0xFFE8C5E5), const Color(0xFFB0C4F5)], const Color(0xFFD4A0D4)),
    _FilterPreset('Nightcore', [const Color(0xFF0D0221), const Color(0xFF1B0041)], const Color(0xFF00F5FF)),
    _FilterPreset('Vivid', [const Color(0xFF1A3A4A), const Color(0xFF0D2030)], const Color(0xFF00C6FF)),
    _FilterPreset('Portra 400', [const Color(0xFF3D2B1F), const Color(0xFF5C4033)], const Color(0xFFFFD59E)),
    _FilterPreset('Tri-X B&W', [const Color(0xFF1C1C1C), const Color(0xFF3D3D3D)], Colors.white),
    _FilterPreset('Fuji Velvia', [const Color(0xFF1A3020), const Color(0xFF2D5034)], const Color(0xFF39FF14)),
    _FilterPreset('Cinematic', [const Color(0xFF0A0A1A), const Color(0xFF1A1A3A)], const Color(0xFF4169E1)),
    _FilterPreset('Golden Hr', [const Color(0xFF3D2000), const Color(0xFF6B3800)], const Color(0xFFFFBE00)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Filter Studio',
                style: TextStyle(
                  color: kWhite,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Filter scroll
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final sel = _selected == i;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = i);
                    },
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: f.colors,
                        ),
                        border: Border.all(
                          color: sel ? kOrange : Colors.white12,
                          width: sel ? 2 : 1,
                        ),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: kOrange.withOpacity(0.3),
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              f.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: sel ? kOrange : Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Preview canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _filters[_selected].colors,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Sample image placeholder
                        const Center(
                          child: Icon(Icons.image_outlined,
                              color: Colors.white10, size: 80),
                        ),
                        if (_filters[_selected].accent != null)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    _filters[_selected].accent!.withOpacity(0.08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // Watermark
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: GlassBox(
                            radius: BorderRadius.circular(10),
                            blur: 10,
                            opacity: 0.2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Shot with CaptureX',
                                    style: TextStyle(
                                        color: kWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                                Text('capturex.app',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Sliders
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassBox(
                radius: BorderRadius.circular(20),
                blur: 20,
                opacity: 0.12,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SliderRow('EXPOSURE', _exposure, -2, 2, (v) => setState(() => _exposure = v)),
                    _SliderRow('SATURATION', _saturation, -1, 1, (v) => setState(() => _saturation = v)),
                    _SliderRow('TEMPERATURE', _temperature, -1, 1, (v) => setState(() => _temperature = v)),
                    _SliderRow('VIGNETTE', _vignette, 0, 1, (v) => setState(() => _vignette = v)),
                    _SliderRow('GRAIN', _grain, 0, 1, (v) => setState(() => _grain = v), isLast: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _FilterPreset {
  final String name;
  final List<Color> colors;
  final Color? accent;
  const _FilterPreset(this.name, this.colors, this.accent);
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final bool isLast;

  const _SliderRow(this.label, this.value, this.min, this.max, this.onChanged,
      {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final display = value >= 0 && min < 0
        ? '+${value.toStringAsFixed(1)}'
        : value.toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(display,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: kOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── About Page ───────────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 18),

              const Text('CaptureX',
                  style: TextStyle(
                      color: kWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('PRO CAMERA & VIDEO',
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3)),

              const SizedBox(height: 6),
              const Text('Version 1.1.0',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),

              const SizedBox(height: 28),

              // Feature cards
              _AboutCard(
                icon: Icons.camera_alt_rounded,
                title: 'Real Camera',
                subtitle: 'Full live preview with tap-to-focus, pinch-to-zoom, flash control, and front/back switching.',
              ),
              const SizedBox(height: 12),
              _AboutCard(
                icon: Icons.videocam_rounded,
                title: 'Video Recording',
                subtitle: 'Record HD video with audio. Real-time recording timer and seamless photo/video mode switch.',
              ),
              const SizedBox(height: 12),
              _AboutCard(
                icon: Icons.auto_fix_high_rounded,
                title: 'Filter Studio',
                subtitle: 'Moody, Dreamy, Nightcore, Vivid, Cinematic and more. Fine-tune with exposure, saturation, temperature and grain sliders.',
              ),
              const SizedBox(height: 12),
              _AboutCard(
                icon: Icons.water_drop_rounded,
                title: 'Liquid Glass UI',
                subtitle: 'Frosted glass panels with dynamic blur. A premium camera feel from top bar to shutter.',
              ),
              const SizedBox(height: 12),
              _AboutCard(
                icon: Icons.branding_watermark_rounded,
                title: 'Auto Watermark',
                subtitle: '"Shot with CaptureX" watermark automatically applied to every photo with a glass-frosted badge.',
              ),

              const SizedBox(height: 32),

              // Built with
              GlassBox(
                radius: BorderRadius.circular(18),
                blur: 16,
                opacity: 0.1,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('BUILT WITH',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: ['Flutter', 'Dart', 'camera', 'permission_handler', 'path_provider']
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                '© 2025 CaptureX • All rights reserved',
                style: TextStyle(color: Colors.white24, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      radius: BorderRadius.circular(18),
      blur: 16,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kOrangeDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: kWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
