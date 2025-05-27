import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'add_edit_bird_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tap_particle.dart';
import 'dart:ui';
import '../dark_mode.dart';

class BirdListScreen extends StatefulWidget {
  final BirdType birdType;

  const BirdListScreen({super.key, required this.birdType});

  @override
  State<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends State<BirdListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode(); // <-- add this
  final Duration _searchAnimDuration = const Duration(
    milliseconds: 250,
  ); // animation duration

  // color picker //
  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);
  Color? _customTitleColor;

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final brownValue = prefs.getInt('list_customBrown');
      final greenValue = prefs.getInt('list_customTileGreen');
      final titleColorValue = prefs.getInt('list_customTitleColor');
      if (brownValue != null) customBrown = Color(brownValue);
      if (greenValue != null) customTileGreen = Color(greenValue);
      // Reset to white if not set (after reset)
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
                    right: 0, // <-- move from 10 to 0 for closer to the right edge
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
  }

  @override
  void dispose() {
    _searchFocusNode.dispose(); // <-- add this
    super.dispose();
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

    // calculate total quantity //
    final int totalQuantity = birds.fold(0, (sum, b) => sum + b.quantity);

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
                        width: 200,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode, // <-- add this
                            autofocus: true,
                            style: TextStyle(fontSize: 14, color: textColor),
                            decoration: InputDecoration(
                              hintText: 'breed/location',
                              hintStyle: TextStyle(
                                fontSize: 13,
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
                        padding: const EdgeInsets.only(
                          top: 8.0,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.search, size: 24),
                          tooltip: 'Search',
                          onPressed: () {
                            setState(() {
                              _showSearchBar = true;
                            });
                            // Request focus when opening
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
                    child: ListView.builder(
                      itemCount: filteredBirds.length,
                      itemBuilder: (ctx, index) {
                        final bird = filteredBirds[index];
                        String? statusDetails;
                        if (bird.isAlive == false &&
                            bird.healthStatus != null &&
                            bird.healthStatus!.isNotEmpty) {
                          statusDetails = bird.healthStatus;
                        }
                        String? customBandColor;
                        if (bird.notes.contains('Custom Band Color:')) {
                          customBandColor = bird.notes
                              .split('Custom Band Color:')
                              .last
                              .trim()
                              .split('\n')
                              .first
                              .trim();
                        }
                        return TapParticle(
                          color: customTileGreen,
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
                                              File(bird.imagePath!).existsSync())
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
                                          if (bird.additionalImages.any((img) => img.isNotEmpty && File(img).existsSync()))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10.0,
                                              ),
                                              child: Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: bird.additionalImages
                                                    .where((imgPath) => imgPath.isNotEmpty && File(imgPath).existsSync())
                                                    .map(
                                                      (
                                                        imgPath,
                                                      ) => GestureDetector(
                                                        onTap: () =>
                                                            _showImagePopup(
                                                              context,
                                                              imgPath,
                                                              allImages: bird
                                                                  .additionalImages.where((img) => img.isNotEmpty && File(img).existsSync()).toList(),
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
                          child: ListTile(
                            leading:
                                (bird.imagePath != null &&
                                 bird.imagePath!.isNotEmpty &&
                                 File(bird.imagePath!).existsSync())
                                ? CircleAvatar(
                                    backgroundImage: FileImage(File(bird.imagePath!)),
                                    radius: 28,
                                  )
                                : (bird.additionalImages.any((img) => img.isNotEmpty && File(img).existsSync()))
                                  ? _TileImageCarousel(
                                      profileImage: bird.imagePath,
                                      additionalImages: bird.additionalImages.where((img) => img.isNotEmpty && File(img).existsSync()).toList(),
                                      onTap: (imgPath, allImages) =>
                                          _showImagePopup(
                                            context,
                                            imgPath,
                                            allImages: allImages,
                                          ),
                                    )
                                  : CircleAvatar(
                                      child: Icon(Icons.pets, color: textColor),
                                      radius: 28,
                                    ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (bird.label != null &&
                                    bird.label!.isNotEmpty)
                                  Text(
                                    bird.label!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Segoe UI',
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
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (bird.customBandColor != null &&
                                          bird.customBandColor!.isNotEmpty)
                                      ? bird.customBandColor!
                                      : bird.bandColor
                                            .toString()
                                            .split('.')
                                            .last,
                                  style: TextStyle(color: subtitleColor),
                                ),
                                if (bird.type == BirdType.chicken &&
                                    bird.chickenType != null)
                                  Text(
                                    bird.chickenType!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey,
                                      fontStyle: FontStyle.italic,
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
              Positioned(
                left: 16,
                bottom: 12,
                child: TapParticle(
                  color: customTileGreen,
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      builder: (ctx) {
                        // breed breakdown //
                        final Map<String, int> breedTotals = {};
                        for (final bird in filteredBirds) {
                          breedTotals[bird.breed] =
                              (breedTotals[bird.breed] ?? 0) + bird.quantity;
                        }
                        final breedList = breedTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        return Dialog(
                          backgroundColor: Colors.white.withOpacity(0.85),
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
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.07),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.bar_chart,
                                          color: Colors.black,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Breed Breakdown',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: customTileGreen,
                                          ),
                                        ),
                                        const Spacer(),
                                        TapParticle(
                                          color: customTileGreen,
                                          onTap: null,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.black,
                                              size: 22,
                                            ),
                                            splashRadius: 18,
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(
                                      height: 18,
                                      thickness: 1,
                                      color: Colors.brown.withOpacity(0.12),
                                    ),
                                    ...breedList.map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              entry.value.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: customTileGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (breedList.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.0,
                                        ),
                                        child: Text(
                                          'No breeds found.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: customTileGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: customTileGreen.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      'Total: $totalQuantity',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: customTileGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: TapParticle(
            color: customTileGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditBirdScreen(birdType: widget.birdType),
                ),
              );
            },
            child: FloatingActionButton(
              backgroundColor: customTileGreen,
              onPressed: null,
              child: const Icon(Icons.add, color: Colors.white),
            ),
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
      ...widget.additionalImages.where((img) => img.isNotEmpty && File(img).existsSync()),
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
      child: CircleAvatar(
        backgroundImage: FileImage(File(_allImages[_currentIndex])),
        radius: 28,
      ),
    );
  }
}
