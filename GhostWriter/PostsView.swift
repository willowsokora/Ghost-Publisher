//
//  Posts.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct PostRow: View {
	let post: BlogPost

	var body: some View {
		NavigationLink(destination: PostView(post: post)) {
			VStack(alignment: .leading) {
				Text(post.title).font(.system(size: 22))
				HStack {
					Text("Published by \(post.authors[0])").font(.caption)
					Spacer()
					Text(post.publishedDescriptor).font(.caption)
				}
			}
		}
	}

}

struct PostsView: View {

	@ObservedObject var authManager: AuthManager = AuthManager.instance
	@ObservedObject var contentManager: ContentManager = ContentManager.instance
	@State var query = ""
	@State var needsSetup = false
	@State var showRefreshView = false
	@State var pullStatus = CGFloat.zero
	@State var delete = false
	@State var deleteIndex = 0
	@State var error: String?
	@State var refreshing = false

	var setupButton: some View {
		Button(action: {
			if self.authManager.session == nil {
				self.needsSetup = true
			} else {
				self.authManager.session = nil
				self.contentManager.posts = []
				UserDefaults.standard.removeObject(forKey: "sessionCookie")
			}
		}, label: {
			Text(self.authManager.session == nil ? "Sign in" : "Sign out")
		})
	}

	var composeButton: some View {
		NavigationLink(destination: PostView()) {
			Image(systemName: "square.and.pencil").imageScale(.large)
		}
	}

	var refreshButton: some View {
		#if targetEnvironment(macCatalyst)
			return Button(action: {
				self.contentManager.loadPosts()
			}, label: {
				Image(systemName: "arrow.2.circlepath").imageScale(.large)
			})
		#else
			return Text("")
		#endif
	}

	var trailing: some View {
		HStack {
			if self.authManager.session != nil {
				refreshButton
				NavigationLink(destination: PostView()) {
					Image(systemName: "square.and.pencil").imageScale(.large)
				}
			}
		}
	}

    var body: some View {
		NavigationView {
			List {
				ForEach(self.contentManager.posts) { post in
					PostRow(post: post)
				}.onDelete { indexSet in
					if let deleteIndex = indexSet.first {
						self.delete = true
						self.deleteIndex = deleteIndex
					}
				}
			}
			.onRefresh(isRefreshing: refreshing) {
				self.refreshing = true
				self.contentManager.loadPosts() { error in
					self.error = error
					self.refreshing = false
				}
			}
			.navigationBarTitle(authManager.session?.blogTitle ?? "Please sign in")
			.navigationBarItems(leading: self.setupButton, trailing: self.trailing)
			.introspectNavigationController { navigationController in
				navigationController.navigationBar.backItem?.title = ""
			}
			.alert(isPresented: $delete) {
				Alert(title: Text("Delete post"), message: Text("Are you sure you want to delete your post \"\(self.contentManager.posts[deleteIndex].title)\"? This action cannot be undone"), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete"), action: {
					self.contentManager.deletePost(at: self.deleteIndex)
				}))
			}
		}
		.sheet(isPresented: $needsSetup) {
			SetupView()
		}
		.alert(item: $error) { error in
			Alert(title: Text("Error loading posts"), message: Text(error), dismissButton: .default(Text("Okay")))
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.onAppear {
			self.reload()
		}
    }

	func reload() {
		if self.authManager.session == nil || self.authManager.session?.expires ?? Date() <= Date() {
			self.needsSetup = true
		} else {
			self.contentManager.loadPosts()
		}
	}

}

struct PostsView_Previews: PreviewProvider {
    static var previews: some View {
        PostsView()
    }
}
