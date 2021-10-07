package dev.ahsanaliflutter.flutter_nsfw
import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.github.devzwy.nsfw.NSFWHelper
import com.momentolabs.frameslib.Frames
import com.momentolabs.frameslib.data.model.FrameRetrieveRequest
import com.momentolabs.frameslib.data.model.Status
import java.io.File

/** FlutterNsfwPlugin */
class FlutterNsfwPlugin: FlutterPlugin, MethodCallHandler {
  private var mContext: Context? = null


  private lateinit var channel : MethodChannel

   override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_nsfw")
        channel.setMethodCallHandler(this)
        Log.d("TAG", "onAttachedToEngine: ")
        this.mContext = flutterPluginBinding.applicationContext

    }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Log.d("TAG", "onMethodCall: ${call.method}")
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "initNsfw" -> {
        handleInitNsfw(call, result)
      }
      "getPhotoNSFWScore" -> {
        handlegetPhotoNSFWScore(call, result)
      }
      "detectNSFWVideo" -> {
        handledetectNSFWVideo(call,result)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun handlegetPhotoNSFWScore(call: MethodCall, result: MethodChannel.Result) {
    val filePath: String? = call.argument<String>("filePath")
    if (filePath != null) {
      val file = File(filePath)
      NSFWHelper.getNSFWScore(file) {
        val data = "nsfw:${it.nsfwScore}\nsfw:${it.sfwScore}\nScanning time：${it.timeConsumingToScanData} ms"
        Log.d("TAG", "handleNSFW: $data")

        result.success(it.nsfwScore)
      }
    } else {
      result.success(0.0)
    }

  }

  /**
   * initialization
   */
  private fun handleInitNsfw(call: MethodCall, result: MethodChannel.Result) {
    val enableLog = call.argument<Boolean>("enableLog") ?: true
    val isOpenGPU:Boolean = call.argument<Boolean>("isOpenGPU") ?: true
    val modelPath:String = call.argument<String>("modelPath") ?: return
    val numThreads = call.argument<Int>("numThreads") ?: 4

    if (enableLog) {
      NSFWHelper.openDebugLog()
    }


    //before calling the detector
    NSFWHelper.initHelper(
            context = mContext!!,
            isOpenGPU = isOpenGPU,
            modelPath = modelPath,
            numThreads = numThreads
    )

    result.success(true)

  }

  private fun handledetectNSFWVideo(call: MethodCall, result: MethodChannel.Result) {
    val nsfwThreshold:Double = call.argument<Double>("nsfwThreshold") ?: 0.7
    val durationPerFrame:Int = call.argument<Int>("durationPerFrame") ?: 6000

    try {
      val multiFrameRequest = FrameRetrieveRequest.MultipleFrameRequest(
        videoPath = call.argument<String>("videoPath") ?: return,
        frameWidth = call.argument<Int>("frameWidth") ?: 200,
        frameHeight = call.argument<Int>("frameHeight") ?: 300,
        durationPerFrame = durationPerFrame.toLong()
      )
      Frames
        .load(multiFrameRequest)
        .into { framesResource ->
          if (framesResource.status == Status.COMPLETED) {
            framesResource.frames.forEach frames@{
              val bitmap: Bitmap? = it.bitmap
                NSFWHelper.getNSFWScore(bitmap!!).let {
                  nsfwResult ->
                  if (nsfwResult.nsfwScore > nsfwThreshold.toFloat()) {
                 Log.d(
                     "IFCONDITION",
                     "If Condition The image has a NSFW score of ${nsfwResult.nsfwScore.toString()}"
                        )
                    result.success(true)
                    return@frames
                  } else {
                    if(it.frameIndex==framesResource.frames.lastIndex){
                      result.success(false)
                    }
                    Log.d(
                      "ELSECONDITION",
                      "Else Condition this is the frame index ${it.frameIndex} and this is the frames length ${framesResource.frames.size} and nsfw score is ${nsfwResult.nsfwScore.toString()}"
                    )


                  }
                }




            }
          }
        }

    } catch (e: Exception) {
      result.error("NSFWDetectorError", e.localizedMessage, e.cause)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    Log.d("TAG", "onDetachedFromEngine: ")
    mContext = binding.applicationContext
  }
}
