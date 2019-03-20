//
//  Tasks.swift
//  PhotosBackup: Manages rsync backups of photo libraries to disk images
//  Copyright (C) 2019 Chaitanya Kanchan
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import os

class Tasks {
    
    static let defaultVolumeName = "photosBackup"
    var logBuffer: String = "" {
        didSet {
            logObserver?(logBuffer)
        }
    }
    
    var mountPoint: URL? = nil {
        didSet {
            NotificationCenter.default.post(name: .mountPointDidChange, object: self)
            let mpStr = mountPoint?.path ?? "unmounted"
            logBuffer.append("Mount point set to \(mpStr)")
            os_log("Mounted volume at %{public}@", log: .fileSystem, type: .info, mpStr)
            if let pt = mountPoint {
                do {
                    let capacity = try getMaxCapacity(forVolume: pt)
                    mountCapacity = capacity
                } catch {
                    os_log("Unable to get capacity", log: .fileSystem, type: .error)
                }
            }
        }
    }

    var mountCapacity: Int64? = nil
    
    var logObserver: ((String) -> Void)? = nil
    var currentTask: Process? = nil
    var configuration: Configuration
    
    func readabilityHandler(label: String) -> ((FileHandle) -> Void) {
        return { (pipe: FileHandle) in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                guard !line.isEmpty else {return}
                let output = "\(label): \(line)"
                self.logBuffer.append(output + "\n")
            }
        }
    }
    
    func runTask(_ task: Process) throws {
        try runTask(task,
                stdOutHandler: readabilityHandler(label: "StdOut"),
                stdErrHandler: readabilityHandler(label: "StdErr"))
    }
    
    func runTask(_ task: Process,
                 stdOutHandler: @escaping ((FileHandle) -> Void),
                 stdErrHandler: @escaping ((FileHandle) -> Void)) throws {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        let outputData = outputPipe.fileHandleForReading
        let errorData = errorPipe.fileHandleForReading
        
        outputData.readabilityHandler = stdOutHandler
        errorData.readabilityHandler = stdErrHandler
        
        currentTask = task
        
        try task.run()
    }
    

    func validatePhotosStatus() -> PhotosLibraryStatus {

        switch (configuration.photosLibraryURL, configuration.getPhotosInfo()) {
        case (.some, .some(let photosInfo)):
            if photosInfo.size != 0 {
                logBuffer.append("Found photos library at \(photosInfo.url.path) size \(photosInfo.size / 1_048_576) MB\n")
                os_log(.info, log: .fileSystem, "Found photos library with size")
                return .Accessible

            } else {
                logBuffer.append("Found photos library at \(photosInfo.url.path) but unable to read any data from this location. Likely photos access is not granted.\n")
                os_log(.error, log: .fileSystem, "Unable to read from location")
                return .PermissionDenied
            }
            
        case (.some(let url), .none):
            logBuffer.append("Photos library location set to \(url.path) but unable to get information. Will try again later\n")
            os_log(.info, log: .fileSystem, "Photos library location set, no information returned: destination unreachable")
            return .Unreachable
            
        case (.none, .none):
            logBuffer.append("No photos library location set\n")
            return .Unconfigured

        case (.none, .some): fatalError("Shouldn't be able to reach this state!")
        }

    }
    
    func promptPhotosAccess(){
        DispatchQueue.main.async {
            switch NSAlert.promptPhotosAccess().runModal() {
            case .alertFirstButtonReturn: // 'Open System Preferences'
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
                NSWorkspace.shared.open(url)
            case .alertSecondButtonReturn: //Quit
                os_log("Photo access was not granted", log: .fileSystem, type: .error)
                exit(EXIT_FAILURE)
            default:
                os_log("Unspecified error requesting photo access", log: .fileSystem, type: .error)
                exit(EXIT_FAILURE)
            }
        }
    }
    
    init(withConfiguration configuration: Configuration) {
        self.configuration = configuration
        switch validatePhotosStatus() {
        case .PermissionDenied:
            promptPhotosAccess()
        case .Unreachable:
            if NSApp.isActive {
                NSAlert.photosLibraryNotFound.runModal()
            } else {
                notifyUnreachablePhotosLibrary()
            }
        case .Accessible, .Unconfigured:
            break
        }
        
        if let sparseBundleURL = configuration.sparseBundleURL {
            do {
                os_log("Attempting to mount sparse bundle at url: %{public}@", log: .fileSystem, type: .info, sparseBundleURL.path)
                try mountSparseBundle(atURL: sparseBundleURL)
            } catch {
                let err = error.localizedDescription
                os_log("Error mounting sparsebundle: %{public}@", log: .fileSystem, type: .error, err)
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sparseBundleWasUnmounted), name: NSWorkspace.didUnmountNotification, object: NSWorkspace.shared)
    }
}

