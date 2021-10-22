//
//  ViewController.swift
//  CameraApp
//
//  Created by Erik Flores on 21/10/21.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
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
    }

    @IBAction func shootAction(_ sender: Any) {

    }



}

