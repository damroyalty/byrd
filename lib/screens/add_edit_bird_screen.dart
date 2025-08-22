import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tap_particle.dart';
import '../dark_mode.dart';
import 'package:path/path.dart' as path;
import '../providers/global_colors_provider.dart';
import 'package:path_provider/path_provider.dart';

class AddEditBirdScreen extends StatefulWidget {
  final BirdType? birdType;
  final Bird? birdToEdit;

  const AddEditBirdScreen({super.key, this.birdType, this.birdToEdit});

  @override
  _AddEditBirdScreenState createState() => _AddEditBirdScreenState();
}

class _AddEditBirdScreenState extends State<AddEditBirdScreen> {
  final _formKey = GlobalKey<FormState>();
  late BirdType _birdType;
  File? _imageFile;
  final List<File> _additionalImages = [];
  final ImagePicker _picker = ImagePicker();

  // form //
  late String _breed;
  late int _quantity;
  late SourceType _source;
  String? _sourceDetail;
  late DateTime _date;
  DateTime? _arrivalDate;
  bool? _isAlive;
  String? _healthStatus;
  late Gender _gender;
  late String _location;
  String _notes = '';
  String? _label;

  // search //
  List<String> _filteredBreeds = [];

  // breed dropdown options //
  final Map<BirdType, List<String>> _breedOptions = {
    BirdType.chicken: [
      'Orpington',
      'Easter Egger',
      'Silkie',
      'Cream Legbar',
      'Ameraucana',
      'Cochin',
      'Wyandotte',
      'Barnevelder',
      'Andalusian',
      'Barred Plymouth',
      'White Plymouth',
      'Silver Penciled Plymouth',
      'Australorp',
      'Maran',
      'Wellsummer',
      'Buckeye',
      'Salmon Faverolle',
      'Campine',
      'Deathlayer',
      'Hamburg',
      'Speckled Sussex',
      'Dorking',
      'Golden Buff',
      'ISA',
      'Austra White',
      'Rhode Island Red',
      'Plymouth Rock',
      'Leghorn',
      'Sussex',
      'Bantams',
      'Other',
    ],
    BirdType.duck: [
      'Pekin',
      'Jumbo Pekin',
      'Khaki Campbell',
      'Rouen',
      'Muscovy',
      'Khelsh Hartegwin',
      'Runner',
      'Cayuqa',
      'Silver Appleyard',
      'Magpie',
      'Gold 300 Hybid',
      'Buff',
      'White Crested',
      'Other',
    ],
    BirdType.turkey: [
      'Broad Breasted White',
      'Black Slate',
      'Blue Slate',
      'Royal Palm',
      'Bourbon Red',
      'Narragansett',
      'Other',
    ],
    BirdType.goose: [
      'Tufted Roman',
      'Buff',
      'Sebastopol',
      'Embden',
      'Toulouse',
      'African',
      'Chinese',
      'Other',
    ],
    BirdType.other: ['Other'],
  };

  String? _deadStatus;
  String? _damageNotes;

  String? _customBandColor;
  BandColor? _bandColorOrNull;

  DateTime? _replacementDate;

  String? _chickenType; // "layer" or "dual"
  String? _runnerColorType; // for runner duck
  String? _toulouseColorType; // for toulouse goose
  String? _chickenColorType; // for special chicken breeds

  // chicken breeds to their color type
  final Map<String, List<String>> _chickenColorTypeOptions = {
    'Orpington': [
      'Chocolate',
      'Blue',
      'Buff',
      'Jubilee',
      'Lavender',
      'Black Split to Lander',
    ],
    'Ameraucana': ['Blue', 'Black', 'Splash'],
    'Wyandotte': [
      'Blue Laced Red',
      'Splashed Laced Red',
      'Black Laced Red',
      'Black Laced Golden',
      'Black Laced Silver',
      'Other',
    ],
    'Andalusian': ['Blue', 'Black', 'Splash'],
    'Australorp': ['Black', 'Blue'],
    'Maran': [
      'Black Copper',
      'Blue Copper',
      'Cuckoo',
      'French Blacktailed',
      'Black',
      'Wheaton',
      'White',
      'Golden Cuckoo',
      'Splash',
    ],
    'Deathlayer': ['Gold', 'Silver'],
    'Dorking': ['Silver', 'Red'],
    'Cochin': [
      'White',
      'Partridge',
      'Calico',
      'Blue',
      'Black',
      'Barred',
      'Buff',
      'Bircher',
      'Speckled',
      'Golden Laced',
      'Silver Laced',
      'Splash',
    ],
    'Easter Egger': ['Frizzler', 'Blue', 'Green'],
  };

