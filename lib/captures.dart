import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rampsure/utils/file_utils.dart';
import 'package:flutter_rampsure/utils/widget.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';

// ignore: must_be_immutable
class YoloImageV8 extends StatefulWidget {
  final FlutterVision vision;
  final XFile? picture;
  final CameraDescription cameraPicture;
  CameraController? controller;
  final List<CameraDescription> cameras;

  YoloImageV8(
      {Key? key,
      required this.vision,
      this.picture,
      required this.cameraPicture,
      this.controller,
      required this.cameras})
      : super(key: key);

  @override
  State<YoloImageV8> createState() => _YoloImageV8State();
}

class _YoloImageV8State extends State<YoloImageV8> {
  late List<Map<String, dynamic>> yoloResults;
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;
  bool isCamera = false;
  bool isDetecting = false;
  bool onPickImageTap = false;

  @override
  void initState() {
    super.initState();
    utils()
        .loadYoloModel(vision: FlutterVision(), isLoaded: true)
        .then((value) {
      setState(() {
        yoloResults = [];
        isLoaded = true;
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    widget.controller!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
        // appBar: AppBar(
        //   backgroundColor: Color.fromRGBO(0, 179, 226, 0.4),
        //   title: const Text(
        //     "Home",
        //   ),
        //   elevation: 2,
        // ),
        backgroundColor: Colors.grey[80],
        body: Stack(
          fit: StackFit.expand,
          children: [
            imageFile != null
                ? Image.file(imageFile!)
                : TextButton(
                    onPressed: pickImage,
                    child: const Text(
                      'Pick from Gallery',
                      style: TextStyle(
                          fontSize: 23, color: Color.fromRGBO(0, 0, 0, 0.6)),
                    )),
            ...utils().displayBoxesAroundRecognizedObjects(
              screen: size,
              imageHeight: imageHeight,
              imageWidth: imageWidth,
              yoloResults: yoloResults,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  imageFile != null
                      ? TextButton(
                          onPressed: yoloOnImage,
                          child: const Text(
                            'Detect',
                            style: TextStyle(
                                fontSize: 23,
                                color: Color.fromRGBO(22, 141, 173, 0.694)),
                          ))
                      : const SizedBox(),
                  TextButton(
                      onPressed: () async {
                        if (imageFile != null) {
                          final path = await gallaryMergeAndSaveImage();
                          if (path.isNotEmpty) {
                            // ignore: use_build_context_synchronously
                            utils().SnakBarView(
                                context, 'Image successfully saved in gallary');
                          }
                          yoloResults.clear();
                        }
                      },
                      child: const Text(
                        'Downlod',
                        style: TextStyle(
                            fontSize: 23,
                            color: Color.fromRGBO(22, 141, 173, 0.694)),
                      )),
                ],
              ),
            ),
          ],
        ));
  }

  Future<void> pickImage() async {
    yoloResults.clear();
    onPickImageTap = true;
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (photo != null) {
      setState(() {
        imageFile = File(photo.path);
      });
    }
  }

  yoloOnImage() async {
    Uint8List byte = await imageFile!.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight =  image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
      bytesList: byte,
      imageHeight: image.height,
      imageWidth: image.width,
    );
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    } else {
      const AlertDialog(content: Text("Plase select image first"));
    }
  }

  gallaryMergeAndSaveImage() async {
    try {
      String localName = 'image${DateTime.now().millisecondsSinceEpoch}';

      final String filePath = await FileUtils().mediaFilesForMobile(
          sourceFilePath: imageFile!.path, msgFileName: localName);

      // await ImageGallerySaver.saveImage(pngBytes);

      return filePath;
    } catch (e) {
      print(e);
      return "";
    }
  }
}
