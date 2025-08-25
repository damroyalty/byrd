import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'bird_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tap_particle.dart';
import 'dart:ui';
import '../dark_mode.dart';
import '../utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/global_colors_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();
  final Duration _searchAnimDuration = const Duration(milliseconds: 250);

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
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.file(
                              File(bird.imagePath!),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.pets, color: Colors.grey[600]),
                            ),
                          ),
                        ),
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
  double _lastScrollWidth = 0.0;
  late AnimationController _glitterController;

  Color? _customTitleColor;
  bool _useAnimatedTitle = true;

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
      duration: const Duration(seconds: 7),
    );
    _glitterController.repeat();

    _loadColors();
    _loadDarkMode();
    _loadTitleColor();
    _initializeNavigationBarColor();

    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _showSearchBar) {
        setState(() {
          _showSearchBar = false;
          _searchController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _marqueeController.removeListener(_marqueeTick);
    _marqueeController.dispose();
    _glitterController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _marqueeTick() {
    setState(() {});
  }

  void _updateMarqueeDuration(double scrollWidth) {
    if (scrollWidth != _lastScrollWidth && scrollWidth > 0) {
      _lastScrollWidth = scrollWidth;
      final duration = Duration(
        milliseconds: (1000 * scrollWidth / _marqueeSpeed).round(),
      );
      _marqueeController.stop();
      _marqueeController.duration = duration;
      _marqueeController.repeat();
    }
  }

  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final brownValue = prefs.getInt('home_customBrown');
      final greenValue = prefs.getInt('home_customTileGreen');
      if (brownValue != null) customBrown = Color(brownValue);
      if (greenValue != null) customTileGreen = Color(greenValue);
    });
  }

  Future<void> _initializeNavigationBarColor() async {
    final globalColors = Provider.of<GlobalColorsProvider>(context, listen: false);
    await globalColors.loadColors();
  }

  Future<void> _saveBrownColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_customBrown', color.value);
  }

  Future<void> _saveTileGreenColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('home_customTileGreen', color.value);
    
    final globalColors = Provider.of<GlobalColorsProvider>(context, listen: false);
    await globalColors.updateNavigationBarColor(color);
  }

  void _showColorPickerDialogForBrown() async {
    Color tempColor = customBrown;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color for the Banner'),
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
                _saveBrownColor(tempColor);
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
          title: const Text('Pick a Secondary Color'),
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
                _saveTileGreenColor(tempColor);
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

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    darkModeNotifier.value = isDark;
  }

  Future<void> _saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
  }

  Future<void> _loadTitleColor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final colorValue = prefs.getInt('home_customTitleColor');
      final useAnim = prefs.getBool('home_useAnimatedTitle');
      if (colorValue != null) {
        _customTitleColor = Color(colorValue);
        _useAnimatedTitle = false;
      }
      if (useAnim != null) {
        _useAnimatedTitle = useAnim;
        if (_useAnimatedTitle) _customTitleColor = null;
      }
    });
  }

  Future<void> _saveTitleColor(Color? color, bool useAnim) async {
    final prefs = await SharedPreferences.getInstance();
    if (color != null && !useAnim) {
      await prefs.setInt('home_customTitleColor', color.value);
    } else {
      await prefs.remove('home_customTitleColor');
    }
    await prefs.setBool('home_useAnimatedTitle', useAnim);
  }

  void _showTitleColorPickerDialog() async {
    Color tempColor = _customTitleColor ?? Colors.white;
    bool tempUseAnim = _useAnimatedTitle;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color for the Title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: tempColor,
                  onColorChanged: (color) {
                    tempColor = color;
                    tempUseAnim = false;
                  },
                  enableAlpha: false,
                  pickerAreaHeightPercent: 0.7,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsv,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Restore Animation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _useAnimatedTitle = true;
                      _customTitleColor = null;
                    });
                    _saveTitleColor(null, true);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _customTitleColor = tempColor;
                  _useAnimatedTitle = tempUseAnim;
                });
                _saveTitleColor(tempUseAnim ? null : tempColor, tempUseAnim);
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

  Future<void> _resetAllColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('home_customBrown');
    await prefs.remove('home_customTileGreen');
    await prefs.remove('edit_customBrown');
    await prefs.remove('edit_customTileGreen');
    await prefs.remove('list_customBrown');
    await prefs.remove('list_customTileGreen');
    await prefs.remove('home_customTitleColor');
    await prefs.setBool('home_useAnimatedTitle', true);
    await prefs.remove('edit_customTitleColor');
    await prefs.remove('list_customTitleColor');
    setState(() {
      customBrown = Colors.brown;
      customTileGreen = const Color(0xFF388E3C);
      _useAnimatedTitle = true;
      _customTitleColor = null;
    });
  }

  void _showSupportPopup() {
    showDialog(
      context: context,
      builder: (ctx) {
        final links = [
          {
            'label': 'PayPal',
            'url': 'https://paypal.me/damroyaltyxxii',
            'icon': Icons.attach_money,
          },
          {
            'label': 'Instagram',
            'url': 'https://www.instagram.com/damroyalty',
            'icon': Icons.camera_alt,
          },
          {
            'label': 'X/Twitter',
            'url': 'https://www.x.com/damroyalty',
            'icon': Icons.alternate_email,
          },
          {
            'label': 'GitHub',
            'url': 'https://www.github.com/damroyalty',
            'icon': Icons.code,
          },
          {
            'label': 'Linktree',
            'url': 'https://linktr.ee/damroyalty',
            'icon': Icons.link,
          },
          {
            'label': 'Twitch',
            'url': 'https://www.twitch.tv/devroyalty',
            'icon': Icons.videogame_asset,
          },
          {
            'label': 'Discord',
            'url': 'https://discord.gg/kDs2mmQwwS',
            'icon': Icons.forum,
          },
        ];
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.pink[400], size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Support the dev',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: customTileGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 18,
                  thickness: 1,
                  color: Colors.green.withOpacity(0.12),
                ),
                Column(
                  children: links
                      .map(
                        (link) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            leading: Icon(
                              link['icon'] as IconData,
                              color: customTileGreen,
                            ),
                            title: Text(
                              link['label'] as String,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onTap: () async {
                              final url = Uri.parse(link['url'] as String);
                              try {
                                bool launched = false;

                                if (await canLaunchUrl(url)) {
                                  launched = await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }

                                if (!launched && await canLaunchUrl(url)) {
                                  launched = await launchUrl(
                                    url,
                                    mode: LaunchMode.platformDefault,
                                  );
                                }

                                if (!launched && await canLaunchUrl(url)) {
                                  launched = await launchUrl(
                                    url,
                                    mode: LaunchMode.inAppWebView,
                                  );
                                }

                                if (!launched) {
                                  throw 'Could not launch ${url.toString()}';
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Cannot open ${link['label']}: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            tileColor: Colors.green[50],
                            hoverColor: Colors.green[100],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (verCtx) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "You are currently on version 1.6",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text:
                                            "Since this is an unofficial app, check ",
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () async {
                                            final url = Uri.parse(
                                              "https://github.com/damroyalty/byrd/releases",
                                            );
                                            try {
                                              bool launched = false;

                                              if (await canLaunchUrl(url)) {
                                                launched = await launchUrl(
                                                  url,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              }

                                              if (!launched &&
                                                  await canLaunchUrl(url)) {
                                                launched = await launchUrl(
                                                  url,
                                                  mode: LaunchMode
                                                      .platformDefault,
                                                );
                                              }

                                              if (!launched &&
                                                  await canLaunchUrl(url)) {
                                                launched = await launchUrl(
                                                  url,
                                                  mode: LaunchMode.inAppWebView,
                                                );
                                              }

                                              if (!launched) {
                                                throw 'Could not launch GitHub releases';
                                              }
                                            } catch (e) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Cannot open link: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            "here",
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              decoration:
                                                  TextDecoration.underline,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: " for any further updates.",
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextButton(
                                  onPressed: () => Navigator.of(verCtx).pop(),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "v1.6 (tap for details)",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    // local device time //
    final now = DateTime.now();

    final birdsWithReplacement = Provider.of<BirdsProvider>(context).birds
        .map((bird) {
          final replacementDate = extractReplacementDate(bird.notes);
          if (replacementDate == null) return null;
          final daysDiff = replacementDate.difference(now).inDays;
          if (daysDiff < 0 || daysDiff > 180) return null; // 6 months

          // color/type for display if present //
          String breedDisplay = bird.breed;
          String? colorType;
          final notes = bird.notes;
          if (bird.type == BirdType.chicken) {
            final match = RegExp(
              r'([A-Za-z]+) Color/Type: ([^\n]+)',
            ).firstMatch(notes);
            if (match != null && match.group(2) != null) {
              colorType = match.group(2)!;
            }
          } else if (bird.type == BirdType.duck && bird.breed == 'Runner') {
            final match = RegExp(
              r'Runner Color/Type: ([^\n]+)',
            ).firstMatch(notes);
            if (match != null && match.group(1) != null) {
              colorType = match.group(1)!;
            }
          } else if (bird.type == BirdType.goose && bird.breed == 'Toulouse') {
            final match = RegExp(
              r'Toulouse Color/Type: ([^\n]+)',
            ).firstMatch(notes);
            if (match != null && match.group(1) != null) {
              colorType = match.group(1)!;
            }
          }
          if (colorType != null && colorType.isNotEmpty) {
            breedDisplay += ' ($colorType)';
          }

          final formattedDate = formatReplacementDate(replacementDate);
          final displayText =
              '${bird.typeName} | $breedDisplay | ${bird.location} | Replacement: $formattedDate';

          return <String, Object?>{
            'typeName': bird.typeName,
            'breedDisplay': breedDisplay,
            'location': bird.location,
            'replacementDate': replacementDate,
            'daysDiff': daysDiff,
            'displayText': displayText,
          };
        })
        .whereType<Map<String, Object?>>()
        .toList();

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
          appBar: AppBar(
            backgroundColor: customBrown,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TapParticle(
                  onTap: _showColorPickerDialogForBrown,
                  color: customTileGreen,
                  child: Icon(Icons.egg, color: Colors.yellow[800], size: 32),
                ),
                const SizedBox(width: 2),
                TapParticle(
                  onTap: _showTitleColorPickerDialog,
                  color: customTileGreen,
                  child: _useAnimatedTitle
                      ? AnimatedBuilder(
                          animation: _glitterController,
                          builder: (context, child) {
                            final double offset = _glitterController.value;
                            final double slide = offset * 4.0;
                            return ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.yellowAccent.withOpacity(1.0),
                                    Colors.amber.withOpacity(0.95),
                                    Colors.orangeAccent.withOpacity(0.9),
                                    Colors.lightBlueAccent.withOpacity(0.7),
                                    Colors.white,
                                    Colors.greenAccent.withOpacity(0.7),
                                    Colors.white,
                                    Colors.yellow.withOpacity(0.8),
                                    Colors.white,
                                  ],
                                  begin: Alignment(-1.0 + slide, -1.0),
                                  end: Alignment(1.0 + slide, 1.0),
                                  tileMode: TileMode.repeated,
                                ).createShader(bounds);
                              },
                              child: Text(
                                'cluckers',
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 21,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  shadows: [
                                    Shadow(
                                      color: Colors.yellowAccent.withOpacity(
                                        0.9,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 0),
                                    ),
                                    Shadow(
                                      color: Colors.greenAccent.withOpacity(
                                        0.7,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 2),
                                    ),
                                    Shadow(
                                      color: Colors.orangeAccent.withOpacity(
                                        0.7,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 0),
                                    ),
                                    Shadow(
                                      color: Colors.lightBlueAccent.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 0),
                                    ),
                                    Shadow(
                                      color: customBrown.withOpacity(0.2),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Text(
                          'cluckers',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: _customTitleColor ?? Colors.white,
                            letterSpacing: -0.3,
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
                ),
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: _showColorPickerDialogForTileGreen,
                  child: Icon(Icons.grass, color: Colors.green[400], size: 28),
                ),
              ],
            ),
            titleSpacing: 8.0,
            actions: [
              AnimatedSwitcher(
                duration: _searchAnimDuration,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
                child: _showSearchBar
                    ? SizedBox(
                        key: const ValueKey('searchBar'),
                        width: 185,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'breed/location',
                              hintStyle: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              fillColor: isDark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 20,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showSearchBar = false;
                                    _searchController.clear();
                                  });
                                },
                              ),
                            ),
                            onSubmitted: (query) {
                              setState(() {
                                _showSearchBar = false;
                              });
                              if (query.trim().isNotEmpty) {
                                _showSearchResults(context, query.trim());
                              }
                            },
                          ),
                        ),
                      )
                    : Padding(
                        key: const ValueKey('searchIcon'),
                        padding: const EdgeInsets.only(top: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.search, size: 26),
                          tooltip: 'Search',
                          onPressed: () {
                            setState(() {
                              _showSearchBar = true;
                            });
                            Future.delayed(Duration(milliseconds: 10), () {
                              _searchFocusNode.requestFocus();
                            });
                          },
                        ),
                      ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
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
                                  child: _buildBirdTypeTile(
                                    context,
                                    BirdType.other,
                                  ),
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
                              fontSize: 15,
                              color: Colors.brown,
                              fontWeight: FontWeight.w600,
                            );

                            List<InlineSpan> spans = [];
                            for (
                              var i = 0;
                              i < birdsWithReplacement.length;
                              i++
                            ) {
                              final entry = birdsWithReplacement[i];
                              final displayText =
                                  entry['displayText'] as String;
                              final replacementDateObj =
                                  entry['replacementDate'] as DateTime?;
                              final daysDiff = entry['daysDiff'] as int;

                              Color glowColor;
                              Color dateTextColor;
                              List<Shadow> glow;
                              if (daysDiff <= 90) {
                                dateTextColor = Colors.red;
                                glowColor = Colors.redAccent;
                                glow = [
                                  Shadow(
                                    color: glowColor.withOpacity(0.8),
                                    blurRadius: 12,
                                  ),
                                ];
                              } else {
                                dateTextColor = Colors.green[900]!;
                                glowColor = Colors.greenAccent;
                                glow = [
                                  Shadow(
                                    color: glowColor.withOpacity(0.7),
                                    blurRadius: 8,
                                  ),
                                ];
                              }

                              // highlighted date //
                              final dateStr = replacementDateObj != null
                                  ? formatReplacementDate(replacementDateObj)
                                  : '';
                              final beforeDate = displayText.substring(
                                0,
                                displayText.lastIndexOf(dateStr),
                              );
                              final afterDate = displayText.substring(
                                displayText.lastIndexOf(dateStr) +
                                    dateStr.length,
                              );

                              spans.add(
                                TextSpan(text: beforeDate, style: style),
                              );
                              if (dateStr.isNotEmpty) {
                                spans.add(
                                  TextSpan(
                                    text: dateStr,
                                    style: style.copyWith(
                                      color: dateTextColor,
                                      fontWeight: FontWeight.bold,
                                      shadows: glow,
                                    ),
                                  ),
                                );
                              }
                              spans.add(
                                TextSpan(text: afterDate, style: style),
                              );

                              if (i != birdsWithReplacement.length - 1) {
                                spans.add(
                                  const TextSpan(
                                    text: '     •     ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown,
                                    ),
                                  ),
                                );
                              }
                            }

                            final textWidget = RichText(
                              text: TextSpan(children: spans),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            );

                            final plainText = birdsWithReplacement
                                .map((e) => (e['displayText'] ?? '') as String)
                                .join('     •     ');
                            if (_lastMarqueeText != plainText) {
                              _lastMarqueeText = plainText;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final width = _textSize(plainText, style).width;
                                setState(() {
                                  _marqueeTextWidth = width;
                                });
                              });
                            }
                            final scrollWidth = _marqueeTextWidth + 40;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _updateMarqueeDuration(scrollWidth);
                            });
                            return TapParticle(
                              color: customTileGreen,
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder: (ctx) {
                                    return Dialog(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.85,
                                      ),
                                      elevation: 0,
                                      insetPadding: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 120,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 8,
                                            sigmaY: 8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.07),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_month,
                                                      color: Colors.black,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Upcoming Replacements',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: customTileGreen,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.close_rounded,
                                                        color: Colors.black,
                                                        size: 22,
                                                      ),
                                                      splashRadius: 18,
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            ctx,
                                                          ).pop(),
                                                    ),
                                                  ],
                                                ),
                                                Divider(
                                                  height: 18,
                                                  thickness: 1,
                                                  color: Colors.green
                                                      .withOpacity(0.12),
                                                ),
                                                const Text(
                                                  'Replacement tracking content here',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: AnimatedBuilder(
                                animation: _marqueeController,
                                builder: (context, child) {
                                  final t = _marqueeController.value;
                                  final offset = -t * scrollWidth;
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.brown.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.brown.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: offset,
                                            top: 0,
                                            child: SizedBox(
                                              width: scrollWidth,
                                              height: 48,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                      ),
                                                  child: textWidget,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: offset + scrollWidth,
                                            top: 0,
                                            child: SizedBox(
                                              width: scrollWidth,
                                              height: 48,
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12.0,
                                                      ),
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
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.dark_mode,
                          size: 15,
                          color: Colors.brown,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dark Mode',
                          style: TextStyle(fontSize: 12, color: Colors.brown),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: 0.75,
                          child: Switch(
                            value: isDark,
                            onChanged: (val) {
                              darkModeNotifier.value = val;
                              _saveDarkMode(val);
                              setState(() {});
                            },
                            activeColor: Colors.green[700],
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            inactiveTrackColor: isDark
                                ? Colors.white24
                                : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // theme reset button //
                Positioned(
                  bottom: 4,
                  right: 8,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: FloatingActionButton(
                      heroTag: 'resetTheme',
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: _resetAllColors,
                      mini: true,
                      tooltip: 'Reset theme colors to default',
                      child: Icon(Icons.refresh, color: Colors.brown, size: 16),
                    ),
                  ),
                ),
                // support button //
                Positioned(
                  bottom: 4,
                  left: 8,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: FloatingActionButton(
                      heroTag: 'supportDev',
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: _showSupportPopup,
                      mini: true,
                      tooltip: 'Support the dev',
                      child: Icon(
                        Icons.attach_money,
                        color: Colors.green[800],
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        svgAsset = 'assets/icons/chicken.svg';
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

    return TapParticle(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BirdListScreen(birdType: type),
          ),
        );
      },
      color: customTileGreen,
      child: Card(
        color: Colors.green[50],
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    svgAsset,
                    width: 48,
                    height: 48,
                    colorFilter: ColorFilter.mode(
                      customTileGreen,
                      BlendMode.srcIn,
                    ),
                  ),
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
                (i) => (i / (colors.length - 1) + _controller.value) % 1.0,
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