  // color pickers //
  Color customBrown = Colors.brown;
  Color customTileGreen = const Color(0xFF388E3C);
  Color? _customTitleColor;

  Future<void> _loadColors() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final brownValue = prefs.getInt('edit_customBrown');
      final greenValue = prefs.getInt('edit_customTileGreen');
      final titleColorValue = prefs.getInt('edit_customTitleColor');
      if (brownValue != null) customBrown = Color(brownValue.toUnsigned(32));
      if (greenValue != null)
        customTileGreen = Color(greenValue.toUnsigned(32));
      if (titleColorValue != null)
        _customTitleColor = Color(titleColorValue.toUnsigned(32));
    });
  }

  Future<void> _saveBrownColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('edit_customBrown', color.value.toUnsigned(32));
  }

  Future<void> _saveTileGreenColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('edit_customTileGreen', color.value.toUnsigned(32));
    
    final globalColors = Provider.of<GlobalColorsProvider>(context, listen: false);
    await globalColors.updateNavigationBarColor(color);
  }

  Future<void> _saveTitleColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('edit_customTitleColor', color.value.toUnsigned(32));
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

  // custom radio color //
  WidgetStateProperty<Color?> _radioFillColor(
    Color color, {
    bool isDark = false,
  }) {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.selected)) {
        return color;
      }
      if (isDark) {
        return Colors.white;
      }
      return null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadColors();

    if (widget.birdToEdit != null) {
      _birdType = widget.birdToEdit!.type;
      _breed = widget.birdToEdit!.breed;
      _quantity = widget.birdToEdit!.quantity;
      _source = widget.birdToEdit!.source;
      _sourceDetail = widget.birdToEdit!.sourceDetail;
      _date = widget.birdToEdit!.date;
      _arrivalDate = widget.birdToEdit!.arrivalDate;
      _isAlive = widget.birdToEdit!.isAlive;
      _healthStatus = widget.birdToEdit!.healthStatus;
      _gender = widget.birdToEdit!.gender;
      _location = widget.birdToEdit!.location;
      _notes = widget.birdToEdit!.notes;
      _label = widget.birdToEdit!.label;

      if (widget.birdToEdit!.additionalImages.isNotEmpty) {
        _additionalImages.addAll(
          widget.birdToEdit!.additionalImages.map((path) => File(path)),
        );
      }

      if (widget.birdToEdit!.imagePath != null &&
          widget.birdToEdit!.imagePath!.isNotEmpty) {
        _imageFile = File(widget.birdToEdit!.imagePath!);
      }
    } else {
      _birdType = widget.birdType!;
      _breed = _breedOptions[_birdType]!.first;
      _quantity = 1;
      _source = SourceType.egg;
      _date = DateTime.now();
      _gender = Gender.unknown;
      _location = '';
    }

    _filteredBreeds = _breedOptions[_birdType]!;
    // RESTORES //
    if (widget.birdToEdit != null &&
        widget.birdToEdit!.source == SourceType.store &&
        widget.birdToEdit!.isAlive == false) {
      if (widget.birdToEdit!.healthStatus == 'unviable' ||
          widget.birdToEdit!.healthStatus == 'damaged') {
        _deadStatus = widget.birdToEdit!.healthStatus;
      } else if (widget.birdToEdit!.healthStatus != null &&
          widget.birdToEdit!.healthStatus!.startsWith('damaged:')) {
        _deadStatus = 'damaged';
        _damageNotes = widget.birdToEdit!.healthStatus!.substring(8).trim();
      }
    }

    if (widget.birdToEdit != null) {
      if (!BandColor.values.contains(widget.birdToEdit!.bandColor) ||
          (widget.birdToEdit!.customBandColor != null &&
              widget.birdToEdit!.customBandColor!.isNotEmpty)) {
        _customBandColor = widget.birdToEdit!.customBandColor ?? '';
        _bandColorOrNull = null;
      } else {
        _bandColorOrNull = widget.birdToEdit!.bandColor;
      }
    } else {
      _bandColorOrNull = BandColor.none;
    }

    if (widget.birdToEdit != null &&
        widget.birdToEdit!.notes.contains('Replacement Date:')) {
      final match = RegExp(
        r'Replacement Date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})',
      ).firstMatch(widget.birdToEdit!.notes);
      if (match != null) {
        _replacementDate = DateTime.tryParse(match.group(1)!);
      }
    }

    if (widget.birdToEdit != null &&
        widget.birdToEdit!.type == BirdType.chicken) {
      final notes = widget.birdToEdit!.notes;
      if (notes.contains('Chicken Type: Layer')) {
        _chickenType = 'Layer';
      } else if (notes.contains('Chicken Type: Dual')) {
        _chickenType = 'Dual';
      }

      final breed = widget.birdToEdit!.breed;
      if (_chickenColorTypeOptions.containsKey(breed)) {
        final match = RegExp(
          '${breed.replaceAll(' ', '')} Color/Type: ([^\n]+)',
        ).firstMatch(notes);
        if (match != null) {
          _chickenColorType = match.group(1);
        }
      }
    }

    if (widget.birdToEdit != null &&
        widget.birdToEdit!.type == BirdType.duck &&
        widget.birdToEdit!.breed == 'Runner') {
      final notes = widget.birdToEdit!.notes;
      final match = RegExp(r'Runner Color/Type: ([^\n]+)').firstMatch(notes);
      if (match != null) {
        _runnerColorType = match.group(1);
      }
    }

    if (widget.birdToEdit != null &&
        widget.birdToEdit!.type == BirdType.goose &&
        widget.birdToEdit!.breed == 'Toulouse') {
      final notes = widget.birdToEdit!.notes;
      final match = RegExp(r'Toulouse Color/Type: ([^\n]+)').firstMatch(notes);
      if (match != null) {
        _toulouseColorType = match.group(1);
      }
    }
  }

  Future<void> _showImageSourceActionSheet({
    required Function(File) onImagePicked,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (!mounted) return;
                if (pickedFile != null) {
                  final cropped = await _cropImage(File(pickedFile.path));
                  if (!mounted) return;
                  if (cropped != null) onImagePicked(cropped);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (!mounted) return;
                if (pickedFile != null) {
                  final cropped = await _cropImage(File(pickedFile.path));
                  if (!mounted) return;
                  if (cropped != null) onImagePicked(cropped);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _cropImage(File imageFile) async {
    if (Platform.isWindows) {
      return imageFile;
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.brown,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<File> _persistImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'bird_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final savedImage = await imageFile.copy(path.join(appDir.path, fileName));
    return savedImage;
  }

  Future<void> _pickImage() async {
    await _showImageSourceActionSheet(
      onImagePicked: (cropped) async {
        final saved = await _persistImage(cropped);
        setState(() {
          _imageFile = saved;
        });
      },
    );
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 additional photos allowed')),
      );
      return;
    }
    await _showImageSourceActionSheet(
      onImagePicked: (cropped) async {
        final saved = await _persistImage(cropped);
        setState(() {
          _additionalImages.add(saved);
        });
      },
    );
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    String? healthStatusToSave = _healthStatus;
    if (_source == SourceType.store && _isAlive == false) {
      if (_deadStatus == 'unviable') {
        healthStatusToSave = 'unviable';
      } else if (_deadStatus == 'damaged') {
        healthStatusToSave = 'damaged: ${_damageNotes ?? ''}';
      } else {
        healthStatusToSave = null;
      }
    }

    // remove any previous replacement date from notes //
    String notesToSave = _notes.trim();
    notesToSave = notesToSave
        .replaceAll(
          RegExp(r'Replacement Date:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}\n?'),
          '',
        )
        .trim();
    // only add a new replacement date if set //
    if (_replacementDate != null) {
      final dateStr = _replacementDate!.toIso8601String().split('T').first;
      notesToSave =
          '${notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : ''}Replacement Date: $dateStr';
    }

    // add chicken type to notes if chicken is selected //
    if (_birdType == BirdType.chicken && _chickenType != null) {
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Chicken Type: (Layer|Dual)\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          'Chicken Type: $_chickenType';
    }

    // add chicken color for special breeds to notes //
    if (_birdType == BirdType.chicken &&
        _chickenColorTypeOptions.containsKey(_breed) &&
        _chickenColorType != null) {
      notesToSave = notesToSave.replaceAll(
        RegExp('${_breed.replaceAll(' ', '')} Color/Type: [^\n]+\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          '${_breed.replaceAll(' ', '')} Color/Type: $_chickenColorType';
    }

    // add runner duck color to notes if selected //
    if (_birdType == BirdType.duck &&
        _breed == 'Runner' &&
        _runnerColorType != null) {
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Runner Color/Type: [^\n]+\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          'Runner Color/Type: $_runnerColorType';
    }

    // add toulouse goose color to notes if selected //
    if (_birdType == BirdType.goose &&
        _breed == 'Toulouse' &&
        _toulouseColorType != null) {
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Toulouse Color/Type: [^\n]+\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          'Toulouse Color/Type: $_toulouseColorType';
    }

    final bird = Bird(
      id: widget.birdToEdit?.id,
      type: _birdType,
      imagePath: _imageFile?.path ?? widget.birdToEdit?.imagePath,
      breed: _breed,
      quantity: _quantity,
      source: _source,
      sourceDetail: _source == SourceType.store ? _sourceDetail : null,
      date: _date,
      arrivalDate: _source == SourceType.store ? _arrivalDate : null,
      isAlive: _isAlive,
      healthStatus: healthStatusToSave,
      gender: _gender,
      bandColor: _bandColorOrNull ?? BandColor.none,
      customBandColor: _bandColorOrNull == null ? _customBandColor : null,
      location: _location,
      notes: notesToSave,
      additionalImages: _additionalImages.map((file) => file.path).toList(),
      label: _label,
    );

    final birdsProvider = Provider.of<BirdsProvider>(context, listen: false);
    if (widget.birdToEdit != null) {
      birdsProvider.updateBird(bird);
    } else {
      birdsProvider.addBird(bird);
    }

    Navigator.of(context).pop();
  }

  Future<void> _selectDate(BuildContext context, bool isArrivalDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isArrivalDate ? _arrivalDate ?? DateTime.now() : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isArrivalDate) {
          _arrivalDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    widget.birdToEdit != null
                        ? 'Edit ${getBirdTypeName(_birdType)}'
                        : 'Add ${getBirdTypeName(_birdType)}',
                    style: TextStyle(
                      color: _customTitleColor ?? Colors.white,
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
              TapParticle(
                onTap: _saveForm,
                color: customTileGreen,
                child: IconButton(
                  icon: Icon(Icons.save, color: customTileGreen),
                  onPressed: null,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  // profile image //
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TapParticle(
                          onTap: _pickImage,
                          color: customTileGreen,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: customTileGreen.withOpacity(0.15),
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: customTileGreen,
                                  )
                                : null,
                          ),
                        ),
                        if (_imageFile != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: TapParticle(
                              color: customTileGreen,
                              onTap: () async {
                                final cropped = await _cropImage(_imageFile!);
                                if (cropped != null) {
                                  final saved = await _persistImage(cropped);
                                  setState(() {
                                    _imageFile = saved;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.crop, color: customTileGreen, size: 22),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    initialValue: _label,
                    decoration: InputDecoration(
                      labelText: 'Main Label/Name (optional)',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    style: TextStyle(color: textColor),
                    onSaved: (value) {
                      _label = value?.trim();
                    },
                  ),
                  const SizedBox(height: 8),

                  // breed dropdown //
                  DropdownButtonFormField<String>(
                    value: _filteredBreeds.contains(_breed)
                        ? _breed
                        : _filteredBreeds.first,
                    decoration: InputDecoration(
                      labelText: 'Breed',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    items: [
                      ..._filteredBreeds.map((breed) {
                        return DropdownMenuItem(
                          value: breed,
                          child: Text(
                            breed,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }),
                    ],
                    dropdownColor: isDark
                        ? const Color(0xFF222222)
                        : Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _breed = value!;
                        // resets color/type dropdowns if breed changes //
                        if (_birdType == BirdType.duck && _breed != 'Runner') {
                          _runnerColorType = null;
                        }
                        if (_birdType == BirdType.goose &&
                            _breed != 'Toulouse') {
                          _toulouseColorType = null;
                        }
                        if (_birdType == BirdType.chicken &&
                            !_chickenColorTypeOptions.containsKey(_breed)) {
                          _chickenColorType = null;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a breed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  if (_breed == 'Other')
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Custom Breed',
                        labelStyle: TextStyle(color: subtitleColor),
                      ),
                      style: TextStyle(color: textColor),
                      onSaved: (value) {
                        _breed = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a breed';
                        }
                        return null;
                      },
                    ),
                  if (_birdType == BirdType.duck && _breed == 'Runner')
                    DropdownButtonFormField<String>(
                      value: _runnerColorType,
                      decoration: InputDecoration(
                        labelText: 'Color/Type',
                        labelStyle: TextStyle(color: subtitleColor),
                        enabledBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              )
                            : null,
                        focusedBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF222222)
                          : Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'Fawn & White',
                          child: Text(
                            'Fawn & White',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Chocolate',
                          child: Text(
                            'Chocolate',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Black',
                          child: Text(
                            'Black',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Blue',
                          child: Text(
                            'Blue',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Silver',
                          child: Text(
                            'Silver',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _runnerColorType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select color/type';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 14),
                  if (_birdType == BirdType.goose && _breed == 'Toulouse')
                    DropdownButtonFormField<String>(
                      value: _toulouseColorType,
                      decoration: InputDecoration(
                        labelText: 'Color/Type',
                        labelStyle: TextStyle(color: subtitleColor),
                        enabledBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              )
                            : null,
                        focusedBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF222222)
                          : Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text(
                            'Normal',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Buff',
                          child: Text(
                            'Buff',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'French',
                          child: Text(
                            'French',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Large Dewlap',
                          child: Text(
                            'Large Dewlap',
                            style: TextStyle(color: textColor),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _toulouseColorType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select color/type';
                        }
                        return null;
                      },
                    ),
                  if (_birdType == BirdType.chicken &&
                      _chickenColorTypeOptions.containsKey(_breed))
                    DropdownButtonFormField<String>(
                      value: _chickenColorType,
                      decoration: InputDecoration(
                        labelText: 'Color/Type',
                        labelStyle: TextStyle(color: subtitleColor),
                        enabledBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              )
                            : null,
                        focusedBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF222222)
                          : Colors.white,
                      items: _chickenColorTypeOptions[_breed]!
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _chickenColorType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select color/type';
                        }
                        return null;
                      },
                    ),
                  if (_birdType == BirdType.chicken)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Chicken Type',
                          style: TextStyle(color: textColor),
                        ),
                        Row(
                          children: [
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<String>(
                                value: 'Layer',
                                groupValue: _chickenType,
                                onChanged: (value) {
                                  setState(() {
                                    _chickenType = value;
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Layer', style: TextStyle(color: textColor)),
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<String>(
                                value: 'Dual',
                                groupValue: _chickenType,
                                onChanged: (value) {
                                  setState(() {
                                    _chickenType = value;
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Dual', style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_chickenType == null || _chickenType!.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Please select chicken type',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),

                  // quantity //
                  TextFormField(
                    initialValue: _quantity.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _quantity = int.parse(value!);
                    },
                  ),

                  // source //
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Where it was from',
                        style: TextStyle(color: textColor),
                      ),
                      Row(
                        children: [
                          TapParticle(
                            color: customTileGreen,
                            onTap: null,
                            child: Radio<SourceType>(
                              value: SourceType.egg,
                              groupValue: _source,
                              onChanged: (SourceType? value) {
                                setState(() {
                                  _source = value!;
                                });
                              },
                              fillColor: _radioFillColor(
                                customTileGreen,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          Text('Egg', style: TextStyle(color: textColor)),
                          TapParticle(
                            color: customTileGreen,
                            onTap: null,
                            child: Radio<SourceType>(
                              value: SourceType.store,
                              groupValue: _source,
                              onChanged: (SourceType? value) {
                                setState(() {
                                  _source = value!;
                                });
                              },
                              fillColor: _radioFillColor(
                                customTileGreen,
                                isDark: isDark,
                              ),
                            ),
                          ),
                          Text(
                            'Breeder/Store',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_source == SourceType.store)
                        TextFormField(
                          initialValue: _sourceDetail,
                          decoration: InputDecoration(
                            labelText: 'Store/Supplier Name',
                            labelStyle: TextStyle(color: subtitleColor),
                            enabledBorder: isDark
                                ? OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                    ),
                                  )
                                : null,
                            focusedBorder: isDark
                                ? OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  )
                                : null,
                          ),
                          style: TextStyle(color: textColor),
                          onSaved: (value) {
                            _sourceDetail = value;
                          },
                          validator: (value) {
                            if (_source == SourceType.store &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter where you got the bird';
                            }
                            return null;
                          },
                        ),
                      if (_source == SourceType.egg) ...[
                        const SizedBox(height: 10),
                        Text('Status', style: TextStyle(color: textColor)),
                        Row(
                          children: [
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<bool>(
                                value: true,
                                groupValue: _isAlive,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAlive = value;
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Alive', style: TextStyle(color: textColor)),
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<bool>(
                                value: false,
                                groupValue: _isAlive,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAlive = value;
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Dead', style: TextStyle(color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: _healthStatus,
                          decoration: InputDecoration(
                            labelText: _isAlive == true
                            ? 'Health Status/Notes (sick, bumble foot, not eating, etc.)'
                            : 'Health Status/Notes (dead)',
                            labelStyle: TextStyle(color: subtitleColor),
                            enabledBorder: isDark
                                ? OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white54,
                                    ),
                                  )
                                : null,
                            focusedBorder: isDark
                                ? OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  )
                                : null,
                          ),
                          style: TextStyle(color: textColor),
                          onSaved: (value) {
                            _healthStatus = value;
                          },
                        ),
                      ],
                    ],
                  ),

                  // date //
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hatch/Order Date',
                        style: TextStyle(color: textColor),
                      ),
                      TapParticle(
                        onTap: () => _selectDate(context, false),
                        color: customTileGreen,
                        child: InputDecorator(
                          decoration: const InputDecoration(),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: textColor),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat.yMd().format(_date),
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_source == SourceType.store) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Arrival Date',
                          style: TextStyle(color: textColor),
                        ),
                        TapParticle(
                          onTap: () => _selectDate(context, true),
                          color: customTileGreen,
                          child: InputDecorator(
                            decoration: const InputDecoration(),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: textColor),
                                const SizedBox(width: 10),
                                Text(
                                  _arrivalDate == null
                                      ? 'Select arrival date'
                                      : DateFormat.yMd().format(_arrivalDate!),
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Arrival Status',
                          style: TextStyle(color: textColor),
                        ),
                        Row(
                          children: [
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<bool>(
                                value: true,
                                groupValue: _isAlive,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAlive = value;
                                    if (_isAlive != false) {
                                      _deadStatus = null;
                                      _damageNotes = null;
                                    }
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Alive', style: TextStyle(color: textColor)),
                            TapParticle(
                              color: customTileGreen,
                              onTap: null,
                              child: Radio<bool>(
                                value: false,
                                groupValue: _isAlive,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAlive = value;
                                  });
                                },
                                fillColor: _radioFillColor(
                                  customTileGreen,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            Text('Dead', style: TextStyle(color: textColor)),
                          ],
                        ),
                        if (_isAlive == false) ...[
                          Row(
                            children: [
                              TapParticle(
                                color: customTileGreen,
                                onTap: null,
                                child: Radio<String>(
                                  value: 'unviable',
                                  groupValue: _deadStatus,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _deadStatus = value;
                                      _damageNotes = null;
                                    });
                                  },
                                  fillColor: _radioFillColor(
                                    customTileGreen,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Unviable',
                                style: TextStyle(color: textColor),
                              ),
                              TapParticle(
                                color: customTileGreen,
                                onTap: null,
                                child: Radio<String>(
                                  value: 'damaged',
                                  groupValue: _deadStatus,
                                  onChanged: (String? value) {
                                    setState(() {
                                      _deadStatus = value;
                                    });
                                  },
                                  fillColor: _radioFillColor(
                                    customTileGreen,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                              Text(
                                'Damaged',
                                style: TextStyle(color: textColor),
                              ),
                            ],
                          ),
                          if (_deadStatus == 'damaged')
                            TextFormField(
                              initialValue: _damageNotes,
                              decoration: InputDecoration(
                                labelText: 'Damage Notes',
                                labelStyle: TextStyle(color: subtitleColor),
                                enabledBorder: isDark
                                    ? OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white54,
                                        ),
                                      )
                                    : null,
                                focusedBorder: isDark
                                    ? OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              style: TextStyle(color: textColor),
                              onChanged: (value) {
                                _damageNotes = value;
                              },
                              onSaved: (value) {
                                _damageNotes = value;
                              },
                              validator: (value) {
                                if (_deadStatus == 'damaged' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please describe the damage';
                                }
                                return null;
                              },
                            ),
                        ],
                      ],
                    ],
                  ),

                  // gender //
                  Text('Gender', style: TextStyle(color: textColor)),
                  Row(
                    children: [
                      TapParticle(
                        color: customTileGreen,
                        onTap: null,
                        child: Radio<Gender>(
                          value: Gender.male,
                          groupValue: _gender,
                          onChanged: (Gender? value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                          fillColor: _radioFillColor(
                            customTileGreen,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Text('Male', style: TextStyle(color: textColor)),
                      TapParticle(
                        color: customTileGreen,
                        onTap: null,
                        child: Radio<Gender>(
                          value: Gender.female,
                          groupValue: _gender,
                          onChanged: (Gender? value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                          fillColor: _radioFillColor(
                            customTileGreen,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Text('Female', style: TextStyle(color: textColor)),
                      TapParticle(
                        color: customTileGreen,
                        onTap: null,
                        child: Radio<Gender>(
                          value: Gender.unknown,
                          groupValue: _gender,
                          onChanged: (Gender? value) {
                            setState(() {
                              _gender = value!;
                            });
                          },
                          fillColor: _radioFillColor(
                            customTileGreen,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      Text('Unknown', style: TextStyle(color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // band color //
                  DropdownButtonFormField<BandColor?>(
                    value: _bandColorOrNull,
                    decoration: InputDecoration(
                      labelText: 'Band Color',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF222222)
                        : Colors.white,
                    items: [
                      ...BandColor.values.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Text(
                            color.toString().split('.').last,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }),
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'other',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _bandColorOrNull = value;
                        if (value != null) {
                          _customBandColor = null;
                        } else {
                          _customBandColor = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_bandColorOrNull == null)
                    TextFormField(
                      initialValue: _customBandColor,
                      decoration: InputDecoration(
                        labelText: 'Custom Band Color',
                        labelStyle: TextStyle(color: subtitleColor),
                        enabledBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54),
                              )
                            : null,
                        focusedBorder: isDark
                            ? OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              )
                            : null,
                      ),
                      style: TextStyle(color: textColor),
                      onChanged: (value) {
                        _customBandColor = value;
                      },
                      onSaved: (value) {
                        _customBandColor = value;
                      },
                      validator: (value) {
                        if ((_bandColorOrNull == null) &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter a band color';
                        }
                        return null;
                      },
                    ),

                  // location //
                  TextFormField(
                    initialValue: _location,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    style: TextStyle(color: textColor),
                    onSaved: (value) {
                      _location = value!;
                    },
                  ),

                  // replacement date //
                  const SizedBox(height: 10),
                  Text('Replacement Date', style: TextStyle(color: textColor)),
                  TapParticle(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _replacementDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _replacementDate = picked;
                        });
                      }
                    },
                    color: customTileGreen,
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: textColor),
                          const SizedBox(width: 10),
                          Text(
                            _replacementDate == null
                                ? 'Select replacement date'
                                : DateFormat.yMd().format(_replacementDate!),
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // notes //
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: _notes,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      labelStyle: TextStyle(color: subtitleColor),
                      enabledBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            )
                          : null,
                      focusedBorder: isDark
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            )
                          : null,
                    ),
                    style: TextStyle(color: textColor),
                    maxLines: 3,
                    onSaved: (value) {
                      _notes = value!;
                    },
                  ),

                  // additional images //
                  const SizedBox(height: 20),
                  Text(
                    'Additional Photos (up to 10)',
                    style: TextStyle(color: textColor),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      for (var imageFile in _additionalImages)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                imageFile,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            TapParticle(
                              onTap: () {
                                setState(() {
                                  _additionalImages.remove(imageFile);
                                });
                              },
                              color: customTileGreen,
                              child: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      TapParticle(
                        onTap: _pickAdditionalImage,
                        color: customTileGreen,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: customTileGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            Icons.add_a_photo,
                            color: customTileGreen,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (widget.birdToEdit != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Center(
                        child: TapParticle(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Bird'),
                                content: const Text(
                                  'Are you sure you want to delete this bird? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final birdsProvider = Provider.of<BirdsProvider>(
                                context,
                                listen: false,
                              );
                              birdsProvider.removeBird(widget.birdToEdit!.id);
                              Navigator.of(context).pop();
                            }
                          },
                          color: customTileGreen,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              'Delete Bird',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.red,
                            ),
                            onPressed: null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ParticleBurst extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final VoidCallback? onCompleted;
  const ParticleBurst({
    super.key,
    required this.color,
    this.size = 60,
    this.duration = const Duration(milliseconds: 600),
    this.onCompleted,
  });
  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward().whenComplete(() => widget.onCompleted?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _ParticlePainter(_controller.value, widget.color),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ParticlePainter(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final count = 12;
    final radius = size.width / 2 * progress;
    final paint = Paint()
      ..color = color.withOpacity(1 - progress)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * 3.14159;
      final dx = center.dx + radius * Math.cos(angle);
      final dy = center.dy + radius * Math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 4 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

class Math {
  static double cos(double x) => Math._cos(x);
  static double sin(double x) => Math._sin(x);
  static double _cos(double x) =>
      double.parse((Math._cosRaw(x)).toStringAsFixed(10));
  static double _sin(double x) =>
      double.parse((Math._sinRaw(x)).toStringAsFixed(10));
  static double _cosRaw(double x) => Math._trig(x, true);
  static double _sinRaw(double x) => Math._trig(x, false);
  static double _trig(double x, bool cos) =>
      cos ? Math._cosTaylor(x) : Math._sinTaylor(x);
  static double _cosTaylor(double x) {
    double res = 1;
    double pow = 1;
    double fact = 1;
    int sign = -1;
    for (int i = 2; i <= 10; i += 2) {
      pow *= x * x;
      fact *= i * (i - 1);
      res += sign * pow / fact;
      sign *= -1;
    }
    return res;
  }

  static double _sinTaylor(double x) {
    double res = x;
    double pow = x;
    double fact = 1;
    int sign = -1;
    for (int i = 3; i <= 11; i += 2) {
      pow *= x * x;
      fact *= i * (i - 1);
      res += sign * pow / fact;
      sign *= -1;
    }
    return res;
  }
}

class _AnimatedTapWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  const _AnimatedTapWidget({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
  });
  @override
  State<_AnimatedTapWidget> createState() => _AnimatedTapWidgetState();
}

class _AnimatedTapWidgetState extends State<_AnimatedTapWidget> {
  bool _showParticles = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _showParticles = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          setState(() => _showParticles = false);
          widget.onTap();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showParticles)
            Positioned.fill(
              child: ParticleBurst(color: widget.color, size: 60),
            ),
        ],
      ),
    );
  }
}

String getBirdTypeName(BirdType type) {
  switch (type) {
    case BirdType.chicken:
      return 'Chicken';
    case BirdType.duck:
      return 'Duck';
    case BirdType.turkey:
      return 'Turkey';
    case BirdType.goose:
      return 'Goose';
    case BirdType.other:
      return 'Other';
  }
}
