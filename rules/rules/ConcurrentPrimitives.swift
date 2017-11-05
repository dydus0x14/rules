//
//  ConcurrentPrimitives.swift
//  rules
//
//  Created by Anton Davydov on 01/11/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import Foundation

/**
     A Future represents the result of an asynchronous computation like java.util.concurrent.Future.
     Methods are provided to check if the computation is complete, to wait for its completion,
     and to retrieve the result of the computation.
 */
public protocol Future {
    associatedtype T
    
    var isCancelled: Bool { get }
    var isDone: Bool { get }
    
    func get() throws -> T
    func cancel()
}
