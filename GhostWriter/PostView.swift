//
//  PostView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import SwiftUIX

struct PostView: View {

	let renderOptions = [ "Editor", "Preview" ]
	let markdownCheat = """
		## markdown quick reference
		# headers
		*emphasis*
		**strong**
		* list
		>block quote
			code (4 spaces indent)
		[links](https://wikipedia.org)
		"""

	@ObservedObject var post: BlogPost = BlogPost()
	@State var isEditing = false
	@State var render = "Editor"
	@State var saveStatus = "New"
	@State var showOptionsSheet = false
	@State var showPublishSheet = false
	@State var saveTimer: Timer? = nil
	@State var showImagePicker = false

    var body: some View {
		VStack {
			HStack {
				Text(saveStatus).font(.footnote).foregroundColor(.placeholderText)
				Spacer()
				Picker(selection: $render, label: Text("Render mode")) {
					ForEach(renderOptions, id: \.self) {
						Text($0)
					}
				}.pickerStyle(SegmentedPickerStyle())
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
			if render == "Editor" {
				TextView(markdownCheat, text: $post.markdown)
				if post.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					HelperWebView(post: post, content: $post.markdown).frame(width: 0, height: 0, alignment: .center)
				}
			} else {
				MarkdownView(content: self.post.markdown)
			}

		}
		.navigationBarItems(
			trailing: HStack() {
				Button(action: {
					self.showImagePicker = true
				}, label: {
					Image(systemName: "camera.fill").imageScale(.large)
				})
				.imagePicker(isPresented: $showImagePicker) { imageInfo in
					self.post.markdown += "\n![Image](\(imageInfo.imageURL))"
					if let attribution = imageInfo.attribution {
						self.post.markdown += "\n\(attribution.markdownAttribution)\n"
					}
				}
				Button(action: {
					self.showPublishSheet = true
				}, label: {
					Image(systemName: "paperplane.fill").imageScale(.large)
				})
				.disabled(self.post.title.isEmpty)
				.sheet(isPresented: $showPublishSheet) {
					PublishPostView(post: self.post)
				}
				Button(action: {
					self.showOptionsSheet = true
				}, label: {
					Image(systemName: "gear").imageScale(.large)
				})
				.sheet(isPresented: $showOptionsSheet) {
					OptionsView(post: self.post)
				}
			}
		)
		.navigationBarTitle("", displayMode: .inline)
		.padding()
		.modifier(KeyboardAdapter())
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
