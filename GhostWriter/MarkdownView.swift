//
//  DownView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/20/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import WebKit
import Down

struct MarkdownView: UIViewRepresentable {

	let content: String

	func makeUIView(context: Context) -> UIView {
		do {
			let downView = try DownView(frame: .zero, markdownString: content)
			downView.navigationDelegate = context.coordinator
			downView.backgroundColor = .clear
			return downView
		} catch {
			let view = UILabel(frame: .zero)
			view.text = error.localizedDescription
			return view
		}
	}

	func updateUIView(_ uiView: UIView, context: Context) {
		if let downView = uiView as? DownView {
			try? downView.update(markdownString: content)
		}
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator()
	}

	class Coordinator: NSObject, WKNavigationDelegate {

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			let cssString = "body {color: \(UIColor.label.hexString)!important;background-color: \(UIColor.systemBackground.hexString)!important;padding: 0px; font-size: 1rem;}"
			let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
			webView.evaluateJavaScript(jsString)
		}

		func hexStringFromColor(color: UIColor) -> String {
		   let components = color.cgColor.components
		   let r: CGFloat = components?[0] ?? 0.0
		   let g: CGFloat = components?[1] ?? 0.0
		   let b: CGFloat = components?[2] ?? 0.0

		   let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
		   print(hexString)
		   return hexString
		}

		func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
			if navigationAction.navigationType == .linkActivated {
				if let url = navigationAction.request.url {
					if UIApplication.shared.canOpenURL(url) {
						UIApplication.shared.open(url)
					}
					decisionHandler(.cancel)
				}
			}
			decisionHandler(.cancel)
		}
	}
}
