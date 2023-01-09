
//
//  ContentView.swift
//  Firebase-Shoppinglist
//
//  Created by David Svensson on 2023-01-03.
//
import SwiftUI
import Firebase
import FirebaseAuth

// 1. förbättra strukturen genom att lägga över shoppinglistan ( items)
// i ett observable object
// 2. användaren kan välja att skapa ett konto i en instälnings sida.
//
struct ContentView: View {
    
    @State var signedIn = false
    
    var body: some View {
        if !signedIn {
            SigningInView(signedIn: $signedIn)
        } else   {
            ShoppingListView()
        }
    }
}

struct SigningInView: View {
    @Binding var signedIn : Bool
    
    var body: some View {
        
        if !signedIn {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(3)
                .onAppear() {
                    let user = Auth.auth().currentUser
                    if user == nil {
                        Auth.auth().signInAnonymously { authResult, error in
                            if let error = error {
                                print("error signing in \(error)")
                                
                            } else {
                                print("Signed in \(Auth.auth().currentUser!.uid)")
                                signedIn = true
                            }
                        }
                    } else {
                        signedIn = true
                        print("redan inloggad")
                    }
                }
            }
    }
}

struct ShoppingListView: View {
    let db = Firestore.firestore()
    @State private var newItemName = ""
    @State var item = [Item]()
    @ObservedObject var items = Items()
    @State var isAddingItem = false
    
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(items.items) { item in
                        ItemRowView(item: item)
                    }.onDelete() { indexSet in
                        items.deleteItem(indexSet: indexSet)
                    }
                    if isAddingItem {
                        AddingItemView(isAddingItem: $isAddingItem)
                    }
                }
                .navigationTitle("ShoppingList")
                .navigationBarItems(trailing: NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape")
                })
                .onTapGesture {
                    self.isAddingItem = true
                }
                .onReceive(items.objectWillChange) {
                    if items.test {
                        isAddingItem = false
                    } else {
                        isAddingItem = true
                    }
                }
            }.onAppear() {
                items.listenToFirestore()
            }
        }
    }
}

struct SettingsView : View {
    let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
    @State var email = ""
    @State var password = ""
    @State var showCreateAccountView = false
    @Environment(\.presentationMode) var presentationMode
    @State var isAnonymous = false
    @State var showText = true
    @State var showContentView = false
    
    var body: some View {
        if showText {
            Text("")
                .onAppear(){
                    guard let user = Auth.auth().currentUser else {return}
                    if user.isAnonymous {
                        isAnonymous = true
                        showText = false
                    } else {
                        isAnonymous = false
                        showText = false
                    }
                }
        }
        if isAnonymous {
            VStack {
                Spacer()
                WelcomeText()
                Spacer()
                UserImage()
                TextField("Email", text: $email)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                SecureField("Password", text: $password)
                    .padding()
                    .background(lightGreyColor)
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                Button(action: {
                    showCreateAccountView = true
                }) {
                    Text("Create an new account here!")
                }
                .fullScreenCover(isPresented: $showCreateAccountView, content: CreateAccountView.init)
                
                Spacer()
                Button(action: {
                    print("Button tapped! \(email), \(password)")
                    signIn()
                }) {
                    LoginButtonContent(signText: "LOGIN")
                }
                Spacer()
            }
            .padding()
            
        } else {
            Text("the user is NOT anonymous")
            UserImage()
                .padding(.top, 20)
            Button(action: {
                signOut()
            }) {
                LoginButtonContent(signText: "SIGN OUT")
            }
            .fullScreenCover(isPresented: $showContentView, content: ContentView.init) // hur backar man direkt till contentView utan att skapa ny instans av contentView?
        }
    }
    
    func signIn () {
        let email = $email.wrappedValue
        let password = $password.wrappedValue
        
        
        Auth.auth().signIn(withEmail: email, password: password){ authResult, error in
            if let error = error {
                print("error signing in \(error)")
            } else {
                print("signed in \(authResult!.user.uid)")
                presentationMode.wrappedValue.dismiss()
            }
        }
        
    }
    
    func signOut () {
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
            showContentView = true
        } catch let signOutError as NSError {
            print("Error signing out: ‰@", signOutError)
        }
    }
    
}

struct LoginButtonContent : View {
    var signText : String
    var body: some View {
        Text(signText)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 220, height: 60)
            .background(Color.orange)
            .cornerRadius(15.0)
    }
}

struct WelcomeText : View {
    var body : some View {
        Text("Welcome!")
            .font(.largeTitle)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct UserImage : View {
    var body: some View {
        Image(systemName: "person")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .clipped()
            .cornerRadius(150)
            .padding(.bottom, 75)
        
    }
}

struct CreateAccountText : View {
    var body : some View {
        Text("Creating an new account")
            .font(.title)
            .fontWeight(.semibold)
            .padding(.bottom, 20)
    }
}

struct CreateAccountView : View {
    let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
    @Environment(\.presentationMode) var presentationMode
    @State var showContentView = false
    @State var email = ""
    @State var password = ""
    @State var repeatPassword = ""
    
    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("< Back")
                    .padding(.leading, 10)
                    .font(.title2)
            }
            Spacer()
        }
        VStack {
            Spacer()
            CreateAccountText()
            Spacer()
            UserImage()
            TextField("Email", text: $email)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Password", text: $password)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            SecureField("Repeat password", text: $repeatPassword)
                .padding()
                .background(lightGreyColor)
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            Button(action: {
                //presentationMode.wrappedValue.dismiss()
                createAccount()
            }) {
                LoginButtonContent(signText: "Sign up")
            }
            .fullScreenCover(isPresented: $showContentView, content: ContentView.init) // hur backar man direkt till contentView utan att skapa ny instans av contentView?
            .padding(.top, 20)
        }
        .padding()
    }
    
    func createAccount() {
        let email = $email.wrappedValue
        let password = $password.wrappedValue
        let repeatPassword = $repeatPassword.wrappedValue
        
        if password == repeatPassword {
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("error signing in \(error)")
                } else {
                    showContentView = true
                    print("signed in \(authResult?.user.uid)")
                    
                }
            }
        } else {
            print("lösenord stämmer inte")
        }
    }
}

struct AddingItemView : View {
    @StateObject var items = Items()
    @Binding var isAddingItem : Bool
    @State var newItemName = ""
    
    var body: some View {
        HStack {
            TextField("New item", text: $newItemName, onCommit: {
                items.addItem(itemName: self.newItemName)
                
                self.isAddingItem = false
            })
            .onAppear() {
                self.newItemName = ""
            }
        }
    }
}

struct ItemRowView: View {
    let db = Firestore.firestore()
    
    let item : Item
    @StateObject var items = Items()
    
    var body: some View {
        HStack {
            Text(item.name)
            Spacer()
            Image(systemName: item.done ? "checkmark.circle" : "circle")
                .imageScale(.large)
                .foregroundColor(Color.orange)
                .onTapGesture {
                    items.updateCheckMark(currentItem: item)
                }
        }.onAppear() {
            print("listan är här")
            
        }
    }
}

