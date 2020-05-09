//
//  PublishPostView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/20/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct PublishPostView: View {

	@ObservedObject var post: BlogPost

	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@State var schedule = false
	@State var scheduleFor = Date()
	@State var sendEmail = false
	@State var errorMessage: String? = nil
	
    var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Options")) {
					Toggle(isOn: $schedule) {
						Text("Schedule for later")
					}
					if schedule {
						DatePicker(selection: $scheduleFor, displayedComponents: [.date, .hourAndMinute]) {
							Text("Publish at")
						}
					}
					Toggle(isOn: $sendEmail) {
						Text("Send via email")
					}
				}
				Section {
					HStack {
						Spacer()
						Button(action: {
							self.post.status = self.schedule ? .scheduled : .published
							if self.schedule {
								self.post.publishedAt = self.scheduleFor
							}
							ContentManager.instance.publish(self.post) { post, message in
								if post != nil {
									self.presentationMode.wrappedValue.dismiss()
									AppStoreReviewManager.requestReviewIfAppropriate()
								} else {
									self.errorMessage = message
								}
							}
						}, label: {
							Text("Publish")
						})
						Spacer()
					}
				}
			}
			.alert(item: $errorMessage) { message in
				Alert(title: Text("Error publishing"), message: Text(message), dismissButton: .default(Text("Okay")))
			}
			.navigationBarTitle("Publish")
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
		}
		.navigationViewStyle(StackNavigationViewStyle())
    }
}
