import UIKit
import Flutter
import NSFWDetector
import AVFoundation
import PromiseKit



enum FlutterNSFWError: Error {
    case unknownMethod
}


class AssetData : Hashable {
   
    var name: String = ""
    var path: String = ""
    var avasset: AVAsset?
    var images:[UIImage]?
    var documentDirectoryPath: URL?
    var maxLabel: String = ""
    var trimmedPath: URL?
   
    static func == (lhs: AssetData, rhs: AssetData) -> Bool {
        if (lhs.name == rhs.name && lhs.path == rhs.path) {
            return true
        }
        return false
    }
   
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
}




public class SwiftFlutterNsfwPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_nsfw", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterNsfwPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do{
        switch call.method {
            case "getBitmapNSFWScore":
                guard let arguments = call.arguments as? [AnyHashable: Any] else { return }
                guard let imageData = arguments["imageData"] as? FlutterStandardTypedData else { return }
                guard let image:UIImage = UIImage(data: imageData.data) else { return }
                handleGetPhotoNSFWScore(image: image).done{ nsfwResult in
                    result(nsfwResult)
                }

            case "getPhotoNSFWScore":
                guard let arguments = call.arguments as? [AnyHashable: Any] else { return }
                guard let imagePath = arguments["filePath"] as? String else { return }
                guard let image:UIImage = UIImage(named: imagePath) else { return }
                handleGetPhotoNSFWScore(image: image).done{ nsfwResult in
                    result(nsfwResult)
                }

        
            case "detectNSFWVideo":
                guard let arguments = call.arguments as? [AnyHashable: Any] else { return }
                guard let videoPath = arguments["videoPath"] as? String else { return }
                guard let nsfwThresh = arguments["nsfwThreshold"] as? Double else { return }
                handleDetectNSFWVideo(videoPath: videoPath, nsfwThresh: nsfwThresh, completion: result)
            
            default:
                throw FlutterNSFWError.unknownMethod
        }
    } catch {
        print("FlutterNSFWError bridge error: \(error)")
        result(0)
    }
  }
    
    
    @available(iOS 12.0, *)
        func handleGetPhotoNSFWScore(image:UIImage)->Promise<Float>{
            return Promise { seal in
                let detector = NSFWDetector.shared
                detector.check(image: image, completion: { result in
                    switch result {
                    case let .success(nsfwConfidence: confidence):
                        print("Confidance",confidence)
                            seal.resolve(.fulfilled(confidence));

                    default:
                        break
                    }
                })
            

                
            }
        }


    @available(iOS 12.0, *)
        func checkImage(image:UIImage, nsfwThresh:Double)->Promise<Bool>{
            return Promise { seal in
                let detector = NSFWDetector.shared
                detector.check(image: image, completion: { result in
                    switch result {
                    case let .success(nsfwConfidence: confidence):
                        print("Is NSFW",confidence)
                        if Double(confidence) > nsfwThresh {
                            seal.resolve(.fulfilled(true));

                        } else {
                            seal.resolve(.fulfilled(false));
                        }
                    default:
                        break
                    }
                })
            

                
            }
        }
    
    
    func handleDetectNSFWVideo(videoPath:String,nsfwThresh:Double ,completion: @escaping FlutterResult){
       let assetData = AssetData()
        assetData.name = videoPath
        let avasset = AVAsset(url: URL.init(fileURLWithPath: videoPath))
        assetData.avasset = avasset
        let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: Notification.Name("SendUpdatesToUser"), object: nil, userInfo: ["text":"Will start generating frames for \(videoPath)"])
        getImagesForAssetAsynchronously(assetData: assetData,completionHandler:{ [self] assetData, result in
          if result {
           for (idx, element) in assetData.images!.enumerated() {
               do {
                  firstly{
                    checkImage(image: element,nsfwThresh:nsfwThresh)
                  }.done{ result in
                      if(result){
                          completion(result)
                      }else if idx ==  assetData.images!.endIndex-1 {
                     completion(false)
                   }
                  }

              
                   
               }
                }
          }

        })
    }
    
    func getImagesForAssetAsynchronously(assetData: AssetData, completionHandler: @escaping (AssetData, Bool)-> Void) {
       
        let duration = assetData.avasset!.duration
        let seconds = CMTimeGetSeconds(duration)
        let addition = seconds / 15
        var number = 1.0

        var times = [NSValue]()
        times.append(NSValue(time: CMTimeMake(value: Int64(number), timescale: 1)))
        while number < seconds {
            number += addition
            times.append(NSValue(time: CMTimeMake(value: Int64(number), timescale: 1)))
        }

        struct Formatter {
            static let formatter: DateFormatter = {
                let result = DateFormatter()
                result.dateStyle = .short
                return result
            }()
        }
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Notification.Name("SendUpdatesToUser"), object: nil, userInfo: ["text":"generating images for \(assetData.name)"])

        var timesCounter = 0
        let imageGenerator = AVAssetImageGenerator(asset: assetData.avasset!)
        var images:[UIImage] = []
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgImage, actualImageTime, status, error) in
           
            let seconds = CMTimeGetSeconds(requestedTime)
            let date = Date(timeIntervalSinceNow: seconds)
            let time = Formatter.formatter.string(from: date)
            timesCounter += 1
            switch status {
            case .succeeded: do {
                    if let image = cgImage {
                        //print("Generated image for approximate time: \(time)")
                        let img = UIImage(cgImage: image)
                        images.append(img)
                        notificationCenter.post(name: Notification.Name("SendUpdatesToUser"), object: nil, userInfo: ["text":"Reading data \(assetData.name) at \(seconds)s"])
                        if timesCounter >= times.count {
                            //print("got all images, set the callback")
                            assetData.images = images
                            notificationCenter.post(name: Notification.Name("SendUpdatesToUser"), object: nil, userInfo: ["text":"Finished data generation for \(assetData.name)"])
                            completionHandler(assetData, true)
                        }
                    }
                    else {
                        print("Failed to generate a valid image for time: \(time)")
                    }
                }

            case .failed: do {
                    if let error = error {
                        print("Failed to generate image with Error: \(error) for time: \(time)")
                    }
                    else {
                        print("Failed to generate image for time: \(time)")
                    }
                }

            case .cancelled: do {
                print("Image generation cancelled for time: \(time)")
                }
            @unknown default:
                print("unknown case")
            }
        }
    }
   

    
}
