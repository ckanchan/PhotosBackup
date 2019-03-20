//
//  Configuration.swift
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

import Foundation
import Photos

class Configuration {
    private var userDefaults: UserDefaults
    
    var photosLibraryURL: URL? {
        return userDefaults.url(forKey: .PhotosLibraryURLKey)
    }
    
    var sparseBundleURL: URL? {
        return userDefaults.url(forKey: .SparseBundleURLKey)
    }
    
    var remountURL: URL? {
        return userDefaults.url(forKey: .RemountURL)
    }
    
    var lastBackupDate: Date? {
        return userDefaults.object(forKey: .LastBackupKey) as? Date
    }
    
    var scheduleEnabled: Schedule?  {
        let scheduleNum = userDefaults.integer(forKey: .ScheduleEnabled)
        return Schedule(rawValue: scheduleNum)
    }
    
    var isConfigured: Bool {
        switch (sparseBundleURL, photosLibraryURL) {
        case (.some(let photosURL), .some(let sparseURL) ):
            let fm = FileManager.default
            return fm.fileExists(atPath: photosURL.path) && fm.fileExists(atPath: sparseURL.path)
        default:
            return false
        }
    }
    
    func savePhotosLibraryURL(_ url: URL) {
        userDefaults.set(url, forKey: .PhotosLibraryURLKey)
    }
    
    func saveSparseBundleURL(_ url: URL) {
        userDefaults.set(url, forKey: .SparseBundleURLKey)
    }
    
    func setLastBackupDate() {
        userDefaults.set(Date(), forKey: .LastBackupKey)
    }
    
    func setSchedule(_ schedule: Schedule) {
        userDefaults.set(schedule.rawValue, forKey: .ScheduleEnabled)
    }
    
    func setRemountURL(_ url: URL?) {
        userDefaults.set(url, forKey: .RemountURL)
    }

    /// - Parameter url: URL to the photoslibrary package.
    /// - Returns: A tuple with members `url` reflecting the successfully located URL and `size`, the size of the folder in _bytes_.
    func getPhotosInfo() -> (url: URL, size: Int64)? {
        guard let photosURL = self.photosLibraryURL else {return nil}
        return getPackageInfo(photosURL)
    }

    
    func getPackageInfo(_ packageURL: URL) -> (url: URL, size: Int64)? {
        let fm = FileManager.default

        guard fm.fileExists(atPath: packageURL.path) else {return nil}
        let size = packageURL.size() 
        
        return (packageURL, size)
    }
    
    init(withUserDefaults userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
}
