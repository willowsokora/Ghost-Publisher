//
//  SearchView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct SearchView: UIViewRepresentable {

	@Binding var text: String
	var placeholder: String

	class Coordinator: NSObject, UISearchBarDelegate {

		@Binding var text: String

		init(text: Binding<String>) {
			_text = text
		}

		func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
			text = searchText
		}
	}

	func makeCoordinator() -> Coordinator {
		return Coordinator(text: $text)
	}

	func makeUIView(context: Context) -> UISearchBar {
		let searchBar = UISearchBar(frame: .zero)
		searchBar.delegate = context.coordinator
		searchBar.placeholder = placeholder
		searchBar.searchBarStyle = .minimal
		searchBar.autocapitalizationType = .none
		return searchBar
	}

	func updateUIView(_ uiView: UISearchBar, context: Context) {
		uiView.text = text
	}
}
