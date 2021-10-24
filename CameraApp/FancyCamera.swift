//
//  FancyCamera.swift
//  CameraApp
//
//  Created by Erik Flores on 24/10/21.
//

import Foundation
import AVFoundation
import UIKit

class FancyCamera: UIViewController {
    @IBOutlet weak var shootButton: UIButton!
    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    var stillImageOutput: AVCapturePhotoOutput!
    var stillImage: UIImage?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    let captureSession = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configure() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: .video, position: .unspecified)
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

        view.bringSubviewToFront(shootButton)
        captureSession.startRunning()
    }


    @IBAction func shootAction(_ sender: Any) {
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto

        stillImageOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
    }
}

extension FancyCamera: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            return
        }
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        stillImage = UIImage(data: imageData)
    }
}
