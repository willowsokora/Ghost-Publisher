//
//  ImagePicker.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/23/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import SwiftUIX

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
	let callback: (String?) -> Void
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
	func imagePicker(isPresented: Binding<Bool>, imageURL: Binding<String?>, title: String = "Select an image") -> some View {
		self.modifier(ImagePicker(isPresented: isPresented, title: title) { imageURL.wrappedValue = $0 })
	}

	func imagePicker(isPresented: Binding<Bool>, title: String = "Select an image", callback: @escaping (String?) -> Void) -> some View {
		self.modifier(ImagePicker(isPresented: isPresented, title: title, callback: callback))
	}
}
