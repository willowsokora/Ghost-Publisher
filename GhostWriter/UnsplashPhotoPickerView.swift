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
	let callback: (String?) -> Void

	func makeUIViewController(context: UIViewControllerRepresentableContext<UnsplashPhotoPickerView>) -> UnsplashPhotoPicker {
		let credentialFile = Bundle.main.path(forResource: "Unsplash", ofType: "plist")
		let credentials = NSDictionary(contentsOfFile: credentialFile!)
		let picker = UnsplashPhotoPicker(configuration: .init(accessKey: credentials["ACCESS_KEY"]!, secretKey: credentials["SECRET_KEY"]))
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
			if let photo = photos.first {
				parent.callback(photo.urls[.regular]?.absoluteString)
				parent.presentationMode.wrappedValue.dismiss()
			}
		}

		func unsplashPhotoPickerDidCancel(_ photoPicker: UnsplashPhotoPicker) {}
	}
}
