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

import Rainbow

public actor Logger {
    // TODO: implement log levels
    // TODO: implement "labels" so that apps can enable / disable Loftwing logs

    /// Logs an informative message.
    public static func info(_ message: String) {
        print("\("[INFO]".blue) \(message)")
    }

    /// Logs a warning message.
    public static func warning(_ message: String) {
        print("\("[WARNING]".yellow) \(message)")
    }

    /// Logs an error message.
    public static func error(_ message: String) {
        print("\("[ERROR]".red) \(message)")
    }

    /// Logs a debug message. Only works if the app was compiled with
    /// LOFTWING_DEBUG flag.
    public static func debug(_ message: String) {
        #if LOFTWING_DEBUG
            print("\("[DEBUG]".green) \(message)")
        #endif
    }
}
