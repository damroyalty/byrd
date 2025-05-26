import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bird.dart';
import '../providers/birds_provider.dart';
import 'add_edit_bird_screen.dart';

class BirdListScreen extends StatefulWidget {
  final BirdType birdType;

  const BirdListScreen({super.key, required this.birdType});

  @override
  State<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends State<BirdListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final birds = Provider.of<BirdsProvider>(context).getBirdsByType(widget.birdType);
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
        : birds.where((b) =>
            b.breed.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            b.location.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${bird.typeName}s'),
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
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.trim();
                  });
                },
                onSubmitted: (query) {
                  setState(() {
                    _searchQuery = query.trim();
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
                    if (bird.isAlive == false && bird.healthStatus != null && bird.healthStatus!.isNotEmpty) {
                      statusDetails = bird.healthStatus;
                    }
                    String? customBandColor;
                    if (bird.notes.contains('Custom Band Color:')) {
                      customBandColor = bird.notes.split('Custom Band Color:').last.trim().split('\n').first.trim();
                    }
                    return ListTile(
                      leading: bird.imagePath != null
                          ? CircleAvatar(
                              backgroundImage: FileImage(File(bird.imagePath!)),
                            )
                          : const CircleAvatar(child: Icon(Icons.pets)),
                      title: Text(bird.location.isNotEmpty ? bird.location : 'No Location/Pin'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Breed: ${bird.breed}\nQty: ${bird.quantity} • ${bird.gender.toString().split('.').last}'),
                          if (statusDetails != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'Status: $statusDetails',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        (bird.customBandColor != null && bird.customBandColor!.isNotEmpty)
                          ? bird.customBandColor!
                          : bird.bandColor.toString().split('.').last
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditBirdScreen(birdToEdit: bird),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: $totalQuantity',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditBirdScreen(birdType: widget.birdType),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
