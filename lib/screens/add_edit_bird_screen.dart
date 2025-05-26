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
      'Rhode Island Red',
      'Plymouth Rock',
      'Leghorn',
      'Sussex',
      'Other',
    ],
    BirdType.duck: ['Pekin', 'Khaki Campbell', 'Rouen', 'Muscovy', 'Other'],
    BirdType.turkey: [
      'Broad Breasted White',
      'Bourbon Red',
      'Narragansett',
      'Other',
    ],
    BirdType.goose: ['Embden', 'Toulouse', 'African', 'Chinese', 'Other'],
    BirdType.other: ['Other'],
  };

  String? _deadStatus;
  String? _damageNotes;

  String? _customBandColor;
  BandColor? _bandColorOrNull;

  DateTime? _replacementDate;

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
    if (widget.birdToEdit != null && widget.birdToEdit!.source == SourceType.store && widget.birdToEdit!.isAlive == false) {
      if (widget.birdToEdit!.healthStatus == 'unviable' || widget.birdToEdit!.healthStatus == 'damaged') {
        _deadStatus = widget.birdToEdit!.healthStatus;
      } else if (widget.birdToEdit!.healthStatus != null && widget.birdToEdit!.healthStatus!.startsWith('damaged:')) {
        _deadStatus = 'damaged';
        _damageNotes = widget.birdToEdit!.healthStatus!.substring(8).trim();
      }
    }

    if (widget.birdToEdit != null) {
      if (!BandColor.values.contains(widget.birdToEdit!.bandColor) ||
          (widget.birdToEdit!.customBandColor != null && widget.birdToEdit!.customBandColor!.isNotEmpty)) {
        _customBandColor = widget.birdToEdit!.customBandColor ?? '';
        _bandColorOrNull = null;
      } else {
        _bandColorOrNull = widget.birdToEdit!.bandColor;
      }
    } else {
      _bandColorOrNull = BandColor.none;
    }

    if (widget.birdToEdit != null && widget.birdToEdit!.notes.contains('Replacement Date:')) {
      final match = RegExp(r'Replacement Date:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})').firstMatch(widget.birdToEdit!.notes);
      if (match != null) {
        _replacementDate = DateTime.tryParse(match.group(1)!);
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
      notesToSave = notesToSave.replaceAll(RegExp(r'Replacement Date:\s*[0-9]{4}-[0-9]{2}-[0-9]{2}\n?'), '');
      notesToSave = (notesToSave.isNotEmpty ? notesToSave.trim() + '\n' : '') + 'Replacement Date: $dateStr';
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
                  const DropdownMenuItem(
                    value: null,
                    child: Text('other'),
                  ),
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
                  decoration: const InputDecoration(labelText: 'Custom Band Color'),
                  onChanged: (value) {
                    _customBandColor = value;
                  },
                  onSaved: (value) {
                    _customBandColor = value;
                  },
                  validator: (value) {
                    if ((_bandColorOrNull == null) && (value == null || value.isEmpty)) {
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
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
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
            ],
          ),
        ),
      ),
    );
  }
}
