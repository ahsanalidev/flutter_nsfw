
# Flutter NSFW

 [![](https://img.shields.io/badge/Base-TensorFlow-brightgreen.svg)](https://github.com/ahsanalidev/flutter_nsfw) 
[![License](https://img.shields.io/badge/License-BSD%203--Clause-orange.svg)](https://opensource.org/licenses/BSD-3-Clause)

  

- 1- [Download](https://github.com/devzwy/open_nsfw_android/blob/dev/app/src/main/assets/nsfw.tflite), tflite model and put it in the assets folder
- 2 - Add the path of the tflite model to pubspec.yaml
- 3 - Read the file using path_provider plugin
- 4 - Make a seperate class for accessing the NSFW detector as
``` dart
class NSFWDetector {
  NSFWDetector(this.modelPath, this.enableLog, this.isOpenGPU, this.numThreads);

  final String modelPath;
  final bool enableLog;
  final bool isOpenGPU;
  final int numThreads;

  bool isInitialized = false;

  Future<dynamic> detectInPhoto(String photoPath) async {
    if (!isInitialized) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      var file = File(appDocPath + "/nsfw.tflite");
      if (!file.existsSync()) {
        var data = await rootBundle.load("assets/nsfw.tflite");
        final buffer = data.buffer;
        await file.writeAsBytes(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      await FlutterNsfw.initNsfw(
        file.path,
      );
      isInitialized = true;
    }

    return FlutterNsfw.getPhotoNSFWScore(photoPath);
  }

  Future<dynamic> detectVideo(
    String videoPath,
    double nsfwThreshold,
    int width,
    int height,
  ) async {
    if (!isInitialized) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      var file = File(appDocPath + "/nsfw.tflite");
      if (!file.existsSync()) {
        var data = await rootBundle.load("assets/nsfw.tflite");
        final buffer = data.buffer;
        await file.writeAsBytes(
            buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      await FlutterNsfw.initNsfw(
        file.path,
      );
      isInitialized = true;
    }
    final result = await FlutterNsfw.detectNSFWVideo(
        videoPath: videoPath,
        nsfwThreshold: nsfwThreshold,
        frameWidth: width,
        frameHeight: height,
        durationPerFrame: 1000);
    if (result != null) {
      print('the result is true');
      return result as bool;
    } else {
      print('this result is false');
      return false;
    }
  }
}
```

- 5 - Initiate the instance of the class that you have previously made 
``` dart
  NSFWDetector _nsfwDetector =
      NSFWDetector('assets/nsfw.tflite', true, true, 2);
```

- 6 - Make helper method for detecting nsfw photo, 
``` dart
  Future<dynamic> detectNSFWImage(String photo) async {
    final nsfwStatus = await _nsfwDetector.detectInPhoto(photo);
    if (nsfwStatus > 0.80) {
      return true;
    } else {
      return false;
    }
  }

```
- 7 - Make helper mothod for detecting NSFW video,
``` dart
  Future<dynamic> detectNSFWVideo(String video, int width, int height) async {
    final nsfwStatus =
        await _nsfwDetector.detectVideo(video, 0.70, width, height);
    return nsfwStatus ?? false;
  }
```


If you find that the model is increasing your App Size you can also host your model Firebase ML kit
If you are using running the example app on emulator so it might not work because of GPU constraints please use a real device.
  

