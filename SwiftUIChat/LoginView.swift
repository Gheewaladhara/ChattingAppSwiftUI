//
//  ContentView.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 30/05/24.
//

import SwiftUI
import Firebase
import FirebaseStorage



struct LoginView: View {
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    let didCompleteLoginProcess: () -> ()
    
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    @State private var shouldShowImagePicker = false
    
    var body: some View {
        NavigationView{
            ScrollView{
                
                VStack(spacing: 16){
                    
                    Picker(selection: $isLoginMode, label: Text("Picker Here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                        
                    
                    if !isLoginMode{
                        Button{
                            shouldShowImagePicker.toggle()
                        }label: {
                            
                            VStack{
                                
                                if let image = self.image{
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128 )
                                        .cornerRadius(64)
                                }else{
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(.label))
                                }
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.black, lineWidth: 3)
                            )
                            
                        }
                    }
                    
    //                Image(systemName: "person.fill")
    //                    .font(.system(size: 64))
    //                    .padding()
                    
                    
                    Group{
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                        .padding(12)
                        .background(Color.white)
                    
                    Button{
                        handleAction()
                    }label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log  In" : "Create Account")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .font(.system(size: 14, weight: .semibold ))
                            Spacer()
                        }.background(Color.blue)
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    
                    
                }.padding()
            }
            
            .navigationTitle(isLoginMode ? "Log  in" : "Create Account")
            .background(Color(.init(white: 0, alpha: 0.05))
                .ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    
    private func handleAction() {
        if isLoginMode{
            print("Should Log Into FireBase with  Existing credentials")
            loginUser()
        }else{
            createNewAccount()
//            print("Register a new account inside of Firebase Auth then Store Image in Storage somehow...")
        }
    }
    
    private func loginUser(){
        FirebaseManager.shared.auth.signIn(withEmail: email, password: password) { result, err in
            
            if let err = err{
                print("Failed To login User: ", err)
                self.loginStatusMessage = "Failed To login  User: \(err)"
                return
            }
            
            print("SuccesFully logged in as User: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "SuccesFully logged in User: \(result?.user.uid ?? "")"
            self.isLoggedIn = true
            self.didCompleteLoginProcess()
        }
    }
    
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount(){
        if self.image == nil{
            self.loginStatusMessage = "You must select an avtar image"
            return 
        }
        
//        if self.email == nil{
//            self.loginStatusMessage = "You must filled the details"
//            return
//        }
        
        FirebaseManager.shared.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err{
                print("Failed To Create User: ", err)
                self.loginStatusMessage = "Failed To Create User: \(err)"
                return
            }
            
            print("SuccesFully Create User: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "SuccesFully Create User: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage(){
        
       // let filename = UUID().uuidString
        guard let uid = FirebaseManager .shared.auth.currentUser?.uid else{return}
        
        let ref = FirebaseManager.shared.storage.reference(withPath: uid)
        
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else{return}
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err{
                self.loginStatusMessage = "failed to push image to Storage: \(err)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err{
                    self.loginStatusMessage = "failed to retrive downloadURL: \(err)"
                    return
                }
                
                self.loginStatusMessage = "SuccessFully Stored Image WithURL: \(url?.absoluteString ?? "")"
                
                guard let url = url else { return }
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL){
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else{return}
        let userData = ["email": self.email, "uid": uid, "profileImageUrl": imageProfileUrl.absoluteString, "password": password]
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData) { err in
                if let err = err{
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("Sccess !")
                self.isLoggedIn = true
                self.didCompleteLoginProcess()  
        }
    }
}

#Preview {
    LoginView(didCompleteLoginProcess: {
         
    })
    
    
}

