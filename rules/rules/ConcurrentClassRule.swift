//  ConcurrentClassRule.swift
//  rules
//
//  Created by Anton Davydov on 06/11/2017.
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

class ConcurrentClassRule<T>: Rule {
    public typealias V = T
    
    fileprivate typealias LateBindClosure = (T) -> Void
    fileprivate typealias RuleClosure = (AnyObject) throws -> LateBindClosure?
    fileprivate typealias OptionalRuleClosure = (AnyObject?) throws -> LateBindClosure?
    fileprivate typealias RequirementClosure = (AnyObject) throws -> Bool
    fileprivate typealias DumpRuleClosure = (T) throws -> AnyObject
    fileprivate typealias DumpOptionalRuleClosure = (T) throws -> AnyObject?
    
    fileprivate var pathRequirements = [(JSONPath, RequirementClosure)]()
    
    fileprivate var pathMandatoryRules = [(JSONPath, RuleClosure)]()
    fileprivate var pathOptionalRules = [(JSONPath, OptionalRuleClosure)]()
    
    fileprivate var mandatoryDumpRules = [(JSONPath, DumpRuleClosure)]()
    fileprivate var optionalDumpRules = [(JSONPath, DumpOptionalRuleClosure)]()
    
    fileprivate let objectFactory: ()->T
    
    public init(_ objectFactory: @autoclosure @escaping ()->V) {
        self.objectFactory = objectFactory
    }
    
    open func required<R: Rule>(_ path: JSONPath, _ rule: R, requirement: @escaping (R.V)->Bool) -> Self {
        pathRequirements.append((path,  { requirement(try rule.validate($0)) }))
        return self
    }
    
    open func expect<R: Rule>(_ path: JSONPath, _ rule: R, _ bind: @escaping (T, R.V)->Void) -> Self {
        pathMandatoryRules.append((path, storeRule(rule, bind)))
        return self
    }
    
    open func expect<R: Rule>(_ path: JSONPath, _ rule: R, _ bind: @escaping (T, R.V)->Void, dump: @escaping (T)->R.V?) -> Self {
        pathMandatoryRules.append((path, storeRule(rule, bind)))
        mandatoryDumpRules.append((path, storeDumpRuleForseNull(rule, dump)))
        return self
    }
    
    open func expect<R: Rule>(_ path: JSONPath, _ rule: R, _ bind: @escaping (T, R.V)->Void, dump: @escaping (T)->R.V) -> Self {
        pathMandatoryRules.append((path, storeRule(rule, bind)))
        mandatoryDumpRules.append((path, storeDumpRule(rule, dump)))
        return self
    }
    
    open func expect<R: Rule>(_ path: JSONPath, _ rule: R, dump: @escaping (T)->R.V?) -> Self {
        mandatoryDumpRules.append((path, storeDumpRuleForseNull(rule, dump)))
        return self
    }
    
    open func expect<R: Rule>(_ path: JSONPath, _ rule: R, dump: @escaping (T)->R.V) -> Self {
        mandatoryDumpRules.append((path, storeDumpRule(rule, dump)))
        return self
    }
    
    open func optional<R: Rule>(_ path: JSONPath, _ rule: R, ifNotFound: R.V? = nil, _ bind: @escaping (T, R.V)->Void) -> Self {
        pathOptionalRules.append((path, storeOptionalRule(rule, ifNotFound, bind)))
        return self
    }
    
    open func optional<R: Rule>(_ path: JSONPath, _ rule: R, ifNotFound: R.V? = nil, _ bind: @escaping (T, R.V)->Void, dump: @escaping (T)->R.V?) -> Self {
        pathOptionalRules.append((path, storeOptionalRule(rule, ifNotFound, bind)))
        optionalDumpRules.append((path, storeDumpRule(rule, dump)))
        return self
    }
    
    open func optional<R: Rule>(_ path: JSONPath, _ rule: R, dump: @escaping (T)->R.V?) -> Self {
        optionalDumpRules.append((path, storeDumpRule(rule, dump)))
        return self
    }
    
    public func validate(_ jsonValue: AnyObject) throws -> V {
        guard let json = jsonValue as? NSDictionary else {
            throw RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected dictionary \(T.self).", nil)
        }
        
        return try ConcurrentClassRuleFuture(objectFactory, json, pathRequirements, pathMandatoryRules, pathOptionalRules).get()
    }
    
