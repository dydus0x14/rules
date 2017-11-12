//
//  ViewController.swift
//  rulesDemo
//
//  Created by Anton Davydov on 12/11/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import UIKit
import Bender

class ViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rulesDemo.perform()
    }
}

func perform() {
    let path = Bundle(for: ViewController.self).path(forResource: "five_megs", ofType: "json")!
    let data = try! Data(contentsOf: URL(fileURLWithPath: path))
    let json = try! JSONSerialization.jsonObject(with: data, options: []) as AnyObject
    
    let arrayRuleResult = measure {
        do {
            let _ = try arrayRule.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let concurrentArrayRuleResult = measure {
        do {
            let _ = try concurrentArrayRule.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let arrayConcurrentItemRuleResult = measure {
        do {
            let _ = try arrayConcurrentItemRule.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    let concurrentArrayConcurrentItemRuleResult = measure {
        do {
            let _ = try concurrentArrayConcurrentItemRule.validate(json)
        } catch let error {
            print(error)
        }
    }
    
    print("arrayRuleResult \(arrayRuleResult)")
    print("concurrentArrayRuleResult \(concurrentArrayRuleResult)")
    print("arrayConcurrentItemRuleResult \(arrayConcurrentItemRuleResult)")
    print("concurrentArrayConcurrentItemRuleResult \(concurrentArrayConcurrentItemRuleResult)")
}

func measure(problemBlock: ()->Void) -> Double {
    let start = DispatchTime.now()
    problemBlock()
    let end = DispatchTime.now()
    
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000_000
}
