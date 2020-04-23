//
//  ActivityIndicatorView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct ActivityIndicatorView: UIViewRepresentable {

	@Binding var animating: Bool

	func makeUIView(context: Context) -> UIActivityIndicatorView {
		let view = UIActivityIndicatorView(style: .medium)
		view.hidesWhenStopped = true
		return view
	}

	func updateUIView(_ activityIndicator: UIActivityIndicatorView, context: Context) {
		animating ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
	}
}
