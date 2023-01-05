
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
            ShoppinListView()
           // SettingsView()
        }
    }
}

struct SigningInView: View {
    @Binding var signedIn : Bool
    
    var body: some View {
        Text("Signing in...")
            .onAppear() {
                let user = Auth.auth().currentUser
                if user == nil {
                    Auth.auth().signInAnonymously { authResult, error in
                        if let error = error {
                            print("error signing in \(error)")
                            
                        } else {
                            print("Signed in \(Auth.auth().currentUser?.uid)")
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

struct ShoppinListView: View {
    let db = Firestore.firestore()
    @State private var newItemName = ""
    @State var item = [Item]()
    @ObservedObject var items = Items()
    @State var isAddingItem = false
    @State var emptyList = true
    //@ObservedObject var test = Items()
    
    var body: some View {
        
        NavigationView {
            VStack {
                if emptyList {
                    Text("Tap to add a new item")
                        .font(.headline)
                        .fontWeight(.regular)
                }
                List {
                    
                    ForEach(items.items) { item in
                        ItemRowView(item: item, emptyList: $emptyList)
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
                    self.emptyList = false
                    self.isAddingItem = true
                }
                .onReceive(items.objectWillChange) { // tillfällig lösning
                               if items.test {
                                   print("items.test är sant")
                               } else {
                                   print("items.test är falskt")
                               }
                           }
            }.onAppear() {
                items.listenToFirestore()
                if items.test{
                    print("sant")
                } else {
                    print("falsk")
                }
            }
        }
    }
}

struct SettingsView : View {
    let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
    @State var email = ""
    @State var password = ""
    
    
    var body: some View {
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
            //Spacer()
            Text("Create an new account here")
                .foregroundColor(.blue)
                .onTapGesture {
                    print("the user want to create an new account")
                }
            Spacer()
            Button(action: {
                print("Button tapped! \(email), \(password)")
                createAccount()
            }) {
                LoginButtonContent()
            }
            Spacer()
        }
        .padding()
    }
    
    func createAccount () {
        let email = $email.wrappedValue
        let password = $password.wrappedValue
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("error signing in \(error)")
            } else {
                print("signed in \(authResult?.user.uid)")
            }
        }
    }
    
}

struct LoginButtonContent : View {
    var body: some View {
        Text("LOGIN")
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
    @Binding var emptyList : Bool
    
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
            emptyList = false
        }
    }
}

