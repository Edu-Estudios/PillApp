//
//  DetailMedicinasVM.swift
//  PillApp
//
//  Created by Eduardo Martin Lorenzo on 19/3/22.
//

import SwiftUI
import CoreData

final class DetailMedicinasVM: ObservableObject {
    @Published var isEdition = false
    @Published var medicineName = ""
    @Published var medicineNotes = ""
    @Published var category: Categories = .others
    @Published var icon: Icons = .pills
    
    @Published var initialDate = Date.now
    @Published var finalDate = Date.now
    @Published var medicineDate = Date.now // Se utiliza para la edicion de una medicina
    
    @Published var dailyPeriodicities = [1, 2, 3, 4]
    @Published var dailyPeriodicity = 0
    
    @Published var hourFirstTime = Date.now
    @Published var hourSecondTime = Date.now
    @Published var hourThirdTime = Date.now
    @Published var hourFourthTime = Date.now
    
    @Published var periodicity = Periodicities.day
    @Published var dayOfWeek = DaysOfWeek.monday
    
    
    var medicine: Medicinas?
    
    init(medicine: Medicinas?) {
        if let medicine = medicine {
            self.medicine = medicine
            isEdition = true
            medicineName = medicine.name ?? ""
            medicineNotes = medicine.notes ?? ""
            category = Categories(rawValue: medicine.category ?? "Others") ?? .others
            icon = Icons(rawValue: medicine.icon ?? "Pills") ?? .pills
            medicineDate = medicine.date ?? Date.now
        }
    }
    
    /// Realiza la llamada a los métodos de guardar los datos. En función de la variable **isEdition** llamará al método **edit** o al método **create** para editar o crear un recordatorio de medicinas
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    @MainActor
    func save(context: NSManagedObjectContext) {
        Task {
            do {
                if isEdition {
                    try await edit(context: context)
                } else {
                    try await create(context: context)
                }
                NotificationCenter.default.post(name: .updateYears, object: nil)
            } catch {
                print("ERROR saving data \(error.localizedDescription)")
            }
        }
    }
    
