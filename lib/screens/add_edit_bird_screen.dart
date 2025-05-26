import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show TextDirection;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';

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
  late BandColor _bandColor;
  late String _location;
  String _notes = '';

  // search //
  String _searchQuery = '';
  List<String> _filteredBreeds = [];
  List<String> _locationSuggestions = [];

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

  // Add a new field for chicken type
  String? _chickenType; // "Layer", "Dual", or null
  String? _runnerColorType; // For Runner duck
  String? _toulouseColorType; // For Toulouse goose
  String? _chickenColorType; // For special chicken breeds

  // Map of chicken breeds to their color/type options
  final Map<String, List<String>> _chickenColorTypeOptions = {
    'Orpington': [
      'Chocolate', 'Blue', 'Buff', 'Jubilee', 'Lavender', 'Black Split to Lander'
    ],
    'Ameraucana': [
      'Blue', 'Black', 'Splash'
    ],
    'Wyandotte': [
      'Blue Laced Red', 'Splashed Laced Red', 'Black Laced Red', 'Black Laced Golden', 'Black Laced Silver', 'Other'
    ],
    'Andalusian': [
      'Blue', 'Black', 'Splash'
    ],
    'Australorp': [
      'Black', 'Blue'
    ],
    'Maran': [
      'Black Copper', 'Blue Copper', 'Cuckoo', 'French Blacktailed', 'Black', 'Wheaton', 'White', 'Golden Cuckoo', 'Splash'
    ],
    'Deathlayer': [
      'Gold', 'Silver'
    ],
    'Dorking': [
      'Silver', 'Red'
    ],
    'Cochin': [
      'White', 'Partridge', 'Calico', 'Blue', 'Black', 'Barred', 'Buff', 'Bircher', 'Speckled', 'Golden Laced', 'Silver Laced', 'Splash'
    ],
    'Easter Egger': [
      'Frizzler', 'Blue', 'Green'
    ],
  };

  @override
  void initState() {
    super.initState();

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
      _bandColor = widget.birdToEdit!.bandColor;
      _location = widget.birdToEdit!.location;
      _notes = widget.birdToEdit!.notes;
    } else {
      _birdType = widget.birdType!;
      _breed = _breedOptions[_birdType]!.first;
      _quantity = 1;
      _source = SourceType.egg;
      _date = DateTime.now();
      _gender = Gender.unknown;
      _bandColor = BandColor.none;
      _location = '';
    }

    _filteredBreeds = _breedOptions[_birdType]!;
    _locationSuggestions = [];
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

    // Restore chicken type if editing and type is chicken
    if (widget.birdToEdit != null &&
        widget.birdToEdit!.type == BirdType.chicken) {
      final notes = widget.birdToEdit!.notes;
      if (notes.contains('Chicken Type: Layer')) {
        _chickenType = 'Layer';
      } else if (notes.contains('Chicken Type: Dual')) {
        _chickenType = 'Dual';
      }

      // Restore chicken color/type for special breeds
      final breed = widget.birdToEdit!.breed;
      if (_chickenColorTypeOptions.containsKey(breed)) {
        final match = RegExp('${breed.replaceAll(' ', '')} Color/Type: ([^\n]+)').firstMatch(notes);
        if (match != null) {
          _chickenColorType = match.group(1);
        }
      }
    }

    // Restore Runner duck color/type if editing
    if (widget.birdToEdit != null && widget.birdToEdit!.type == BirdType.duck && widget.birdToEdit!.breed == 'Runner') {
      final notes = widget.birdToEdit!.notes;
      final match = RegExp(r'Runner Color/Type: ([^\n]+)').firstMatch(notes);
      if (match != null) {
        _runnerColorType = match.group(1);
      }
    }

    // Restore Toulouse goose color/type if editing
    if (widget.birdToEdit != null && widget.birdToEdit!.type == BirdType.goose && widget.birdToEdit!.breed == 'Toulouse') {
      final notes = widget.birdToEdit!.notes;
      final match = RegExp(r'Toulouse Color/Type: ([^\n]+)').firstMatch(notes);
      if (match != null) {
        _toulouseColorType = match.group(1);
      }
    }
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      final allBreeds = _breedOptions.values
          .expand((list) => list)
          .toSet()
          .toList();
      _filteredBreeds = allBreeds
          .where((breed) => breed.toLowerCase().contains(query.toLowerCase()))
          .toList();
      if (_filteredBreeds.isEmpty) {
        _filteredBreeds = _breedOptions[_birdType]!;
      }
      _locationSuggestions = query.isNotEmpty ? [query] : [];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickAdditionalImage() async {
    if (_additionalImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 additional photos allowed')),
      );
      return;
    }

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _additionalImages.add(File(pickedFile.path));
      });
    }
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

    // add replacement date to notes if set //
    String notesToSave = _notes;
    if (_replacementDate != null) {
      final dateStr = _replacementDate!.toIso8601String().split('T').first;
      // remove any previous replacement date from notes
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Replacement Date:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}\n?'),
        '',
      );
      notesToSave =
          '${notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : ''}Replacement Date: $dateStr';
    }

    // Add chicken type to notes if chicken is selected
    if (_birdType == BirdType.chicken && _chickenType != null) {
      // Remove any previous chicken type from notes
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Chicken Type: (Layer|Dual)\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          'Chicken Type: $_chickenType';
    }

    // Add chicken color/type for special breeds to notes
    if (_birdType == BirdType.chicken && _chickenColorTypeOptions.containsKey(_breed) && _chickenColorType != null) {
      // Remove any previous color/type for this breed
      notesToSave = notesToSave.replaceAll(
        RegExp('${_breed.replaceAll(' ', '')} Color/Type: [^\n]+\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          '${_breed.replaceAll(' ', '')} Color/Type: $_chickenColorType';
    }

    // Add Runner duck color/type to notes if selected
    if (_birdType == BirdType.duck && _breed == 'Runner' && _runnerColorType != null) {
      notesToSave = notesToSave.replaceAll(
        RegExp(r'Runner Color/Type: [^\n]+\n?'),
        '',
      );
      notesToSave =
          (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') +
          'Runner Color/Type: $_runnerColorType';
    }

    // Add Toulouse goose color/type to notes if selected
    if (_birdType == BirdType.goose && _breed == 'Toulouse' && _toulouseColorType != null) {
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
      imagePath: _imageFile?.path,
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
    );

    final birdsProvider = Provider.of<BirdsProvider>(context, listen: false);
    if (widget.birdToEdit != null) {
      birdsProvider.updateBird(bird);
    } else {
      birdsProvider.addBird(bird);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.birdToEdit != null ? 'Edit Bird' : 'Add Bird'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // profile image //
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green[100],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.green,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // breed dropdown //
              DropdownButtonFormField<String>(
                value: _filteredBreeds.contains(_breed)
                    ? _breed
                    : _filteredBreeds.first,
                decoration: const InputDecoration(labelText: 'Breed'),
                items: [
                  ..._filteredBreeds.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _breed = value!;
                    // Reset color/type dropdowns if breed changes
                    if (_birdType == BirdType.duck && _breed != 'Runner') {
                      _runnerColorType = null;
                    }
                    if (_birdType == BirdType.goose && _breed != 'Toulouse') {
                      _toulouseColorType = null;
                    }
                    if (_birdType == BirdType.chicken && !_chickenColorTypeOptions.containsKey(_breed)) {
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
              if (_breed == 'Other')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Custom Breed'),
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
              // Move color/type dropdowns right under breed
              if (_birdType == BirdType.duck && _breed == 'Runner')
                DropdownButtonFormField<String>(
                  value: _runnerColorType,
                  decoration: const InputDecoration(labelText: 'Color/Type'),
                  items: const [
                    DropdownMenuItem(value: 'Fawn & White', child: Text('Fawn & White')),
                    DropdownMenuItem(value: 'Chocolate', child: Text('Chocolate')),
                    DropdownMenuItem(value: 'Black', child: Text('Black')),
                    DropdownMenuItem(value: 'Blue', child: Text('Blue')),
                    DropdownMenuItem(value: 'Silver', child: Text('Silver')),
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
              if (_birdType == BirdType.goose && _breed == 'Toulouse')
                DropdownButtonFormField<String>(
                  value: _toulouseColorType,
                  decoration: const InputDecoration(labelText: 'Color/Type'),
                  items: const [
                    DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'Buff', child: Text('Buff')),
                    DropdownMenuItem(value: 'French', child: Text('French')),
                    DropdownMenuItem(value: 'Large Dewlap', child: Text('Large Dewlap')),
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
              // Chicken color/type dropdown for special breeds
              if (_birdType == BirdType.chicken && _chickenColorTypeOptions.containsKey(_breed))
                DropdownButtonFormField<String>(
                  value: _chickenColorType,
                  decoration: const InputDecoration(labelText: 'Color/Type'),
                  items: _chickenColorTypeOptions[_breed]!
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
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
              // Chicken type radio buttons (Layer/Dual) for chickens only
              if (_birdType == BirdType.chicken)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text('Chicken Type'),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Layer',
                          groupValue: _chickenType,
                          onChanged: (value) {
                            setState(() {
                              _chickenType = value;
                            });
                          },
                        ),
                        const Text('Layer'),
                        Radio<String>(
                          value: 'Dual',
                          groupValue: _chickenType,
                          onChanged: (value) {
                            setState(() {
                              _chickenType = value;
                            });
                          },
                        ),
                        const Text('Dual'),
                      ],
                    ),
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
                decoration: const InputDecoration(labelText: 'Quantity'),
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
                  const Text('Where it was from'),
                  Row(
                    children: [
                      Radio<SourceType>(
                        value: SourceType.egg,
                        groupValue: _source,
                        onChanged: (SourceType? value) {
                          setState(() {
                            _source = value!;
                          });
                        },
                      ),
                      const Text('Egg'),
                      Radio<SourceType>(
                        value: SourceType.store,
                        groupValue: _source,
                        onChanged: (SourceType? value) {
                          setState(() {
                            _source = value!;
                          });
                        },
                      ),
                      const Text('Breeder/Store'),
                    ],
                  ),
                  if (_source == SourceType.store)
                    TextFormField(
                      initialValue: _sourceDetail,
                      decoration: const InputDecoration(
                        labelText: 'Store/Supplier Name',
                      ),
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
                    const Text('Status'),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _isAlive,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAlive = value;
                            });
                          },
                        ),
                        const Text('Alive'),
                        Radio<bool>(
                          value: false,
                          groupValue: _isAlive,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAlive = value;
                            });
                          },
                        ),
                        const Text('Dead'),
                      ],
                    ),
                    if (_isAlive == false)
                      TextFormField(
                        initialValue: _healthStatus,
                        decoration: const InputDecoration(
                          labelText: 'Health Status/Notes',
                        ),
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
                  const Text('Hatch/Order Date'),
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 10),
                          Text(DateFormat.yMd().format(_date)),
                        ],
                      ),
                    ),
                  ),
                  if (_source == SourceType.store) ...[
                    const SizedBox(height: 10),
                    const Text('Arrival Date'),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 10),
                            Text(
                              _arrivalDate == null
                                  ? 'Select arrival date'
                                  : DateFormat.yMd().format(_arrivalDate!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Arrival Status'),
                    Row(
                      children: [
                        Radio<bool>(
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
                        ),
                        const Text('Alive'),
                        Radio<bool>(
                          value: false,
                          groupValue: _isAlive,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAlive = value;
                            });
                          },
                        ),
                        const Text('Dead'),
                      ],
                    ),
                    if (_isAlive == false) ...[
                      Row(
                        children: [
                          Radio<String>(
                            value: 'unviable',
                            groupValue: _deadStatus,
                            onChanged: (String? value) {
                              setState(() {
                                _deadStatus = value;
                                _damageNotes = null;
                              });
                            },
                          ),
                          const Text('Unviable'),
                          Radio<String>(
                            value: 'damaged',
                            groupValue: _deadStatus,
                            onChanged: (String? value) {
                              setState(() {
                                _deadStatus = value;
                              });
                            },
                          ),
                          const Text('Damaged'),
                        ],
                      ),
                      if (_deadStatus == 'damaged')
                        TextFormField(
                          initialValue: _damageNotes,
                          decoration: const InputDecoration(
                            labelText: 'Damage Notes',
                          ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender'),
                  Row(
                    children: [
                      Radio<Gender>(
                        value: Gender.male,
                        groupValue: _gender,
                        onChanged: (Gender? value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const Text('Male'),
                      Radio<Gender>(
                        value: Gender.female,
                        groupValue: _gender,
                        onChanged: (Gender? value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const Text('Female'),
                      Radio<Gender>(
                        value: Gender.unknown,
                        groupValue: _gender,
                        onChanged: (Gender? value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const Text('Unknown'),
                    ],
                  ),
                ],
              ),

              // band color //
              DropdownButtonFormField<BandColor?>(
                value: _bandColorOrNull,
                decoration: const InputDecoration(labelText: 'Band Color'),
                items: [
                  ...BandColor.values.map((color) {
                    return DropdownMenuItem(
                      value: color,
                      child: Text(color.toString().split('.').last),
                    );
                  }),
                  const DropdownMenuItem(value: null, child: Text('other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _bandColorOrNull = value;
                    if (value != null) {
                      _bandColor = value;
                      _customBandColor = null;
                    } else {
                      _customBandColor = '';
                    }
                  });
                },
              ),
              if (_bandColorOrNull == null)
                TextFormField(
                  initialValue: _customBandColor,
                  decoration: const InputDecoration(
                    labelText: 'Custom Band Color',
                  ),
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
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (value) {
                  _location = value!;
                },
              ),

              // replacement date //
              const SizedBox(height: 10),
              const Text('Replacement Date'),
              InkWell(
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
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 10),
                      Text(
                        _replacementDate == null
                            ? 'Select replacement date'
                            : DateFormat.yMd().format(_replacementDate!),
                      ),
                    ],
                  ),
                ),
              ),

              // notes //
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
                onSaved: (value) {
                  _notes = value!;
                },
              ),

              // additional images //
              const SizedBox(height: 20),
              const Text('Additional Photos (up to 5)'),
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
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _additionalImages.remove(imageFile);
                            });
                          },
                        ),
                      ],
                    ),
                  GestureDetector(
                    onTap: _pickAdditionalImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              // Subtle delete button at the bottom if editing
              if (widget.birdToEdit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete Bird', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Bird'),
                            content: const Text('Are you sure you want to delete this bird? This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final birdsProvider = Provider.of<BirdsProvider>(context, listen: false);
                          birdsProvider.removeBird(widget.birdToEdit!.id);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
