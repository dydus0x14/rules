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
    
    /**
     Starts JSON array validation and returns Future if succeeded. Validation throws if jsonValue is not a JSON array.
     
     - parameter jsonValue: JSON array to be validated and converted into [T]
     
     - throws: throws RuleError
     
     - returns: Future object to get value or cancel execution.
     */
    open func startValidate<K: Future>(_ jsonValue: AnyObject) throws -> K where K.T == T {
        guard let jsonArray = jsonValue as? NSArray else {
            throw RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected array of \(T.self).", nil)
        }

        let validator: (Any) throws->T = { [unowned self] jsonObject in
            return try self.itemRule.validate(jsonObject as AnyObject)
        }
        
        return ConcurrentArrayRuleFuture<NSArray, [T]>(jsonArray, validator) as! K
    }
    
    /**
     Starts array of AnyObject type dump.
     
     - parameter value: array with items of type T
     
     - throws: ?
     
     - returns: returns Future object to get result or cancel execution.
     */
    open func startDump<K: Future>(_ value: V) throws -> K where K.T == AnyObject {
        let dump: (T) throws->AnyObject = { [unowned self] value in
            return try self.itemRule.dump(value)
        }
        return ConcurrentArrayRuleFuture<[T], [AnyObject]>(value, dump) as! K
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
        
        let validator: (Any) throws->T = { [unowned self] jsonObject in
            return try self.itemRule.validate(jsonObject as AnyObject)
        }
        
        return try ConcurrentArrayRuleFuture<NSArray, [T]>(jsonArray, validator).get()
    }

    /**
     Dumps array of AnyObject type in case of success. Throws if cannot dump any item in source array.
     
     - parameter value: array with items of type T
     
     - throws: throws RuleError if cannot dump any item in source array
     
     - returns: returns array of AnyObject, dumped by item rule
     */
    open func dump(_ value: V) throws -> AnyObject {
        let dump: (T) throws->AnyObject = { [unowned self] value in
            return try self.itemRule.dump(value)
        }
        return try ConcurrentArrayRuleFuture<[T], [AnyObject]>(value, dump).get() as AnyObject
    }
}


/**
    The executor of concurrent validation and dumping process. All items are run in async background queue.
    To increase performance this implementation does not guarantee the order of the elements in the result array.
    There is no error handling for failed items yet.
 */
public class ConcurrentArrayRuleFuture<ICollection: Sequence, OCollection: Sequence>: Future {
    
    public typealias T = [OCollection.Element]
    
    fileprivate var result = [OCollection.Element]()
    fileprivate var error: Error?
    fileprivate let operationQueue: OperationQueue
    fileprivate let semaphore: DispatchSemaphore
    public var isCancelled: Bool = false
    public var isDone: Bool {
        return operationQueue.operationCount == 0
    }
    
    init(_ input: ICollection, _ itemExecutor: @escaping (ICollection.Element) throws->OCollection.Element) {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 4 // OperationQueue.defaultMaxConcurrentOperationCount
        operationQueue.qualityOfService = .utility
        
        semaphore = DispatchSemaphore(value: 1)
        
        perform(input, itemExecutor)
    }
    
    public func get() throws -> T {
        operationQueue.waitUntilAllOperationsAreFinished()
        return result
    }
    
    public func cancel() {
        isCancelled = true
        operationQueue.cancelAllOperations()
    }
    
    fileprivate func perform(_ input: ICollection, _ itemExecutor: @escaping (ICollection.Element) throws->OCollection.Element) {
        let amountOfOperations = operationQueue.maxConcurrentOperationCount
        var blockOperation: BlockOperation!
    
        for (index, object) in input.enumerated() {
            if index % amountOfOperations == 0 {
                blockOperation = BlockOperation()
            }
            blockOperation.addExecutionBlock { [weak self] in
                do {
                    let value = try itemExecutor(object)
                    self?.semaphore.wait()
                    self?.result.append(value)
                    self?.semaphore.signal()
                } catch let error {
                    print(error)
                }
            }
            if (index + 1) % amountOfOperations == 0 {
                operationQueue.addOperation(blockOperation)
                blockOperation = nil
            }
        }
        
        if blockOperation != nil {
            operationQueue.addOperation(blockOperation)
        }
    }
}
