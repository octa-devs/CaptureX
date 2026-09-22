import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF090C13),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CaptureXApp());
}

class CaptureXApp extends StatelessWidget {
  const CaptureXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CaptureX — Classic Camera Lenses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07090E),
        primaryColor: const Color(0xFFFF9F0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9F0A),
          surface: Color(0xFF10141E),
        ),
      ),
      home: const ClassicCameraScreen(),
    );
  }
}

class ClassicLens {
  final String id;
  final String name;
  final String focal;
  final double defaultAperture;
  final String opticalFormula;
  final Color tintColor;
  final double vignette;

  const ClassicLens({
    required this.id,
    required this.name,
    required this.focal,
    required this.defaultAperture,
    required this.opticalFormula,
    required this.tintColor,
    required this.vignette,
  });
}

const List<ClassicLens> kClassicLenses = [
  ClassicLens(
    id: 'noctilux_50',
    name: 'Noctilux 50mm',
    focal: '50mm',
    defaultAperture: 0.95,
    opticalFormula: 'Spherical Ultra-Speed',
    tintColor: Color(0xFFFFAA33),
    vignette: 0.35,
  ),
  ClassicLens(
    id: 'helios_44_2',
    name: 'Helios 44-2',
    focal: '58mm',
    defaultAperture: 2.0,
    opticalFormula: 'Biotar 6-Elements',
    tintColor: Color(0xFF33FFAA),
    vignette: 0.45,
  ),
  ClassicLens(
    id: 'summicron_35',
    name: 'Summicron 35mm',
    focal: '35mm',
    defaultAperture: 2.0,
    opticalFormula: 'Double-Gauss',
    tintColor: Color(0xFFFFFFFF),
    vignette: 0.20,
  ),
  ClassicLens(
    id: 'biotar_75',
    name: 'Biotar 75mm',
    focal: '75mm',
    defaultAperture: 1.5,
    opticalFormula: 'Carl Zeiss Jena',
    tintColor: Color(0xFFFFCC66),
    vignette: 0.38,
  ),
  ClassicLens(
    id: 'anamorphic_50',
    name: 'Anamorphic 1.33x',
    focal: '50mm',
    defaultAperture: 1.8,
    opticalFormula: 'Cylindrical Squeeze',
    tintColor: Color(0xFF38BDF8),
    vignette: 0.28,
  ),
  ClassicLens(
    id: 'macro_100',
    name: 'Macro 100mm',
    focal: '100mm',
    defaultAperture: 2.8,
    opticalFormula: 'Apochromatic 1:1',
    tintColor: Color(0xFFFFFFFF),
    vignette: 0.15,
  ),
];

class ClassicCameraScreen extends StatefulWidget {
  const ClassicCameraScreen({super.key});

  @override
  State<ClassicCameraScreen> createState() => _ClassicCameraScreenState();
}

class _ClassicCameraScreenState extends State<ClassicCameraScreen> {
  int _activeTabIndex = 1; // 0: Aperture, 1: Lens, 2: Depth, 3: Color Lab, 4: Frame, 5: Crop
  ClassicLens _selectedLens = kClassicLenses[0];
  double _currentAperture = 0.95;
  double _depthBlur = 85.0;
  String _activeColorPreset = 'Moody Noir';
  String _activeFrame = 'watermark';
  double _aspectRatio = 3 / 4;
  Offset _focusPoint = const Offset(0.5, 0.65);
  bool _isFlashing = false;

  final List<double> _apertureStops = [0.95, 1.2, 1.4, 1.8, 2.8, 4.0, 5.6, 8.0];

