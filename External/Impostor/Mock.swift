/*
    Copyright 2021 natinusala

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

import Foundation
import XCTest

/// Allows to mock a protocol given in generic parameter.
open class Mock<Mocked> {
    /// Holds records of all calls for all functions.
    var calls: [String: [Call]] = [:]

    /// Are we inside an `expect(expectations:)` call?
    var expectationsMode = false

    public init() {}

    /// Records a call of the function name with given parameters.
    public func record(_ funcName: String = #function, args: [Any?] = []) {
        if self.expectationsMode {
            // Expectations mode: ensure that the given call exists and has the
            // correct parameters
            if let callsForThatFunction = self.calls[funcName] {
                if !callsForThatFunction.contains(Call(args: args)) {
                    XCTFail("\(funcName) call with parameters \(makeSummary(for: args)) not found")
                }
            } else {
                XCTFail("\(funcName) not called (was expected to be called with parameters \(makeSummary(for: args)))")
            }
        } else {
            // Normal mode: record call
            if var callsForThatFunction = self.calls[funcName] {
                callsForThatFunction.append(Call(args: args))
            } else {
                self.calls[funcName] = [Call(args: args)]
            }
        }
    }

    /// Allows to assert that mocked methods are called with the appropriate
    /// parameters.
    public func expect(expectations: (Mocked) -> ()) {
        guard let instance = self as? Mocked else {
            XCTFail("Mock does not inherit from the mocked protocol, please use expectWithInstance(_:expectations:)")
            return
        }

        self.expectWithInstance(instance, expectations: expectations)
    }

    /// Allows to assert that mocked methods are called with the appropriate
    /// parameters. To be used when the mock does inherit from the mocked protocol.
    public func expectWithInstance(_ instance: Mocked, expectations: (Mocked) -> ()) {
        self.expectationsMode = true
        expectations(instance)
        self.expectationsMode = false
    }
}

/// Same class as `Mock`, but with an UUID-based `Equatable` implementation.
open class EquatableMock<T>: Mock<T>, Equatable {
    let uuid = UUID()

    public static func == (lhs: EquatableMock<T>, rhs: EquatableMock<T>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

/// Represents a call to one function.
public struct Call: Equatable {
    let summary: String
    let args: [Any?]

    public init(args: [Any?]) {
        self.args = args
        self.summary = makeSummary(for: args)
    }

    public static func == (lhs: Call, rhs: Call) -> Bool {
        return lhs.summary == rhs.summary
    }
}

/// Makes a summary of the given arguments.
/// From SwiftMock, licensed under MIT license.
private func makeSummary(for argument: Any) -> String {
    switch argument {
        case let string as String:
            return string
        case let array as [Any]:
            var result = "["
            for (index, item) in array.enumerated() {
                result += makeSummary(for: item)
                if index < array.count-1 {
                    result += ","
                }
            }
            result += "]"
            return result
        case let dict as [String: Any]:
            var result = "["
            for (index, key) in dict.keys.sorted().enumerated() {
                if let value = dict[key] {
                    result += "\(makeSummary(for: key)):\(makeSummary(for:value))"
                }
                if index < dict.count-1 {
                    result += ","
                }
            }
            result += "]"
            return result
        default:
            return String(describing: argument)
    }
}
