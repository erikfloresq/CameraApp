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
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    var stillImageOutput: AVCapturePhotoOutput!
    var stillImage: UIImage?
    var photoData: Data?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    func configure() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        currentDevice = backFacingCamera

        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }
        stillImageOutput = AVCapturePhotoOutput()

        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(stillImageOutput)

        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame

        view.bringSubviewToFront(shootButtonContainer)
        view.bringSubviewToFront(cameraRotationButton)
        captureSession.startRunning()
    }


    @IBAction func shootAction(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto

        stillImageOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    @IBAction func cameraRotationAction(_ sender: Any) {

    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        photoData = imageData
        stillImage = UIImage(data: imageData)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            //didFinish()
            return
        }

        guard let photoData = photoData else {
            print("No photo data resource")
            //didFinish()
            return
        }

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
