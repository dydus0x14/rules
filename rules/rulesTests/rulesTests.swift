//
//  rulesTests.swift
//  rulesTests
//
//  Created by Anton Davydov on 25/10/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import XCTest
import Bender
@testable import rules

class rulesTests: XCTestCase {
    var json: AnyObject!
    var itemRule: ClassRule<Item>!
    
    override func setUp() {
        let friendRule = ClassRule(Friend())
            .expect("id", IntRule, { $0.ID = $1 })
            .expect("name", StringRule, { $0.name = $1 })
        
        self.itemRule = ClassRule(Item())
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
            .expect("email", StringRule, { $0.email = $1 })
            .expect("phone", StringRule, { $0.phone = $1 })
            .expect("tags", ArrayRule(itemRule: StringRule), { $0.tags = $1 })
            .expect("latitude", DoubleRule, { $0.latitude = $1 })
            .expect("longitude", DoubleRule, { $0.longitude = $1 })
            .expect("friends", ArrayRule(itemRule: friendRule), { $0.friends = $1 })
        
        let path = Bundle(for: rulesTests.self).path(forResource: "five_megs", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        self.json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    }
    
    func testPerformanceArrayRule() {
        let arrayRule = ArrayRule(itemRule: itemRule)
        measure {
            let _ = try? arrayRule.validate(json)
        }
    }
    
    func testPerformanceConcurrentArrayRule() {
        let concurrentArrayRule = ConcurrentArrayRule(itemRule: itemRule)
        measure {
            let _ = try? concurrentArrayRule.validate(json)
        }
    }
    
}

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