    public func dump(_ value: V) throws -> AnyObject {
        fatalError("Not implemented yet")
    }
    
    //MARK: - implementation
    
    fileprivate func storeRule<R: Rule>(_ rule: R, _ bind: ((T, R.V)->Void)? = nil) -> RuleClosure {
        return { (json) in
            let v = try rule.validate(json)
            if let b = bind {
                return { b($0, v) }
            }
            return nil
        }
    }
    
    fileprivate func storeOptionalRule<R: Rule>(_ rule: R, _ ifNotFound: R.V?, _ bind: ((T, R.V)->Void)?) -> OptionalRuleClosure {
        return { (optionalJson) in
            guard let json = optionalJson, !(json is NSNull) else {
                if let v = ifNotFound, let b = bind {
                    return { b($0, v) }
                }
                return nil
            }
            
            let v = try rule.validate(json)
            if let b = bind {
                return { b($0, v) }
            }
            return nil
        }
    }
    
    fileprivate func storeDumpRule<R: Rule>(_ rule: R, _ dump: @escaping (T)->R.V) -> DumpRuleClosure {
        return { struc in return try rule.dump(dump(struc)) }
    }
    
    fileprivate func storeDumpRuleForseNull<R: Rule>(_ rule: R, _ dump: @escaping (T)->R.V?) -> DumpRuleClosure {
        return { struc in
            if let v = dump(struc) {
                return try rule.dump(v)
            }
            return NSNull()
        }
    }
    
    fileprivate func storeDumpRule<R: Rule>(_ rule: R, _ dump: @escaping (T)->R.V?) -> DumpOptionalRuleClosure {
        return { struc in
            if let v = dump(struc) {
                return try rule.dump(v)
            }
            return nil
        }
    }
}

class ConcurrentClassRuleFuture<T>: Future {
    typealias V = T
    
    typealias LateBindClosure = (T) -> Void
    typealias RuleClosure = (AnyObject) throws -> LateBindClosure?
    typealias OptionalRuleClosure = (AnyObject?) throws -> LateBindClosure?
    typealias RequirementClosure = (AnyObject) throws -> Bool
    
    fileprivate let objectFactory: ()->T
    
    fileprivate var pathRequirements = [(JSONPath, RequirementClosure)]()
    
    fileprivate var pathMandatoryRules = [(JSONPath, RuleClosure)]()
    fileprivate var pathOptionalRules = [(JSONPath, OptionalRuleClosure)]()
    
    fileprivate let operationQueue: OperationQueue
    fileprivate let runQueue: OperationQueue
    fileprivate let semaphore: DispatchSemaphore
    
    fileprivate var resultError: Error?
    fileprivate var result: T?
    
    var isCancelled: Bool { return true }
    var isDone: Bool { return true }
    
    init(_ objectFactory: @escaping ()->T, _ jsonValue: NSDictionary, _ pathRequirements: [(JSONPath, RequirementClosure)], _ pathMandatoryRules: [(JSONPath, RuleClosure)],
         _ pathOptionalRules: [(JSONPath, OptionalRuleClosure)]) {
        
        self.pathRequirements = pathRequirements
        self.pathMandatoryRules = pathMandatoryRules
        self.pathOptionalRules = pathOptionalRules
        self.objectFactory = objectFactory
        self.operationQueue = OperationQueue()
        self.runQueue = OperationQueue()
        self.semaphore = DispatchSemaphore(value: 1)
        
        operationQueue.maxConcurrentOperationCount = 3 //OperationQueue.defaultMaxConcurrentOperationCount
        operationQueue.qualityOfService = .utility
        
        runQueue.maxConcurrentOperationCount = 1
        runQueue.qualityOfService = .utility
        
        runQueue.addOperation {
            self.perform(jsonValue)
        }
    }
    
    func get() throws -> T {
        runQueue.waitUntilAllOperationsAreFinished()
        if let result = result {
            return result
        }
        
        throw resultError ?? NSError(domain: "Unknown error", code: -1, userInfo: nil)
    }
    
    func cancel() {
        runQueue.cancelAllOperations()
        operationQueue.cancelAllOperations()
        
        runQueue.waitUntilAllOperationsAreFinished()
    }
    
