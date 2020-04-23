//
//  KeyboardAdapter.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import Combine

struct KeyboardAdapter: ViewModifier {
	@State var currentHeight: CGFloat = 0

	func body(content: Content) -> some View {
		GeometryReader { geometry in
			content
			.padding(.bottom, self.currentHeight)
			.animation(.easeOut(duration: 0.16))
			.onAppear {
				NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardWillShowNotification)
					.merge(with: NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardWillChangeFrameNotification))
					.compactMap { notification in
						notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect
					}
					.map { rect in
						rect.height - geometry.safeAreaInsets.bottom
					}
					.subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
				NotificationCenter.Publisher(center: .default, name: UIResponder.keyboardWillHideNotification)
					.compactMap { notification in
						CGFloat.zero
					}
					.subscribe(Subscribers.Assign(object: self, keyPath: \.currentHeight))
			}
		}
	}
}
