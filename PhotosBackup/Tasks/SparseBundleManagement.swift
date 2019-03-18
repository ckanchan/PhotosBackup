//
//  SparseBundleManagement.swift
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
import NetFS

extension Tasks {
    func setMountPoint(forVolume volume: String) -> ((Process) -> Void) {
        return { (process: Process) -> Void in
            guard process.terminationReason == .exit,
                let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) else {
                    self.mountPoint = nil
                    
                    return
            }
            
            self.mountPoint = volumes.first(where: {$0.lastPathComponent == volume})
        }
    }
    
    func getMaxCapacity(forVolume volume: URL) throws -> Int64? {
        let resourceValues = try volume.resourceValues(forKeys: [.volumeTotalCapacityKey])
        return resourceValues.volumeTotalCapacity.map {Int64($0)}
    }
    
    func isBackupPossible() -> Bool {
        guard let capacity = self.mountCapacity,
            let photos = configuration.getPhotosInfo() else {return false}
        return capacity > photos.size
    }
    
    /// - Parameter directory: Folder in which the `sparsebundle` is to be created
    /// - Parameter volumeName: Mount name of the `sparsebundle` when the diskimage is attached
    /// - Parameter size: Maximum size of the `sparsebundle` in _megabytes_
    func createSparseBundle(inDirectory directory: URL,
                            volumeName: String = Tasks.defaultVolumeName,
                            size: Int64) throws -> URL {
        
        let hdiutil = Process.createHdiutil()
        let sizeMB = "\(size)m"
        
        // Configure task to create and mount the dmg
        hdiutil.currentDirectoryURL = directory
        hdiutil.arguments = ["create",
                             "-size", sizeMB,
                             "-type", "SPARSEBUNDLE",
                             "-fs", "HFS+",
                             "-volname", Tasks.defaultVolumeName,
                             "-attach", Tasks.defaultVolumeName]
        
        hdiutil.terminationHandler = setMountPoint(forVolume: volumeName)
        try self.runTask(hdiutil)
        hdiutil.waitUntilExit()
        currentTask = nil
        if hdiutil.terminationReason == .exit {
            let sparseBundleURL = directory.appendingPathComponent(volumeName).appendingPathExtension("sparsebundle")
            os_log("Successfully created sparsebundle at path: %{public}@", log: .fileSystem, type: .info, sparseBundleURL.path)
            let resourceValues = try sparseBundleURL.resourceValues(forKeys: [.volumeURLForRemountingKey])
            configuration.setRemountURL(resourceValues.volumeURLForRemounting)
            return sparseBundleURL
        } else {
            throw Error.CouldNotCreateSparseBundleDiskImage
        }
    }
    
    func mountSparseBundle(atURL url: URL) throws {
        let hdiutil = Process.createHdiutil()
        if let networkShare = configuration.remountURL {
            let exitStatus = NetFSMountURLSync(networkShare as CFURL, nil, nil, nil, nil, nil, nil)
            switch exitStatus {
            case EXIT_SUCCESS, EEXIST:
                logBuffer.append("Remounted network share")
                break
            default:
                throw Error.UnableToMountNetworkVolume
            }
        }
        
        // Mount the dmg that already exists
        guard url.pathExtension == "sparsebundle",
            FileManager.default.fileExists(atPath: url.path) else {
                os_log("Sparse bundle does not exist at url: %{public}@", log: .fileSystem, type: .error, url.path)
                throw Error.UnableToMountSparseBundle
        }
        
        hdiutil.arguments = ["attach", url.path,
                             "-nobrowse"]
        
        hdiutil.terminationHandler = setMountPoint(forVolume: url.deletingPathExtension().lastPathComponent)
        try self.runTask(hdiutil)
        hdiutil.waitUntilExit()
        currentTask = nil
        
        let resourceValues = try url.resourceValues(forKeys: [.volumeURLForRemountingKey])
        configuration.setRemountURL(resourceValues.volumeURLForRemounting)
    }
    
    func detachSparseBundle(atURL url: URL) {
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: url)
            mountPoint = nil
            currentTask = nil
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @objc func sparseBundleWasUnmounted(_ notification: Notification) {
        guard let mountPoint = mountPoint,
            let userInfo = notification.userInfo as? [String: Any],
            let path = userInfo["NSDevicePath"] as? String else {return}
        
        if mountPoint.path == path {
            self.mountPoint = nil
            os_log("Sparse bundle was unmounted at %{public}@", log: .fileSystem, type: .info, mountPoint.path)
        }
    }
}
