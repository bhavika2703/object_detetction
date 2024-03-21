import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rampsure/utils/app_colors.dart';
import 'package:fluttertoast/fluttertoast.dart';



// ignore: camel_case_types
class utils{

 AppBar appBarView({String? title}) {
    return AppBar(
      title:  Text(
       title ??  "OBJECT DETECTOR APP",
      ),
      elevation: 0,
    );
  }

   Future<void> loadYoloModel({vision,isLoaded}) async {
    await vision.loadYoloModel(
        labels: 'assets/labels.txt', //cattle_labels
        modelPath: 'assets/models/yolov8n.tflite', //Cattle_float16
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true);
      
       isLoaded = true;

  }


    List<dynamic> displayBoxesAroundRecognizedObjects({required Size screen,yoloResults,imageWidth,imageHeight}) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    double pady = (screen.height - newHeight) / 2;

    return yoloResults.map((result) {
      var tag = result["tag"];

      final color = tag == 'ear'
          ? Colors.orange
          : (tag == 'eye' ? Colors.blue : Colors.pink);

      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
          //  borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color:color, width: 2.0),
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

 showToast(
     {required String message,
       required ToastGravity gravity,
       required FToast fToast,
       int duration = 1}) {
   fToast.showToast(
     child: Container(
         padding: const EdgeInsets.all(6),
         decoration: BoxDecoration(
           color: AppColors.appBrown,
           borderRadius: BorderRadius.circular(8.0),
         ),
         child: Text(message, style: const TextStyle(color: Colors.white))),
     gravity: gravity,
     toastDuration: Duration(seconds: duration),
   );
 }



 // ignore: non_constant_identifier_names
  SnakBarView(BuildContext context,String message){
  return  ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                            content:
                                Text(message)),
                      );
                      
  }


  thumbnailView(File? clickImageFile,videoController,VideoPlayer){
    Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white, width: 2),
        image: clickImageFile != null
            ? DecorationImage(
          image: FileImage(clickImageFile),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: videoController != null && videoController!.value.isInitialized
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        ),
      )
          : Container(),
    );
  }

}