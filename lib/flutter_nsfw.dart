import 'dart:async';

import 'package:flutter/services.dart';

class FlutterNsfw {
  static const MethodChannel _channel = MethodChannel('flutter_nsfw');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  ///initialization
  /// [modelPath] Model path is required for android only you can either choose to upload model in you asset folder or upload in firebse ml
  /// [enableLog] Whether to enable log
  /// [isOpenGPU] Whether to enable GPU scanning acceleration, some models that are compatible and unfriendly can be turned off. On by default
  /// [numThreads] Internally allocated threads when scanning data. Default 4
  static Future<void> initNsfw(
    String modelPath, {
    bool enableLog = true,
    bool isOpenGPU = true,
    int numThreads = 4,
  }) async {
    await _channel.invokeMethod('initNsfw', {
      "modelPath": modelPath,
      "enableLog": enableLog,
      "isOpenGPU": isOpenGPU,
      "numThreads": numThreads,
    });
  }

  ///Call to get the result
  ///
  /// [filePath] Picture file url
  static Future<dynamic> getPhotoNSFWScore(String filePath) async {
    final result = await _channel.invokeMethod('getPhotoNSFWScore', {
      "filePath": filePath,
    });
    return result;
  }

  ///Call to detect weather video is NSFW or not
  ////// [videoPath] Video file url
  //// [nsfwThreshold] minimum treshold above which to classify as NSFW like 0.7
  ////[frameWidth] frame width while detecting nsfw
  //// [frameHeight] frame height while detecting nsfw
  //// [durationPerFrame] duration per frame while detecting nsfw
  static Future<dynamic> detectNSFWVideo({
    required String videoPath,
    required double nsfwThreshold,
    int frameWidth = 200,
    int frameHeight = 300,
    int durationPerFrame = 6000,
  }) async {
    final result = await _channel.invokeMethod('detectNSFWVideo', {
      "videoPath": videoPath,
      "nsfwThreshold": nsfwThreshold,
      "frameWidth": frameWidth,
      "frameHeight": frameHeight,
      "durationPerFrame": durationPerFrame,
    });
    return result;
  }
}
