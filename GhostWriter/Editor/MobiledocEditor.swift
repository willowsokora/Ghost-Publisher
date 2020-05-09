//
//  MobiledocEditor.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 5/7/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import WebKit

struct MobiledocEditor: UIViewRepresentable {

	@Binding var mobiledoc: String
	@Binding var newCardPayload: [String: Any?]?

	func makeUIView(context: Context) -> MobiledocEditorView {
		let mobiledocEditorView = MobiledocEditorView()
		mobiledocEditorView.webView.navigationDelegate = context.coordinator
		mobiledocEditorView.webView.configuration.userContentController.add(context.coordinator, name: "postDidChange")
		mobiledocEditorView.webView.configuration.userContentController.add(context.coordinator, name: "logging")



		let headingOneItem = UIBarButtonItem(title: "H", style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleHeadingOne))
		headingOneItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 21, weight: .medium)], for: .normal)
		let headingTwoItem = UIBarButtonItem(title: "H", style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleHeadingTwo))
		headingTwoItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 19, weight: .medium)], for: .normal)

		let markupItems = [
			UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleBold)),
			UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleUnderlined)),
			UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleItalic)),
			headingOneItem,
			headingTwoItem,
			UIBarButtonItem(image: UIImage(systemName: "quote.bubble"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.toggleQuote)),
			UIBarButtonItem(image: UIImage(systemName: "link"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.insertLink)),
		]

		if UIDevice.current.userInterfaceIdiom == .phone {
			let toolbar = UIToolbar()
			var toolbarItems: [UIBarButtonItem] = [
				UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.undo)),
				UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.redo)),
				UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
			]
			toolbarItems.append(contentsOf: markupItems)
			toolbarItems.append(contentsOf: [
				UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
				UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.resign))
			])
			toolbar.items = toolbarItems
			toolbar.sizeToFit()

			mobiledocEditorView.webView.accessoryView = toolbar
		} else {
			mobiledocEditorView.webView.inputAssistantItem.trailingBarButtonGroups = [
				UIBarButtonItemGroup(barButtonItems: markupItems, representativeItem: UIBarButtonItem(image: UIImage(systemName: "textformat"), style: .plain, target: nil, action: nil))
			]
			mobiledocEditorView.webView.inputAssistantItem.leadingBarButtonGroups = [
				UIBarButtonItemGroup(barButtonItems: [
					UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.undo)),
					UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right"), style: .plain, target: mobiledocEditorView.webView, action: #selector(mobiledocEditorView.webView.redo))
				], representativeItem: UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left"), style: .plain, target: nil, action: nil))
			]
		}

		return mobiledocEditorView
	}

	func updateUIView(_ mobiledocEditorView: MobiledocEditorView, context: Context) {
		if var newCardPayload = newCardPayload, let type = newCardPayload.removeValue(forKey: "type") as? String {
			do {
				let payloadJSON = try JSONSerialization.data(withJSONObject: newCardPayload)
				mobiledocEditorView.webView.evaluateJavaScript("insertCard('\(type)', '\(payloadJSON.base64EncodedString())')")
			} catch {}
		}
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator(mobiledoc: $mobiledoc)
	}

	class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

		@Binding var mobiledoc: String

		init(mobiledoc: Binding<String>) {
			_mobiledoc = mobiledoc
		}

		func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
			//Because mobiledoc is really complex AND contains html, we need to encode to base64 before passing it to our webview
			guard let utf8Data = mobiledoc.data(using: .utf8) else { return }
			let base64String = utf8Data.base64EncodedString()
			webView.evaluateJavaScript("bootstrapEditor('\(base64String)')")
		}

		func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
			if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
				UIApplication.shared.open(url)
				decisionHandler(.cancel)
				return
			}
			decisionHandler(.allow)
		}

		func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
			if message.name == "postDidChange", let mobiledoc = message.body as? String {
				self.mobiledoc = mobiledoc
			} else if message.name == "logging" {
				print(message.body)
			} else {
				print("\(message.name): \(message.body)")
			}
		}
	}
}

class MobiledocEditorView: UIView {
	open override var inputAccessoryView: UIView? {
		get { return webView.accessoryView }
		set { webView.accessoryView = newValue }
	}

	private(set) var webView: MobiledocWebView

	var selectedRange = (x: 0, y: 0)

	public override init(frame: CGRect) {
		webView = MobiledocWebView()
		super.init(frame: frame)
		setup()
	}

	required public init?(coder aDecoder: NSCoder) {
		webView = MobiledocWebView()
		super.init(coder: aDecoder)
		setup()
	}

	private func setup() {
		webView.frame = bounds
		webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

		addSubview(webView)

		if let filePath = Bundle.main.path(forResource: "editor", ofType: "html") {
			let url = URL(fileURLWithPath: filePath, isDirectory: false)
			webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
		}
	}
}

class MobiledocWebView: WKWebView {

	var accessoryView: UIView?
	override var inputAccessoryView: UIView? {
        return accessoryView
    }

	@objc func toggleBold() {
		evaluateJavaScript("toggleMarkup('strong')")
	}

	@objc func toggleItalic() {
		evaluateJavaScript("toggleMarkup('i')")
	}

	@objc func toggleUnderlined() {
		evaluateJavaScript("toggleMarkup('u')")
	}

	@objc func toggleHeadingOne() {
		evaluateJavaScript("toggleSection('h1')")
	}

	@objc func toggleHeadingTwo() {
		evaluateJavaScript("toggleSection('h2')")
	}

	@objc func toggleQuote() {
		evaluateJavaScript("toggleSection('blockquote')")
	}

	@objc func insertLink() {
		evaluateJavaScript("prepareForLink()") { _, _ in
			let alert = UIAlertController(title: "Insert link", message: nil, preferredStyle: .alert)
			alert.addTextField { field in
				field.placeholder = "Insert link"
			}
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
			alert.addAction(UIAlertAction(title: "Insert", style: .default) { _ in
				if let textField = alert.textFields?.first, let link = textField.text {
					self.evaluateJavaScript("insertLink('\(link)')")
				}
			})
			self.nearestViewController?.present(alert, animated: true)
		}
	}

	@objc func resign() {
		resignFirstResponder()
	}

	@objc func undo() {
		evaluateJavaScript("undo()")
	}

	@objc func redo() {
		evaluateJavaScript("redo()")
	}
}
