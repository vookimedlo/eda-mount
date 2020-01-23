//
//  SystemShare.swift
//  eda_mount
//
//  Created by Michal Duda on 23/01/2020.
//  Copyright © 2020 Michal Duda. All rights reserved.
//

import Foundation
import NetFS

typealias NetFSMountCallback = (Int32, UnsafeMutableRawPointer?, CFArray?) -> Void
typealias MountCallbackHandler = (Int32, URL?, [String]?) -> Void

class SystemShare {
    enum ShareMountError: Error {
        case InvalidURL
        case MountpointInaccessible
        case InvalidMountOptions
    }

    enum MountOption {
        case NoBrowse
        case ReadOnly
        case AllowSubMounts
        case SoftMount
        case MountAtMountDirectory

        case Guest
        case AllowLoopback
        case NoAuthDialog
        case AllowAuthDialog
        case ForceAuthDialog
    }

    let url: URL
    var mountPoint: String = "/Volumes"
    var username: String?
    var password: String?

    init(_ url: URL) {
        self.url = url
    }

    init(_ urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw ShareMountError.InvalidURL
        }

        self.url = url
    }

    public func mount(options: [MountOption]?) -> Int32 {
        let mountDirectoryURL = URL(fileURLWithPath: mountPoint)
        var openOptions: NSMutableDictionary
        var mountOptions: NSMutableDictionary

        if options != nil {
            (openOptions, mountOptions) = try! SystemShare.processOptionsForNetFS(options: options!)
        } else {
            openOptions = NSMutableDictionary()
            mountOptions = NSMutableDictionary()
        }

        return NetFSMountURLSync(url as CFURL,
                                 mountDirectoryURL as CFURL,
                                 username as CFString?,
                                 password as CFString?,
                                 openOptions as CFMutableDictionary,
                                 mountOptions as CFMutableDictionary,
                                 nil)
    }

    fileprivate static func processOptionsForNetFS(options: [SystemShare.MountOption]) throws -> (NSMutableDictionary, NSMutableDictionary) {
        let openOptions: NSMutableDictionary = NSMutableDictionary()
        let mountOptions: NSMutableDictionary = NSMutableDictionary()

        for opt in options {
            switch opt {
            // mount_options
            case .NoBrowse:
                if let existingValue = mountOptions.value(forKey: kNetFSMountFlagsKey) as? Int32 {
                    mountOptions[kNetFSMountFlagsKey] = existingValue | MNT_DONTBROWSE
                } else {
                    mountOptions[kNetFSMountFlagsKey] = MNT_DONTBROWSE
                }
            case .ReadOnly:
                if let existingValue = mountOptions.value(forKey: kNetFSMountFlagsKey) as? Int32 {
                    mountOptions[kNetFSMountFlagsKey] = existingValue | MNT_RDONLY
                } else {
                    mountOptions[kNetFSMountFlagsKey] = MNT_RDONLY
                }
            case .AllowSubMounts:
                mountOptions[kNetFSAllowSubMountsKey] = true
            case .SoftMount:
                mountOptions[kNetFSSoftMountKey] = true
            case .MountAtMountDirectory:
                mountOptions[kNetFSMountAtMountDirKey] = true

            // open_options
            case .Guest:
                openOptions[kNetFSUseGuestKey] = true
            case .AllowLoopback:
                openOptions[kNetFSAllowLoopbackKey] = true
            case .NoAuthDialog:
                openOptions[kNAUIOptionKey] = kNAUIOptionNoUI
            case .AllowAuthDialog:
                openOptions[kNAUIOptionKey] = kNAUIOptionAllowUI
            case .ForceAuthDialog:
                openOptions[kNAUIOptionKey] = kNAUIOptionForceUI
            }
        }

        return (openOptions, mountOptions)
    }
}
