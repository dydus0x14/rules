//
//  ISO8601DateRule.swift
//  rules
//
//  Created by Anton Davydov on 15/11/2017.
//  Copyright © 2017 Anton Davydov. All rights reserved.
//

import Foundation
import Bender

/// Bender rule for validating and dumping ISO8601-formatted dates
public class ISO8601DateRule: Rule {
    public typealias V = Date
    
    public init() {
    }
    
    public func validate(_ jsonValue: AnyObject) throws -> V {
        guard let value = jsonValue as? String else {
            throw RuleError.invalidJSONType("Value of unexpected type found: \"\(jsonValue)\". Expected ISO8601 date string.", nil)
        }
        do {
            return try Date(iso8601String: value)
        } catch {
            throw RuleError.invalidJSONType("String of unexpected format found: \"\(value)\". Expected ISO8601 date string.", nil)
        }
    }
    
    public func dump(_ value: V) throws -> AnyObject {
        return value.iso8601String() as AnyObject
    }
}

public let Iso8601DateRule = ISO8601DateRule()

enum ISO8601Error: Error {
    case unableToConvert
}

public extension Date {
    
    public init(iso8601String string:String) throws {
        if let date = readFormatter.date(from: string) {
            self.init(timeInterval: 0, since: date)
        } else {
            throw ISO8601Error.unableToConvert
        }
    }
    
    public func iso8601String() -> String {
        return writeFormatter.string(from: self)
    }
}

private func makeReadFormatter() -> Foundation.DateFormatter {
    let formatter = Foundation.DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}

private func makeWriteFormatter() -> Foundation.DateFormatter {
    let formatter = makeReadFormatter()
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter
}

private let readFormatter: Foundation.DateFormatter = {
    return makeReadFormatter()
}()

private let writeFormatter: Foundation.DateFormatter = {
    return makeWriteFormatter()
}()
