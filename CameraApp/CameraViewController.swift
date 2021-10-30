//
//  FancyCamera.swift
//  CameraApp
//
//  Created by Erik Flores on 24/10/21.
//

import Foundation
import AVFoundation
import UIKit
import Photos

enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

class CameraViewController: UIViewController {
    @IBOutlet weak var shootButtonContainer: UIView! {
        didSet {
            shootButtonContainer.layer.cornerRadius = 30
            shootButtonContainer.backgroundColor = .white
        }
    }
    @IBOutlet weak var shootButton: UIButton! {
        didSet {
            shootButton.layer.cornerRadius = 25
            shootButton.layer.borderColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)
            shootButton.layer.borderWidth = 2
            shootButton.backgroundColor = .white
        }
    }
    @IBOutlet weak var cameraRotationButton: UIButton!
    @IBOutlet weak var previewImage: UIImageView! {
        didSet {
            previewImage.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var previewLayer: PreviewView!
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    var photoOutput: AVCapturePhotoOutput!
    var photoData: Data?
    let captureSession = AVCaptureSession()
    let sessionQueue = DispatchQueue(label: "session queue")
    var feedbackGenerator : UINotificationFeedbackGenerator? = nil
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    var setupResult: SessionSetupResult = .success

    override func viewDidLoad() {
        super.viewDidLoad()
        previewLayer.session = captureSession
        view.bringSubviewToFront(shootButtonContainer)
        view.bringSubviewToFront(cameraRotationButton)
        view.bringSubviewToFront(previewImage)
        sessionQueue.async {
            self.configureCaptureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let videoPreviewLayerConnection = previewLayer.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }

            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    func configureCaptureSession() {
        if setupResult != .success {
            return
        }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        addInput()
        addOutput()
    }

    func startSession() {
        sessionQueue.async {
            switch self.setupResult {
                case .success:
                    self.captureSession.startRunning()
                case .notAuthorized:
                    print("notAuthorized")
                case .configurationFailed:
                    print("configurationFailed")
            }

        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.captureSession.stopRunning()
            }
        }
    }

    func addInput() {
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async {
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if self.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    self.previewLayer.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
        } catch {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
    }

    func addOutput() {
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.maxPhotoQualityPrioritization = .quality
        } else {
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        captureSession.commitConfiguration()
    }


    @IBAction func shootAction(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto

        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @IBAction func cameraRotationAction(_ sender: Any) {
        sessionQueue.async {
            self.changeCamera()
        }
    }

    func changeCamera() {
        let currentVideoDevice = self.videoDeviceInput.device
        let currentPosition = currentVideoDevice.position

        let backVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
                                                                               mediaType: .video, position: .back)
        let frontVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
                                                                                mediaType: .video, position: .front)
        var newVideoDevice: AVCaptureDevice? = nil

        switch currentPosition {
        case .unspecified, .front:
            newVideoDevice = backVideoDeviceDiscoverySession.devices.first

        case .back:
            newVideoDevice = frontVideoDeviceDiscoverySession.devices.first

        @unknown default:
            print("Unknown capture position. Defaulting to back, dual-camera.")
            newVideoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        }
        if let videoDevice = newVideoDevice {
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.captureSession.beginConfiguration()
                self.captureSession.removeInput(self.videoDeviceInput)
                if self.captureSession.canAddInput(videoDeviceInput) {
                    self.captureSession.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    self.captureSession.addInput(self.videoDeviceInput)
                }
                self.photoOutput.maxPhotoQualityPrioritization = .quality
                self.captureSession.commitConfiguration()
            } catch {
                print("Error occurred while creating video device input: \(error)")
            }
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            feedbackGenerator = nil
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            feedbackGenerator = nil
            return
        }
        photoData = imageData
        previewImage.image = UIImage(data: imageData)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            feedbackGenerator = nil
            return
        }

        guard let photoData = photoData else {
            print("No photo data resource")
            feedbackGenerator = nil
            return
        }

        feedbackGenerator?.notificationOccurred(.success)
        feedbackGenerator?.prepare()

        savePhoto(photoData: photoData)
    }

    func savePhoto(photoData: Data) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                } completionHandler: { _, error in
                    guard error == nil else {
                        return
                    }
                }
            } else {

            }
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}
