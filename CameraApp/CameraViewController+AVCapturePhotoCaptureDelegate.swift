//
//  CameraViewController+AVCapturePhotoCaptureDelegate.swift
//  CameraApp
//
//  Created by Erik Flores on 30/10/21.
//

import AVFoundation
import UIKit
import Photos

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
