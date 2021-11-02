//
//  RealmDataProvider.swift
//  StoryMap
//
//  Created by Dory on 02/11/2021.
//

import Foundation
import RealmSwift

class RealmDataProvider {
    static var shared = RealmDataProvider()
    private var realm: Realm?
    
    private init() {
        self.realm = try? Realm()
    }
    
    func write(object: Object) {
        do {
            try realm?.write {
                realm?.add(object)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func write(objects: [Object]) {
        do {
            try realm?.write {
                objects.forEach { object in
                    realm?.add(object)
                }
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func read(type: Object.Type, with filter: String? = nil) -> Results<Object>? {
        guard var objects = realm?.objects(type) else {
            return nil
        }
        
        if let filter = filter {
            objects = objects.filter(filter)
        }
        return objects
    }
    
    func update(with closure: @escaping () -> Void) {
        do {
            try realm?.write {
                closure()
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    func delete(object: Object) {
        do {
            try realm?.write {
                realm?.delete(object)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    func deleteAll() {
        do {
            try realm?.write {
                realm?.deleteAll()
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
