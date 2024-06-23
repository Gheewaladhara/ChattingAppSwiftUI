//
//  CreateNewMessageView.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 02/06/24.
//

import SwiftUI
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
     
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    init() {
        fatchAllUsers()
    }
    
    private func fatchAllUsers() {
        FirebaseManager.shared.firestore.collection("users")
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fatch Users: \(error )"
                     print("Failed to fatch Users: \(error )")
                    return
                }
                
                documentsSnapshot?.documents.forEach({ snapshot in
                    let data = snapshot.data()
                    let user = ChatUser(data: data)
                    if user.uid != FirebaseManager.shared.auth.currentUser?.uid {
                        self.users.append(.init(data: data))
                    }
                })
    
//                 self.errorMessage = "Fetched user succesfully"
            }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectNewUser : (ChatUser) -> ()
    
    // In SwiftUI, @Environment(\. presentationMode) is a property wrapper that gives you access to the presentation mode of the current view
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                Text(vm.errorMessage)
                
                ForEach(vm.users) { user in
                    
                    Button{
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    }label: {
                        
                        HStack{
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle (cornerRadius: 50)
                                    .stroke(Color(.label ), lineWidth: 1)
                                )
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        }.padding(.horizontal)
                    }
                    Divider()
                        .padding(.vertical, 8)
                    
                }
            }.navigationTitle("New Message")
                .toolbar{
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button{
                            presentationMode.wrappedValue.dismiss()
                        }label: {
                            Text("Cancel")
                        }
                    }
                }
        }
    }
}

#Preview {
//    CreateNewMessageView(didSelectNewUser: (ChatUser) -> (chatUser))
    MainMessageView()
}
