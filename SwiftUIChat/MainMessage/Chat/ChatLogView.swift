//
//  ChatLogView.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 02/06/24.
//

import SwiftUI
import PhotosUI
import Firebase

struct FireBaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static var profileImageUrl = "profileImageUrl"
    static let email = "email"
}

class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    
    @Published var chatMessage = [ChatMessage]()
    
    let chatUser : ChatUser?
    
    init (chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchedMessages()
    }
    
    var firestorelistener: ListenerRegistration?
    
    private func fetchedMessages() {
//        firestoreistener?.remove()
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        firestorelistener = FirebaseManager.shared.firestore
            .collection("messages")
            .document(fromID)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for message \(error)"
                    print(error)
                    
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added{
                        
                        do {
                           let cm = try
                                change.document.data(as: ChatMessage.self)
                            self.chatMessage.append(cm)
                           print("Appending chat message in ChatLogView \(Date())")
                        }catch{
                            print("failed to decoded message \(error)")
                        }
                        
                        let data = change.document.data()
                        self.chatMessage.append(.init(documentId: change.document.documentID, data: data))
                    }
                })
              
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    func handleSend() {
        print(chatText)
        
        guard let fromID = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = chatUser?.uid else { return }
        
        guard !chatText.isEmpty else {
               self.errorMessage = "Message text cannot be empty"
               return
           }
        
        
        let document = FirebaseManager.shared.firestore.collection("messages")
            .document(fromID)
            .collection(toId)
            .document()
        
        let messageData: [String: Any] = [
                    FireBaseConstants.fromId: fromID,
                    FireBaseConstants.toId: toId,
                    FireBaseConstants.text: self.chatText,
                    "timestamp": Timestamp()
                ]
        
        document.setData(messageData) {[weak self]error in
            if let error = error {
                self?.errorMessage = "Failed to save message into FireStore \(error)"
                return
            }
            print("Successfully saved current user sending message")
            
            self?.persistrecentMessage()
            self?.chatText = ""
           
            self?.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromID)
            .document()
        
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into FireStore \(error)"
                return
            }
            print("Recipient saved message as well")
            
//            self.chatText = ""
        }
        
    }
    
    private func persistrecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let toId = self.chatUser?.uid else {return}
        
        let document = FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FireBaseConstants.timestamp: Timestamp(),
            FireBaseConstants.text : self.chatText,
            FireBaseConstants.fromId : uid,
            FireBaseConstants.toId : toId,
            FireBaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FireBaseConstants.email: chatUser.email,
//            FireBaseConstants.profileImageUrl = data
            
        ] as [String : Any]
        
        document.setData(data){ error in
            if let error = error {
                self.errorMessage = "failed to save recent message \(error)"
                print("failed to save recent message \(error)")
                return
            }
        }
    }
    
    
    @Published var count = 0
}

struct ChatLogView: View {
    
    let chatUser : ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @State var chatText = ""
    
    @ObservedObject var vm : ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView 
            Text(vm.errorMessage)
        }
            .navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear{
                vm.firestorelistener?.remove()
            }
        
//            .navigationBarItems(trailing: Button(action: {
//                vm.count += 1
//            }, label: {
//                Text("Count: \(vm.count)")
//            }))
        
    }
    
    static let emptyScrollTotring = "Empty"
    
    
    private var messagesView: some View{
        
        VStack{
            
            ScrollView{
                ScrollViewReader{ scrollViewProxy in
                    VStack{
                        ForEach(vm.chatMessage) { message in
                            MessageView(message: message)
                        }
                        
                        HStack{ Spacer() }
                            .id(Self.emptyScrollTotring)
                    }
                    .onReceive(vm.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)){
                            scrollViewProxy.scrollTo(Self.emptyScrollTotring, anchor: .bottom)
                        }
                        
                    }
                    
                        
                }
                
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .background(Color(.systemBackground).ignoresSafeArea())
            }
            
        }
        
    }
    
    
    private var chatBottomBar: some View{
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
// 
            ZStack {
                DescriptionPlaceHolder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            
            
            Button{
                vm.handleSend()
            }label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct MessageView: View{
    let message: ChatMessage
    
    var body: some View{
        VStack{
            if message.fromId == FirebaseManager.shared.auth.currentUser?.uid {
                
                HStack{
                    Spacer()
                    HStack{
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                  
            }else{
                HStack{
                    HStack{
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        
      
    }
}

private struct DescriptionPlaceHolder: View {
    var body: some View{
        HStack{
            Text("Description")
                .foregroundColor(Color(.lightGray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

#Preview {
//    NavigationView{
//        ChatLogView(chatUser: .init(data: [ "uid": "YFS3kKU9gAZVa67DV5XewA56cKW2" ,"email": "jaimini@gmail.com"]))
//    }
    MainMessageView()
}
