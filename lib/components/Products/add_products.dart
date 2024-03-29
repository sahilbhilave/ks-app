import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kisan/components/Navigation.dart';
import 'package:kisan/main.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String productName = '';
  String description = '';
  String selectedUnit = 'Per Day'; // Default value
  List<File> images = [];
  String price = '0';
  String selectedState = 'Maharashtra'; // Default state
  String selectedCity = 'Pune'; // Default city
  final ImagePicker picker = ImagePicker();
  List<String> states = ['Maharashtra'];
  Map<String, List<String>> cities = {
    'Maharashtra': ['Pune', 'Kolhapur', 'Satara'],
    // 'State 2': ['City 2A', 'City 2B', 'City 2C'],
    // 'State 3': ['City 3A', 'City 3B', 'City 3C'],
  };
  Future<void> getImages() async {
    List<XFile> selectedImages = await picker.pickMultiImage();

    print(
        "Selected Images: ${selectedImages.map((image) => image.path).toList()}");

    List<File> compressedImages = [];

    for (int i = 0; i < selectedImages.length; i++) {
      // Compress the image before adding it to the list
      File compressedImage = await _compressImage(selectedImages[i].path);
      compressedImages.add(compressedImage);
    }

    setState(() {
      images = compressedImages;
    });
  }

  Future<File> _compressImage(String imagePath) async {
    final List<int> bytes = (await FlutterImageCompress.compressWithFile(
      imagePath,
      quality: 80, // Adjust the quality as needed (0 to 100)
    )) as List<int>;

    final String path = imagePath.split('/').last;
    final File compressedImage =
        File('${(await getTemporaryDirectory()).path}/$path');
    await compressedImage.writeAsBytes(bytes);

    return compressedImage;
  }

  Future<void> uploadImagesAndSubmit() async {
    final user = supabase.auth.currentUser;
    List<String> imageUrls = [];
    if (images.isEmpty) {
      print("No images selected");
    }
    if (images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        String filename =
            '${user?.email}/${DateTime.now().millisecondsSinceEpoch}${images[i].path.split('/').last}';
        final String storageResponse =
            await supabase.storage.from('products_images').upload(
                  filename,
                  images[i],
                  fileOptions:
                      const FileOptions(cacheControl: '3600', upsert: false),
                );
        imageUrls.add(filename);
      }
    }
    final response = await supabase.from('products').upsert([
      {
        'name': user?.userMetadata?['full_name'],
        'email': user?.email,
        'product': productName,
        'description': description,
        'price': price,
        'type': selectedUnit,
        'city': selectedCity, // Replace with actual city value
        'state': selectedState, // Replace with actual state value
        'images': imageUrls,
      },
    ]);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => Navigation(
                page: 1,
              )),
    );

    if (response.error != null) {
      print('Supabase error: ${response.error!.message}');
    } else {
      print('Data inserted successfully');
    }
  }

  void removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Form'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Navigation(
                        page: 1,
                      )),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  productName = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Product Name',
                icon: Icon(Icons.shopping_bag),
              ),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  description = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Description',
                icon: Icon(Icons.description),
              ),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  price = value;
                });
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                icon: Icon(Icons.attach_money),
              ),
            ),
            DropdownButton<String>(
              value: selectedUnit,
              onChanged: (value) {
                setState(() {
                  selectedUnit = value!;
                });
              },
              items: ['Per Day', 'Per Week', 'Per Month', 'To Sell']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              hint: const Text('Select Unit'),
            ),
            DropdownButton<String>(
              value: selectedState,
              onChanged: (value) {
                setState(() {
                  selectedState = value!;
                  // Reset city when changing state
                  selectedCity = cities[selectedState]![0];
                });
              },
              items: states.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              hint: const Text('Select State'),
            ),
            DropdownButton<String>(
              value: selectedCity,
              onChanged: (value) {
                setState(() {
                  selectedCity = value!;
                });
              },
              items: cities[selectedState]!.map<DropdownMenuItem<String>>(
                (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
              hint: const Text('Select City'),
            ),
            ElevatedButton.icon(
              onPressed: getImages,
              icon: const Icon(Icons.image),
              label: const Text('Upload Images'),
            ),
            if (images.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Images:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (int i = 0; i < images.length; i++)
                    Row(
                      children: [
                        Image.file(images[i], height: 100),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            removeImage(i);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              onPressed: uploadImagesAndSubmit,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
