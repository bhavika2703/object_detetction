// ignore: file_names
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rampsure/captures.dart';
import 'package:flutter_rampsure/yolovideo.dart';

import 'package:flutter_vision/flutter_vision.dart';

import 'capture_view/camera_capture.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
    this.picture,
    required this.cameras,
  }) : super(key: key);

  final XFile? picture;
  final List<CameraDescription> cameras;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late FlutterVision vision;
  late CameraController controller;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeTesseractModel();

    await vision.closeYoloModel();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/bg.jpg',fit: BoxFit.cover,height: MediaQuery.of(context).size.height,),
            Center(
              child: TextButton(
                onPressed: () {
                  showImagePickerOption(context);
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18.0), // Custom border radius
                        side:
                            const BorderSide(color: Colors.white), // Custom border color
                      ),
                    ),
                    backgroundColor: MaterialStateProperty.all(Colors.grey[90])),
                child:  const Text(
                  "Select an options",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 17, color: Colors.brown),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.blue[20],
        context: context,
        builder: (builder) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4.5,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return YoloImageV8(
                            controller: controller,
                            vision: vision,
                            picture: widget.picture,
                            cameraPicture: widget.cameras[0],
                            cameras: widget.cameras,
                          );
                        }));
                      },
                      child:   SizedBox(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.image,
                              size: 70,
                              color: Colors.brown,
                            ),
                            Text("Gallery",style: TextStyle(color: Colors.purple.shade500))
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CameraCaptureViewScreen(
                                      vision: vision, cameras: widget.cameras,
                                  captureImageFiles: (captureImage) {

                                  },
                                    )));
                      },
                      child:  SizedBox(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 70,
                              color: Colors.brown,
                            ),
                            Text("Camera",style: TextStyle(color: Colors.purple.shade500))
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => YoloVideo(
                                      vision: vision,
                                      cameras: widget.cameras,
                                    )));
                      },
                      child:  SizedBox(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.video_file_rounded,
                              size: 70,
                              color: Colors.brown,
                            ),
                            Text("Video frame",style: TextStyle(color: Colors.purple.shade500),)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
