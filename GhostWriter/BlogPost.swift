//
//  BlogPost.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import Foundation

enum Visibility: String, Codable {
	case `public`
	case members
	case `private`

	var displayString: String {
		switch self {
		case .members: return "Members only"
		case .private: return "Paid members only"
		default: return "Public"
		}
	}

	static var allValues: [Visibility] {
		[ .public, .members, .private ]
	}
}
enum Status: String, Codable {
	case draft
	case published
	case scheduled
}

class BlogPost: Identifiable, ObservableObject {
	@Published var new = true
	@Published var id: String
	@Published var slug: String
	@Published var title: String
	var htmlContent: String
	@Published var markdown: String {
		didSet {
			self.changed = true
		}
	}
	@Published var featureImage: String?
	@Published var authors: [String]
	@Published var excerpt: String
	@Published var tags: [String]
	@Published var status: Status = .draft
	@Published var visibility: Visibility
	@Published var featured: Bool
	var createdAt: Date
	var publishedAt: Date?
	@Published var updatedAt: String?
	@Published var changed = false
	var mobileDoc: String {
		"""
		{
			"version": "0.3.1",
			"markups": [],
			"atoms": [],
			"cards": [["markdown", { "cardName": "markdown", "markdown": "\(markdown)" }]],
			"sections": [[10, 0]]
		}
		"""
	}

	var publishedDescriptor: String {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .short
		switch status {
		case .draft: return "Draft"
		case .scheduled: return "Scheduled for \(formatter.string(from: publishedAt!))"
		case .published: return formatter.string(from: publishedAt!)
		}
	}

	init(id: String = "", slug: String = "", title: String = "", htmlContent: String = "", markdown: String = "", featureImage: String? = nil, authors: [String] = [], excerpt: String = "", tags: [String] = [], status: Status = .draft, visibility: Visibility = .public, featured: Bool = false, createdAt: Date = Date(), publishedAt: Date? = nil, updatedAt: String? = nil) {
		self.id = id
		self.slug = slug
		self.title = title
		self.htmlContent = htmlContent
		self.markdown = markdown
		self.featureImage = featureImage
		if authors.isEmpty {
			self.authors = AuthManager.instance.getDefaultAuthors()
		} else {
			self.authors = authors
		}
		self.excerpt = excerpt
		self.tags = tags
		self.status = status
		self.visibility = visibility
		self.featured = featured
		self.createdAt = createdAt
		self.publishedAt = publishedAt
		self.updatedAt = updatedAt
		self.new = id.isEmpty
	}

	func update(from dict: [String: Any?]) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = DATE_FORMAT
		guard let id = dict["id"] as? String,
			let slug = dict["slug"] as? String,
			let authors = dict["authors"] as? [[String: Any?]],
			let statusString = dict["status"] as? String,
			let status = Status.init(rawValue: statusString),
			let visibilityString = dict["visibility"] as? String,
			let visibility = Visibility.init(rawValue: visibilityString),
			let featured = dict["featured"] as? Bool,
			let createdAtString = dict["created_at"] as? String,
			let createdAt = dateFormatter.date(from: createdAtString) else {
				return
		}
		var authorEmails = [String]()
		var tagNames = [String]()
		var publishedAt: Date?
		for author in authors {
			if let authorEmail = author["email"] as? String {
				authorEmails.append(authorEmail)
			}
		}
		if let tags = dict["tags"] as? [[String: Any?]] {
			for tag in tags {
				if let tagName = tag["name"] as? String {
					tagNames.append(tagName)
				}
			}
		}
		let updatedAt = dict["updated_at"] as? String
		if let publishedAtString = dict["published_at"] as? String {
			publishedAt = dateFormatter.date(from: publishedAtString)
		}
		self.id = id
		self.slug = slug
		self.authors = authorEmails
		self.tags = authorEmails
		self.status = status
		self.visibility = visibility
		self.featured = featured
		self.createdAt = createdAt
		self.publishedAt = publishedAt
		self.updatedAt = updatedAt
		self.new = false
	}

	static func parse(from dict: [String: Any?]) -> BlogPost? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = DATE_FORMAT
		guard let id = dict["id"] as? String,
			let slug = dict["slug"] as? String,
			let title = dict["title"] as? String,
			let authors = dict["authors"] as? [[String: Any?]],
			let statusString = dict["status"] as? String,
			let status = Status.init(rawValue: statusString),
			let visibilityString = dict["visibility"] as? String,
			let visibility = Visibility.init(rawValue: visibilityString),
			let featured = dict["featured"] as? Bool,
			let createdAtString = dict["created_at"] as? String,
			let createdAt = dateFormatter.date(from: createdAtString) else {
				return nil
		}
		let featureImage = dict["feature_image"] as? String
		let html = dict["html"] as? String ?? ""
		var authorEmails = [String]()
		var tagNames = [String]()
		var publishedAt: Date?
		for author in authors {
			if let authorEmail = author["email"] as? String {
				authorEmails.append(authorEmail)
			}
		}
		if let tags = dict["tags"] as? [[String: Any?]] {
			for tag in tags {
				if let tagName = tag["name"] as? String {
					tagNames.append(tagName)
				}
			}
		}
		let updatedAt = dict["updated_at"] as? String
		if let publishedAtString = dict["published_at"] as? String {
			publishedAt = dateFormatter.date(from: publishedAtString)
		}
		return BlogPost(id: id, slug: slug, title: title, htmlContent: html, featureImage: featureImage, authors: authorEmails, tags: tagNames, status: status, visibility: visibility, featured: featured, createdAt: createdAt, publishedAt: publishedAt, updatedAt: updatedAt)
	}

	func generateSlug() -> String {
		return title.lowercased().replacingOccurrences(of: " ", with: "-").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
	}

}
