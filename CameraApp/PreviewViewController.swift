//
//  PreviewViewController.swift
//  CameraApp
//
//  Created by Erik Flores on 30/10/21.
//

import UIKit

class PreviewViewController: UIViewController {

    var previewImage: UIImageView? {
        didSet {
            previewImage?.contentMode = .scaleAspectFit
            previewImage?.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    override func loadView() {
        super.loadView()
        view.backgroundColor = .systemBackground
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addShareButton()
        if let previewImage = previewImage {
            add(imageView: previewImage)
        }
    }

    func add(imageView: UIImageView) {
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func addShareButton() {
        let sharedButton = UIImage(systemName: "square.and.arrow.up")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: sharedButton, style: .plain, target: self, action: #selector(showShareActions(_:)))
    }

    @objc
    func showShareActions(_ sender: UIBarButtonItem) {
        var itemsToShare: [Any] = []
        if let imageToShare = previewImage?.image {
            itemsToShare.append(imageToShare)
        }
        let sharedViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        present(sharedViewController, animated: true, completion: nil)
    }

}
