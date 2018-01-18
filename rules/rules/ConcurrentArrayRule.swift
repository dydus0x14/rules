//  ConcurrentArrayRule.swift
//  rules
//
//  Created by Anton Davydov on 25/10/2017.
//  Original work Copyright © 2017 Anton Davydov
//
//  The MIT License (MIT)
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import Bender

/**
    Validator for arrays of items of type T, that should be validated by rule of type R, i.e. where R.V == T.
    This is an improved version of ArrayRule and allows to proceed array items separately on background thread.
 */
public class ConcurrentArrayRule<T, R: Rule>: Rule where R.V == T {
    public typealias V = [T]
    fileprivate var itemRule: R
    
    /**
     Validator initializer
     
     - parameter itemRule: rule for validating array items of type R.V
     */
    public init(itemRule: R) {
        self.itemRule = itemRule
    }

    // MARK:- Rule
    /**
     Validates JSON array and returns [T] if succeeded. Validation throws if jsonValue is not a JSON array or if item rule throws for any item.
     
     - parameter jsonValue: JSON array to be validated and converted into [T]
     
     - throws: throws ValidateError
     
     - returns: array of objects of first generic parameter argument if validation was successful
     */
    open func validate(_ jsonValue: AnyObject) throws -> V {
        guard let jsonArray = jsonValue as? NSArray else {
            throw RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected array of \(T.self).", nil)
        }
        
        return self.validate(input: jsonArray)
    }

    /**
     Dumps array of AnyObject type in case of success. Throws if cannot dump any item in source array.
     
     - parameter value: array with items of type T
     
     - throws: throws RuleError if cannot dump any item in source array
     
     - returns: returns array of AnyObject, dumped by item rule
     */
    open func dump(_ value: V) throws -> AnyObject {
        return self.dump(input: value)
    }
}

extension ConcurrentArrayRule {
    
    fileprivate func validate(input: NSArray) -> V {
        let operationQueue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 1)
        let dispatchGroups = [DispatchGroup].init(repeating: DispatchGroup(), count: input.count)
        var result = V()
        
        for (index, object) in input.enumerated() {
            dispatchGroups[index].enter()
            
            operationQueue.async {
                do {
                    let value = try self.itemRule.validate(object as AnyObject)
                    
                    semaphore.wait()
                    result.append(value)
                    semaphore.signal()
                } catch let error {
                    print(error)
                    // TODO: Handle error
                }
                dispatchGroups[index].leave()
            }
        }
        
        dispatchGroups.forEach { $0.wait() }
        return result
    }
    
    fileprivate func dump(input: V) -> NSArray {
        let operationQueue = DispatchQueue(label: "", qos: .userInteractive, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 1)
        let dispatchGroups = [DispatchGroup].init(repeating: DispatchGroup(), count: input.count)
        let result = NSMutableArray.init(capacity: input.count)
        
        for (index, object) in input.enumerated() {
            dispatchGroups[index].enter()
            
            operationQueue.async {
                do {
                    let value = try self.itemRule.dump(object)
                    
                    semaphore.wait()
                    result.adding(value)
                    semaphore.signal()
                } catch let error {
                    print(error)
                    // TODO: Handle error
                }
                dispatchGroups[index].leave()
            }
        }
        
        dispatchGroups.forEach { $0.wait() }
        return result
    }
}
