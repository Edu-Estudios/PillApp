//
//  ContentView.swift
//  PillApp
//
//  Created by Eduardo Martin Lorenzo on 25/1/22.
//

import SwiftUI

struct ContentView: View {
    @State private var showAlert = false
    @State private var alertData = AlertData.empty
    
    var body: some View {
        ZStack {
            TabView {
                MedicinasView(medicinesVM: MedicinesVM())
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                MedicinasAPIView(medicinesAPIVM: MedicinasAPIVM())
                    .tabItem {
                        Label("Medicines", systemImage: "pills")
                    }
            }
            // TODO: Corregir bug del Blur
            //.blur(radius: showAlert ? 30 : 0)
            .onReceive(NotificationCenter.default.publisher(for: .showAlert)) { notification in
                if let data = notification.object as? AlertData {
                    showAlert = true
                    alertData = data
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .hideAlert)) { _ in
                showAlert = false
            }
            
            
            if (showAlert) {
                AlertView(image: alertData.image, title: alertData.title, text: alertData.text, seeButtons: true)
            }
             
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
