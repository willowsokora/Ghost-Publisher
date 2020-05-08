//
//  ImagePicker.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/23/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import SwiftUIX
import UnsplashPhotoPicker

struct ImageInfo {
	let imageURL: String
	let attribution: UnsplashUser?

	init(imageURL: String, attribution: UnsplashUser? = nil) {
		self.imageURL = imageURL
		self.attribution = attribution
	}
}

extension UnsplashUser {
	var htmlAttribution: String {
		return "Photo by <a href=\"https://unsplash.com/@\(username)?utm_source=ghost_publisher&utm_medium=referral\">\(name ?? "Anonymous")</a> on <a href=\"https://unsplash.com/?utm_source=ghost_publisher&utm_medium=referral\">Unsplash</a>"
	}
}

fileprivate struct ImagePicker: ViewModifier {

	enum ImagePickerType: String, Identifiable {
		case camera
		case library
		case unsplash

		var id: String {
			self.rawValue
		}
	}

	@Binding var isPresented: Bool
	var title = "Select an image"
	let callback: (ImageInfo) -> Void
	@State var pickerType: ImagePickerType? = nil

	func body(content: Content) -> some View {
		content
			.actionOver(presented: $isPresented, title: title, message: nil, buttons: [
				ActionOverButton(title: "Take photo", type: .normal) {
					self.pickerType = .camera
				},
				ActionOverButton(title: "Select from device", type: .normal) {
					self.pickerType = .library
				},
				ActionOverButton(title: "Select from Unsplash", type: .normal) {
					self.pickerType = .unsplash
				},
				ActionOverButton(title: nil, type: .cancel, action: nil)
			], ipadAndMacConfiguration: IpadAndMacConfiguration(anchor: nil, arrowEdge: nil))
			.sheet(item: $pickerType) { pickerType in
				SwitchOver(self.pickerType)
					.case(.camera) {
						ImagePickerView(useCamera: true, callback: self.callback)
					}
					.case(.library) {
						ImagePickerView(callback: self.callback)
					}
					.case(.unsplash) {
						UnsplashPhotoPickerView(callback: self.callback)
					}
			}
	}
}

extension View {
	func imagePicker(isPresented: Binding<Bool>, imageURL: Binding<ImageInfo?>, title: String = "Select an image") -> some View {
		self.modifier(ImagePicker(isPresented: isPresented, title: title, callback: { imageURL.wrappedValue = $0 }))
	}

	func imagePicker(isPresented: Binding<Bool>, title: String = "Select an image", callback: @escaping (ImageInfo) -> Void) -> some View {
		self.modifier(ImagePicker(isPresented: isPresented, title: title, callback: callback))
	}
}
