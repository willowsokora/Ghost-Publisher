//
//  SetupView.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import SwiftUI

struct SiteResponse: Codable {
	let site: Site
}

struct Site: Codable {
	let title: String
}

struct SetupView: View {

	@Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
	@State var blogURL = "https://"
	@State var message = ""
	@State var error = false
	@State var verifying = false
	@State var verified = false
	@State var email = ""
	@State var password = ""
	@State var blogTitle = ""
	@State var alert = false

    var body: some View {
		NavigationView {
			Form {
				Section(header: Text("Blog URL")) {
					VStack(alignment: .leading) {
						HStack {
							TextField("Blog URL", text: $blogURL) {
								self.verifying = true
								guard self.blogURL.trimmingCharacters(in: ["/"]).range(of: "^(http:\\/\\/www\\.|https:\\/\\/www\\.|http:\\/\\/|https:\\/\\/)?[a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\\/.*)?$", options: .regularExpression) != nil else {
									self.message = "Please enter a valid URL"
									self.verifying = false
									self.error = true
									return
								}
								URLSession.shared.dataTask(with: URL(string: "\(self.blogURL)/ghost/api/v3/admin/site")!) { data, _, err in
									self.verifying = false
									if let data = data, let siteResponse = try? JSONDecoder().decode(SiteResponse.self, from: data) {
										self.blogTitle = siteResponse.site.title
										self.message = "Found blog: \"\(self.blogTitle)\""
										self.verified = true
										self.error = false
									} else {
										self.message = "Ghost site not found"
										self.error = true
									}
								}.resume()
							}.keyboardType(.URL)
								.accessibility(label: Text("blogURL"))
							ActivityIndicatorView(animating: $verifying)
						}
						if !message.isEmpty {
							Text(message).foregroundColor(error ? .red : .green).font(.caption)
						}
					}
				}
				if verified {
					Section(header: Text("Credentials")) {
						TextField("Email", text: $email)
							.keyboardType(.emailAddress)
							.accessibility(label: Text("username"))
						SecureField("Password", text: $password)
							.accessibility(label: Text("password"))
					}
					Section {
						HStack {
							Spacer()
							Button(action: {
								AuthManager.instance.authenticate(on: self.blogURL, title: self.blogTitle, with: self.email, identifiedBy: self.password) { success in
									if success {
										self.presentationMode.wrappedValue.dismiss()
									} else {
										self.alert = true
									}
								}
							}, label: {
								Text("Sign in")
							}).accessibility(label: Text("signin"))
							Spacer()
						}
					}
				}
			}
			.alert(isPresented: $alert) {
				Alert(title: Text("Authentication error"), message: Text("Sorry, we were unable to authenticate you. Please make sure blog url, email, and password match your credentials"), dismissButton: .default(Text("Okay")))
			}
			.listStyle(GroupedListStyle())
			.environment(\.horizontalSizeClass, .regular)
			.onAppear {
				if let blogURL = UserDefaults.standard.string(forKey: "blogURL") {
					self.blogURL = blogURL
					if let cookies = HTTPCookieStorage.shared.cookies {
						for cookie in cookies {
							if cookie.name == "ghost-admin-api-session" {
								HTTPCookieStorage.shared.deleteCookie(cookie)
							}
						}
					}
				}
			}
			.navigationBarTitle("Sign in")
		}
		.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
