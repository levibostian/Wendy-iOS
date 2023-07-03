import CoreData
import Foundation

internal class CoreDataManager {
    internal static let shared = CoreDataManager()

    private init() {}
    
    internal lazy var privateContext: NSManagedObjectContext = {
        var managedObjectContext: NSManagedObjectContext?
        if #available(iOS 10.0, *) {
            managedObjectContext = self.persistentContainer.newBackgroundContext()
        } else {
            // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
            let coordinator = self.persistentStoreCoordinator
            managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            managedObjectContext?.persistentStoreCoordinator = coordinator
        }
        return managedObjectContext!
    }()

    private lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named in the application's documents Application Support directory.
        var documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        documentUrl.appendPathComponent("WendyDataModel.sqlite")
        return documentUrl
    }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.frameworkUrlForWendyFramework().url(forResource: "Wendy", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.applicationDocumentsDirectory, options: nil)
            return coordinator
        } catch let error as NSError {
            Fatal.error("Error setting up database in Wendy.", error: error)
            return coordinator
        }
    }()

//    @available(iOS 10.0, *)
    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Wendy", managedObjectModel: self.managedObjectModel)
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error with core data \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    internal func saveContext() {
        if privateContext.hasChanges {
            privateContext.performAndWait {
                do {
                    try privateContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
//                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextError"), object: "Wendy Coredata error \(nserror), \(nserror.userInfo)")
                    NotificationCenter.default.post(name: Notification.Name("wendyCoreDataSaveContextErrorPendingTaskUserInfo"), object: nserror.userInfo)
                }
            }
        }
    }
}
