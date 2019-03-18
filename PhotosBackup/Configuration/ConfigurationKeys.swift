//
//  ConfigurationKeys.swift
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

extension String {
    static var HasPhotosAccess: String {
        return "HasPhotosAccess"
    }
    
    static var PhotosLibraryURLKey: String {
        return "PhotosLibraryURL"
    }
    
    static var SparseBundleURLKey: String {
        return "SparseBundleURLKey"
    }
    
    static var LastBackupKey: String {
        return "LastBackup"
    }
    
    static var ScheduleEnabled: String {
        return "ScheduleEnabled"
    }
    
    static var RemountURL: String {
        return "RemountURL"
    }
}
