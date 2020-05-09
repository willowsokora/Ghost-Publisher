//
//  PostView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct PostView: View {

	@ObservedObject var post: BlogPost = BlogPost()
	@State var isEditing = false
	@State var saveStatus = "New"
	@State var showOptionsSheet = false
	@State var showPublishSheet = false
	@State var saveTimer: Timer? = nil
	@State var showImagePicker = false
	@State var showLinkDialog = false
	@State var insertLinkTmp = ""

	@State var newCardPayload: [String: Any?]? = nil

    var body: some View {
		VStack {
			HStack {
				Text(saveStatus).font(.footnote).foregroundColor(.placeholderText)
				Spacer()
			}
			TextField("Title", text: $post.title,
				onEditingChanged: { focused in
					if !focused && self.post.new {
						if self.post.title.isEmpty {
							self.post.title = "Untitled"
						}
						self.saveStatus = "Saving..."
						ContentManager.instance.publish(self.post) { _, _ in
							self.saveStatus = "Saved"
						}
					}
				}, onCommit: {
					if self.post.new {
						self.saveStatus = "Saving..."
						ContentManager.instance.publish(self.post) { _, _ in
							self.saveStatus = "Saved"
						}
					}
				}
			).font(.title)
			Divider()
			MobiledocEditor(mobiledoc: $post.mobiledoc, showImagePicker: $showImagePicker, newCardPayload: $newCardPayload)
			.imagePicker(isPresented: $showImagePicker) { imageInfo in
				var payload = [
					"type": "image",
					"src": imageInfo.imageURL,
				]
				if let attribution = imageInfo.attribution {
					payload["caption"] = attribution.htmlAttribution
				}
				self.newCardPayload = payload
			}
		}
		.navigationBarItems(
			trailing: HStack() {
				Button(action: {
					self.showPublishSheet = true
				}, label: {
					Image(systemName: .paperplaneFill).imageScale(.large)
				})
				.disabled(self.post.title.isEmpty)
				.sheet(isPresented: $showPublishSheet) {
					PublishPostView(post: self.post)
				}
				Button(action: {
					self.showOptionsSheet = true
				}, label: {
					Image(systemName: .gear).imageScale(.large)
				})
				.sheet(isPresented: $showOptionsSheet) {
					OptionsView(post: self.post)
				}
				.accessibility(label: Text("options"))
			}
		)
		.navigationBarTitle("", displayMode: .inline)
		.padding()
		.onAppear {
			if !self.post.new {
				self.saveStatus = self.post.status.rawValue.capitalized
			}
			self.saveTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
				DispatchQueue.main.async {
					if !self.post.new && self.post.status == .draft && self.post.changed {
						self.saveStatus = "Saving..."
						ContentManager.instance.publish(self.post) { _, error in
							self.saveStatus = error != nil ? error! : "Saved draft"
							self.post.changed = false
						}
					}
				}
			}
		}
		.onDisappear {
			self.saveTimer?.invalidate()
			ContentManager.instance.loadPosts()
		}
    }
}

struct PostView_Previews: PreviewProvider {
    static var previews: some View {
        PostView()
    }
}
