//
//  RefreshableList.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/21/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import Introspect

public extension List {
	func onRefresh(isRefreshing: Bool, title: String = "", action: @escaping () -> Void) -> some View {
		return self.introspectTableView { tableView in
			if let refreshHandler = tableView.refreshHandler {
				if isRefreshing {
					NotificationCenter.default.post(name: .beginRefreshing, object: nil, userInfo: ["id": refreshHandler.id])
				} else {
					NotificationCenter.default.post(name: .endRefreshing, object: nil, userInfo: ["id": refreshHandler.id])
				}
			} else {
				let refreshControl = UIRefreshControl()
				refreshControl.attributedTitle = NSAttributedString(string: title)
				let handler = RefreshHandler(refreshControl: refreshControl)
				handler.onRefresh = action
				tableView.refreshHandler = handler
				tableView.refreshControl = refreshControl
			}
		}
	}
}

extension Notification.Name {
	static var beginRefreshing: Notification.Name {
		Notification.Name(rawValue: "me.jacobsokora.ghostwriter.beginRefreshing")
	}

	static var endRefreshing: Notification.Name {
		Notification.Name(rawValue: "me.jacobsokora.ghostwriter.endRefreshing")
	}
}

internal class RefreshHandler: NSObject {

	weak var refreshControl: UIRefreshControl? = nil
	var onRefresh: (() -> Void)? = nil
	let id = UUID()


	init(refreshControl: UIRefreshControl) {
		super.init()
		self.refreshControl = refreshControl
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(beginRefreshing(_:)), name: .beginRefreshing, object: nil)
		nc.addObserver(self, selector: #selector(endRefreshing(_:)), name: .endRefreshing, object: nil)
		refreshControl.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	@objc func valueChanged(_ sender: UIRefreshControl) {
		onRefresh?()
	}

	@objc func beginRefreshing(_ notification: Notification) {
		guard let id = notification.userInfo?["id"] as? UUID else { return }
		guard self.id == id else { return }
		DispatchQueue.main.async {
			self.refreshControl?.beginRefreshing()
		}
	}

	@objc func endRefreshing(_ notification: Notification) {
		guard let id = notification.userInfo?["id"] as? UUID else { return }
		guard self.id == id else { return }
		DispatchQueue.main.async {
			self.refreshControl?.endRefreshing()
		}
	}
}

var StoredPropertyKey: UInt8 = 0

extension UITableView {
	var refreshHandler: RefreshHandler? {
		get {
			guard let object = objc_getAssociatedObject(self, &StoredPropertyKey) as? RefreshHandler else {
				return nil
			}
			return object
		}
		set {
			objc_setAssociatedObject(self, &StoredPropertyKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
}
