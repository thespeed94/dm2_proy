//
//  ViewModel.swift
//  CL_02_DavidArrarte
//
//  Created by David Arrarte on 5/06/22.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class ViewModel: ObservableObject {
    @Published var list = [Todo]()
    @Published var gettedTodo = Todo(id: "", name: "")
    
    func updateData(id: String, name: String) {
        // referencia a la BD
        let db = Firestore.firestore()
        
        db.collection("todos").document(id).setData(["name": name], merge: true) { error in
            // verificamos errores
            if error == nil {
                // sin errores
                self.getData()
            } else {
                
            }
        }
    }
    
    func deleteData(todoToDelete: String) {
        // referencia a la BD
        let db = Firestore.firestore()
        
        db.collection("todos").document(todoToDelete).delete { error in
            // verificamos errores
            if error == nil {
                // sin errores
                
                DispatchQueue.main.async {
                    // eliminamos la lista que eliminamos
                    self.list.removeAll { todo in
                        // validamos que sea el mismo id a eliminar
                        return todo.id == todoToDelete
                    }
                }
                
            } else {
                
            }
        }
    }
    
    func addData(name: String) {
        // referencia a la BD
        let db = Firestore.firestore()
        
        db.collection("todos").addDocument(data: ["name": name]) { error in
            // verificamos errores
            if error == nil {
                // sin errores
                self.getData()
            } else {
                
            }
        }
    }
    
    func getDataById(uid: String) {
        // referencia a la BD
        let db = Firestore.firestore()
        
        db.collection("todos").getDocuments{ (snapshot, error) in
            // validamos errores
            if error == nil {
                if let snapshot = snapshot {
                    // actualizamos la lista en el hilo principal
                    DispatchQueue.main.async {
                        // obtenemos todos los documentos
                        snapshot.documents.map{ d in
                            // creamos y seteamos cada documento obtenido de firebase
                            if uid == d.documentID {
                                self.gettedTodo = Todo(id: d.documentID, name: d["name"] as? String ?? "")
                            }
                            
                        }
                        
                        if self.gettedTodo.id.isEmpty {
                            return;
                        }
                    }
                    
                }
            } else {
                
            }
        }
    }
    
    func getData() {
        
        // referencia a la BD
        let db = Firestore.firestore()
        
        db.collection("todos").getDocuments{ (snapshot, error) in
            // validamos errores
            if error == nil {
                if let snapshot = snapshot {
                    // actualizamos la lista en el hilo principal
                    DispatchQueue.main.async {
                        // obtenemos todos los documentos
                        self.list = snapshot.documents.map{ d in
                            // creamos y seteamos cada documento obtenido de firebase
                            return Todo(id: d.documentID, name: d["name"] as? String ?? "")
                        }
                    }
                    
                }
            } else {
                
            }
        }
    }
}
