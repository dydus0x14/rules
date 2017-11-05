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
 */
public class ConcurrentArrayRule<T, R: Rule>: Rule where R.V == T {
    public typealias V = [T]
    typealias ValidateClosure = (AnyObject) throws -> T
    fileprivate var itemRule: R
    
    /**
     Validator initializer
     
     - parameter itemRule: rule for validating array items of type R.V
     */
    public init(itemRule: R) {
        self.itemRule = itemRule
    }
    
    open func validate<K: Future>(_ jsonValue: AnyObject) -> K where K.T == T {
        let validator: (AnyObject) throws->T = { [unowned self] jsonObject in
            return try self.itemRule.validate(jsonObject)
        }
        return ConcurrentArrayRuleFuture<V, T>(jsonValue, validator) as! K
    }

    /**
     Validates JSON array and returns [T] if succeeded. Validation throws if jsonValue is not a JSON array or if item rule throws for any item.
     
     - parameter jsonValue: JSON array to be validated and converted into [T]
     
     - throws: throws ValidateError
     
     - returns: array of objects of first generic parameter argument if validation was successful
     */
    open func validate(_ jsonValue: AnyObject) throws -> V {
        let validator: (AnyObject) throws->T = { [unowned self] jsonObject in
            return try self.itemRule.validate(jsonObject)
        }
        return try ConcurrentArrayRuleFuture<V, T>(jsonValue, validator).get()
    }
    
    /**
     Dumps array of AnyObject type in case of success. Throws if cannot dump any item in source array.
     
     - parameter value: array with items of type T
     
     - throws: throws RuleError if cannot dump any item in source array
     
     - returns: returns array of AnyObject, dumped by item rule
     */
    open func dump(_ value: V) throws -> AnyObject {
        var array = [AnyObject]()
        for (index, t) in value.enumerated() {
            try autoreleasepool {
                do {
                    array.append(try itemRule.dump(t))
                } catch let err as RuleError {
                    throw RuleError.invalidDump("Unable to dump array of \(T.self): item #\(index) could not be dumped.", err)
                }
            }
        }
        return array as AnyObject
    }
}

/**
    The executor of concurrent validation process. All items are run in async background queue.
    To increase performance this implementation does not guarantee the order of the elements in the result array.
 */
public class ConcurrentArrayRuleFuture<T: Collection, V>: Future where T.Element == V  {
    fileprivate var result = [V]()
    fileprivate var error: Error?
    fileprivate let validateQueue: OperationQueue
    fileprivate let writeQueue: OperationQueue
    public var isCancelled: Bool = false
    public var isDone: Bool {
        return validateQueue.operationCount == 0 && writeQueue.operationCount == 0
    }
    
    init(_ jsonValue: AnyObject, _ validate: @escaping (AnyObject) throws->V) {
        validateQueue = OperationQueue()
        validateQueue.maxConcurrentOperationCount = 4 // OperationQueue.defaultMaxConcurrentOperationCount
        validateQueue.qualityOfService = .utility
        
        writeQueue = OperationQueue()
        writeQueue.maxConcurrentOperationCount = 1
        writeQueue.qualityOfService = .utility
        
        perform(jsonValue, validate)
    }
    
    public func get() throws -> T {
        validateQueue.waitUntilAllOperationsAreFinished()
        return result as! T
    }
    
    public func cancel() {
        isCancelled = true
        validateQueue.cancelAllOperations()
        writeQueue.cancelAllOperations()
    }
    
    fileprivate func perform(_ jsonValue: AnyObject, _ validate: @escaping (AnyObject) throws ->V) {
        guard let jsonArray = jsonValue as? NSArray else {
            self.error = RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected array of \(T.self).", nil)
            return
        }
        
        for object in jsonArray {
            let op = BlockOperation(block: { [weak self] in
                do {
                    let value = try validate(object as AnyObject)
                    self?.writeQueue.addOperation { self?.result.append(value) }
                } catch _ {
                    // TODO: Handle error
                }
            })
            validateQueue.addOperation(op)
        }
    }
}


