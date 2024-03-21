import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rampsure/utils/file_utils.dart';
import 'package:flutter_rampsure/utils/widget.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

enum RecordingState { stopped, recording }

// ignore: must_be_immutable
class VideoFrameViewScreen extends StatefulWidget {
  final FlutterVision vision;
  List<CameraDescription> cameras;
  Function(XFile) captureVideoFile;

  VideoFrameViewScreen({super.key, required this.vision, required this.cameras,required this.captureVideoFile});

  @override
  State<VideoFrameViewScreen> createState() => _VideoFrameViewScreenState();
}

class _VideoFrameViewScreenState extends State<VideoFrameViewScreen> {
  CameraController? controller;

  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  XFile? videoFile;
  RxBool isRecording = RxBool(false);
  late FToast fToast;
  final recordingState = RecordingState.stopped.obs;
  Timer? _timer;
  final RxInt recordingTime = RxInt(0);

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    init();
  }

  init() async {
    widget.cameras = await availableCameras();
    controller = CameraController(widget.cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    controller?.initialize().then((value) async {
      utils()
          .loadYoloModel(isLoaded: true, vision: FlutterVision())
          .then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = true;
          yoloResults = [];
        });
      });
      if (!mounted) {
        return;
      }
      setState(() {});
      await startDetection();
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
    }
  }

  @override
  void dispose() async {
    super.dispose();
    controller!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
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
            aspectRatio: controller!.value.aspectRatio,
            child: CameraPreview(
              controller!,
            ),
          ),
          ...videoDisplayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            left: MediaQuery.of(context).size.width / 2.5,
            child: Column(
              children: [
               /* Obx(
                      () => Visibility(
                    visible:isRecording.value,
                    child: Text(recordingTime.toString(),style: const TextStyle(color: Colors.white),),
                  ),
                ),*/
                Obx(
                  () {
                    return InkWell(
                      onTap: () async {
                        if (_timer?.isActive ?? false) {
                          return; // Check if a timer is already running
                        }

                        _timer = Timer(const Duration(milliseconds: 600), () {
                          if (recordingState.value == RecordingState.stopped) {
                            startRecoding();
                          } else {
                            stopRecodingAndDetection();
                          }
                          _timer = null; // Clear the timer after execution
                        });
                      },
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: recordingState.value == RecordingState.stopped
                              ? Colors.white
                              : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                              width: 5,
                              color:
                                  recordingState.value == RecordingState.stopped
                                      ? Colors.black26
                                      : Colors.white,
                              style: BorderStyle.solid),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    yoloResults.clear();
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
    if (isRecording.value) return;
    if (controller!.value.isRecordingVideo) {
      // A recording has already started, do nothing.
      return;
    }
    isRecording.value = true;
    print('isRecoding  true ');
    recordingTime.value.isNaN;
    recordingTime.value = 0;
    Timer.periodic(const Duration(seconds: 1), (_) {
      recordingTime.value++;
    });
    if (isRecording.isTrue) {
      try {
        await controller!.startVideoRecording(
          onAvailable: (image) {
            cameraImage = image;
            yoloOnFrame(image);
          },
        );
        recordingState.value = RecordingState.recording;
        utils().showToast(
            message:' recoding started',
            gravity: ToastGravity.CENTER,
            fToast: fToast);

        setState(() {
          isDetecting = true;
        });
      } on CameraException catch (e) {
        print('Error starting to record video::::: ${e.code}');
      }
    } else {
      print('isRecoding value is false');
    }
  }

  Future<void> startDetection() async {
    try {
      setState(() {
        isDetecting = true;
      });
      await controller!.startImageStream((image) async {
        if (isDetecting) {
          cameraImage = image;
          yoloOnFrame(image);
        }
      });
      if (controller!.value.isStreamingImages) {
        return;
      }
    } on CameraException catch (e) {
      print('Error Detection video:::: ${e.code}');
    }
  }

  Future<void> stopRecodingAndDetection() async {
    if (!isRecording.value) return;
    isRecording.value = false;
    print('isRecoding  false ');
    if (!controller!.value.isRecordingVideo) {
      // Recording is already is stopped state
      return;
    }
    if (isRecording.isFalse) {
      try {
        final video = await controller!.stopVideoRecording();
        recordingState.value = RecordingState.stopped;
        setState(() {
          videoFile = video;
          isDetecting = false;
          yoloResults.clear();
        });
        widget.captureVideoFile(videoFile!);
        saveVideo(videoFile!.path);
        recordingTime.value = 0;
      } on CameraException catch (e) {
        print('Error stopping video recording: $e');
        return;
      }
    }
  }

  saveVideo(String videoPath) async {
    String localName = '${DateTime.now().millisecondsSinceEpoch}_FLUT';

    final String filePath = await FileUtils()
        .videoFileSave(sourceFilePath: videoFile!.path, msgFileName: localName);
    File(videoPath).deleteSync();

    if (filePath.isNotEmpty) {
      // ignore: use_build_context_synchronously
      utils().showToast(
          message: 'video successfully save',
          gravity: ToastGravity.CENTER,
          fToast: fToast);
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
            style: TextStyle(
              color: color,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
