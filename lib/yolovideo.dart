import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_rampsure/utils/widget.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:video_player/video_player.dart';


// ignore: must_be_immutable
class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  List<CameraDescription> cameras;
  YoloVideo({Key? key, required this.vision, required this.cameras})
      : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  CameraController? controller;

  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  XFile? videoFile;
  bool isRecording =false;


  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //await Permission.storage.request();
    widget.cameras = await availableCameras();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    controller?.initialize().then((value) {
      utils().loadYoloModel(isLoaded: true,vision: FlutterVision()).then((value) {
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
    controller?.dispose();
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
            aspectRatio: controller!.value.aspectRatio,
            child: CameraPreview(
              controller!,
            ),
          ),
          ...videoDisplayBoxesAroundRecognizedObjects(size),
         /* Positioned(
            top:40,
            width: MediaQuery.of(context).size.width,
            child: TextButton(
              child: Text('Start Detection'),
              onPressed: () {
                startDetection();
              },
            ),
          ),*/
          Positioned(
            bottom: 75,
            width: MediaQuery.of(context).size.width,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    width: 5, color: Colors.white, style: BorderStyle.solid),
              ),
              child: isDetecting
                  ? IconButton(
                onPressed: () async {
                  stopDetection();
                },
                icon: const Icon(
                  Icons.stop,
                  color: Colors.red,
                ),
                iconSize: 50,
              )
                  : IconButton(
                onPressed: () async {
                  await startRecoding();
                },
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                ),
                iconSize: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> yoloOnFrame(CameraImage cameraImage) async {
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

  Future<void> startRecoding() async {
    setState(() {
      isDetecting = true;
    });
      if (isRecording) {
        return; // Prevent starting recording simultaneously
      }
    // Start recording without any additional arguments
    await controller!.startVideoRecording();

    setState(() {
      isRecording = true;
    });
  /*  if (controller!.value.isStreamingImages) {
      return;
    }
    await controller!.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });*/
  }

  Future<void> startDetection() async {
    if (controller!.value.isStreamingImages) {
      return;
    }
    await controller!.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });

    //if (isRecording) {
      final video =  await controller!.stopVideoRecording();
      setState(() {
        videoFile = video;
        isRecording = false;
      });
    print('stop video $video');
    final result = await ImageGallerySaver.saveFile(videoFile!.path);
      print('result  of the saving $result');
      if (result !=null) {
      // ignore: use_build_context_synchronously
      utils().SnakBarView(
          context, 'Video successfully saved in gallary');}
      File(video.path).deleteSync();
   // }

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
            border: Border.all(color: color,width: 2),
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
