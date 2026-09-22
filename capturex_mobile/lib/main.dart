import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAMERAS
// ─────────────────────────────────────────────────────────────────────────────

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF07090E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  try {
    _cameras = await availableCameras();
  } catch (_) {}
  runApp(const CaptureXApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

const kBg = Color(0xFF07090E);
const kSurface = Color(0xFF0D1018);
const kOrange = Color(0xFFFF9F0A);
const kOrangeGlow = Color(0x44FF9F0A);
const kRed = Color(0xFFFF3B30);
const kGlassBorder = Color(0x14FFFFFF);

// ─────────────────────────────────────────────────────────────────────────────
// COLOR MATRIX ENGINE
// Builds a single 4×5 RGBA color matrix combining all adjustments.
// Values in the 5th column (offsets) are in the 0-255 channel range.
// ─────────────────────────────────────────────────────────────────────────────

List<double> buildColorMatrix({
  double brightness = 0,   // -255 … 255
  double contrast = 1.0,   // 0.1 … 3.0
  double saturation = 1.0, // 0.0 … 3.0
  double warmth = 0,       // -80 … 80  (warm +R -B, cool -R +B)
  double tint = 0,         // -50 … 50  (green +G, magenta -G)
}) {
  // Luminance weights (ITU-R BT.709)
  const rL = 0.2126, gL = 0.7152, bL = 0.0722;
  final s = saturation;
  final sr = rL * (1 - s);
  final sg = gL * (1 - s);
  final sb = bL * (1 - s);
  final co = 128.0 * (1 - contrast); // contrast pivot at 128
  return [
    (sr + s) * contrast, sg * contrast,       sb * contrast,       0, co + brightness + warmth,
    sr * contrast,       (sg + s) * contrast, sb * contrast,       0, co + brightness + tint,
    sr * contrast,       sg * contrast,       (sb + s) * contrast, 0, co + brightness - warmth,
    0, 0, 0, 1, 0,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER PRESETS
// ─────────────────────────────────────────────────────────────────────────────

class CxFilter {
  final String name;
  final double brightness, contrast, saturation, warmth, tint;
  final List<Color> thumbColors; // gradient for the thumbnail card
  final Color? labelColor;

  const CxFilter({
    required this.name,
    this.brightness = 0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.warmth = 0,
    this.tint = 0,
    required this.thumbColors,
    this.labelColor,
  });

  // Returns the combined matrix: preset params + user delta params
  List<double> matrix({
    double dBrightness = 0,
    double dContrast = 1.0,
    double dSaturation = 1.0,
    double dWarmth = 0,
    double dTint = 0,
  }) =>
      buildColorMatrix(
        brightness: (brightness + dBrightness).clamp(-255, 255),
        contrast: (contrast * dContrast).clamp(0.1, 3.0),
        saturation: (saturation * dSaturation).clamp(0.0, 3.0),
        warmth: (warmth + dWarmth).clamp(-80, 80),
        tint: (tint + dTint).clamp(-50, 50),
      );
}

const kFilters = <CxFilter>[
  CxFilter(
    name: 'Original',
    thumbColors: [Color(0xFF1E2D3D), Color(0xFF2A4058)],
  ),
  CxFilter(
    name: 'Moody',
    contrast: 1.35, saturation: 0.62, warmth: -14, brightness: -22,
    thumbColors: [Color(0xFF0C0D14), Color(0xFF181B26)],
    labelColor: Color(0xFF8B9BC8),
  ),
  CxFilter(
    name: 'Dreamy',
    brightness: 28, contrast: 0.86, saturation: 0.78, warmth: 20,
    thumbColors: [Color(0xFFD4A8E8), Color(0xFF94B8F4)],
    labelColor: Color(0xFFECC8F0),
  ),
  CxFilter(
    name: 'Nightcore',
    contrast: 1.5, saturation: 2.1, warmth: -28, brightness: -14,
    thumbColors: [Color(0xFF04000F), Color(0xFF160040)],
    labelColor: Color(0xFF00F5FF),
  ),
  CxFilter(
    name: 'Vivid',
    contrast: 1.38, saturation: 1.65, brightness: 14,
    thumbColors: [Color(0xFF0B3F8A), Color(0xFF0097B2)],
    labelColor: Color(0xFF40C8FF),
  ),
  CxFilter(
    name: 'Portra',
    warmth: 24, saturation: 0.84, contrast: 0.92, brightness: 10,
    thumbColors: [Color(0xFF3A2010), Color(0xFFBE8A58)],
    labelColor: Color(0xFFFFD59E),
  ),
  CxFilter(
    name: 'B&W',
    saturation: 0.0, contrast: 1.18,
    thumbColors: [Color(0xFF0E0E0E), Color(0xFF6A6A6A)],
    labelColor: Color(0xFFCCCCCC),
  ),
  CxFilter(
    name: 'Cinematic',
    contrast: 1.28, saturation: 0.72, warmth: -12, tint: -7, brightness: -18,
    thumbColors: [Color(0xFF060610), Color(0xFF152030)],
    labelColor: Color(0xFF4488AA),
  ),
  CxFilter(
    name: 'Vintage',
    warmth: 30, contrast: 0.80, saturation: 0.70, brightness: 14,
    thumbColors: [Color(0xFF5A2E0C), Color(0xFFBDA47E)],
    labelColor: Color(0xFFE8C89A),
  ),
  CxFilter(
    name: 'Velvia',
    saturation: 2.0, contrast: 1.30, warmth: 12,
    thumbColors: [Color(0xFF0B3316), Color(0xFF22993A)],
    labelColor: Color(0xFF44FF66),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// GLASS BOX
// ─────────────────────────────────────────────────────────────────────────────

class GlassBox extends StatelessWidget {
  final Widget child;
  final double blur, opacity;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final Color? bg, border;

  const GlassBox({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.10,
    this.radius,
    this.padding,
    this.bg,
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
            color: bg ?? Colors.white.withOpacity(opacity),
            borderRadius: radius,
            border: Border.all(color: border ?? kGlassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────────────────────────────────────

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
        sliderTheme: SliderThemeData(
          activeTrackColor: kOrange,
          thumbColor: kOrange,
          inactiveTrackColor: Colors.white10,
          overlayColor: kOrangeGlow,
          trackHeight: 2.5,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale, _rise;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0, 0.65, curve: Curves.easeOut));
    _scale = Tween(begin: 0.72, end: 1.0).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.55, curve: Curves.easeOutBack)));
    _rise = Tween(begin: 32.0, end: 0.0).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));
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
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _rise.value),
            child: Transform.scale(
              scale: _scale.value,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                              color: kOrange.withOpacity(0.45),
                              blurRadius: 56,
                              spreadRadius: 6)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset('assets/logo.png',
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'CaptureX',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PRO CAMERA & VIDEO',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kOrange,
                          letterSpacing: 3.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN  (IndexedStack + bottom nav)
// ─────────────────────────────────────────────────────────────────────────────

enum _Tab { camera, gallery, about }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  _Tab _tab = _Tab.camera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      extendBody: true,
      body: IndexedStack(
        index: _tab.index,
        children: const [CameraPage(), GalleryPage(), AboutPage()],
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (t) => setState(() => _tab = t),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final _Tab current;
  final ValueChanged<_Tab> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_Tab.camera, Icons.camera_alt_rounded, 'Camera'),
      (_Tab.gallery, Icons.photo_library_outlined, 'Gallery'),
      (_Tab.about, Icons.info_outline_rounded, 'About'),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 60 + bottomPad,
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: const BoxDecoration(
            color: Color(0xCC07090E),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
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
                          color: sel ? kOrange : Colors.white30, size: 22),
                      const SizedBox(height: 2),
                      Text(label,
                          style: TextStyle(
                              color: sel ? kOrange : Colors.white30,
                              fontSize: 10,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: sel ? 18 : 0,
                        height: 2,
                        decoration: BoxDecoration(
                            color: kOrange,
                            borderRadius: BorderRadius.circular(1)),
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

// ─────────────────────────────────────────────────────────────────────────────
// CAPTURE MODE
// ─────────────────────────────────────────────────────────────────────────────

enum CaptureMode { photo, video, portrait, slowmo }

extension _CmExt on CaptureMode {
  String get label {
    switch (this) {
      case CaptureMode.photo: return 'PHOTO';
      case CaptureMode.video: return 'VIDEO';
      case CaptureMode.portrait: return 'PORTRAIT';
      case CaptureMode.slowmo: return 'SLOW-MO';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA PAGE
// ─────────────────────────────────────────────────────────────────────────────

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  // Camera
  CameraController? _ctrl;
  bool _permDenied = false, _initializing = true;
  int _camIdx = 0;

  // Capture
  CaptureMode _mode = CaptureMode.photo;
  bool _recording = false, _capturing = false, _flashing = false;
  FlashMode _flash = FlashMode.off;
  Timer? _recTimer;
  int _recSec = 0;

  // Zoom
  double _zoom = 1.0, _minZoom = 1.0, _maxZoom = 5.0;

  // Focus
  Offset? _focusPt;
  bool _showFocus = false;

  // Filter / controls
  int _filterIdx = 0;
  bool _showControls = false;

  // User adjustments (multiplicative on top of preset)
  double _uBrightness = 0;    // -100..100
  double _uContrast = 1.0;    // 0.5..2.0
  double _uSaturation = 1.0;  // 0..2.5
  double _uWarmth = 0;        // -60..60
  double _uTint = 0;          // -40..40
  double _uVignette = 0;      // 0..1
  double _uGrain = 0;         // 0..1
  double _uExposure = 0;      // hardware -2..2

  List<double> get _matrix => kFilters[_filterIdx].matrix(
        dBrightness: _uBrightness,
        dContrast: _uContrast,
        dSaturation: _uSaturation,
        dWarmth: _uWarmth,
        dTint: _uTint,
      );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _ctrl!.dispose();
      _ctrl = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) _initCamera(_cameras[_camIdx]);
    }
  }

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final cam = await Permission.camera.request();
    await Permission.microphone.request();
    if (cam.isDenied || cam.isPermanentlyDenied) {
      if (mounted) setState(() { _permDenied = true; _initializing = false; });
      return;
    }
    if (_cameras.isEmpty) {
      if (mounted) setState(() => _initializing = false);
      return;
    }
    await _initCamera(_cameras[_camIdx]);
  }

  Future<void> _initCamera(CameraDescription desc) async {
    if (mounted) setState(() => _initializing = true);
    final prev = _ctrl;
    _ctrl = null;
    try { await prev?.dispose(); } catch (_) {}

    final c = CameraController(desc, ResolutionPreset.high,
        enableAudio: true, imageFormatGroup: ImageFormatGroup.jpeg);
    try {
      await c.initialize();
      if (!mounted) { c.dispose(); return; }
      _minZoom = await c.getMinZoomLevel();
      _maxZoom = await c.getMaxZoomLevel();
      await c.setFlashMode(_flash);
      setState(() { _ctrl = c; _initializing = false; _zoom = 1.0; });
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  Future<void> _flip() async {
    if (_cameras.length < 2) return;
    HapticFeedback.lightImpact();
    _camIdx = (_camIdx + 1) % _cameras.length;
    await _initCamera(_cameras[_camIdx]);
  }

  Future<void> _cycleFlash() async {
    HapticFeedback.selectionClick();
    const order = [
      FlashMode.off,
      FlashMode.auto,
      FlashMode.always,
      FlashMode.torch
    ];
    _flash = order[(order.indexOf(_flash) + 1) % order.length];
    await _ctrl?.setFlashMode(_flash);
    if (mounted) setState(() {});
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.off => Icons.flash_off_rounded,
        FlashMode.auto => Icons.flash_auto_rounded,
        FlashMode.always => Icons.flash_on_rounded,
        FlashMode.torch => Icons.highlight_rounded,
        _ => Icons.flash_off_rounded,
      };
  Color get _flashColor =>
      _flash == FlashMode.off ? Colors.white54 : kOrange;

  Future<void> _onTapFocus(TapDownDetails d, Size sz) async {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    final x = (d.localPosition.dx / sz.width).clamp(0.0, 1.0);
    final y = (d.localPosition.dy / sz.height).clamp(0.0, 1.0);
    setState(() { _focusPt = d.localPosition; _showFocus = true; });
    try {
      await _ctrl!.setFocusPoint(Offset(x, y));
      await _ctrl!.setExposurePoint(Offset(x, y));
    } catch (_) {}
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showFocus = false);
    });
  }

  // ── Capture ────────────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized || _capturing) return;
    HapticFeedback.heavyImpact();
    setState(() { _capturing = true; _flashing = true; });
    Future.delayed(
        const Duration(milliseconds: 80),
        () { if (mounted) setState(() => _flashing = false); });
    try {
      final file = await _ctrl!.takePicture();
      final dir = await getTemporaryDirectory();
      final path =
          p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.saveTo(path);
      if (mounted) _showPreview(path);
    } catch (_) {}
    if (mounted) setState(() => _capturing = false);
  }

  Future<void> _toggleVideo() async {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (_recording) {
      HapticFeedback.heavyImpact();
      final file = await _ctrl!.stopVideoRecording();
      _recTimer?.cancel();
      setState(() { _recording = false; _recSec = 0; });
      if (mounted) _showPreview(file.path, isVideo: true);
    } else {
      HapticFeedback.heavyImpact();
      await _ctrl!.startVideoRecording();
      setState(() { _recording = true; _recSec = 0; });
      _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recSec++);
      });
    }
  }

  String _fmtSec(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _showPreview(String path, {bool isVideo = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PreviewSheet(path: path, isVideo: isVideo),
    );
  }

  void _resetAdjustments() {
    HapticFeedback.selectionClick();
    setState(() {
      _uBrightness = 0; _uContrast = 1; _uSaturation = 1;
      _uWarmth = 0; _uTint = 0; _uVignette = 0;
      _uGrain = 0; _uExposure = 0;
    });
    _ctrl?.setExposureOffset(0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_permDenied) return _permissionScreen();
    if (_initializing) return _loadingScreen();
    if (_cameras.isEmpty) return _noCameraScreen();
    return _cameraBody(context);
  }

  Widget _cameraBody(BuildContext context) {
    final ctrl = _ctrl!;
    return LayoutBuilder(builder: (ctx, bc) {
      final navH = 60.0 + MediaQuery.of(ctx).padding.bottom;
      return Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen camera preview (with real-time filter) ──
          GestureDetector(
            onTapDown: (d) => _onTapFocus(d, bc.biggest),
            onScaleUpdate: (d) async {
              final z = (_zoom * d.scale).clamp(_minZoom, _maxZoom);
              setState(() => _zoom = z);
              await _ctrl?.setZoomLevel(z);
            },
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_matrix),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: ctrl.value.previewSize?.height ?? bc.maxWidth,
                    height: ctrl.value.previewSize?.width ?? bc.maxHeight,
                    child: CameraPreview(ctrl),
                  ),
                ),
              ),
            ),
          ),

          // ── Vignette overlay ──
          if (_uVignette > 0.01)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(_uVignette * 0.88),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

          // ── Grain overlay ──
          if (_uGrain > 0.01) IgnorePointer(child: _GrainOverlay(_uGrain)),

          // ── Flash burst ──
          if (_flashing)
            IgnorePointer(
                child: Container(color: Colors.white.withOpacity(0.6))),

          // ── Tap-to-focus ring ──
          if (_showFocus && _focusPt != null)
            Positioned(
              left: _focusPt!.dx - 30,
              top: _focusPt!.dy - 30,
              child: const _FocusRing(),
            ),

          // ── Glass top bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: _topBar(ctx),
          ),

          // ── Zoom badge ──
          if (_zoom > 1.05)
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 70,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_zoom.toStringAsFixed(1)}×',
                      style: const TextStyle(
                          color: kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),

          // ── Bottom panel (filter strip + shutter) ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _bottomPanel(ctx, navH),
          ),
        ],
      );
    });
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _topBar(BuildContext ctx) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: GlassBox(
          radius: BorderRadius.circular(22),
          blur: 26,
          opacity: 0.13,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              // Flash
              _TbBtn(
                  icon: _flashIcon,
                  color: _flashColor,
                  onTap: _cycleFlash),
              const Spacer(),
              // Title / REC timer
              if (_recording)
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                        color: kRed, shape: BoxShape.circle),
                  ),
                  Text(_fmtSec(_recSec),
                      style: const TextStyle(
                          color: kRed,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace')),
                ])
              else
                const Text('CaptureX',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
              const Spacer(),
              // Controls toggle
              _TbBtn(
                icon: Icons.tune_rounded,
                color: _showControls ? kOrange : Colors.white54,
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

  // ── Bottom panel ───────────────────────────────────────────────────────────

  Widget _bottomPanel(BuildContext ctx, double navH) {
    return Padding(
      padding: EdgeInsets.only(bottom: navH),
      child: GlassBox(
        radius: const BorderRadius.vertical(top: Radius.circular(32)),
        blur: 30,
        opacity: 0.15,
        border: Colors.white.withOpacity(0.10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),

            // ── Adjustments panel (collapsible) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child:
                  _showControls ? _adjustmentsPanel() : const SizedBox.shrink(),
            ),

            // ── Filter strip ──
            _filterStrip(),

            const SizedBox(height: 10),

            // ── Mode selector ──
            _modeSelector(),

            const SizedBox(height: 18),

            // ── Shutter row ──
            _shutterRow(),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  // ── Adjustments panel ──────────────────────────────────────────────────────

  Widget _adjustmentsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        children: [
          _Slider('BRIGHTNESS', _uBrightness, -100, 100,
              (v) => setState(() => _uBrightness = v)),
          _Slider('CONTRAST', _uContrast, 0.5, 2.0,
              (v) => setState(() => _uContrast = v)),
          _Slider('SATURATION', _uSaturation, 0, 2.5,
              (v) => setState(() => _uSaturation = v)),
          _Slider('TEMPERATURE', _uWarmth, -60, 60,
              (v) => setState(() => _uWarmth = v)),
          _Slider('TINT', _uTint, -40, 40,
              (v) => setState(() => _uTint = v)),
          _Slider('VIGNETTE', _uVignette, 0, 1,
              (v) => setState(() => _uVignette = v)),
          _Slider('GRAIN', _uGrain, 0, 1,
              (v) => setState(() => _uGrain = v)),
          _Slider('EXPOSURE', _uExposure, -2, 2, (v) async {
            setState(() => _uExposure = v);
            try { await _ctrl?.setExposureOffset(v); } catch (_) {}
          }),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _resetAdjustments,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text('Reset all',
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          Divider(
              color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Filter strip ───────────────────────────────────────────────────────────

  Widget _filterStrip() {
    return SizedBox(
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: kFilters.length,
        itemBuilder: (_, i) {
          final f = kFilters[i];
          final sel = _filterIdx == i;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filterIdx = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: f.thumbColors,
                ),
                border: Border.all(
                  color: sel
                      ? kOrange
                      : Colors.white.withOpacity(0.12),
                  width: sel ? 2.0 : 1.0,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                            color: kOrange.withOpacity(0.35),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                f.name,
                style: TextStyle(
                    color: sel
                        ? kOrange
                        : (f.labelColor ?? Colors.white70),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Mode selector ──────────────────────────────────────────────────────────

  Widget _modeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: CaptureMode.values.map((m) {
        final sel = _mode == m;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _mode = m);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Column(
              children: [
                Text(m.label,
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white38,
                        fontSize: 11,
                        fontWeight:
                            sel ? FontWeight.w800 : FontWeight.w500,
                        letterSpacing: 0.6)),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: sel ? 16 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                      color: kOrange,
                      borderRadius: BorderRadius.circular(1)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Shutter row ────────────────────────────────────────────────────────────

  Widget _shutterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CircleBtn(
              icon: Icons.flip_camera_ios_rounded,
              size: 52,
              onTap: _flip),

          // ── CENTERED SHUTTER ──
          _ShutterButton(
            isVideo: _mode == CaptureMode.video,
            isRecording: _recording,
            onTap: _mode == CaptureMode.video
                ? _toggleVideo
                : _capturePhoto,
          ),

          _CircleBtn(
              icon: Icons.photo_library_outlined,
              size: 52,
              onTap: () {}),
        ],
      ),
    );
  }

  // ── State screens ──────────────────────────────────────────────────────────

  Widget _loadingScreen() => const Scaffold(
        backgroundColor: kBg,
        body: Center(
            child: CircularProgressIndicator(color: kOrange, strokeWidth: 2)),
      );

  Widget _noCameraScreen() => const Scaffold(
        backgroundColor: kBg,
        body: Center(
            child: Text('No camera detected',
                style: TextStyle(color: Colors.white54))),
      );

  Widget _permissionScreen() => Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: Colors.white24, size: 64),
                const SizedBox(height: 20),
                const Text('Camera Access Required',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                    'CaptureX needs camera and microphone permission to shoot photos and record video.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white54, fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: openAppSettings,
                  child: const Text('Open Settings',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER ROW
// ─────────────────────────────────────────────────────────────────────────────

class _Slider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged;

  const _Slider(this.label, this.value, this.min, this.max, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final String disp = min < 0
        ? (value >= 0
            ? '+${value.toStringAsFixed(1)}'
            : value.toStringAsFixed(1))
        : value.toStringAsFixed(2);

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
        ),
        Expanded(
          child: SizedBox(
            height: 28,
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(disp,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: kOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRAIN OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

class _GrainOverlay extends StatelessWidget {
  final double amount;
  const _GrainOverlay(this.amount);

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GrainPainter(amount));
}

class _GrainPainter extends CustomPainter {
  final double amount;
  final math.Random _rng = math.Random(17);
  _GrainPainter(this.amount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(amount * 0.20);
    final n =
        (size.width * size.height * amount * 0.0018).toInt().clamp(0, 10000);
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(
          Offset(_rng.nextDouble() * size.width,
              _rng.nextDouble() * size.height),
          _rng.nextDouble() * 1.4,
          paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.amount != amount;
}

// ─────────────────────────────────────────────────────────────────────────────
// FOCUS RING
// ─────────────────────────────────────────────────────────────────────────────

class _FocusRing extends StatefulWidget {
  const _FocusRing();
  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scale = Tween(begin: 1.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: const SizedBox(
          width: 60, height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                  BorderSide(color: kOrange, width: 1.5)),
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHUTTER BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ShutterButton extends StatefulWidget {
  final bool isVideo, isRecording;
  final VoidCallback onTap;
  const _ShutterButton(
      {required this.isVideo,
      required this.isRecording,
      required this.onTap});

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween(begin: 1.0, end: 0.87).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.isVideo ? kRed : Colors.white;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: ringColor.withOpacity(0.85), width: 3.5),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isRecording ? 26 : 65,
              height: widget.isRecording ? 26 : 65,
              decoration: BoxDecoration(
                color: widget.isVideo ? kRed : Colors.white,
                borderRadius: BorderRadius.circular(
                    widget.isRecording ? 6 : 100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCLE BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.10),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.43),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _TbBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TbBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08)),
          child: Icon(icon, color: color, size: 19),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PREVIEW SHEET  (after capture — with WORKING save to gallery)
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewSheet extends StatefulWidget {
  final String path;
  final bool isVideo;
  const _PreviewSheet({required this.path, this.isVideo = false});

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  bool _saving = false, _saved = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Request gallery access if not already granted
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) await Gal.requestAccess(toAlbum: true);

      if (widget.isVideo) {
        await Gal.putVideo(widget.path, album: 'CaptureX');
      } else {
        await Gal.putImage(widget.path, album: 'CaptureX');
      }

      if (mounted) setState(() { _saving = false; _saved = true; });
    } on GalException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Save failed: ${e.type.toString()}'),
            backgroundColor: Colors.red[800]));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save. Check storage permission.'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF00D1018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 14),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preview',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                if (_saved)
                  Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    const Text('Saved!',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ]),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Image preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 320,
                child: widget.isVideo
                    ? Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                              Icons.play_circle_outline_rounded,
                              color: Colors.white38,
                              size: 64),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(widget.path),
                              fit: BoxFit.cover),
                          // Liquid glass watermark
                          Positioned(
                            bottom: 14, right: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                    sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withOpacity(0.35),
                                    borderRadius:
                                        BorderRadius.circular(11),
                                    border: Border.all(
                                        color: Colors.white24),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Shot with CaptureX',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w700)),
                                      Text('capturex.app',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _saved ? Colors.green[700] : kOrange,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black))
                        : Icon(
                            _saved
                                ? Icons.check_rounded
                                : Icons.download_rounded,
                            size: 18),
                    label: Text(
                      _saving
                          ? 'Saving…'
                          : _saved
                              ? 'Saved!'
                              : 'Save to Gallery',
                      style:
                          const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: _saving || _saved ? null : _save,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY PAGE  (placeholder)
// ─────────────────────────────────────────────────────────────────────────────

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined,
                color: Colors.white12, size: 64),
            SizedBox(height: 16),
            Text('Gallery',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Your saved photos appear here',
                style:
                    TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT PAGE
// ─────────────────────────────────────────────────────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Logo
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: kOrange.withOpacity(0.38),
                        blurRadius: 44,
                        spreadRadius: 4)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/logo.png',
                      fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 16),
              const Text('CaptureX',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6)),
              const SizedBox(height: 3),
              const Text('PRO CAMERA & VIDEO',
                  style: TextStyle(
                      color: kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3)),
              const SizedBox(height: 4),
              const Text('Version 1.2.0',
                  style:
                      TextStyle(color: Colors.white38, fontSize: 12)),

              const SizedBox(height: 26),

              // Feature cards
              for (final item in const [
                (Icons.camera_alt_rounded, 'Real Camera',
                    'Live preview with tap-to-focus, pinch-to-zoom, front/back flip and flash control.'),
                (Icons.videocam_rounded, 'Video Recording',
                    'HD video with real-time timer, red indicator and full audio capture.'),
                (Icons.auto_fix_high_rounded, 'Filter Studio',
                    '10 creative presets — Moody, Dreamy, Nightcore, Vivid, Portra, Cinematic, Velvia and more — live on the camera dock.'),
                (Icons.tune_rounded, 'Advanced Controls',
                    'Brightness, Contrast, Saturation, Temperature, Tint, Vignette and Grain — 8 real-time sliders.'),
                (Icons.water_drop_rounded, 'Liquid Glass UI',
                    'Frosted BackdropFilter panels, glass dialogs and glass watermark throughout the entire app.'),
                (Icons.branding_watermark_rounded, 'Auto Watermark',
                    '"Shot with CaptureX" glass-frosted badge stamped on every photo automatically.'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassBox(
                    radius: BorderRadius.circular(18),
                    blur: 16,
                    opacity: 0.09,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: kOrange.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.$1, color: kOrange, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$2,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 3),
                              Text(item.$3,
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Credits card
              GlassBox(
                radius: BorderRadius.circular(20),
                blur: 18,
                opacity: 0.09,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Text('CREDITS',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2)),
                    const SizedBox(height: 14),
                    _CreditRow('Lead Developers', 'OctaDevs'),
                    const SizedBox(height: 8),
                    _CreditRow('Built with', 'Flutter & Dart'),
                    const SizedBox(height: 8),
                    _CreditRow('Platform', 'Android • iOS'),
                    const SizedBox(height: 8),
                    _CreditRow('Camera SDK', 'flutter/camera'),
                    const Divider(color: Colors.white10, height: 22),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        'camera',
                        'permission_handler',
                        'path_provider',
                        'gal',
                        'path'
                      ]
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white10),
                                ),
                                child: Text(t,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w600)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              const Text('© 2026 CaptureX by OctaDevs',
                  style:
                      TextStyle(color: Colors.white30, fontSize: 11),
                  textAlign: TextAlign.center),
              const Text('All rights reserved.',
                  style:
                      TextStyle(color: Colors.white24, fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  final String label, value;
  const _CreditRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );
}
