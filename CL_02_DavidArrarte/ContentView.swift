//
//  ContentView.swift
//  CL_02_DavidArrarte
//
//  Created by David Arrarte on 5/06/22.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class AppViewModel: ObservableObject {
    
    let auth = Auth.auth()
    let databaseFire = Firestore.firestore()
    
    @Published var signedIn = false
    @Published var signedEmail = ""
    @Published var statusMessage = ""
    @Published var statusMessageIsError = true
    @Published var fullnameData = ""
    @Published var usertypeData = ""
    
    // Para el cRUD
    @Published var crudId = ""
    @Published var crudName = ""
    
    var isSignedIn: Bool {
        getDataUser(currentUid: auth.currentUser?.uid ?? "")
        return auth.currentUser != nil
    }
    
    var currentSignedEmail: String {
        return auth.currentUser?.email ?? ""
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            self.statusMessage = "Email y contraseña obligatorios"
            return
        }
        auth.signIn(withEmail: email, password: password) {[weak self] result, error in
            guard result != nil, error == nil else {
                print("Error al niciar sesión: ", error!.localizedDescription)
                self?.statusMessage = "Error al iniciar sesión: \(error!.localizedDescription)"
                return
            }
            
            DispatchQueue.main.async { [self] in
                let user = Auth.auth().currentUser
                // Exitoso
                self?.statusMessage = ""
                self?.signedIn = true
                self?.signedEmail = (user?.email)!
                self?.getDataUser(currentUid: user!.uid)
            }
        }
    }
    
    func signUp(email: String, password: String, fullname: String, usertype: String) {
        guard !email.isEmpty, !password.isEmpty, !fullname.isEmpty, !usertype.isEmpty else {
            self.statusMessage = "Todos con campos son obligatorios"
            return
        }
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                print("Error al registrar usuario: ", error!.localizedDescription)
                self?.statusMessage = "Error al registrar usuario: \(error!.localizedDescription)"
                return
            }
            DispatchQueue.main.async {
                // Exitoso
                guard let uid = self?.auth.currentUser?.uid else {
                    return
                }
                self?.auth.addStateDidChangeListener { (auth, user) in
                  if (user != nil) {
                      let userData = ["fullname": fullname, "email": email, "password": password, "usertype": usertype]
                      Firestore.firestore().collection("users")
                          .document(uid).setData(userData) { err in
                              if let err = err {
                                  print("Error", err)
                                  return
                              }
                      }
                  }
                }
                
                let user = Auth.auth().currentUser
                self?.statusMessage = ""
                self?.signedIn = true
                self?.signedEmail = (user?.email)!
                self?.getDataUser(currentUid: user!.uid)
                print("Exitoso")
            }
                
        }
    }
    
    
    func signOut(){
        try? auth.signOut()
        
        self.signedIn = false
        self.statusMessage = ""
        cleanDataUser()
    }
    
    func getDataUser(currentUid: String) {
        if !currentUid.isEmpty {
            let docRef = Firestore.firestore().collection("users").document(currentUid)
            return docRef.getDocument {(document, error) in
                guard error == nil else {
                    print("error", error ?? "")
                    return
                }
                if let document = document, document.exists {
                    let data = document.data()
                    self.fullnameData = data?["fullname"] as! String
                    self.usertypeData = data?["usertype"] as! String
                }
            }
        }
    }
    
    func cleanDataUser() {
        self.fullnameData = ""
        self.usertypeData = ""
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @ObservedObject var model = ViewModel()
    let currentEmail = Auth.auth().currentUser?.email;
    let currentUid = Auth.auth().currentUser?.uid;
    // temp Crud
    @State var sCrudId = ""
    @State var sCrudName = ""
    
    var body: some View {
        NavigationView {
            if viewModel.signedIn {
                VStack {
                    Text("Bienvenido, " + viewModel.signedEmail)
                    Text(viewModel.fullnameData)
                    TextField("Id", text: $sCrudId)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                    TextField("Name", text: $sCrudName)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                    HStack {
                        Button(action: {
                            guard !sCrudName.isEmpty else {
                                viewModel.statusMessage = "El nombre es obligatorio"
                                return
                            }
                            model.addData(name: sCrudName)
                            
                            sCrudName = ""
                            viewModel.statusMessage = ""
                        }, label: {
                            Text("Agregar")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.806))
                                .foregroundColor(Color.black)
                        })
                        Button(action: {
                            model.getDataById(uid: sCrudId)
                            sCrudName = model.gettedTodo.name
                        }, label: {
                            Text("Obtener")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.806))
                                .foregroundColor(Color.black)
                        })
                    }
                    HStack {
                        Button(action: {
                            guard !sCrudName.isEmpty, !sCrudId.isEmpty else {
                                viewModel.statusMessage = "El nombre y id es obligatorio"
                                return
                            }
                            model.updateData(id: sCrudId, name: sCrudName)
                            sCrudName = ""
                            sCrudId = ""
                            viewModel.statusMessage = ""
                        }, label: {
                            Text("Actualizar")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.806))
                                .foregroundColor(Color.black)
                        })
                        Button(action: {
                            guard !sCrudId.isEmpty else {
                                viewModel.statusMessage = "El id es obligatorio"
                                return
                            }
                            model.deleteData(todoToDelete: sCrudId)
                            sCrudName = ""
                            sCrudId = ""
                            viewModel.statusMessage = ""
                        }, label: {
                            Text("Eliminar")
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Color(hue: 1.0, saturation: 0.0, brightness: 0.806))
                                .foregroundColor(Color.black)
                        })
                    }
                    Text(viewModel.statusMessage)
                        .padding()
                        .foregroundColor(Color.red)
                    List (model.list) { item in
                        Text(item.id + " | " + item.name)
                            .onTapGesture {
                                sCrudId = item.id
                                sCrudName = item.name
                            }
                    }
                    Button(action: {
                        viewModel.signOut()
                    }, label: {
                        Text("Cerrar sesión")
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .background(Color.green)
                            .foregroundColor(Color.white)
                            .cornerRadius(10)
                            .padding()
                    })
                }
            } else {
                SignInView()
            }
            
        }
        .onAppear {
            viewModel.signedIn = viewModel.isSignedIn
            viewModel.signedEmail = viewModel.currentSignedEmail
        }
        
    }
    
    init() {
        model.getData()
    }
}


