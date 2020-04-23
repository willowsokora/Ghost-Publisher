//
//  AuthManager.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct Session {
	let user: String
	let blogURL: String
	let blogTitle: String
	let sessionCookie: String
	let expires: Date?
}

struct AuthRequest: Codable {
	let username: String
	let password: String
}

class AuthManager: ObservableObject {

	static let instance = AuthManager()

	private init() {}

	@Published var session: Session?

	func authenticate(on blogURL: String, title: String, with email: String, identifiedBy password: String, _ callback: @escaping (Bool) -> Void) {
		guard let url = URL(string: "\(blogURL)/ghost/api/v3/admin/session") else {
			session = nil
			callback(false)
			return
		}
		let authRequest = AuthRequest(username: email, password: password)
		guard let authData = try? JSONEncoder().encode(authRequest) else {
			session = nil
			callback(false)
			return
		}
		print(url)
		var urlRequest = URLRequest(url: url)
		urlRequest.httpBody = authData
		urlRequest.httpMethod = "POST"
		urlRequest.addValue("https://ghostwriter.jacobsokora.me", forHTTPHeaderField: "Origin")
		urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
		urlRequest.httpShouldHandleCookies = true
		var success = false
		URLSession.shared.dataTask(with: urlRequest) { data, response, error in
			guard let url = response?.url,
				let httpResponse = response as? HTTPURLResponse,
				let fields = httpResponse.allHeaderFields as? [String: String] else {
					print("Unable to retrieve header fields")
					callback(false)
					return
			}
			let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
			HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
			for cookie in cookies {
				if cookie.name == "ghost-admin-api-session" {
					UserDefaults.standard.set(blogURL, forKey: "blogURL")
					UserDefaults.standard.set(title, forKey: "blogTitle")
					UserDefaults.standard.set(email, forKey: "blogUser")
					UserDefaults.standard.set(cookie.value, forKey: "sessionCookie")
					UserDefaults.standard.set(cookie.expiresDate, forKey: "sessionExpires")
					success = true
					DispatchQueue.main.async {
						self.session = Session(user: email, blogURL: blogURL, blogTitle: title, sessionCookie: cookie.value, expires: cookie.expiresDate)
						ContentManager.instance.loadPosts()
					}
				}
			}
			callback(success)
		}.resume()
	}

	func getDefaultAuthors() -> [String] {
		guard let session = session else {
			return []
		}
		return [session.user]
	}
}
