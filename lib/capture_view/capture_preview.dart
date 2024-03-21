import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class FullScreenImagePage extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDelete;

  const FullScreenImagePage({
    Key? key,
    required this.imagePath,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.only(left: 10, top: 10),
          child: RawMaterialButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            elevation: 0,
            fillColor: Colors.black12,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.close,
              size: 25,
              color: AppColors.appBrown,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10, top: 10),
            child: IconButton(
              icon: const Icon(Icons.delete,
                  color: AppColors.appBrown, size: 25),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
      body: Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Center(child: Image.file(File(imagePath)))),
    );
  }
}
