//
//  ImagePickerView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/23/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {

	typealias UIViewControllerType = UIImagePickerController

	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	var useCamera = false
	let callback: (ImageInfo) -> Void

	func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> ImagePickerView.UIViewControllerType {
		let picker = UIImagePickerController()
		if useCamera {
			picker.sourceType = .camera
		}
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePickerView>) {

	}

	func makeCoordinator() -> ImagePickerView.Coordinator {
		return Coordinator(self)
	}

	class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

		let parent: ImagePickerView

		init(_ parent: ImagePickerView) {
			self.parent = parent
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let image = info[.originalImage] as? UIImage {
				let alert = UIAlertController(title: "Uploading...", message: nil, preferredStyle: .alert)
				let loadingIndicator = UIActivityIndicatorView(style: .large)
				loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
				alert.view.addSubview(loadingIndicator)
				let xConstraint = NSLayoutConstraint(item: loadingIndicator, attribute: .centerX, relatedBy: .equal, toItem: alert.view, attribute: .centerX, multiplier: 1, constant: 1)
				let yConstraint = NSLayoutConstraint(item: loadingIndicator, attribute: .centerY, relatedBy: .equal, toItem: alert.view, attribute: .centerY, multiplier: 1.5, constant: 1)
				NSLayoutConstraint.activate([ xConstraint, yConstraint ])
				loadingIndicator.isUserInteractionEnabled = false
				loadingIndicator.startAnimating()
				let height = NSLayoutConstraint(item: alert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100)
				alert.view.addConstraint(height)
				picker.present(alert, animated: true)
				ContentManager.instance.uploadImage(image) { imageURL, error in
					if let imageURL = imageURL {
						self.parent.callback(ImageInfo(imageURL: imageURL))
					}
					alert.dismiss()
					self.parent.presentationMode.wrappedValue.dismiss()
				}
			}
		}
	}
}
