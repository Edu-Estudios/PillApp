//
//  MedicinasAPIView.swift
//  PillApp
//
//  Created by Eduardo Martin Lorenzo on 27/2/22.
//

import SwiftUI

struct MedicinasAPIView: View {
    @ObservedObject var medicinesAPIVM: MedicinasAPIVM
    @AppStorage("hideLanguageDialog") private var hideLanguageDialog = false
    
    init(medicinesAPIVM: MedicinasAPIVM) {
        self.medicinesAPIVM = medicinesAPIVM
        UITableView.appearance().backgroundColor = UIColor(Color("Background"))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("Background").edgesIgnoringSafeArea(.all)
                if (medicinesAPIVM.searchedMedicines.isEmpty) {
                    VStack(alignment: .center) {
                        Image(systemName: "magnifyingglass.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("MainColor"))
                            .frame(width: 80, height: 80)
                        if (!medicinesAPIVM.isLoadingData && !medicinesAPIVM.query.isEmpty) {
                            Text("No results found")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else if (medicinesAPIVM.isLoadingData) {
                            Text("Searching...")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Find the medicine you want here.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    List {
                        ForEach(medicinesAPIVM.searchedMedicines) { medicine in
                            NavigationLink(medicine.nombre.capitalized) {
                                DetalleMedicinaApiView(medicinasAPIVM: medicinesAPIVM, medicament: medicine)
                            }
                            .onAppear {
                                if (medicinesAPIVM.searchedMedicines.count > 24 && medicine.id == medicinesAPIVM.searchedMedicines.last?.id) {
                                    medicinesAPIVM.page += 1
                                    medicinesAPIVM.launchAsync()
                                }
                            }
                        }
                    }
                    if (medicinesAPIVM.isLoadingData) {
                        ProgressView()
                            .frame(alignment: .center)
                    }
                }
            }
            .navigationTitle("Search medicaments")
            .searchable(text: $medicinesAPIVM.query)
            .onAppear {
                if (!hideLanguageDialog && !isSpanish()) {
                    NotificationCenter.default.post(name: .showAlert, object: AlertData(title: "Data Notice", image: "heart.text.square.fill", text: "The medicines that appear in this functionality are only medicines sold in Spain.", textButton: "See spanish info"))
                    hideLanguageDialog = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MedicinasAPIView_Previews: PreviewProvider {
    static var previews: some View {
        MedicinasAPIView(medicinesAPIVM: MedicinasAPIVM())
    }
}
