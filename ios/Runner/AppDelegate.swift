import Flutter
import Vision
import CoreImage
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    SelfieSubjectLiftingPlugin.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "SelfieSubjectLiftingPlugin")
    )
  }
}

final class SelfieSubjectLiftingPlugin: NSObject {
  private static let channelName = "app.tubestr/selfie_subject_lifting"
  private let ciContext = CIContext()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = SelfieSubjectLiftingPlugin()
    channel.setMethodCallHandler(instance.handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "extractStickerPng" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard
      let arguments = call.arguments as? [String: Any],
      let imagePath = arguments["imagePath"] as? String
    else {
      result(
        FlutterError(
          code: "bad_args",
          message: "Missing imagePath for selfie subject lifting.",
          details: nil
        )
      )
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let pngData = self.extractStickerPng(imagePath: imagePath)
      DispatchQueue.main.async {
        if let pngData {
          result(FlutterStandardTypedData(bytes: pngData))
        } else {
          result(nil)
        }
      }
    }
  }

  private func extractStickerPng(imagePath: String) -> Data? {
    guard #available(iOS 17.0, *) else {
      return nil
    }
    guard
      let ciImage = CIImage(
        contentsOf: URL(fileURLWithPath: imagePath),
        options: [.applyOrientationProperty: true]
      )
    else {
      return nil
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

    do {
      try handler.perform([request])
      guard
        let observation = request.results?.first as? VNInstanceMaskObservation
      else {
        return nil
      }

      let maskedPixelBuffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: true
      )
      let maskedImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
      guard let cgImage = ciContext.createCGImage(maskedImage, from: maskedImage.extent) else {
        return nil
      }
      return UIImage(cgImage: cgImage).pngData()
    } catch {
      return nil
    }
  }
}