    /// Realiza la tarea asíncrona de crear un nuevo recordatorio de medicina. Los errores lanzados (throws) serán gestionados en el método **save**
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    func create(context: NSManagedObjectContext) async throws{
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: initialDate), to: Calendar.current.startOfDay(for: finalDate))
        let idGroup = UUID()
        if let days = components.day {
            switch periodicity {
            case .day:
                for day in 0...days {
                    var date = Calendar.current.date(byAdding: .day, value: day, to: initialDate) ?? Date.now
                    
                    for period in 0...dailyPeriodicity {
                        
                        switch period {
                        case 0:
                            let hour = Calendar.current.component(.hour, from: hourFirstTime)
                            let minutes = Calendar.current.component(.minute, from: hourFirstTime)
                            
                            date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        case 1:
                            let hour = Calendar.current.component(.hour, from: hourSecondTime)
                            let minutes = Calendar.current.component(.minute, from: hourSecondTime)
                            
                            date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        case 2:
                            let hour = Calendar.current.component(.hour, from: hourThirdTime)
                            let minutes = Calendar.current.component(.minute, from: hourThirdTime)
                            
                            date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        case 3:
                            let hour = Calendar.current.component(.hour, from: hourFourthTime)
                            let minutes = Calendar.current.component(.minute, from: hourFourthTime)
                            
                            date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        default:
                            print("ERROR: Error no controlado")
                        }
                        
                        try await createMedicine(context: context, idGroup: idGroup, date: date)
                    }
                }
            case .week:
                for day in 0...(days + 1) {
                    var date = Calendar.current.date(byAdding: .day, value: day, to: initialDate) ?? Date.now
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    let dayInWeek = dateFormatter.string(from: date)
                    
                    if dayOfWeek.rawValue == dayInWeek {
                        let hour = Calendar.current.component(.hour, from: hourFirstTime)
                        let minutes = Calendar.current.component(.minute, from: hourFirstTime)
                        
                        date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        try await createMedicine(context: context, idGroup: idGroup, date: date)
                    }
                    
                    
                }
            case .biweekly:
                for day in 0...(days + 1) {
                    if (day % 15 == 0) {
                        var date = Calendar.current.date(byAdding: .day, value: day, to: initialDate) ?? Date.now
                        let hour = Calendar.current.component(.hour, from: hourFirstTime)
                        let minutes = Calendar.current.component(.minute, from: hourFirstTime)
                        
                        date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        
                        try await createMedicine(context: context, idGroup: idGroup, date: date)
                    }
                }
            case .monthly:
                for day in 0...(days + 1) {
                    if (day % 30 == 0) {
                        var date = Calendar.current.date(byAdding: .day, value: day, to: initialDate) ?? Date.now
                        let hour = Calendar.current.component(.hour, from: hourFirstTime)
                        let minutes = Calendar.current.component(.minute, from: hourFirstTime)
                        
                        date = Calendar.current.date(bySettingHour: hour, minute: minutes, second: 0, of: date) ?? Date.now
                        
                        try await createMedicine(context: context, idGroup: idGroup, date: date)
                    }
                }
            }
        }
    }
    
    /// Realiza el guardado de un recordatorio de medicina en Core Data de manera asíncrona. Los errores lanzados (throws) serán gestionados en el método **save**
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    func createMedicine(context: NSManagedObjectContext, idGroup: UUID, date: Date) async throws {
        let medicine = Medicinas(context: context)
        let id = UUID()
        medicine.id = id
        medicine.idGroup = idGroup
        medicine.name = medicineName
        medicine.notes = medicineNotes
        medicine.date = date
        medicine.category = category.localizedString()
        medicine.icon = icon.rawValue
        medicine.taken = false
        
        try await context.perform {
            try context.save()
            Notifications().createNotification(id: id, date: date, element: self.medicineName, type: 1)
        }
    }
    
    /// Realiza el guardado de los datos editados un recordatorio de medicina en Core Data de manera asíncrona. Los errores lanzados (throws) serán gestionados en el método **save**
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    func edit(context: NSManagedObjectContext) async throws {
        let oldDate = medicine?.date ?? Date.now
        medicine?.name = medicineName
        medicine?.notes = medicineNotes
        medicine?.category = category.localizedString()
        medicine?.icon = icon.rawValue
        medicine?.date = medicineDate
        
        try await context.perform {
            if ((self.medicine?.hasChanges) != nil) {
                try context.save()
                let id = self.medicine?.id ?? UUID()
                if self.medicineDate != oldDate {
                    Notifications().eliminarNotificacion(id: id)
                    Notifications().createNotification(id: id, date: self.medicineDate, element: self.medicineName, type: 1)
                }
            }
        }
    }
    
    /// Realiza la tarea asíncrona de eliminar un recordatorio, o un bloque, de medicinas.
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    ///  - Parameter medicine: objeto de la medicina que se quiere eliminar. --> (Medicinas)
    ///  - Parameter deleteAll: permite indicar si se quiere borrar un recordatorio de forma individual o si se quieren eliminar todos los recordatorios asociados. --> (Bool)
    func delete(context: NSManagedObjectContext, medicine: Medicinas, deleteAll: Bool) {
        Task {
            do {
                if !deleteAll {
                    try await deleteOne(context: context, medicine: medicine)
                } else {
                    try await deleteAllGroup(context: context, medicines: getMedicamentsWith(medicament: medicine, context: context))
                }
            }
        }
    }
    
    /// Realiza la tarea asíncrona de eliminar un recordatorio de medicinas.
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    ///  - Parameter medicine: objeto de la medicina que se quiere eliminar. --> (Medicinas)
    func deleteOne(context: NSManagedObjectContext, medicine: Medicinas) async throws {
        if let id = medicine.id {
            context.delete(medicine)
            do {
                try context.save()
                Notifications().eliminarNotificacion(id: id)
            } catch {
                print("ERROR in medicine delete: \(error.localizedDescription)")
            }
        }
    }
    
    /// Realiza la tarea asíncrona de eliminar un bloque de recordatorios de medicinas
    ///
    ///  - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    ///  - Parameter medicine: array de objetos medicina que se quiere eliminar. --> ([Medicinas])
    func deleteAllGroup(context: NSManagedObjectContext, medicines: [Medicinas]) async throws {
        for medicine in medicines {
            if let id = medicine.id {
                context.delete(medicine)
                Notifications().eliminarNotificacion(id: id)
            }
        }
        
        do {
            try context.save()
        } catch {
            print("ERROR in medicament delete: \(error.localizedDescription)")
        }
    }
    
    /// Recupera de Core Data el array de medicinas asociados por el **idGroup** de una medicina
    ///
    /// - Parameter medicament: objeto de la medicina de la que se obtendrán todos los recordatorios asociados. --> (Medicinas)
    /// - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    /// - Returns: [Medicinas]
    func getMedicamentsWith(medicament: Medicinas, context: NSManagedObjectContext) -> [Medicinas] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Medicinas")
        fetchRequest.predicate = NSPredicate(format: "idGroup == %@ && date >= %@", (medicament.idGroup ?? UUID()) as CVarArg, Calendar.current.startOfDay(for: medicament.date ?? Date.now) as CVarArg)
        do {
            return try context.fetch(fetchRequest) as! [Medicinas]
        } catch {
            print("ERROR: \(error.localizedDescription)")
        }
        return []
    }
    
    /// Realiza la modificación, de manera asíncrona, del estado de un recordatorio de medicina.
    ///
    /// - Parameter medicament: objeto de la medicina que se quiere editar el estado. --> (Medicinas)
    /// - Parameter context: contexto de la aplicación para la gestión de los datos de Core Data. --> (NSManagedObjectContext)
    func changeState(medicament: Medicinas, context: NSManagedObjectContext) async {
        medicament.taken.toggle()
        
        do {
            try await context.perform {
                    try context.save()
                    if (medicament.taken) {
                        Notifications().eliminarNotificacion(id: medicament.id ?? UUID())
                    } else {
                        Notifications().createNotification(id: medicament.id ?? UUID(), date: medicament.date ?? Date.now, element: medicament.name ?? "", type: 1)
                    }
            }
        } catch {
            print("ERROR changing state: \(error.localizedDescription)")
        }
    }
}
