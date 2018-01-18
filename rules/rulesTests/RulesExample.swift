//
//  RulesExample.swift
//  rules
//
//  Created by Anton Davydov on 12/11/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import Foundation
import Bender

let arrayRule = ArrayRule(itemRule: itemClassRule)
let concurrentArrayRule = ConcurrentArrayRule(itemRule: itemClassRule)
let arrayConcurrentItemRule = ArrayRule(itemRule: itemConcurrentClassRule)
let concurrentArrayConcurrentItemRule = ConcurrentArrayRule(itemRule: itemConcurrentClassRule)

let friendRule = ClassRule(Friend())
    .expect("id", IntRule, { $0.ID = $1 })
    .expect("name", StringRule, { $0.name = $1 })


let itemClassRule = ClassRule(Item())
    .required("_id", StringRule, requirement: { $0 != "" })
    .expect("_id", StringRule, { $0.ID = $1 })
    .expect("index", IntRule, { $0.index = $1 })
    .expect("guid", StringRule, { $0.guid = $1 })
    .expect("isActive", BoolRule, { $0.isActive = $1 })
    .expect("balance", StringRule, { $0.balance = $1 })
    .expect("picture", StringRule, { $0.picture = $1 })
    .expect("age", IntRule, { $0.age = $1 })
    .expect("eyeColor", StringRule, { $0.eyeColor = $1 })
    .expect("name", StringRule, { $0.name = $1 })
    .expect("gender", StringRule, { $0.gender = $1 })
    .expect("company", StringRule, { $0.company = $1 })
    .optional("email", StringRule, { $0.email = $1 })
    .optional("phone", StringRule, { $0.phone = $1 })
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1 })
    .optional("latitude", DoubleRule, { $0.latitude = $1 })
    .optional("longitude", DoubleRule, { $0.longitude = $1 })
    .optional("friends", ArrayRule(itemRule: friendRule), { $0.friends = $1 })

let itemConcurrentClassRule = ConcurrentClassRule(Item())
    .required("_id", StringRule, requirement: { $0 != "" })
    .expect("_id", StringRule, { $0.ID = $1 })
    .expect("index", IntRule, { $0.index = $1 })
    .expect("guid", StringRule, { $0.guid = $1 })
    .expect("isActive", BoolRule, { $0.isActive = $1 })
    .expect("balance", StringRule, { $0.balance = $1 })
    .expect("picture", StringRule, { $0.picture = $1 })
    .expect("age", IntRule, { $0.age = $1 })
    .expect("eyeColor", StringRule, { $0.eyeColor = $1 })
    .expect("name", StringRule, { $0.name = $1 })
    .expect("gender", StringRule, { $0.gender = $1 })
    .expect("company", StringRule, { $0.company = $1 })
    .optional("email", StringRule, { $0.email = $1 })
    .optional("phone", StringRule, { $0.phone = $1 })
    .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1 })
    .optional("latitude", DoubleRule, { $0.latitude = $1 })
    .optional("longitude", DoubleRule, { $0.longitude = $1 })
    .optional("friends", ArrayRule(itemRule: friendRule), { $0.friends = $1 })

/**
 An example has been copy-pasted from Bender library
 */
class Friend {
    var ID: Int?
    var name: String?
}

class Item: CustomStringConvertible {
    var ID: String!
    var index: Int!
    var guid: String?
    var isActive: Bool?
    var balance: String?
    var picture: String?
    var age: Int?
    var eyeColor: String?
    var name: String?
    var gender: String?
    var company: String?
    var email: String?
    var phone: String?
    var tags: [String]?
    var latitude: Double?
    var longitude: Double?
    var friends: [Friend]?
    
    var description: String {
        return "@Item id \(ID ?? "#"), name: \(name ?? "no name")"
    }
}
