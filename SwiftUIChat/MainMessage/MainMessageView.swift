//
//  MainMessageView.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 01/06/24.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseFirestoreSwift

class MainMessageViewModel: ObservableObject{
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    
    init() {
        
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurruntUser()
        fetchRecentMessages()
    }
        
    private var fireStoreListener: ListenerRegistration?
    
    func fetchRecentMessages()  {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        self.recentMessages.removeAll()
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
        
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages \(error)"
                    print(error)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                         let docId = change.document.documentID
                    
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        return rm.id == docId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    do {
                      let rm = try  change.document.data(as: RecentMessage.self)
                        self.recentMessages.insert(rm, at: 0)
                    } catch {
                        print(error)
                    }
                    
                })
            }
    }
    
     func fetchCurruntUser(){
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid
        else {
            //self.errorMessage = "could nor findfirebase uid"
            return }
        
        FirebaseManager.shared.firestore.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                self.errorMessage = "failed to fatch currunt user: \(error)"
              //  print("failed to fatch currunt user:" , error)
                return
            }
            
            guard let data = snapshot?.data() else {
                self.errorMessage = "no data found "
                
                return }
            
            self.chatUser = .init(data: data)
            
        }
    }
    
    
    
    func handleSignOut(){
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
}
 
struct MainMessageView: View {
    
    @State var ShouldShowLogoutOption = false
    @State var shouldNavigatetoChatLoginView = false
    @ObservedObject private var vm = MainMessageViewModel()
    @State var chatUser: ChatUser?
    
    var body: some View {
        NavigationView{
            
            VStack{
//                Text("User: \(vm.chatUser?.uid ?? "")")
                
                customNavBar
                MessageView
                
                NavigationLink("", destination: ChatLogView(chatUser: chatUser), isActive: $shouldNavigatetoChatLoginView)
                
            }.navigationTitle("Chats")
            .overlay(
                NewMessageButton, alignment: .bottom )
            .navigationBarHidden(true)
        }
    }
    
    private var customNavBar: some View{
        
        HStack(spacing: 16) {
            
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1)
                ).shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                
                Text(email)
                                
                    .font(.system(size: 24, weight: .bold))
                
                HStack{
                    Circle()
                    .foregroundColor(.green)
                    .frame(width: 14,height: 14)
                Text("Online")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            Button{
                ShouldShowLogoutOption.toggle()
            }label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
            
        }.padding()
            .actionSheet(isPresented: $ShouldShowLogoutOption) {
                .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                    .destructive(Text("Sign Out"), action: {
                        print("Handle sign out")
                        vm.handleSignOut()
                    }),
                    .cancel()
                    
                ])
            }
            .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    self.vm.isUserCurrentlyLoggedOut = false
                    
                    self.vm.fetchCurruntUser()
                    self.vm.fetchRecentMessages()
                })
        }
}
    
    
    private var MessageView: some View{
        
        ScrollView{
            ForEach(vm.recentMessages) { recentMessage in
                
                VStack{
                    
                    Button {
                        self.chatUser = .init(data: [
                            "uid": recentMessage.toId,
                            "email": recentMessage.email,
                            "profileImageUrl": recentMessage.profileImageUrl
                        ])
                        self.shouldNavigatetoChatLoginView.toggle()
                    } label: {
                        
                        HStack(spacing: 16 ) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color(.label), lineWidth: 2)
                                )
                                .shadow(radius: 5)
                            
                            
                            VStack(alignment: .leading, spacing: 8){
                                Text(recentMessage.email)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    .multilineTextAlignment(.leading)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text(recentMessage.timeAgo)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(.label))
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
                
            }.padding(.bottom, 50)
        }
    }
    
    
    @State var shouldShowNewMessageScreen = false
    
    private var NewMessageButton: some View {
        Button{
            shouldShowNewMessageScreen.toggle()
        }label: {
            HStack{
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
                .background(Color.blue)
                .cornerRadius(32)
                .padding(.horizontal)
                .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen){
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.shouldNavigatetoChatLoginView.toggle()
                self.chatUser = user
            })
        }
    }
}

#Preview {
    
    MainMessageView()
        
}
