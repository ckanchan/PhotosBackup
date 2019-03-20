//
//  RSync.swift
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

extension Tasks {
    func backupPhotosLibrary(at url: URL?, to destination: URL) throws {
        guard let photosLibraryURL = url else {return}
        let fm = FileManager.default
        guard fm.fileExists(atPath: photosLibraryURL.path) else {
            throw Error.PhotosLibraryNotFound
        }
        
        guard fm.fileExists(atPath: destination.path) else {
            mountPoint = nil
            throw Error.MountPointNotReachable
        }
        
        
        let rsync = Process.createRsync(from: photosLibraryURL, to: destination)
        let rsyncOutputHandler = {[weak self]  (pipe: FileHandle) in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                guard !line.isEmpty else {return}
                self?.logBuffer.append("Rsync: " + line + "\n")
                let output = line.components(separatedBy: .whitespaces)
                    .filter {!$0.isEmpty}
                guard let percentCompleteStr = output.first(where: {$0.contains("%")}) else {return}
                let percentComplete = percentCompleteStr.dropLast()
                guard let percentCompleteInt = Int(percentComplete) else {return}
                
                let notification = Notification(name: .backupProgress, object: nil, userInfo: ["progress": percentCompleteInt])
                
                NotificationCenter.default.post(notification)
            }
        }
        
        let rsyncTerminationHandler = {[weak self] (process: Process) in
            let delegate = NSApp.delegate as! AppDelegate
            if process.terminationReason == .exit {
                self?.configuration.setLastBackupDate()
                NotificationCenter.default.post(name: .backupComplete, object: nil)
                os_log("Rsync completed backup", log: .rsync, type: .info)
            } else {
                delegate.updateStatus(withLabel: "Error!")
                os_log("Rsync failed to exit successfully", log: .rsync, type: .error)
            }
            self?.currentTask = nil
        }
        rsync.terminationHandler = rsyncTerminationHandler
        
        try self.runTask(rsync,
                         stdOutHandler: rsyncOutputHandler,
                         stdErrHandler: readabilityHandler(label: "RsyncError"))
        
        rsync.waitUntilExit()
    }
}