    fileprivate func perform(_ json: NSDictionary) {
        do {
            try validateRequirements(json)
            let newStruct = objectFactory()
            try validateMandatoryRules(newStruct, json)
            try validateOptionalRules(newStruct, json)
            self.result = newStruct
        
        } catch let error {
            resultError = error
        }
    }
    
    fileprivate func validateRequirements(_ json: NSDictionary) throws {
        var requirementsError: Error?
        
        for (path, rule) in pathRequirements {
            let blockOperation = BlockOperation()
            blockOperation.addExecutionBlock {
                guard let value = objectIn(json as AnyObject, atPath: path) else {
                    requirementsError = RuleError.expectedNotFound("Unable to check the requirement, field \"\(path)\" not found in struct.", nil)
                    return
                }
                
                do {
                    if !(try rule(value)) {
                        requirementsError = RuleError.unmetRequirement("Requirement was not met for field \"\(path)\" with value \"\(value)\"", nil)
                    }
                } catch let err {
                    switch err {
                    case RuleError.unmetRequirement: requirementsError = err
                    default:
                        requirementsError = RuleError.unmetRequirement("Requirement was not met for field \"\(path)\" with value \"\(value)\"", err as? RuleError)
                    }
                }
            }
            operationQueue.addOperation(blockOperation)
        }
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if let requirementsError = requirementsError {
            throw requirementsError
        }
    }
    
    fileprivate func validateMandatoryRules(_ outputValue: T, _ json: NSDictionary) throws {
        var mandatoryError: Error?
        
        let amountOfOperations = operationQueue.maxConcurrentOperationCount
        var blockOperation: BlockOperation!
        for (index, (path, rule)) in pathMandatoryRules.enumerated() {
            if index % amountOfOperations == 0 {
                blockOperation = BlockOperation()
            }
            blockOperation.addExecutionBlock {
                guard let value = objectIn(json as AnyObject, atPath: path) else {
                    mandatoryError = RuleError.expectedNotFound("Unable to validate \"\(json)\" as \(T.self). Mandatory field \"\(path)\" not found in struct.", nil)
                    return
                }
                
                do {
                    if let binding = try rule(value) {
                        binding(outputValue)
                    }
                } catch let err {
                    mandatoryError = RuleError.invalidJSONType("Unable to validate mandatory field \"\(path)\" for \(T.self).", err as? RuleError)
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
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if let requirementsError = mandatoryError {
            throw requirementsError
        }
    }
    
    fileprivate func validateOptionalRules(_ outputValue: T, _ json: NSDictionary) throws {
        var optionalError: Error?
        let amountOfOperations = operationQueue.maxConcurrentOperationCount
        var blockOperation: BlockOperation!
        for (index, (path, rule)) in pathOptionalRules.enumerated() {
            if index % amountOfOperations == 0 {
                blockOperation = BlockOperation()
            }
            blockOperation.addExecutionBlock {
                let value = objectIn(json as AnyObject, atPath: path)
                do {
                    if let binding = try rule(value) {
                        binding(outputValue)
                    }
                } catch let err {
                    optionalError = RuleError.invalidJSONType("Unable to validate optional field \"\(path)\" for \(T.self).", err as? RuleError)
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
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if let optionalError = optionalError {
            throw optionalError
        }
    }
}

// MARK:-
fileprivate func objectIn(_ object: AnyObject, atPath path: String) -> AnyObject? {
    if let dict = object as? NSDictionary, let value = dict.value(forKey: path) as AnyObject?, !(value is NSNull) {
        return value
    }
    return nil
}

fileprivate func objectIn(_ object: AnyObject, atPath path: JSONPath) -> AnyObject? {
    if let key = path.singleString {
        return objectIn(object, atPath: key)
    }
    
    var currentObject: AnyObject? = object
    for pathItem in path.elements {
        if let currentDict = currentObject as? NSDictionary, case .DictionaryKey(let item) = pathItem, let next = currentDict.value(forKey: item) as AnyObject?, !(next is NSNull) {
            currentObject = next
            continue
        }
        if let currentArray = currentObject as? NSArray, case .ArrayIndex(let index) = pathItem, currentArray.count > index && !(currentArray[index] is NSNull) {
            currentObject = currentArray[index] as AnyObject?
            continue
        }
        currentObject = nil
    }
    return currentObject
}

