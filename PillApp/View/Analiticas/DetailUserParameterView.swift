//
//  DetailMeasurement.swift
//  PillApp
//
//  Created by Eduardo Martin Lorenzo on 1/6/22.
//

import SwiftUI

struct DetailUserParameter: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var analyticsVM: AnalyticsVM
    @ObservedObject var detailParametersVM: DetailParametersVM
    
    @FocusState var actualField: ParametersField?
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    
    var body: some View {
        Form {
            TextField("Value", value: $detailParametersVM.parameterValue, formatter: formatter)
                .keyboardType(.decimalPad)
                .focused($actualField, equals: .value)
            DatePicker("Analytic date", selection: $detailParametersVM.parameterDate,displayedComponents: .date)
            Menu {
                ForEach(detailParametersVM.parameterTypes) { type in
                    Button(type.name) {
                        detailParametersVM.parameterTypeSelected = type
                    }
                }
            } label: {
                HStack {
                    Text("Parameter")
                    
                    Spacer()
                    
                    Text("\(detailParametersVM.parameterTypeSelected?.name ?? "")")
                }
            }
        }
        .background(Color("Background"))
        .navigationTitle(detailParametersVM.isEdition ? "Edit parameter" : "Add parameter")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(detailParametersVM.isEdition ? "Edit" : "Create") {
                    detailParametersVM.save(context: viewContext)
                    dismiss()
                }
                .disabled(detailParametersVM.parameterValue == 0.0)
            }
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button {
                        actualField = nil
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
        }
    }
}

struct DetailMeasurement_Previews: PreviewProvider {
    static var previews: some View {
        DetailUserParameter(detailParametersVM: DetailParametersVM(parameter: nil, parameterTypes: [], userParameters: []))
    }
}