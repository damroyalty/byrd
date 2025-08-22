import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'add_edit_bird_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tap_particle.dart';
import '../dark_mode.dart';
import 'dart:async';
import 'dart:math';
import '../providers/global_colors_provider.dart';

class BirdListScreen extends StatefulWidget {
  final BirdType birdType;

  const BirdListScreen({super.key, required this.birdType});

  @override
  State<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends State<BirdListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();
  final Duration _searchAnimDuration = const Duration(milliseconds: 250);

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _bounceAnimation;
  Timer? _animationTimer;

  // color picker //
  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);
  Color? _customTitleColor;

  @override
  void initState() {
    super.initState();
    _loadColors();
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && _showSearchBar) {
        setState(() {
          _showSearchBar = false;
          _searchController.clear();
          _searchQuery = '';
        });
      }
    });
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _bounceAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _startAnimationTimer();
  }

  void _startAnimationTimer() {
    _animationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _animationController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationTimer?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final brownValue = prefs.getInt('list_customBrown');
      final greenValue = prefs.getInt('list_customTileGreen');
      final titleColorValue = prefs.getInt('list_customTitleColor');
      if (brownValue != null) customBrown = Color(brownValue);
      if (greenValue != null) customTileGreen = Color(greenValue);
      if (titleColorValue != null) {
        _customTitleColor = Color(titleColorValue);
      } else {
        _customTitleColor = Colors.white;
      }
    });
  }

  Future<void> _saveBrownColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('list_customBrown', color.value);
  }

  Future<void> _saveTileGreenColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('list_customTileGreen', color.value);
    
    final globalColors = Provider.of<GlobalColorsProvider>(context, listen: false);
    await globalColors.updateNavigationBarColor(color);
  }

  Future<void> _saveTitleColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('list_customTitleColor', color.value);
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

  void _showTitleColorPickerDialog() async {
    Color tempColor = _customTitleColor ?? Colors.green[700]!;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color for the Title'),
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
                  _customTitleColor = tempColor;
                });
                _saveTitleColor(tempColor);
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

  void _showImagePopup(
    BuildContext ctx,
    String imgPath, {
    List<String>? allImages,
  }) {
    int initialIndex = 0;
    List<String> images = allImages ?? [imgPath];
    if (allImages != null) {
      initialIndex = images.indexOf(imgPath);
    }
    showDialog(
      context: ctx,
      builder: (imgCtx) {
        PageController controller = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              int currentIndex = controller.hasClients
                  ? controller.page?.round() ?? initialIndex
                  : initialIndex;
              return Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: controller,
                    itemCount: images.length,
                    onPageChanged: (idx) => setState(() {}),
                    itemBuilder: (context, idx) {
                      return InteractiveViewer(
                        child: Image.file(
                          File(images[idx]),
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 30,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(imgCtx).pop(),
                    ),
                  ),
                  if (images.length > 1 &&
                      (controller.hasClients
                              ? controller.page?.round() ?? 0
                              : 0) >
                          0)
                    Positioned(
                      left: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          controller.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  if (images.length > 1 &&
                      (controller.hasClients
                              ? controller.page?.round() ?? 0
                              : 0) <
                          images.length - 1)
                    Positioned(
                      right: 8,
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final birds = Provider.of<BirdsProvider>(
      context,
    ).getBirdsByType(widget.birdType);
    final bird = Bird(
      type: widget.birdType,
      breed: '',
      quantity: 0,
      source: SourceType.egg,
      date: DateTime.now(),
      gender: Gender.unknown,
      bandColor: BandColor.none,
      location: '',
    );

    // bird count (alive) //
    final int totalQuantity = birds.where((b) => b.isAlive == true).fold(0, (sum, b) => sum + b.quantity);

    // search query //
    final filteredBirds = _searchQuery.isEmpty
        ? birds
        : birds
              .where(
                (b) =>
                    b.breed.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    b.location.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        final textColor = isDark ? Colors.white : Colors.black;
        final subtitleColor = isDark ? Colors.white70 : Colors.black87;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
          appBar: AppBar(
            backgroundColor: customBrown,
            elevation: 0,
            leading: TapParticle(
              onTap: () => Navigator.of(context).maybePop(),
              color: customTileGreen,
              child: const BackButton(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TapParticle(
                  onTap: _showColorPickerDialogForBrown,
                  color: customTileGreen,
                  child: Icon(Icons.egg, color: Colors.yellow[800], size: 26),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _showTitleColorPickerDialog,
                  child: Text(
                    bird.type == BirdType.goose ? 'Geese' : '${bird.typeName}s',
                    style: TextStyle(
                      color: _customTitleColor ?? textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TapParticle(
                  onTap: _showColorPickerDialogForTileGreen,
                  color: customTileGreen,
                  child: Icon(Icons.grass, color: Colors.green[400], size: 22),
                ),
              ],
            ),
            titleSpacing: 4.0,
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
                            style: TextStyle(fontSize: 10, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'breed/location',
                              hintStyle: TextStyle(
                                fontSize: 9,
                                color: subtitleColor,
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
                                color: subtitleColor,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showSearchBar = false;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ),
                            onChanged: (query) {
                              setState(() {
                                _searchQuery = query.trim();
                              });
                            },
                            onSubmitted: (query) {
                              setState(() {
                                _showSearchBar = false;
                                _searchQuery = query.trim();
                              });
                            },
                          ),
                        ),
                      )
                    : Padding(
                        key: const ValueKey('searchIcon'),
                        padding: const EdgeInsets.only(top: 8.0),
                        child: IconButton(
                          icon: const Icon(Icons.search, size: 24),
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
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: filteredBirds.length,
                      onReorder: (oldIndex, newIndex) {
                        final originalBirds = birds;
                        final oldBird = filteredBirds[oldIndex];
                        final oldOriginalIndex = originalBirds.indexWhere((b) => b.id == oldBird.id);
                        
                        int newOriginalIndex;
                        if (newIndex >= filteredBirds.length) {
                          newOriginalIndex = originalBirds.indexWhere((b) => b.id == filteredBirds.last.id);
                        } else {
                          final newBird = filteredBirds[newIndex];
                          newOriginalIndex = originalBirds.indexWhere((b) => b.id == newBird.id);
                        }
                        
                        Provider.of<BirdsProvider>(context, listen: false)
                            .reorderBirds(widget.birdType, oldOriginalIndex, newOriginalIndex);
                      },
                      itemBuilder: (ctx, index) {
                        final bird = filteredBirds[index];
                        String? statusDetails;
                        if (bird.isAlive == false && bird.healthStatus != null && bird.healthStatus!.isNotEmpty) {
                          statusDetails = bird.healthStatus;
                        }
                                return TapParticle(
          key: ValueKey(bird.id),
  color: customTileGreen,
  child: ConstrainedBox(
    constraints: const BoxConstraints(
      minHeight: 100,
    ),
    child: ListTile(
    contentPadding: const EdgeInsets.only(left: 16, right: 32, top: 8, bottom: 8),
    leading: (bird.imagePath != null &&
            bird.imagePath!.isNotEmpty &&
            File(bird.imagePath!).existsSync())
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(bird.imagePath!),
              width: 80,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
        : (bird.additionalImages.any(
            (img) => img.isNotEmpty && File(img).existsSync(),
          ))
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _TileImageCarousel(
                  profileImage: bird.imagePath,
                  additionalImages: bird.additionalImages
                      .where(
                        (img) => img.isNotEmpty && File(img).existsSync(),
                      )
                      .toList(),
                  onTap: (imgPath, allImages) =>
                      _showImagePopup(context, imgPath, allImages: allImages),
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: customTileGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.pets, color: textColor, size: 20),
              ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bird.label != null && bird.label!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2), 
            decoration: BoxDecoration(
              color: customTileGreen.withOpacity(0.15),
              border: Border.all(color: customTileGreen, width: 1.0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              bird.label!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                fontFamily: 'Segoe UI',
              ),
            ),
          ),
        bird.location.isNotEmpty
            ? Text(
                bird.location,
                style: TextStyle(color: textColor),
              )
            : Text(
                'No Location/Pin',
                style: TextStyle(color: textColor),
              ),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breed: ${bird.breed}\nQty: ${bird.quantity} • ${bird.gender.toString().split('.').last}',
          style: TextStyle(color: subtitleColor),
        ),
        if (statusDetails != null)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '$statusDetails',
              style: TextStyle(
                color: Colors.red[300],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            (() {
              final Map<String, Color> bandColorMap = {
                'red': Colors.red,
                'blue': Colors.blue,
                'green': Colors.green,
                'yellow': Colors.yellow,
                'orange': Colors.orange,
                'purple': Colors.purple,
                'pink': Colors.pink,
                'black': Colors.black,
                'white': Colors.white,
                'none': Colors.transparent,
              };
              String bandColorName = (bird.customBandColor != null &&
                      bird.customBandColor!.isNotEmpty)
                  ? bird.customBandColor!.toLowerCase()
                  : bird.bandColor.toString().split('.').last.toLowerCase();
              Color bandColor = bandColorMap[bandColorName] ?? customTileGreen;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bandColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: bandColor.withOpacity(0.5)),
                ),
                child: Text(
                  (bird.customBandColor != null && bird.customBandColor!.isNotEmpty)
                      ? bird.customBandColor!
                      : bird.bandColor.toString().split('.').last,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              );
            })(),
            if (bird.type == BirdType.chicken && bird.chickenType != null)
              Text(
                bird.chickenType!,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 24),
      ],
    ),
  ),
                        ),



                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                TextStyle labelStyle = const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: 'Segoe UI',
                                );
                                TextStyle valueStyle = const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 17,
                                  fontFamily: 'Segoe UI',
                                );
                                return Dialog(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.95,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                bird.typeName,
                                                style: labelStyle.copyWith(
                                                  fontSize: 20,
                                                  color: customTileGreen,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: customTileGreen,
                                                  size: 22,
                                                ),
                                                tooltip: 'Edit',
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AddEditBirdScreen(
                                                            birdToEdit: bird,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.close,
                                                  color: Colors.grey[700],
                                                  size: 20,
                                                ),
                                                tooltip: 'Close',
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (bird.imagePath != null &&
                                              bird.imagePath!.isNotEmpty &&
                                              File(
                                                bird.imagePath!,
                                              ).existsSync())
                                            Center(
                                              child: GestureDetector(
                                                onTap: () => _showImagePopup(
                                                  context,
                                                  bird.imagePath!,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.file(
                                                    File(bird.imagePath!),
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 10),
                                          SelectableText.rich(
                                            TextSpan(
                                              style: valueStyle,
                                              children: [
                                                TextSpan(
                                                  text: 'Breed: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text: bird.breed + '\n',
                                                ),
                                                TextSpan(
                                                  text: 'Quantity: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text: '${bird.quantity}\n',
                                                ),
                                                TextSpan(
                                                  text: 'Gender: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      bird.gender
                                                          .toString()
                                                          .split('.')
                                                          .last +
                                                      '\n',
                                                ),
                                                TextSpan(
                                                  text: 'Source: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      bird.source
                                                          .toString()
                                                          .split('.')
                                                          .last +
                                                      '\n',
                                                ),
                                                if (bird.sourceDetail != null &&
                                                    bird
                                                        .sourceDetail!
                                                        .isNotEmpty) ...[
                                                  TextSpan(
                                                    text: 'Source Detail: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        bird.sourceDetail! +
                                                        '\n',
                                                  ),
                                                ],
                                                TextSpan(
                                                  text: 'Date: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      bird.date
                                                          .toLocal()
                                                          .toString()
                                                          .split(' ')[0] +
                                                      '\n',
                                                ),
                                                if (bird.arrivalDate !=
                                                    null) ...[
                                                  TextSpan(
                                                    text: 'Arrival Date: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        bird.arrivalDate!
                                                            .toLocal()
                                                            .toString()
                                                            .split(' ')[0] +
                                                        '\n',
                                                  ),
                                                ],
                                                if (bird.isAlive != null) ...[
                                                  TextSpan(
                                                    text: 'Alive: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        (bird.isAlive!
                                                            ? 'Yes'
                                                            : 'No') +
                                                        '\n',
                                                  ),
                                                ],
                                                if (bird.healthStatus != null &&
                                                    bird
                                                        .healthStatus!
                                                        .isNotEmpty) ...[
                                                  TextSpan(
                                                    text: 'Health Status: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        bird.healthStatus! +
                                                        '\n',
                                                  ),
                                                ],
                                                TextSpan(
                                                  text: 'Band Color: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      (bird.customBandColor !=
                                                                  null &&
                                                              bird
                                                                  .customBandColor!
                                                                  .isNotEmpty
                                                          ? bird.customBandColor!
                                                          : bird.bandColor
                                                                .toString()
                                                                .split('.')
                                                                .last) +
                                                      '\n',
                                                ),
                                                TextSpan(
                                                  text: 'Location: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text: bird.location + '\n',
                                                ),
                                                if (bird.notes.isNotEmpty) ...[
                                                  TextSpan(
                                                    text: 'Notes: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text: bird.notes,
                                                    style: valueStyle.copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                          if (bird.additionalImages.any(
                                            (img) =>
                                                img.isNotEmpty &&
                                                File(img).existsSync(),
                                          ))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10.0,
                                              ),
                                              child: Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: bird.additionalImages
                                                    .where(
                                                      (imgPath) =>
                                                          imgPath.isNotEmpty &&
                                                          File(
                                                            imgPath,
                                                          ).existsSync(),
                                                    )
                                                    .map(
                                                      (
                                                        imgPath,
                                                      ) => GestureDetector(
                                                        onTap: () => _showImagePopup(
                                                          context,
                                                          imgPath,
                                                          allImages: bird
                                                              .additionalImages
                                                              .where(
                                                                (img) =>
                                                                    img.isNotEmpty &&
                                                                    File(
                                                                      img,
                                                                    ).existsSync(),
                                                              )
                                                              .toList(),
                                                        ),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: Image.file(
                                                            File(imgPath),
                                                            width: 72,
                                                            height: 72,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  final aliveBirds = birds.where((b) => b.isAlive == true).toList();
                  final Map<String, int> breedCounts = {};
                  for (var b in aliveBirds) {
                    breedCounts[b.breed] = (breedCounts[b.breed] ?? 0) + b.quantity;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.bar_chart, color: customTileGreen),
                            const SizedBox(width: 8),
                            const Text('Breed Breakdown (Alive)'),
                          ],
                        ),
                        content: breedCounts.isEmpty
                            ? const Text('No alive birds.')
                            : SizedBox(
                                width: 260,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: breedCounts.entries.map((entry) {
                                    return ListTile(
                                      title: Text(entry.key),
                                      trailing: Text(entry.value.toString()),
                                    );
                                  }).toList(),
                                ),
                              ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final shakeOffset = Offset(
                      sin(_shakeAnimation.value * 2 * pi * 2) * 4,
                      sin(_shakeAnimation.value * 2 * pi) * 2,
                    );
                    
                    final scale = _bounceAnimation.value;
                    
                    return Transform.translate(
                      offset: shakeOffset,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12, right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: customTileGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalQuantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TapParticle(
                color: customTileGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditBirdScreen(birdType: widget.birdType),
                    ),
                  );
                },
                child: FloatingActionButton(
                  backgroundColor: customTileGreen,
                  elevation: 0,
                  onPressed: null,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TileImageCarousel extends StatefulWidget {
  final String? profileImage;
  final List<String> additionalImages;
  final void Function(String imgPath, List<String> allImages) onTap;

  const _TileImageCarousel({
    Key? key,
    required this.profileImage,
    required this.additionalImages,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_TileImageCarousel> createState() => _TileImageCarouselState();
}

class _TileImageCarouselState extends State<_TileImageCarousel> {
  int _currentIndex = 0;
  late List<String> _allImages;

  @override
  void initState() {
    super.initState();
    _allImages = [
      if (widget.profileImage != null &&
          widget.profileImage!.isNotEmpty &&
          File(widget.profileImage!).existsSync())
        widget.profileImage!,
      ...widget.additionalImages.where(
        (img) => img.isNotEmpty && File(img).existsSync(),
      ),
    ];
  }

  void _nextImage() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _allImages.length;
    });
  }

  void _prevImage() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _allImages.length) % _allImages.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(_allImages[_currentIndex], _allImages),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          _nextImage();
        } else if (details.primaryVelocity != null &&
            details.primaryVelocity! > 0) {
          _prevImage();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.file(
            File(_allImages[_currentIndex]),
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}