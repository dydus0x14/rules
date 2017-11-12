//
//  PerformanceRulesTests.swift
//  PerformanceRulesTests
//
//  Created by Anton Davydov on 25/10/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import XCTest
import Bender
@testable import rules

class PerformanceRulesTests: XCTestCase {
    var json: AnyObject!
    
    override func setUp() {
        
        let path = Bundle(for: PerformanceRulesTests.self).path(forResource: "five_megs", ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        self.json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    }
    
    func testPerformanceArrayRule() {

        measure {
            do {
                let _ = try arrayRule.validate(json)
            } catch let error {
                print(error)
            }
        }
    }

    func testPerformanceConcurrentArrayRule() {

        measure {
            do {
                let _ = try concurrentArrayRule.validate(json)
            } catch let error {
                print(error)
            }
        }
    }
    
    func testPerformanceConcurrentClassRule() {
        
        measure {
            do {
                let _ = try arrayConcurrentItemRule.validate(json)
            } catch let error {
                print(error)
            }
        }
    }
    
    func testPerformanceConcurrentClassAndArrayRule() {

        measure {
            do {
                let _ = try concurrentArrayConcurrentItemRule.validate(json)
            } catch let error {
                print(error)
            }
        }
    }
}
