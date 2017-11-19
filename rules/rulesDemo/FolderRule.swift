//
//  FolderRule.swift
//  rulesDemo
//
//  Created by Anton Davydov on 15/11/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import Foundation
import Bender

func performFolderExample() {
    let path = Bundle(for: ViewController.self).path(forResource: "folders", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: path))
    let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    
    let example1 = measure {
        do {
            let _ = try storeArrayRule1.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let example2 = measure {
        do {
            let _ = try storeArrayRule2.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let example3 = measure {
        do {
            let _ = try storeArrayRule3.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let example4 = measure {
        do {
            let _ = try storeArrayRule4.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    print("Example1: Usual object rules \(example1)")
    print("Example2: Concurrent array rules \(example2)")
    print("Example3: Concurrent class rules \(example3)")
    print("Example4: Concurrent class and array rules \(example4)")
}


//// Data Structures
class File {
    var id: String!
    var name: String!
    var createdAt: Date!
    var updatedAt: Date?
}

class Folder {
    var id: String!
    var name: String!
    var createdAt: Date!
    var updatedAt: Date?
    var files = [File]()
}

struct Tag {
    var name: String
}

class Store {
    var id: String!
    var isActive: Bool!
    var name: String!
    var image: String!
    
    var files = [File]()
    var folders = [Folder]()
    var tags = [Tag]()
}


//// Example1: Usual object rules
let fileClassRule = ClassRule(File())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .optional("createdAt", Iso8601DateRule, { $0.createdAt = $1 })
    .optional("updatedAt", Iso8601DateRule, { $0.updatedAt = $1 })

let folderClassRule = ClassRule(Folder())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .optional("createdAt", Iso8601DateRule, { $0.createdAt = $1 }) { $0.updatedAt }
    .optional("updatedAt", Iso8601DateRule, { $0.updatedAt = $1 }) { $0.updatedAt }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }

let storeClassRule = ClassRule(Store())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .expect("isActive", BoolRule, { $0.isActive = $1 }) { $0.isActive }
    .expect("image", StringRule, { $0.image = $1 }) { $0.image }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }
    .expect("folders", ArrayRule(itemRule: folderClassRule), { $0.folders = $1 }) { $0.folders }
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1.map { Tag(name: $0) }})

let storeArrayRule1 = ArrayRule(itemRule: storeClassRule)

//// Example2: Concurrent array rules
let folderClassRule2 = ClassRule(Folder())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .optional("createdAt", Iso8601DateRule, { $0.createdAt = $1 }) { $0.updatedAt }
    .optional("updatedAt", Iso8601DateRule, { $0.updatedAt = $1 }) { $0.updatedAt }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }

let storeClassRule2 = ClassRule(Store())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .expect("isActive", BoolRule, { $0.isActive = $1 }) { $0.isActive }
    .expect("image", StringRule, { $0.image = $1 }) { $0.image }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }
    .expect("folders", ArrayRule(itemRule: folderClassRule2), { $0.folders = $1 }) { $0.folders }
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1.map { Tag(name: $0) }})

let storeArrayRule2 = ConcurrentArrayRule(itemRule: storeClassRule2)

//// Example3: Concurrent class rules
let folderClassRule3 = ClassRule(Folder())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .optional("createdAt", Iso8601DateRule, { $0.createdAt = $1 }) { $0.updatedAt }
    .optional("updatedAt", Iso8601DateRule, { $0.updatedAt = $1 }) { $0.updatedAt }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }

let storeClassRule3 = ConcurrentClassRule(Store())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .expect("isActive", BoolRule, { $0.isActive = $1 }) { $0.isActive }
    .expect("folders", ArrayRule(itemRule: folderClassRule3), { $0.folders = $1 }) { $0.folders }
    .expect("image", StringRule, { $0.image = $1 }) { $0.image }
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1.map { Tag(name: $0) }})

let storeArrayRule3 = ArrayRule(itemRule: storeClassRule3)

//// Example4: Concurrent class and array rules
let folderClassRule4 = ClassRule(Folder())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .optional("createdAt", Iso8601DateRule, { $0.createdAt = $1 }) { $0.updatedAt }
    .optional("updatedAt", Iso8601DateRule, { $0.updatedAt = $1 }) { $0.updatedAt }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }

let storeClassRule4 = ConcurrentClassRule(Store())
    .expect("id", StringRule, { $0.id = $1 }) { $0.id }
    .expect("files", ArrayRule(itemRule: fileClassRule), { $0.files = $1 }) { $0.files }
    .expect("name", StringRule, { $0.name = $1 }) { $0.name }
    .expect("isActive", BoolRule, { $0.isActive = $1 }) { $0.isActive }
    .expect("folders", ArrayRule(itemRule: folderClassRule4), { $0.folders = $1 }) { $0.folders }
    .expect("image", StringRule, { $0.image = $1 }) { $0.image }
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1.map { Tag(name: $0) }})

let storeArrayRule4 = ConcurrentArrayRule(itemRule: storeClassRule4)
