//
//  ContentManager.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import Alamofire
import Down

let DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

class ContentManager: ObservableObject {
	static let instance = ContentManager()

	private let adminURL: String?

	@Published var posts = [BlogPost]()
	
	private init() {
		adminURL = UserDefaults.standard.string(forKey: "adminURL")
	}

	enum PublishOption {
		case draft, publish, schedule
	}

	func publish(_ post: BlogPost, callback: ((BlogPost?, String?) -> Void)? = nil) {
		guard let session = AuthManager.instance.session else {
			callback?(nil, "Invalid authentication session")
			return
		}
		guard let url = URL(string: "\(session.blogURL)/ghost/api/v3/admin/posts\(post.id.isEmpty ? "" : "/\(post.id)")?source=html") else {
			callback?(nil, "Failed to create url")
			return
		}
		var data: Data?
		do {
			let encoder = JSONEncoder()
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = DATE_FORMAT
			encoder.dateEncodingStrategy = .formatted(dateFormatter)
			try data = encoder.encode(CreatePostPayload(post))
		} catch {
			callback?(nil, "Failed to encode post data")
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = post.id.isEmpty ? "POST" : "PUT"
		request.addValue("https://ghostwriter.jacobsokora.me", forHTTPHeaderField: "Origin")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = data
		URLSession.shared.dataTask(with: request) { data, _, error in
			if let data = data {
				do {
					let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
					if let postData = jsonData["posts"] as? [[String: Any?]] {
						let postDict = postData[0]
						DispatchQueue.main.async {
							if post.new {
								post.update(from: postDict)
							}
							post.updatedAt = postDict["updated_at"] as? String
							callback?(post, nil)
						}
					} else if let errorData = jsonData["errors"] as? [[String: Any?]] {
						let errorDict = errorData[0]
						if let context = errorDict["context"] as? String {
							callback?(nil, context)
						}
					}
				} catch {
					callback?(nil, error.localizedDescription)
				}
			} else {
				callback?(nil, error?.localizedDescription)
			}
		}.resume()
	}

	func deletePost(at index: Int) {
		guard let session = AuthManager.instance.session else {
			return
		}
		let post = posts.remove(at: index)
		guard let url = URL(string: "\(session.blogURL)/ghost/api/v3/admin/posts/\(post.id)") else {
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "DELETE"
		request.addValue("https://ghostwriter.jacobsokora.me", forHTTPHeaderField: "Origin")
		URLSession.shared.dataTask(with: request).resume()
	}

	func delete(_ post: BlogPost) {
		if let index = posts.firstIndex(where: { $0.id == post.id }) {
			deletePost(at: index)
		}
	}

	func uploadImage(_ image: UIImage, callback: @escaping (String?, String?) -> Void) {
		guard let session = AuthManager.instance.session else {
			return callback(nil, "Invalid session")
		}
		guard let url = URL(string: "\(session.blogURL)/ghost/api/v3/admin/images/upload") else {
			return callback(nil, "Unable to create url")
		}
		guard let imageData = image.pngData() else {
			return callback(nil, "Unable to convert image data")
		}
		AF.upload(multipartFormData: {
			$0.append(imageData, withName: "file", fileName: "image.png", mimeType: "image/png")
		}, to: url, usingThreshold: UInt64(), method: .post, headers: [ "Origin": "https://ghostwriter.jacobsokora.me" ]).responseDecodable(of: ImageResponse.self) { response in
			if let imageURL = response.value?.images[0].url {
				callback(imageURL, nil)
			} else {
				callback(nil, response.error?.localizedDescription)
			}
		}
	}

	func loadPosts(callback: @escaping (String?) -> Void = { _ in }) {
		guard let session = AuthManager.instance.session, let url = URL(string: "\(session.blogURL)/ghost/api/v3/admin/posts?formats=html") else {
			callback("Invalid authentication session")
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.addValue("https://ghostwriter.jacobsokora.me", forHTTPHeaderField: "Origin")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		URLSession.shared.dataTask(with: request) { data, _, error in
			if let data = data {
				do {
					let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any?]
					if let postData = jsonData["posts"] as? [[String: Any?]] {
						var posts = [BlogPost]()
						for postDict in postData {
							if let blogPost = BlogPost.parse(from: postDict) {
								posts.append(blogPost)
							}
						}
						DispatchQueue.main.async {
							self.posts = posts
							callback(nil)
						}
					}
				} catch {
					callback(error.localizedDescription)
				}
			} else if let error = error {
				callback(error.localizedDescription)
			}
		}.resume()
	}
}

struct CreatePostPayload: Codable {

	let posts: [PostPayload]

	init(_ blogPost: BlogPost) {
		self.posts = [
			PostPayload(slug: blogPost.slug, title: blogPost.title, html: (try? Down(markdownString: blogPost.markdown).toHTML()) ?? "", feature_image: blogPost.featureImage, authors: blogPost.authors, excerpt: blogPost.excerpt, tags: blogPost.tags, status: blogPost.status, visibility: blogPost.visibility, featured: blogPost.featured, updated_at: blogPost.updatedAt, published_at: blogPost.publishedAt?.utcString)
		]
	}

	struct PostPayload: Codable {
		let slug: String
		let title: String
		let html: String
		let feature_image: String?
		let authors: [String]
		let excerpt: String
		let tags: [String]
		let status: Status
		let visibility: Visibility
		let featured: Bool
		let updated_at: String?
		let published_at: String?
	}
}

struct ImageResponse: Codable {
	let images: [Image]

	struct Image: Codable {
		let url: String
	}
}
