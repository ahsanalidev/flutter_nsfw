
# Flutter NSFW

 [![](https://img.shields.io/badge/Base-TensorFlow-brightgreen.svg)](https://github.com/ahsanalidev/flutter_nsfw) 
[![License](https://img.shields.io/badge/License-BSD%203--Clause-orange.svg)](https://opensource.org/licenses/BSD-3-Clause)
  

- 1- [Download](https://github.com/devzwy/open_nsfw_android/blob/dev/app/src/main/assets/nsfw.tflite), tflite modle and put it in assets folder
- 2 - Add the path of the tfliet to pubspec.yaml
- 3 - Read the file using path_provider plugin
- 4 -  Initialize the plugin before use as 
```
Directory  appDocDir = await  getApplicationDocumentsDirectory();
String  appDocPath = appDocDir.path;
var  file = File(appDocPath + "/nsfw.tflite");
if (!file.existsSync()) {
var  data = await  rootBundle.load("assets/model/nsfw.tflite");
final  buffer = data.buffer;
await  file.writeAsBytes(
buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}
await  FlutterNsfw.initNsfw(file.path);
```

5 - get photo NSFW probability
  

```
  FlutterNsfw.getPhotoNSFWScore(photoPath);
```

  
6 - Get video NSFW probability by providing video path and NSFW threshold above which to classify video as nsfw you may choose to enter optional parameters too. 
  

```
FlutterNsfw.detectNSFWVideo(
videoPath: videoPath,
nsfwThreshold: 0.9,
durationPerFrame: 1000);
```

  

