//
//  Alerts.swift
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

extension NSAlert {
    static var invalidPhotosLibrary: NSAlert {
        let alert = NSAlert()
        alert.messageText = "Invalid photos library"
        alert.informativeText = "The selected file couldn't be opened or isn't a valid photos library"
        return alert
    }
    
    static var invalidSparseBundle: NSAlert {
        let alert = NSAlert()
        alert.messageText = "Invalid sparsebundle"
        alert.informativeText = "The selected file couldn't be opened or isn't a valid sparsebundle"
        return alert
    }
    
    static var unableToCreateSparseBundle: NSAlert {
        let alert = NSAlert()
        alert.messageText = "Unable to create backup target"
        alert.informativeText = "Could not create a sparse bundle directory at the location specified. Please choose another location and try again"
        return alert
    }
    
    static var photosLibraryNotFound: NSAlert {
        let alert = NSAlert()
        alert.messageText = "No photo library could be found at the specified location"
        alert.informativeText = "Check the photo library exists at the path specified and try again"
        return alert
    }
    
    static var mountPointNotFound: NSAlert {
        let alert = NSAlert()
        alert.messageText = "The backup location could not be found"
        alert.informativeText = "Check to see whether the sparsebundle exists at the path specified, and whether it mounted correctly"
        return alert
    }
    
    static var logSaveError: NSAlert {
        let alert = NSAlert()
        alert.messageText = "Error saving log"
        return alert
    }
    
    static var capacityError: NSAlert {
        let alert = NSAlert()
        alert.messageText = "The backup location is too small"
        alert.informativeText = "The selected sparsebundle doesn't have enough mounted capacity to hold a backup of the photos library. Create a new sparse bundle or resize the selected sparsebundle to continue"
        return alert
    }
    
    static func multipleInstances(_ instances: [NSRunningApplication]) -> NSAlert {
        let additionalInstancePids = instances.map {"Process ID: \($0.processIdentifier)"}
            .joined(separator: "\n")
        let alert = NSAlert()
        alert.messageText = "This application is already running"
        alert.informativeText = """
        More than one instance of this application is running. Photos Backup will not work properly with multiple instances running. Quit all instances and try again. This instance will now quit.
        
        Process identifiers:
        
        \(additionalInstancePids)
        """
        alert.addButton(withTitle: "Quit")
        return alert
    }
    
    static func promptPhotosAccess() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = "Please grant photos access"
        alert.informativeText = """
        Photos Backup needs Photos access enabled in order to read your Photos Library.
        Please grant Photos Access in System Preferences.
        """
        
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Quit")
        
        return alert
    }
}
