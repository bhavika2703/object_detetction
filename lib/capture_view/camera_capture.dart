import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rampsure/utils/file_utils.dart';
import 'package:flutter_rampsure/utils/widget.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:video_player/video_player.dart';

import '../utils/app_colors.dart';


// ignore: must_be_immutable
class CameraCaptureViewScreen extends StatefulWidget {
  final FlutterVision vision;
  List<CameraDescription> cameras;
  Function(List<XFile>) captureImageFiles;

  CameraCaptureViewScreen(
      {Key? key, required this.vision, required this.cameras,required this.captureImageFiles})
      : super(key: key);

  @override
  State<CameraCaptureViewScreen> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<CameraCaptureViewScreen> {
  late CameraController controller;
  VideoPlayerController? videoController;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  File? clickImageFile;
  Uint8List? lastDetectedImage;
  bool isLoaded = false;
  bool isDetecting = false;
  int imageHeight = 1;
  int imageWidth = 1;
  List<XFile> capturedImages = [];
  bool isImageCapture = false;
  late FToast fToast;
  final RxBool _isPressed = false.obs;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    init();
  }

  init() async {
    widget.cameras = await availableCameras();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    controller.initialize().then((value) async {
      utils()
          .loadYoloModel(isLoaded: true, vision: FlutterVision())
          .then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = true;
          yoloResults = [];
        });
      });
      await startDetection();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
    videoController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    Future.delayed(const Duration(seconds: 2), () {
      _isPressed.value = false;
    });
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text('model not loaded'),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(
              controller,
            ),
          ),
          ...videoDisplayBoxesAroundRecognizedObjects(size),
          if (capturedImages.isNotEmpty) ...<Widget>[
            Positioned(
              top: MediaQuery.of(context).size.height / 19,
              right: 10,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(AppColors.appBrown),
                ),
                onPressed: () {
                  _saveImages('1');
                },
                child: const Text('Save',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
          Positioned(
            bottom: 10,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _isPressed.value = true;
                          Future.delayed(const Duration(seconds: 1));
                          isDetecting
                              ? stopDetectionCapturePhoto()
                              : startDetection();
                        });
                      },
                      autofocus: true,
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: _isPressed.isTrue ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              width: 5,
                              color: AppColors.appBrown,
                              style: BorderStyle.solid),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 8,
                ),
                if (capturedImages.isNotEmpty) ...<Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 10,
                    width: MediaQuery.of(context).size.width,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                      ),
                      itemCount: capturedImages.length,
                      itemBuilder: (context, index) {
                        final image = capturedImages[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.blueGrey, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                child: Image.file(File(image.path),
                                    fit: BoxFit.cover),
                                onTap: () {
                                  _viewImage(index);
                                },
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: SizedBox(
                                height: 25,
                                width: 25,
                                child: IconButton(
                                  //padding: const EdgeInsets.all(0),
                                  icon: const Icon(Icons.cancel,
                                      color: AppColors.appBrown),
                                  onPressed: () {
                                    _deleteImage(index);
                                  },
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deleteImage(int index) {
    setState(() {
      capturedImages.removeAt(index);
    });
  }

  void _viewImage(int index) {

  }


  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    imageHeight = cameraImage.height;
    imageWidth = cameraImage.width;
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });

    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
        Uint8List imageInUnit8List =
            image.planes.last.bytes; // store unit8List image here ;
        lastDetectedImage = imageInUnit8List;
      }
    });
    if (controller.value.isStreamingImages) {
      return;
    }
  }

  Future<void> stopDetectionCapturePhoto() async {
    await _captureImage();
    setState(() {
      yoloResults.clear();
      print('yoloResults $yoloResults');
    });

    //  await controller.stopImageStream();
    //isDetecting = false;
  }

  Future<void> _captureImage() async {
    try {
      final XFile image = await controller.takePicture();
      setState(() {
        yoloResults.clear();
        isImageCapture = true;
        capturedImages.add(image);
      });

      // await _saveImages();
    } on CameraException catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> _saveImages(String caseNo) async {
    for (var img in capturedImages) {
      //upload this images
      widget.captureImageFiles(capturedImages);
      String localName = '${DateTime.now().millisecondsSinceEpoch}_caseId_001';
      final String filePath = await FileUtils().mediaFilesForMobile(
          sourceFilePath: img.path, msgFileName: localName);

      if (filePath.isNotEmpty) {
        utils().showToast(
            message: 'image save successfully in to the gallery',
            gravity: ToastGravity.CENTER,
            fToast: fToast);
      }
    }
  }

  List<Widget> videoDisplayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    return yoloResults.map((result) {
      var tag = result["tag"];

      final color = tag == 'ear'
          ? Colors.orange
          : (tag == 'eye' ? Colors.blue : Colors.pink);
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            //borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: color, width: 2),
          ),
            child: Text(
              "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                // background: Paint()..color = colorPick,
                color: Colors.brown,
                fontSize: 15.0,
              ),
            ),
        ),
      );
    }).toList();
  }
}
