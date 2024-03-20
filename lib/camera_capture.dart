import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rampsure/utils/file_utils.dart';
import 'package:flutter_rampsure/utils/widget.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:video_player/video_player.dart';


class CameraCaptureScreen extends StatefulWidget {
  final FlutterVision vision;
  List<CameraDescription> cameras;

  CameraCaptureScreen({Key? key, required this.vision, required this.cameras})
      : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<CameraCaptureScreen> {
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

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    widget.cameras = await availableCameras();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    controller.initialize().then((value) {
      utils()
          .loadYoloModel(isLoaded: true, vision: FlutterVision())
          .then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
      });
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
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
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
          Positioned(
            bottom: 60,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    setState(() {
                      isDetecting ? stopDetection() : startDetection();
                    });
                  },
                  icon: Icon(
                    Icons.camera_alt,
                    color: isDetecting ? Colors.green : Colors.white,
                  ),
                  iconSize: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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


  Future<void> stopDetection() async {
    await controller.stopImageStream();
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
    _captureImage();
  }

  Future<void> _captureImage() async {
    try {
      final image = await controller.takePicture();

      String localName = 'image${DateTime.now().millisecondsSinceEpoch}';

      final String filePath = await FileUtils().mediaFilesForMobile(
          sourceFilePath: image.path, msgFileName: localName);
      if (filePath.isNotEmpty) {
     await  utils().SnakBarView(context, 'Image successfully saved in gallary');
      }
    } on CameraException catch (e) {
      print('Error capturing image: $e');
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
