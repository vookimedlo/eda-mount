/*
Licensed under the MIT license:
Copyright (c) 2020 Michal Duda
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation
import PrettyColors

class Terminal {
    private static var isDumb: Bool {
        return ProcessInfo.processInfo.environment["TERM"]?.caseInsensitiveCompare("dumb") == .orderedSame
    }

    private static var isTTY: Bool {
        return isatty(STDOUT_FILENO) != 0
    }

    private static var isDebugged: Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.size(ofValue: info)
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    private static let shallNotBeColored = isDumb || isDebugged || !isTTY

    #if DEBUG
    private static let shallBeShownInDebugSession = isDebugged
    #endif

    static var colorError: PrettyColors.Color.Named.Color? = .red
    static var colorWarn: PrettyColors.Color.Named.Color? = .yellow
    static var colorOK: PrettyColors.Color.Named.Color? = .green
    static var colorImportant: PrettyColors.Color.Named.Color? = .magenta
    static var colorGeneral: PrettyColors.Color.Named.Color?

    private static func print(_ items: [Any], separator: String = " ", terminator: String = "\n", color: PrettyColors.Color.Named.Color?) {
        var output: String = ""

        // Splatting is not in the language yet, so the passed array is processed 'one by one'
        // https://bugs.swift.org/browse/SR-128
        // Swift.print(items, separator: separator, terminator: terminator, to: &output)
        var index = 0
        for item in items {
            Swift.print(item, terminator: "", to: &output)
            if index < items.count - 1 {
                Swift.print(separator, terminator: "", to: &output)
                index += 1
            }
        }
        Swift.print(terminator, terminator: "", to: &output)

        if shallNotBeColored {
            Swift.print(output, separator: "", terminator: "")
        } else {
            if let color = color {
                let coloredString = Color.Wrap(foreground: color).wrap(output)
                Swift.print(coloredString, separator: "", terminator: "")
            } else {
                Swift.print(output, separator: "", terminator: "")
            }
        }
    }

    static func general(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, color: colorGeneral)
    }

    static func error(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, color: colorError)
    }

    static func warn(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, color: colorWarn)
    }

    static func ok(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, color: colorOK)
    }

    static func important(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        print(items, separator: separator, terminator: terminator, color: colorImportant)
    }

    static func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        if shallBeShownInDebugSession {
            print(items, separator: separator, terminator: terminator, color: colorGeneral)
        }
        #endif
    }
}
