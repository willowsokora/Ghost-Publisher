//
//  OptionsView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/20/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI
import SwiftUIX

struct OptionsView: View {

	@ObservedObject var post: BlogPost

	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

	@State var showAddTagSheet = false
	@State var author = ""
	@State var tag = ""
	@State var delete = false
	@State var showImageSelect = false

    var body: some View {
		GeometryReader { geometry in
			NavigationView {
				Form {
					Section(header: Text("Feature image")) {
						if self.post.featureImage == nil {
							HStack {
								Spacer()
								Button(action: {
									self.showImageSelect = true
								}, label: {
									Text("Select an image")
								}).imagePicker(isPresented: self.$showImageSelect, imageURL: self.$post.featureImage)
								Spacer()
							}
						} else {
							AsyncImage(url: URL(string: self.post.featureImage!.imageURL)!, placeholder: Text("Loading..."))
							HStack {
								Spacer()
								Button(action: {
									self.post.featureImage = nil
								}, label: {
									Text("Delete image").foregroundColor(.red)
								})
								Spacer()
							}
						}
					}
					Section {
						VStack(alignment: .leading) {
							Text("Post URL").font(.caption)
							TextField("Post URL", text: self.$post.slug)
						}
						Picker(selection: self.$post.visibility, label: Text("Post access")) {
							ForEach(Visibility.allValues, id: \.self) {
								Text($0.displayString)
							}
						}
						Toggle(isOn: self.$post.featured) {
							Text("Feature this post")
						}
					}
					Section(header: Text("Authors")) {
						ForEach(self.post.authors) { author in
							Text(author)
						}.onDelete { indexSet in
							self.post.authors.remove(atOffsets: indexSet)
						}
						HStack {
							TextField("Add author", text: self.$author)
							Button(action: {
								self.post.authors.append(self.author)
								self.author = ""
							}, label: {
								Image(systemName: "plus")
							})
						}
					}
					Section(header: Text("Tags")) {
						ForEach(self.post.tags) { tag in
							Text(tag)
						}.onDelete { indexSet in
							self.post.tags.remove(atOffsets: indexSet)
						}
						HStack {
							TextField("Add tag", text: self.$tag)
							Button(action: {
								self.post.tags.append(self.tag)
								self.tag = ""
							}, label: {
								Image(systemName: "plus")
							})
						}
					}
					Section(header: Text("Excerpt")) {
						TextView("Excerpt", text: self.$post.excerpt).frame(height: geometry.size.width / 2)
					}
					if !self.post.id.isEmpty {
						Section {
							HStack {
								Spacer()
								Button(action: {
									self.delete = true
								}, label: {
									Text("Delete post").foregroundColor(.red)
								})
								Spacer()
							}
						}
					}
				}
				.alert(isPresented: self.$delete) {
					Alert(title: Text("Delete post"), message: Text("Are you sure you want to delete your post \"\(self.post.title)\"? This action cannot be undone"), primaryButton: .cancel(), secondaryButton: .destructive(Text("Delete")) {
						ContentManager.instance.delete(self.post)
						self.presentationMode.wrappedValue.dismiss()
					})
				}
				.navigationBarTitle("Post options")
				.listStyle(GroupedListStyle())
				.environment(\.horizontalSizeClass, .regular)
				.navigationBarItems(leading: Button(action: {
					self.presentationMode.wrappedValue.dismiss()
				}, label: {
					#if targetEnvironment(macCatalyst)
					Text("Cancel").foregroundColor(.red)
					#else
					Text("")
					#endif
				}))
				.onAppear {
					if self.post.slug.isEmpty {
						self.post.slug = self.post.generateSlug()
					}
				}
			}.navigationViewStyle(StackNavigationViewStyle())
		}.modifier(KeyboardAdapter())
    }
}