  void _triggerCapture() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isFlashing = true;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
        _showExportDialog();
      }
    });
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF111520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shot with CaptureX',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                  border: Border.all(color: Colors.white12),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 260),
                      painter: OpticalBokehPainter(
                        lens: _selectedLens,
                        aperture: _currentAperture,
                        depthBlur: _depthBlur,
                        focusPoint: _focusPoint,
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xDD090C13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Shot with CaptureX',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_selectedLens.name} • ƒ/$_currentAperture • ISO 64',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9F0A),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, color: Colors.black),
                label: const Text(
                  'Saved to Gallery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),

            // Center Framed Viewport
            Expanded(
              child: _buildPhotoViewport(),
            ),

            // Dynamic Drawer based on active bottom tab
            _buildDrawerSection(),

            // Bottom Navigation Bar
            _buildBottomTabBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () {},
          ),
          const Text(
            'Classic Camera Lenses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFFF9F0A), size: 22),
            onPressed: _triggerCapture,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoViewport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: GestureDetector(
            onTapDown: (details) {
              HapticFeedback.selectionClick();
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localOffset = details.localPosition;
              setState(() {
                _focusPoint = Offset(
                  (localOffset.dx / box.size.width).clamp(0.1, 0.9),
                  (localOffset.dy / box.size.height).clamp(0.1, 0.9),
                );
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white12, width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Optical Bokeh Painter
                  CustomPaint(
                    painter: OpticalBokehPainter(
                      lens: _selectedLens,
                      aperture: _currentAperture,
                      depthBlur: _depthBlur,
                      focusPoint: _focusPoint,
                    ),
                  ),

                  // Lens Overlay Badge
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xBB0D111A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedLens.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ƒ/$_currentAperture',
                            style: const TextStyle(
                              color: Color(0xFFFF9F0A),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Flash Burst
                  if (_isFlashing)
                    Container(color: Colors.white.withOpacity(0.9)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection() {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: _getDrawerView(),
    );
  }

  Widget _getDrawerView() {
    switch (_activeTabIndex) {
      case 0: // Aperture
        return Row(
          children: [
            const Text('ƒ/ STOP: ', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _apertureStops.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final stop = _apertureStops[i];
                  final isSelected = _currentAperture == stop;
                  return ActionChip(
                    backgroundColor: isSelected ? const Color(0xFFFF9F0A) : const Color(0xFF161C2A),
                    side: BorderSide(color: isSelected ? const Color(0xFFFF9F0A) : Colors.white12),
                    label: Text(
                      'ƒ/$stop',
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentAperture = stop;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );

      case 1: // Lens Carousel (Default)
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: kClassicLenses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) {
            final lens = kClassicLenses[i];
            final isSelected = _selectedLens.id == lens.id;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedLens = lens;
                  _currentAperture = lens.defaultAperture;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E2536) : const Color(0xFF141926),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF9F0A) : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFFFF9F0A).withOpacity(0.25), blurRadius: 10)]
                          : null,
                    ),
                    child: Icon(
                      Icons.camera_rounded,
                      color: isSelected ? const Color(0xFFFF9F0A) : Colors.white70,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lens.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );

      case 2: // Depth
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('BOKEH ISOLATION', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('${_depthBlur.round()}%', style: const TextStyle(color: Color(0xFFFF9F0A), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _depthBlur,
              min: 0,
              max: 100,
              activeColor: const Color(0xFFFF9F0A),
              inactiveColor: Colors.white12,
              onChanged: (val) {
                setState(() {
                  _depthBlur = val;
                });
              },
            ),
          ],
        );

      case 3: // Color Lab
        final presets = ['Moody Noir', 'Dreamy Glow', 'Nightcore', 'Vivid Pop', 'Portra 400', 'Tri-X B&W'];
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: presets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final p = presets[i];
            final isSelected = _activeColorPreset == p;
            return ChoiceChip(
              label: Text(p, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: const Color(0xFFFF9F0A),
              backgroundColor: const Color(0xFF161C2A),
              onSelected: (val) {
                setState(() {
                  _activeColorPreset = p;
                });
              },
            );
          },
        );

      default:
        return const Center(
          child: Text('Classic Optical Controls Active', style: TextStyle(color: Colors.white54, fontSize: 11)),
        );
    }
  }

  Widget _buildBottomTabBar() {
    final tabs = [
      {'label': 'Aperture', 'icon': Icons.camera_outlined},
      {'label': 'Lens', 'icon': Icons.center_focus_strong_rounded},
      {'label': 'Depth', 'icon': Icons.layers_outlined},
      {'label': 'Color Lab', 'icon': Icons.palette_outlined},
      {'label': 'Frame', 'icon': Icons.crop_portrait_rounded},
      {'label': 'Crop', 'icon': Icons.crop_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF090C13),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _activeTabIndex = index;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tabs[index]['icon'] as IconData,
                  color: isSelected ? Colors.white : Colors.white38,
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  tabs[index]['label'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF9F0A) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class OpticalBokehPainter extends CustomPainter {
  final ClassicLens lens;
  final double aperture;
  final double depthBlur;
  final Offset focusPoint;

  OpticalBokehPainter({
    required this.lens,
    required this.aperture,
    required this.depthBlur,
    required this.focusPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Forest Green / Amber Deep Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF2C3928),
          Color(0xFF4A5C3F),
          Color(0xFF2E271F),
          Color(0xFF1A1410),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Optical Bokeh Discs
    final bokehRadius = (1.0 / aperture) * (depthBlur / 100.0) * (size.width * 0.08);

    for (int i = 0; i < 16; i++) {
      final bx = (math.sin(i * 1.6) * 0.4 + 0.5) * size.width;
      final by = (math.cos(i * 1.2) * 0.25 + 0.3) * size.height;
      final r = ((i % 4) + 2) * (bokehRadius * 0.35);

      final bokehPaint = Paint()
        ..color = const Color(0x55FFE8A0)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4);

      canvas.drawCircle(Offset(bx, by), r, bokehPaint);
    }

    // 3. Ground Earth Layer
    final groundPaint = Paint()..color = const Color(0xFF1A1410);
    final path = Path();
    path.moveTo(0, size.height * 0.72);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.68, size.width, size.height * 0.72);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, groundPaint);

    // 4. In-Focus Subject: Forest Mushroom
    final mx = size.width * focusPoint.dx;
    final my = size.height * focusPoint.dy;
    final mSize = size.width * 0.28;

    // Stem
    final stemPaint = Paint()..color = const Color(0xFFF5EEDB);
    final stemPath = Path();
    stemPath.moveTo(mx - mSize * 0.08, my + mSize * 0.4);
    stemPath.quadraticBezierTo(mx - mSize * 0.04, my, mx - mSize * 0.06, my - mSize * 0.2);
    stemPath.lineTo(mx + mSize * 0.06, my - mSize * 0.2);
    stemPath.quadraticBezierTo(mx + mSize * 0.04, my, mx + mSize * 0.08, my + mSize * 0.4);
    stemPath.close();
    canvas.drawPath(stemPath, stemPaint);

    // Cap
    final capPaint = Paint()..color = const Color(0xFFAD7F50);
    final capPath = Path();
    capPath.moveTo(mx - mSize * 0.45, my - mSize * 0.2);
    capPath.quadraticBezierTo(mx, my - mSize * 0.7, mx + mSize * 0.45, my - mSize * 0.2);
    capPath.quadraticBezierTo(mx, my - mSize * 0.15, mx - mSize * 0.45, my - mSize * 0.2);
    capPath.close();
    canvas.drawPath(capPath, capPaint);

    // Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withOpacity(lens.vignette)],
        radius: 0.85,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant OpticalBokehPainter oldDelegate) {
    return oldDelegate.lens != lens ||
        oldDelegate.aperture != aperture ||
        oldDelegate.depthBlur != depthBlur ||
        oldDelegate.focusPoint != focusPoint;
  }
}
