//
//  MobileDocEditor.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/22/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import WebKit

struct MobileDocEditor: UIViewRepresentable {

	typealias UIViewType = WKWebView

	func makeUIView(context: UIViewRepresentableContext<MobileDocEditor>) -> MobileDocEditor.UIViewType {
		let webView = WKWebView(frame: .zero)
		webView.navigationDelegate = context.coordinator
		return webView
	}

	func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<MobileDocEditor>) {

	}

	func makeCoordinator() -> MobileDocEditor.Coordinator {
		return Coordinator()
	}

	class Coordinator: NSObject, WKNavigationDelegate {

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

		}
	}
}
