import 'dart:typed_data';
import 'package:app/services/VeiculoImgService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';

class TestImageUploadPage extends StatefulWidget {
  const TestImageUploadPage({super.key});

  @override
  _TestImageUploadPageState createState() => _TestImageUploadPageState();
}

class _TestImageUploadPageState extends State<TestImageUploadPage> {
  final List<Uint8List> _additionalImages = [];
  bool _isUploading = false;

  Future<void> _pickAdditionalImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _additionalImages.add(Uint8List.fromList(bytes));
          print('Image added, size: ${bytes.length} bytes');
        });
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadAdditionalImages() async {
  final VeiculoImgService veiculoImgService = VeiculoImgService(dotenv.env['BASE_URL']!);
  
  if (_additionalImages.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No images to upload')),
    );
    return;
  }

  setState(() {
    _isUploading = true;
  });

  for (var image in _additionalImages) {
    try {
      print("Uploading additional image, size: ${image.length} bytes");
      await veiculoImgService.addImageToVehicle(34, image);
      print('Image uploaded successfully');
    } catch (error) {
      print('Failed to upload additional image: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload an image')),
      );
    }
  }

  setState(() {
    _isUploading = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Image upload process completed')),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Image Upload')),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _additionalImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.memory(_additionalImages[index]),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _additionalImages.removeAt(index);
                          print('Image removed from list');
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadAdditionalImages,
              child: _isUploading ? const CircularProgressIndicator() : const Text('Upload Images'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: _pickAdditionalImage,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
