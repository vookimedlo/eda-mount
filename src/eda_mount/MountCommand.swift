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
import Commandant
import Curry

public struct MountCommand: CommandProtocol {
    public struct Options: OptionsProtocol {
        public let url: String
        public let user: String?
        public let password: String?

        public static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CLIError>> {
            return curry(self.init)
                    <*> mode <| Option(key: "url", defaultValue: "", usage: "url to be mounted")
                    <*> mode <| Option(key: "user", defaultValue: nil, usage: "username [default: none]")
                    <*> mode <| Option(key: "password", defaultValue: nil, usage: "password [default: none]")
        }
    }

    public let verb = "mount"
    public let function = "Mounts the given URL"

    public func run(_ options: Options) -> Result<(), CLIError> {
        
        guard let url = URL(string: options.url) else {
            return .failure(.urlFailure("Wrong URL " + options.url))
        }

        let share = SystemShare(url)
        share.username = options.user
        share.password = options.password
        let result = share.mount(options: [.NoAuthDialog])
              
        switch result {
        case 0:
            Terminal.ok("OK")
        default:
            if let message = ErrNo(rawValue: result)?.message {
                Terminal.error(message)
            }
        }

        Terminal.warn(" - Quitting ... Bye, Bye")
        return .success(())
    }
}
