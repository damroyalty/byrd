import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'bird_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _showSearchResults(BuildContext context, String query) {
    final birdsProvider = Provider.of<BirdsProvider>(context, listen: false);
    final allBirds = birdsProvider.birds;
    final lowerQuery = query.toLowerCase();

    final results = allBirds
        .where(
          (bird) =>
              bird.breed.toLowerCase().contains(lowerQuery) ||
              bird.location.toLowerCase().contains(lowerQuery),
        )
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        if (results.isEmpty) {
          return AlertDialog(
            title: const Text('No Results'),
            content: const Text('No birds found matching your search.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }
        return AlertDialog(
          title: const Text('Search Results'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, idx) {
                final bird = results[idx];
                return ListTile(
                  leading: bird.imagePath != null
                      ? CircleAvatar(
                          backgroundImage: FileImage(File(bird.imagePath!)),
                        )
                      : const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text(bird.breed),
                  subtitle: Text('${bird.typeName} • ${bird.location}'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BirdListScreen(birdType: bird.type),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  late final AnimationController _marqueeController;
  double _marqueeTextWidth = 0.0;
  String _lastMarqueeText = '';
  static const double _marqueeSpeed = 30;
  late AnimationController _glitterController;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    );
    _marqueeController.addListener(_marqueeTick);
    _marqueeController.repeat();

    _glitterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.removeListener(_marqueeTick);
    _marqueeController.dispose();
    _glitterController.dispose();
    super.dispose();
  }

  void _marqueeTick() {
    setState(() {});
  }

  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);

  void _showColorPickerDialogForBrown() async {
    Color tempColor = customBrown;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Brown Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              enableAlpha: false,
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  customBrown = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showColorPickerDialogForTileGreen() async {
    Color tempColor = customTileGreen;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Tile Green Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              enableAlpha: false,
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  customTileGreen = tempColor;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      AspectRatio(
        aspectRatio: 1,
        child: _buildBirdTypeTile(context, BirdType.chicken),
      ),
      AspectRatio(
        aspectRatio: 1,
        child: _buildBirdTypeTile(context, BirdType.duck),
      ),
      AspectRatio(
        aspectRatio: 1,
        child: _buildBirdTypeTile(context, BirdType.turkey),
      ),
      AspectRatio(
        aspectRatio: 1,
        child: _buildBirdTypeTile(context, BirdType.goose),
      ),
    ];

    // local device time
    final now = DateTime.now();

    final birdsWithReplacement = Provider.of<BirdsProvider>(context)
        .birds
        .where((bird) {
          final match = RegExp(r'Replacement Date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})').firstMatch(bird.notes);
          return match != null;
        })
        .map((bird) {
          final match = RegExp(r'Replacement Date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})').firstMatch(bird.notes);
          final replacementDate = match != null ? match.group(1) : '';
          final bandColor = (bird.customBandColor != null && bird.customBandColor!.isNotEmpty)
              ? bird.customBandColor!
              : bird.bandColor.toString().split('.').last;
          return {
            'text': '${bird.typeName} | ${bird.breed} | ${bird.location} | $bandColor | Replacement: $replacementDate',
            'replacementDate': replacementDate
          };
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: customBrown,
        title: Row(
          children: [
            GestureDetector(
              onTap: _showColorPickerDialogForBrown,
              child: Icon(Icons.egg, color: Colors.yellow[800], size: 32),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _glitterController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.yellowAccent.withOpacity(0.8),
                        Colors.amberAccent.withOpacity(0.7),
                        Colors.white,
                        Colors.lightBlueAccent.withOpacity(0.5),
                        Colors.white,
                      ],
                      stops: [
                        0.0,
                        (_glitterController.value * 0.5).clamp(0.0, 1.0),
                        (_glitterController.value * 0.7).clamp(0.0, 1.0),
                        (_glitterController.value * 1.0).clamp(0.0, 1.0),
                        (_glitterController.value * 1.2).clamp(0.0, 1.0),
                        1.0,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      tileMode: TileMode.mirror,
                    ).createShader(bounds);
                  },
                  child: Text(
                    'cluckers',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: customBrown.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        Shadow(
                          color: Colors.yellowAccent.withOpacity(0.7),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showColorPickerDialogForTileGreen,
              child: Icon(Icons.grass, color: Colors.green[400], size: 28),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: SizedBox(
              width: 200,
              height: 40,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search breed/location',
                  hintStyle: const TextStyle(fontSize: 13),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    _showSearchResults(context, query.trim());
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 16),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: tiles[2]),
                      const SizedBox(width: 16),
                      Expanded(child: tiles[3]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Spacer(),
                      Expanded(
                        flex: 2,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildBirdTypeTile(context, BirdType.other),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
            if (birdsWithReplacement.isNotEmpty)
              SizedBox(
                height: 48,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final style = const TextStyle(
                      fontSize: 13,
                      color: Colors.brown,
                      fontWeight: FontWeight.w600,
                    );

                    List<InlineSpan> spans = [];
                    for (var i = 0; i < birdsWithReplacement.length; i++) {
                      final entry = birdsWithReplacement[i];
                      final text = entry['text'] as String;
                      final replacementDate = entry['replacementDate'] as String;
                      final replacementReg = RegExp(r'(Replacement:\s*[0-9]{4}-[0-9]{2}-[0-9]{2})');
                      final match = replacementReg.firstMatch(text);

                      if (match != null) {
                        final before = text.substring(0, match.start);
                        final replacementStr = match.group(1)!;
                        final after = text.substring(match.end);

                        Color glowColor = Colors.greenAccent;
                        Color textColor = Colors.green[900]!;
                        List<Shadow> glow = [
                          Shadow(
                            color: glowColor.withOpacity(0.7),
                            blurRadius: 8,
                          ),
                        ];

                        DateTime? repDate;
                        try {
                          repDate = DateTime.parse(replacementDate);
                        } catch (_) {}
                        if (repDate != null) {
                          final diff = repDate.difference(now).inDays;
                          if (diff >= 0 && diff <= 14) {
                            textColor = Colors.red;
                            glowColor = Colors.redAccent;
                            glow = [
                              Shadow(
                                color: glowColor.withOpacity(0.8),
                                blurRadius: 12,
                              ),
                            ];
                          }
                        }

                        spans.add(TextSpan(text: before, style: style));
                        spans.add(TextSpan(
                          text: replacementStr,
                          style: style.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            shadows: glow,
                          ),
                        ));
                        spans.add(TextSpan(text: after, style: style));
                      } else {
                        spans.add(TextSpan(text: text, style: style));
                      }
                      if (i != birdsWithReplacement.length - 1) {
                        spans.add(const TextSpan(
                          text: '     •     ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                        ));
                      }
                    }

                    final textWidget = RichText(
                      text: TextSpan(children: spans),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    );

                    final plainText = birdsWithReplacement.map((e) => e['text'] as String).join('     •     ');
                    if (_lastMarqueeText != plainText) {
                      _lastMarqueeText = plainText;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final width = _textSize(plainText, style).width;
                        setState(() {
                          _marqueeTextWidth = width;
                        });
                      });
                    }
                    final containerWidth = constraints.maxWidth;
                    final totalWidth = _marqueeTextWidth + containerWidth + 40;
                    final elapsed = _marqueeController.lastElapsedDuration?.inMilliseconds ?? 0;
                    final pixels = (elapsed / 1000.0) * _marqueeSpeed;
                    final offset = containerWidth - (pixels % totalWidth);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.brown.withOpacity(0.2)),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: offset,
                              top: 0,
                              child: SizedBox(
                                width: _marqueeTextWidth + 40,
                                height: 48,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: textWidget,
                                  ),
                                ),
                              ),
                            ),
                            if (_marqueeTextWidth > 0)
                              Positioned(
                                left: offset + _marqueeTextWidth + 40,
                                top: 0,
                                child: SizedBox(
                                  width: _marqueeTextWidth + 40,
                                  height: 48,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: textWidget,
                                    ),
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
          ],
        ),
      ),
    );
  }

  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size;
  }

  Widget _buildBirdTypeTile(BuildContext context, BirdType type) {
    final birdCount = Provider.of<BirdsProvider>(
      context,
    ).getBirdCountByType(type);
    final bird = Bird(
      type: type,
      breed: '',
      quantity: 0,
      source: SourceType.egg,
      date: DateTime.now(),
      gender: Gender.unknown,
      bandColor: BandColor.none,
      location: '',
    );

    String? svgAsset;
    switch (type) {
      case BirdType.chicken:
        svgAsset = null;
        break;
      case BirdType.duck:
        svgAsset = 'assets/icons/duck.svg';
        break;
      case BirdType.turkey:
        svgAsset = 'assets/icons/turkey.svg';
        break;
      case BirdType.goose:
        svgAsset = 'assets/icons/goose.svg';
        break;
      case BirdType.other:
        svgAsset = 'assets/icons/other.svg';
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BirdListScreen(birdType: type),
          ),
        );
      },
      child: Card(
        color: Colors.green[50],
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (svgAsset != null)
                    SvgPicture.asset(
                      svgAsset,
                      width: 48,
                      height: 48,
                      colorFilter: ColorFilter.mode(
                        customTileGreen,
                        BlendMode.srcIn,
                      ),
                    )
                  else
                    Icon(_getBirdIcon(type), size: 48, color: customTileGreen),
                  const SizedBox(height: 8),
                  Text(
                    bird.typeName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: customTileGreen,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: customTileGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  birdCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBirdIcon(BirdType type) {
    switch (type) {
      case BirdType.chicken:
        return Icons.egg;
      case BirdType.duck:
        return Icons.water_drop;
      case BirdType.turkey:
        return Icons.fastfood;
      case BirdType.goose:
        return Icons.air;
      case BirdType.other:
        return Icons.pets;
    }
  }
}

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final List<Color>? colors;

  const AnimatedGradientText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.colors,
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _defaultColors = [
    Colors.greenAccent,
    Colors.green,
    Colors.brown,
    Colors.orange,
    Colors.greenAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ?? _defaultColors;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: colors,
              stops: List.generate(
                colors.length,
                (i) => (i / (colors.length - 1) +
                        _controller.value) %
                    1.0,
              ),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              tileMode: TileMode.mirror,
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: widget.fontSize,
              fontWeight: widget.fontWeight,
              letterSpacing: 2,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.greenAccent.withOpacity(0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
