//
//  AppStoreReviewManager.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 5/9/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import StoreKit

enum AppStoreReviewManager {
	static func requestReviewIfAppropriate() {
		// dont request more than once per week
		if let lastDate = UserDefaults.standard.object(forKey: "lastReviewRequest") as? Date, Date().timeIntervalSince(lastDate) < 604800 {
			return
		}
		if Int.random(in: 0..<10) == 5 {
			SKStoreReviewController.requestReview()
			UserDefaults.standard.set(Date(), forKey: "lastReviewRequest")
		}
	}
}
