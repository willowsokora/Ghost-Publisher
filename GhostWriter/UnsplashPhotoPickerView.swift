//
//  UnsplashPhotoPickerView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/23/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import UnsplashPhotoPicker

struct UnsplashPhotoPickerView: UIViewControllerRepresentable {

	typealias UIViewControllerType = UnsplashPhotoPicker

	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	let callback: (ImageInfo) -> Void

	func makeUIViewController(context: UIViewControllerRepresentableContext<UnsplashPhotoPickerView>) -> UnsplashPhotoPicker {
		guard let credentialFile = Bundle.main.path(forResource: "Unsplash", ofType: "plist"), let credentials = NSDictionary(contentsOfFile: credentialFile),
			let accessKey = credentials["ACCESS_KEY"] as? String, let secretKey = credentials["SECRET_KEY"] as? String else {
			fatalError("Failed to load Unsplash credentials, please make sure they exist correctly in Unsplash.plist")
		}
		let picker = UnsplashPhotoPicker(configuration: .init(accessKey: accessKey, secretKey: secretKey))
		picker.photoPickerDelegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UnsplashPhotoPicker, context: UIViewControllerRepresentableContext<UnsplashPhotoPickerView>) {}

	func makeCoordinator() -> Coordinator {
		return Coordinator(self)
	}

	class Coordinator: NSObject, UnsplashPhotoPickerDelegate {

		let parent: UnsplashPhotoPickerView

		init(_ parent: UnsplashPhotoPickerView) {
			self.parent = parent
		}

		func unsplashPhotoPicker(_ photoPicker: UnsplashPhotoPicker, didSelectPhotos photos: [UnsplashPhoto]) {
			if let photo = photos.first, let imageURL = photo.urls[.regular]?.absoluteString {
				parent.callback(ImageInfo(imageURL: imageURL, attribution: photo.user))
				parent.presentationMode.wrappedValue.dismiss()
			}
		}

		func unsplashPhotoPickerDidCancel(_ photoPicker: UnsplashPhotoPicker) {}
	}
}
