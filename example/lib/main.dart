import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nsfw/flutter_nsfw.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    var file = File(appDocPath + "/nsfw.tflite");
    if (!file.existsSync()) {
      var data = await rootBundle.load("assets/nsfw.tflite");
      final buffer = data.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    await FlutterNsfw.initNsfw(file.path);
  }

  String imgPath = "";

  double result = 0.0;
  bool _isNSFW = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imgPath.isNotEmpty)
                Center(
                    child: Image.file(
                  File(imgPath),
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )),
              Text('The result is : $result'),
              ElevatedButton(
                child: Text('Pick image'),
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      imgPath = image.path;
                    });
                    var score = await FlutterNsfw.getPhotoNSFWScore(imgPath);
                    setState(() {
                      result = score;
                    });
                  }
                },
              ),
              Text('The video is $_isNSFW'),
              ElevatedButton(
                child: Text('Pick Video'),
                onPressed: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickVideo(source: ImageSource.gallery);
                  if (image != null) {
                    String videoPath = '';
                    setState(() {
                      videoPath = image.path;
                    });
                    bool isNSFW = await FlutterNsfw.detectNSFWVideo(
                        videoPath: videoPath, nsfwThreshold: 0.9);
                    setState(() {
                      _isNSFW = isNSFW;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
