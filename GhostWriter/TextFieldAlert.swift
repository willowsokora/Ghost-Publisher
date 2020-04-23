//
//  TextFieldAlert.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/20/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct TextFieldAlert: UIViewControllerRepresentable {
	typealias UIViewControllerType = UIAlertController

	var title: String
	@Binding var text: String
	var callback: () -> Void

	func makeUIViewController(context: UIViewControllerRepresentableContext<TextFieldAlert>) -> UIAlertController {
		let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
			self.callback()
		})
		return alert
	}

	func updateUIViewController(_ uiViewController: UIAlertController, context: UIViewControllerRepresentableContext<TextFieldAlert>) {
		uiViewController.textFields?.first?.text = text
	}
}

