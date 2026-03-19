package app.tubestr.mobile

import android.util.Log
import com.alexmercerind.media_kit_libs_android_video.MediaKitLibsAndroidVideoPlugin
import com.alexmercerind.media_kit_video.MediaKitVideoPlugin
import com.antonkarpenko.ffmpegkit.FFmpegKitFlutterPlugin
import com.google_mlkit_commons.GoogleMlKitCommonsPlugin
import com.google_mlkit_face_detection.GoogleMlKitFaceDetectionPlugin
import com.google_mlkit_selfie_segmentation.GoogleMlKitSelfieSegmentationPlugin
import com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin
import com.llfbandit.app_links.AppLinksPlugin
import com.ryanheise.audio_session.AudioSessionPlugin
import com.ryanheise.just_audio.JustAudioPlugin
import dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin
import dev.fluttercommunity.plus.share.SharePlusPlugin
import dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin
import dev.steenbakker.mobile_scanner.MobileScannerPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.camerax.CameraAndroidCameraxPlugin
import io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin
import io.flutter.plugins.inapppurchase.InAppPurchasePlugin
import io.flutter.plugins.pathprovider.PathProviderPlugin
import xyz.justsoft.video_thumbnail.VideoThumbnailPlugin

object AppPluginRegistrant {
    private const val TAG = "AppPluginRegistrant"

    fun registerWith(flutterEngine: FlutterEngine) {
        flutterEngine.plugins.add(AppLinksPlugin())
        flutterEngine.plugins.add(AudioSessionPlugin())
        flutterEngine.plugins.add(CameraAndroidCameraxPlugin())

        try {
            flutterEngine.plugins.add(FFmpegKitFlutterPlugin())
        } catch (throwable: Throwable) {
            Log.e(TAG, "Error registering FFmpegKitFlutterPlugin", throwable)
        }

        flutterEngine.plugins.add(FlutterAndroidLifecyclePlugin())
        flutterEngine.plugins.add(FlutterSecureStoragePlugin())
        flutterEngine.plugins.add(GoogleMlKitCommonsPlugin())
        flutterEngine.plugins.add(GoogleMlKitFaceDetectionPlugin())
        flutterEngine.plugins.add(GoogleMlKitSelfieSegmentationPlugin())
        flutterEngine.plugins.add(InAppPurchasePlugin())
        flutterEngine.plugins.add(JustAudioPlugin())
        flutterEngine.plugins.add(MediaKitLibsAndroidVideoPlugin())
        flutterEngine.plugins.add(MediaKitVideoPlugin())
        flutterEngine.plugins.add(MobileScannerPlugin())
        flutterEngine.plugins.add(PackageInfoPlugin())
        flutterEngine.plugins.add(PathProviderPlugin())
        flutterEngine.plugins.add(SharePlusPlugin())
        flutterEngine.plugins.add(VideoThumbnailPlugin())
        flutterEngine.plugins.add(WakelockPlusPlugin())
    }
}