struct SignInView: View {
    @State var email = ""
    @State var password = ""
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                TextField("Email", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                SecureField("Contraseña", text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                Button(action: {
                    guard !email.isEmpty, !password.isEmpty else {
                        return
                    }
                    
                    viewModel.signIn(email: email, password: password)
                    
                }, label: {
                    Text("Logear")
                        .foregroundColor(Color.white)
                        .frame(width: 200, height: 50)
                        .cornerRadius(0)
                        .background(Color.blue)
                })
                
                NavigationLink("Crear una cuenta", destination: SignUpView())
                    .padding()
                Text(viewModel.statusMessage)
                    .padding()
                    .foregroundColor(Color.red)
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Login")
        
    }
}

struct SignUpView: View {
    @State var email = ""
    @State var password = ""
    @State var fullname = ""
    @State var usertype = ""
    var dropDownList = ["Estudiante", "Profesor"]
    var placeholderList = "Seleccionar Tipo"
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            VStack {
                TextField("Nombre Completo", text: $fullname)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                TextField("Email", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                SecureField("Contraseña", text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                Menu {
                    ForEach(dropDownList, id: \.self){ client in
                        Button(client) {
                            self.usertype = client
                        }
                    }
                } label: {
                    Text(usertype.isEmpty ? placeholderList : usertype)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .foregroundColor(usertype.isEmpty ? .gray : .black)
                
                    
                    
                Button(action: {
                    guard !fullname.isEmpty, !email.isEmpty, !password.isEmpty, !usertype.isEmpty else {
                        return
                    }
                    
                    viewModel.signUp(email: email, password: password, fullname: fullname, usertype: usertype)
                    
                }, label: {
                    Text("Crear cuenta")
                        .foregroundColor(Color.white)
                        .frame(width: 200, height: 50)
                        .cornerRadius(0)
                        .background(Color.blue)
                })
                Text(viewModel.statusMessage)
                    .padding()
                    .foregroundColor(Color.red)
                    
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Crear una cuenta")
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
