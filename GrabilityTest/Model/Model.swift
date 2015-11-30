//
//  Model.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit
import CoreData

// Model class. In charge of providing data for display. It exposses only one method
// for loading data from server. Internally, it keeps a cache wich is used as fallback
// if network is not availble.
//
//
class Model{
    static private let client = NetworkClient()
    static var apps = [GrabilityApp]()
    
    
    static private func load(){
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let entityDescription =
        NSEntityDescription.entityForName("GrabilityApp",
            inManagedObjectContext: managedObjectContext)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        do{
            let objects = try managedObjectContext.executeFetchRequest(request)
            
            if let cachedApps = objects as? [GrabilityApp] {
                Model.apps.removeAll()
                cachedApps.forEach{ (a) in
                    Model.apps.append(a)
                }
            }
        } catch _ {
            //Can't save, we can live without cache
        }
    }
    
    static func get(callback: () -> Void){
        
        let response = client.sendRequestUsingMethod(NetworkClient.HTTPMethod.GET, toEndpoint: "https://itunes.apple.com/us/rss/topfreeapplications/limit=20/json", withParams: nil)
        
        response.success{ ( data) in
            apps.removeAll()
            emptyCache()
            //The client parses data into a dictionary. If this fails, API is not returning
            //what it should. In that case, we usually want the app to fail and report
            //the error using some logging utility
            let json = data as! NSDictionary
            
            //Same logic applies if the JSON structure is not right
            let feed = json["feed"] as! NSDictionary
            let appList = feed["entry"] as! [NSDictionary]
            
            let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
            
            appList.forEach{ (appJson) in
                let entityDescription = NSEntityDescription.entityForName("GrabilityApp",  inManagedObjectContext: managedObjectContext)!
                let app = GrabilityApp(entity: entityDescription, insertIntoManagedObjectContext: managedObjectContext)                                
                
                app.name = readJson(appJson, key: "im:name.label")
                app.summary = readJson(appJson, key: "summary.label")
                app.price = readJson(appJson, key: "im:price.attributes.amount")
                app.currency = readJson(appJson, key: "im:price.attributes.currency")
                app.category = readJson(appJson, key: "category.attributes.label")
                app.imageMedium = readJson(appJson, key: "im:image.label")
                apps.append(app)
                do{
                    try managedObjectContext.save()
                } catch _ {
                    //Can't save, we can live without cache
                }
            }
            print("Network Ok: Loading from server")
            callback()
        }
        
        response.error{(error) in
            load()
            print("Network not available: Loading from cache")
            callback()
        }
    }
    
    static private func emptyCache(){
        let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let entityDescription =
        NSEntityDescription.entityForName("GrabilityApp",
            inManagedObjectContext: managedObjectContext)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        do{
            let objects = try managedObjectContext.executeFetchRequest(request)
            
            if let mObjects = objects as? [NSManagedObject] {
                for mo in mObjects{
                    managedObjectContext.deleteObject(mo)
                }
                
                
                try managedObjectContext.save()
            }
        } catch _ {
            //Can't save, we can live without cache
        }
    }
    
    static private func readJson(json: NSDictionary, key: String) -> String{
        let keys = key.componentsSeparatedByString(".")
        var current: NSDictionary = json
        var val: AnyObject?
        keys.forEach{ (k) in
            val = current[k]
            if (val is NSDictionary){
                current = val as! NSDictionary
            }
            else if (val is [NSDictionary]){
                current = (val as! [NSDictionary]).last!
            }
        }
        return val?.description ?? ""
    }
}

class GrabilityApp : NSManagedObject{
    @NSManaged var name: String
    @NSManaged var imageMedium: String
    @NSManaged var category: String
    @NSManaged var price: String
    @NSManaged var currency: String
    @NSManaged var summary: String
    
}