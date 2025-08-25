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

enum SortField { name, breed, bandColor, gender, alive }

enum AliveFilter { any, alive, dead }

class BirdListScreen extends StatefulWidget {
  final BirdType birdType;

  const BirdListScreen({Key? key, required this.birdType}) : super(key: key);

  @override
  State<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends State<BirdListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;
  final FocusNode _searchFocusNode = FocusNode();
  final Duration _searchAnimDuration = const Duration(milliseconds: 250);

  final TextEditingController _breedFilterController = TextEditingController();
  SortField _sortField = SortField.name;
  bool _sortAsc = true;
  Gender? _genderFilter;
  AliveFilter _aliveFilter = AliveFilter.any;

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _bounceAnimation;
  Timer? _animationTimer;

  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);
  Color? _customTitleColor;

  final Map<String, Color> bandColorMap = {
    'red': Colors.red,
    'pink': Colors.pink,
    'blue': Colors.blue,
    'orange': Colors.orange,
    'yellow': Colors.yellow,
    'green': Colors.green,
    'purple': Colors.purple,
    'brown': Colors.brown,
    'black': Colors.black,
    'white': Colors.grey[300]!,
    'grey': Colors.grey,
  };

  Set<String> _selectedBandColors = <String>{};

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
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    _breedFilterController.dispose();
    super.dispose();
  }

  String _effectiveName(Bird b) {
    final label = (b.label ?? '').trim();
    if (label.isNotEmpty) return label.toLowerCase();
    final breed = b.breed.trim();
    if (breed.isNotEmpty) return breed.toLowerCase();
    final loc = b.location.trim();
    if (loc.isNotEmpty) return loc.toLowerCase();
    return b.typeName.toLowerCase();
  }

  String _bandColorText(Bird b) {
    if (b.customBandColor != null && b.customBandColor!.isNotEmpty) {
      return b.customBandColor!.toLowerCase();
    }
    return b.bandColor.toString().split('.').last.toLowerCase();
  }

  void _openSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        bool tempSortAsc = _sortAsc;
        Gender? tempGender = _genderFilter;
        AliveFilter tempAlive = _aliveFilter;
        final TextEditingController tempBreed = TextEditingController(
          text: _breedFilterController.text,
        );
        Set<String> tempSelectedBandColors = Set<String>.from(
          _selectedBandColors,
        );

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black;
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: customTileGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Sort & Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: textColor,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Sort',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Name/Label'),
                                Row(
                                  children: [
                                    Text(
                                      'Asc',
                                      style: TextStyle(
                                        color: tempSortAsc
                                            ? customTileGreen
                                            : textColor,
                                        fontWeight: tempSortAsc
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Switch(
                                      activeColor: customTileGreen,
                                      inactiveTrackColor: customTileGreen
                                          .withOpacity(0.3),
                                      value: !tempSortAsc,
                                      onChanged: (val) => setModalState(() {
                                        tempSortAsc = !val;
                                      }),
                                    ),
                                    Text(
                                      'Desc',
                                      style: TextStyle(
                                        color: !tempSortAsc
                                            ? customTileGreen
                                            : textColor,
                                        fontWeight: !tempSortAsc
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          selectedColor: customTileGreen.withOpacity(0.2),
                          checkmarkColor: customTileGreen,
                          label: Text('Any'),
                          selected: tempAlive == AliveFilter.any,
                          onSelected: (_) => setModalState(() {
                            tempAlive = AliveFilter.any;
                          }),
                        ),
                        FilterChip(
                          selectedColor: customTileGreen.withOpacity(0.2),
                          checkmarkColor: customTileGreen,
                          label: Text('Alive'),
                          selected: tempAlive == AliveFilter.alive,
                          onSelected: (_) => setModalState(() {
                            tempAlive = AliveFilter.alive;
                          }),
                        ),
                        FilterChip(
                          selectedColor: customTileGreen.withOpacity(0.2),
                          checkmarkColor: customTileGreen,
                          label: Text('Dead'),
                          selected: tempAlive == AliveFilter.dead,
                          onSelected: (_) => setModalState(() {
                            tempAlive = AliveFilter.dead;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any gender'),
                          selected: tempGender == null,
                          selectedColor: customTileGreen.withOpacity(0.2),
                          onSelected: (_) => setModalState(() {
                            tempGender = null;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Male'),
                          selected: tempGender == Gender.male,
                          selectedColor: customTileGreen.withOpacity(0.2),
                          onSelected: (_) => setModalState(() {
                            tempGender = Gender.male;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Female'),
                          selected: tempGender == Gender.female,
                          selectedColor: customTileGreen.withOpacity(0.2),
                          onSelected: (_) => setModalState(() {
                            tempGender = Gender.female;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Unknown'),
                          selected: tempGender == Gender.unknown,
                          selectedColor: customTileGreen.withOpacity(0.2),
                          onSelected: (_) => setModalState(() {
                            tempGender = Gender.unknown;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tempBreed,
                      decoration: InputDecoration(
                        labelText: 'Breed contains',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Band Colors',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAllBandColors().map((color) {
                        final displayColor =
                            bandColorMap[color] ?? customTileGreen;
                        return FilterChip(
                          selected: tempSelectedBandColors.contains(color),
                          selectedColor: displayColor.withOpacity(0.2),
                          checkmarkColor: displayColor,
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: tempSelectedBandColors.contains(color)
                                ? displayColor
                                : Theme.of(context).dividerColor,
                          ),
                          avatar: CircleAvatar(
                            backgroundColor: displayColor,
                            radius: 12,
                          ),
                          label: Text(
                            color[0].toUpperCase() + color.substring(1),
                            style: TextStyle(
                              color: tempSelectedBandColors.contains(color)
                                  ? displayColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setModalState(() {
                              if (selected) {
                                tempSelectedBandColors.add(color);
                              } else {
                                tempSelectedBandColors.remove(color);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSortAsc = true;
                              tempGender = null;
                              tempAlive = AliveFilter.any;
                              tempBreed.clear();
                              tempSelectedBandColors.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: customTileGreen,
                          ),
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _sortField = SortField.name;
                              _sortAsc = tempSortAsc;
                              _genderFilter = tempGender;
                              _aliveFilter = tempAlive;
                              _breedFilterController.text = tempBreed.text;
                              _selectedBandColors = Set<String>.from(
                                tempSelectedBandColors,
                              );
                            });
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: customTileGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _buildBandChip(Bird bird, bool isDark) {
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
    final String bandColorName =
        (bird.customBandColor != null && bird.customBandColor!.isNotEmpty)
        ? bird.customBandColor!.toLowerCase()
        : bird.bandColor.toString().split('.').last.toLowerCase();
    final Color bandColor = bandColorMap[bandColorName] ?? customTileGreen;

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
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  List<String> _getAllBandColors() {
    final Set<String> colors = {};

    colors.addAll(
      BandColor.values.map((c) => c.toString().split('.').last.toLowerCase()),
    );

    final birds = Provider.of<BirdsProvider>(context, listen: false).birds;
    for (var bird in birds) {
      if (bird.customBandColor != null && bird.customBandColor!.isNotEmpty) {
        colors.add(bird.customBandColor!.toLowerCase());
      }
    }

    return colors.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final birdsProvider = Provider.of<BirdsProvider>(context);
    final birds = birdsProvider.getBirdsByType(widget.birdType);
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

    final int totalQuantity = birds
        .where((b) => b.isAlive == true)
        .fold(0, (sum, b) => sum + b.quantity);

    List<Bird> filteredBirds = List.of(birds);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filteredBirds = filteredBirds.where((b) {
        final label = (b.label ?? '').toLowerCase();
        final breed = b.breed.toLowerCase();
        final loc = b.location.toLowerCase();
        final typeName = b.typeName.toLowerCase();
        final bandColor = _bandColorText(b);
        final gender = b.gender.toString().split('.').last.toLowerCase();
        final notes = b.notes.toLowerCase();
        final sourceDetail = (b.sourceDetail ?? '').toLowerCase();
        return label.contains(q) ||
            breed.contains(q) ||
            loc.contains(q) ||
            typeName.contains(q) ||
            bandColor.contains(q) ||
            gender.contains(q) ||
            notes.contains(q) ||
            sourceDetail.contains(q);
      }).toList();
    }

    final breedQuery = _breedFilterController.text.trim().toLowerCase();
    if (breedQuery.isNotEmpty) {
      filteredBirds = filteredBirds
          .where((b) => b.breed.toLowerCase().contains(breedQuery))
          .toList();
    }

    if (_selectedBandColors.isNotEmpty) {
      filteredBirds = filteredBirds
          .where((b) => _selectedBandColors.contains(_bandColorText(b)))
          .toList();
    }

    if (_genderFilter != null) {
      filteredBirds = filteredBirds
          .where((b) => b.gender == _genderFilter)
          .toList();
    }

    if (_aliveFilter != AliveFilter.any) {
      filteredBirds = filteredBirds
          .where(
            (b) => _aliveFilter == AliveFilter.alive
                ? b.isAlive == true
                : b.isAlive == false,
          )
          .toList();
    }

    int cmpStrings(String a, String b) => a.compareTo(b);

    if (!(_sortField == SortField.name && _sortAsc)) {
      if (!(_sortField == SortField.name && _sortAsc)) {
        filteredBirds.sort((a, b) {
          int cmp;
          switch (_sortField) {
            case SortField.name:
              cmp = cmpStrings(_effectiveName(a), _effectiveName(b));
              break;
            case SortField.breed:
              cmp = cmpStrings(a.breed.toLowerCase(), b.breed.toLowerCase());
              break;
            case SortField.bandColor:
              cmp = cmpStrings(_bandColorText(a), _bandColorText(b));
              break;
            case SortField.gender:
              cmp = a.gender.index.compareTo(b.gender.index);
              break;
            case SortField.alive:
              int va = a.isAlive == true ? 0 : (a.isAlive == false ? 1 : 2);
              int vb = b.isAlive == true ? 0 : (b.isAlive == false ? 1 : 2);
              cmp = va.compareTo(vb);
              break;
          }
          final bool asc = _sortField == SortField.name ? _sortAsc : true;
          return asc ? cmp : -cmp;
        });
      }
    }

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
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Sort/Filter',
                onPressed: _openSortFilterSheet,
              ),
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
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          birdsProvider.reorderBirds(
                            widget.birdType,
                            oldIndex,
                            newIndex,
                          );
                        });
                      },
                      itemCount: filteredBirds.length,
                      itemBuilder: (ctx, index) {
                        final bird = filteredBirds[index];
                        String? statusDetails;
                        if (bird.isAlive == false &&
                            bird.healthStatus != null &&
                            bird.healthStatus!.isNotEmpty) {
                          statusDetails = bird.healthStatus;
                        }
                        return TapParticle(
                          key: ValueKey(bird.id),
                          color: customTileGreen,
                          child: ListTile(
                            leading:
                                (bird.imagePath != null &&
                                    bird.imagePath!.isNotEmpty &&
                                    File(bird.imagePath!).existsSync())
                                ? SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(bird.imagePath!),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : (bird.additionalImages.any(
                                    (img) =>
                                        img.isNotEmpty &&
                                        File(img).existsSync(),
                                  ))
                                ? SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _TileImageCarousel(
                                        profileImage: bird.imagePath,
                                        additionalImages: bird.additionalImages
                                            .where(
                                              (img) =>
                                                  img.isNotEmpty &&
                                                  File(img).existsSync(),
                                            )
                                            .toList(),
                                        onTap: (imgPath, allImages) =>
                                            _showImagePopup(
                                              context,
                                              imgPath,
                                              allImages: allImages,
                                            ),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        color: customTileGreen.withOpacity(
                                          0.15,
                                        ),
                                        child: Icon(
                                          Icons.pets,
                                          color: textColor,
                                          size: 48,
                                        ),
                                      ),
                                    ),
                                  ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (bird.label != null &&
                                    bird.label!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: customTileGreen.withOpacity(0.15),
                                      border: Border.all(
                                        color: customTileGreen,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      bird.label!,
                                      style: TextStyle(
                                        color: textColor,
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
                                      statusDetails,
                                      style: TextStyle(
                                        color: Colors.red[300],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildBandChip(bird, isDark),
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
                          ),

                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) {
                                TextStyle labelStyle = TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  fontFamily: 'Segoe UI',
                                  color: isDark ? Colors.white : Colors.black,
                                );
                                TextStyle valueStyle = TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 17,
                                  fontFamily: 'Segoe UI',
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                );
                                return Dialog(
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white.withOpacity(0.95),
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
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    (bird.label != null &&
                                                            bird
                                                                .label!
                                                                .isNotEmpty)
                                                        ? bird.label!
                                                        : bird.typeName,
                                                    style: labelStyle.copyWith(
                                                      fontSize: 20,
                                                      color: customTileGreen,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                              ),
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
                                                  color: textColor,
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
                                                  text: '${bird.breed}\n',
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
                                                      '${bird.gender.toString().split('.').last}\n',
                                                ),
                                                TextSpan(
                                                  text: 'Source: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${bird.source.toString().split('.').last}\n',
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
                                                        '${bird.sourceDetail!}\n',
                                                  ),
                                                ],
                                                TextSpan(
                                                  text: 'Date: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${bird.date.toLocal().toString().split(' ')[0]}\n',
                                                ),
                                                if (bird.arrivalDate !=
                                                    null) ...[
                                                  TextSpan(
                                                    text: 'Arrival Date: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${bird.arrivalDate!.toLocal().toString().split(' ')[0]}\n',
                                                  ),
                                                ],
                                                if (bird.isAlive != null) ...[
                                                  TextSpan(
                                                    text: 'Alive: ',
                                                    style: labelStyle,
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        '${bird.isAlive! ? 'Yes' : 'No'}\n',
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
                                                        '${bird.healthStatus!}\n',
                                                  ),
                                                ],
                                                TextSpan(
                                                  text: 'Band Color: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text:
                                                      '${bird.customBandColor != null && bird.customBandColor!.isNotEmpty ? bird.customBandColor! : bird.bandColor.toString().split('.').last}\n',
                                                ),
                                                TextSpan(
                                                  text: 'Location: ',
                                                  style: labelStyle,
                                                ),
                                                TextSpan(
                                                  text: '${bird.location}\n',
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
                                                      color: isDark
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
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
                  final aliveBirds = birds
                      .where((b) => b.isAlive == true)
                      .toList();
                  final Map<String, int> breedCounts = {};
                  for (var b in aliveBirds) {
                    breedCounts[b.breed] =
                        (breedCounts[b.breed] ?? 0) + b.quantity;
                  }
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        backgroundColor: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.bar_chart, color: customTileGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Breed Breakdown',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: customTileGreen,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Alive: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$totalQuantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: breedCounts.isEmpty
                            ? Text(
                                'No alive birds.',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : SizedBox(
                                width: 260,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: breedCounts.entries.map((entry) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      trailing: Text(
                                        entry.value.toString(),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[800],
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: customTileGreen,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: customTileGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
      child: SizedBox(
        width: 100,
        height: 100,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          clipBehavior: Clip.hardEdge,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Image.file(
                File(_allImages[_currentIndex]),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
