//
//  MedicinasAPIVM.swift
//  PillApp
//
//  Created by Eduardo Martin Lorenzo on 27/2/22.
//

import SwiftUI

final class MedicinasAPIVM: ObservableObject {
    var task: Task<(), Never>?
    
    @Published var searchedMedicines: [MedicineAPI] = []
    @Published var isLoadingData = false
    
    @Published var query = "" {
        didSet {
            page = 1
            
            if !query.isEmpty {
                if task != nil {
                    task?.cancel()
                }
                task = Task { await find() }
            }             
        }
    }
    
    @Published var page = 1 {
        didSet {
            Task(priority: .high) {
                await find()
            }
        }
    }
    
    @Published var dataSheetURL = ""
    @Published var leaftletURL = ""
    
    /// Recupera de forma asíncrona las medicinas de la API de medicinas de CIMA.
    @MainActor func find() async {
        do {
            if (query == "") {
                searchedMedicines.removeAll()
            } else {
                isLoadingData = true
                let decoder = JSONDecoder()
                let (data, _) = try await URLSession.shared.data(from: .urlMedicines(name: query, page: page))
                let result = try decoder.decode(Results.self, from: data)
                if self.page == 1 {
                    self.searchedMedicines.removeAll()
                }
                searchedMedicines.append(contentsOf: result.resultados)
                isLoadingData = false
            }
            
        } catch {
            print("Error recuperando la lista de medicinas \(error)")
        }
    }
    
    /// Recupera la url del documento de una medicina, en función del tipo
    ///
    ///  - Parameter medicament: Objeto de la medicina --> (MedicineAPI)
    ///  - Parameter type: Tipo del documento que se quiere obtener. --> (String)
    ///  - Returns: String
    func getFile(_ medicament: MedicineAPI, type: Int) -> String {
        if let docs = medicament.docs, let document = docs.filter({ $0.tipo == type}).first {
            return document.url
        } else {
            return ""
        }
    }
}
