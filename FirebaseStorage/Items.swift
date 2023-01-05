//
//  Items.swift
//  FirebaseStorage
//
//  Created by Elin Simonsson on 2023-01-03.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class Items : ObservableObject {
    @Published var items = [Item]()
    @Published var test = false
    private var db = Firestore.firestore()
    
    
    func listenToFirestore() {
        guard let user = Auth.auth().currentUser else {return}

        db.collection("users").document(user.uid).collection("items").addSnapshotListener { snapshot, err in
            guard let snapshot = snapshot else {return}

            if let err = err {
                print("Error getting document \(err)")
            } else {
                self.items.removeAll()
                for document in snapshot.documents {

                    let result = Result {
                        try document.data(as: Item.self)
                    }
                    switch result  {
                    case .success (let item) :
                        self.test = true
                        print("inom listenToFirestore \(self.test)")
                        self.items.append(item)
                    case .failure(let error) :
                        print("Error decoding item: \(error)")
                    }
                }
            }
        }
    }
    
    func updateCheckMark (currentItem: Item) {
        if let id = currentItem.id,
           let user = Auth.auth().currentUser {
            
            db.collection("users").document(user.uid).collection("items").document(id).updateData(["done" : !currentItem.done])
        }
    }
    
    func deleteItem(indexSet: IndexSet) {
        for index in indexSet {
            let item = items[index]
            if let id = item.id,
               let user = Auth.auth().currentUser {
                db.collection("users").document(user.uid)
                    .collection("items").document(id).delete()
            }
        }
    }
    
    func addItem (itemName: String) {
        let item = Item(name: itemName)
        guard let user = Auth.auth().currentUser else {return}
        
        do {
            _ = try db.collection("users")
                .document(user.uid)
                .collection("items").addDocument(from: item)
            print("successed to save")
        } catch {
            print("Error saving to Firebase")
        }
    }
}

