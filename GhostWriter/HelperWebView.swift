//
//  HelperWebView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/20/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import WebKit

struct HelperWebView: UIViewRepresentable {

	let post: BlogPost
	@Binding var content: String

	func makeUIView(context: Context) -> WKWebView {
		let webView = WKWebView()
		webView.loadHTMLString("<div id=\"core\">\(post.htmlContent)</div>", baseURL: nil)
		webView.navigationDelegate = context.coordinator
		return webView
	}

	func updateUIView(_ uiView: WKWebView, context: Context) { }

	func makeCoordinator() -> Coordinator {
		return Coordinator(content: $content)
	}

	class Coordinator: NSObject, WKNavigationDelegate {

		@Binding var content: String

		init(content: Binding<String>) {
			_content = content
		}

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			if let turndown = Bundle.main.path(forResource: "turndown", ofType: "js") {
				do {
					let turndownContents = try String(contentsOfFile: turndown, encoding: .utf8)
					webView.evaluateJavaScript(turndownContents) { result, error in
						if let content = result as? String {
							self.content = content
						}
						if let error = error {
							print(error)
						}
					}
				} catch {
					print(error)
				}
			}
		}
	}
}
