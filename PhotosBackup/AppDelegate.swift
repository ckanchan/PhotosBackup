//
//  AppDelegate.swift
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
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    enum MenuItem {
        static var status: NSMenuItem {
            let item =  NSMenuItem(title: "Photos Backup", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return item
        }
        
        static var lastBackup: NSMenuItem {
            let item = NSMenuItem(title: "Last backup: ", action: nil, keyEquivalent: "")
            item.isEnabled = false
            return item
        }
        
        static var configuration: NSMenuItem {
            return NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: "")
            
        }
        
        static var backup: NSMenuItem {
            return NSMenuItem(title: "Back Up Now", action: #selector(runBackup), keyEquivalent: "")
        }
        
        static var quit: NSMenuItem {
            return NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "Q")
        }
        
        static var separator: NSMenuItem {
            return NSMenuItem.separator()
        }
    }
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var taskManager: Tasks!
    var backupSchedule: NSBackgroundActivityScheduler? = nil
    var configuration: Configuration!
    
    func duplicateInstances() -> [NSRunningApplication]? {
        guard let identifier = NSRunningApplication.current.bundleIdentifier else {
         fatalError("The application has no bundle identifier!")
        }
        
        let instances = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
        if instances.count > 1 {
            return instances
        } else {
            return nil
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let instances = duplicateInstances() {
            NSAlert.multipleInstances(instances).runModal()
            os_log("Exiting due to multiple instances", log: .fileSystem, type: .error)
            exit(EXIT_FAILURE)
        }
        
        self.configuration = Configuration()
        self.taskManager = Tasks(withConfiguration: self.configuration)
        
        statusItem.button?.image = #imageLiteral(resourceName: "Empty")
        statusItem.button?.alternateImage = #imageLiteral(resourceName: "Fill")
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.menu = NSMenu()
        statusItem.menu?.items = [MenuItem.status,
                                  MenuItem.lastBackup,
                                  MenuItem.separator,
                                  MenuItem.backup,
                                  MenuItem.configuration,
                                  MenuItem.separator,
                                  MenuItem.quit]
        
        if !configuration.isConfigured {
            showSettings(nil)
        }
        
        configureSchedule()
        updateLastBackupStatus()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus(_:)), name: .backupProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(configureSchedule(_:)), name: .scheduleDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatus(_:)), name: .backupComplete, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let mountPoint = taskManager.mountPoint {
            taskManager.detachSparseBundle(atURL: mountPoint)
        }
        taskManager.currentTask?.terminate()
    }

    @objc func updateStatus(_ notification: Notification) {
        switch notification.name {
        case .backupProgress:
            guard let userInfo = notification.userInfo as? [String: Int],
                let percentComplete = userInfo["progress"] else {return}
            
            updateStatus(withLabel: "Photos backup in progress: \(percentComplete)% complete")
            if taskManager.currentTask == nil {
                fallthrough
            }
        case .backupComplete:
            updateScheduleStatus()
            updateLastBackupStatus()
        default:
            return
        }
    }
    
    func updateScheduleStatus() {
        let str: String
        if let schedule = configuration.scheduleEnabled {
            str = "Photos backup scheduled: \(String(describing: schedule))"
        } else {
            str = "Photos backup unscheduled"
        }
        updateStatus(withLabel: str)
    }
    
    func updateLastBackupStatus() {
        DispatchQueue.main.async { [configuration] in
            let str: String
            if let date = configuration?.lastBackupDate {
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short
                let formattedDate = df.string(from: date)
                str = formattedDate
            } else {
                str = "unknown"
            }
            self.statusItem.menu?.items[1].title = "Last backup: \(str)"
        }
    }
    func updateStatus(withLabel label: String) {
        DispatchQueue.main.async {
            self.statusItem.menu?.items[0].title = label
        }
    }
    
    @objc func configureSchedule(_ notification: Notification) {
        self.configureSchedule()
    }
    
    func configureSchedule() {
        guard let schedule = configuration.scheduleEnabled else {return}
        let interval: Double
        switch schedule {
        case .hourly, .daily, .weekly:
            interval = Double(schedule.rawValue)
        case .disabled:
            backupSchedule?.invalidate()
            backupSchedule = nil
            updateScheduleStatus()
            return
        }

        let activity = NSBackgroundActivityScheduler(identifier: "me.chaidk.photosBackup.scheduledBackup")
        activity.repeats = true
        activity.interval = interval
        
        self.backupSchedule = activity
        activity.schedule { [weak self] completionHandler in
            if activity.shouldDefer {
                completionHandler(.deferred)
                os_log("System deferred scheduled backup", log: .schedule, type: .info)
                return
            } else {
                guard let app = self else {
                    completionHandler(.deferred)
                    os_log("Unable to find app - deferring backup", log: .schedule, type: .error)
                    return
                }
                
                app.runScheduledBackup(completionHandler)
            }
        }
        
        let scheduleDescription = String(describing: schedule).capitalized
        os_log("%{public}@ schedule configured", log: .schedule, type: .info, scheduleDescription)
        updateScheduleStatus()
    }
    
    func runScheduledBackup(_ completion: NSBackgroundActivityScheduler.CompletionHandler) {
        if mountPointIsReachable() {
            runBackup(self)
            taskManager.logBuffer.append("SCHEDULE: Completed scheduled backup\n")
            os_log("Completed scheduled backup", log: .schedule, type: .info)
            completion(.finished)
        } else {
            guard let sparseBundleURL = configuration.sparseBundleURL else {
                notifyNoDestinationConfigured()
                os_log("No backup destination configured - deferring.", log: .schedule, type: .error)
                completion(.deferred)
                return
            }
            
            do {
                try taskManager.mountSparseBundle(atURL: sparseBundleURL)
                runBackup(self)
                taskManager.logBuffer.append("SCHEDULE: Completed scheduled backup\n")
                os_log("Completed scheduled backup", log: .schedule, type: .info)
                completion(.finished)
            } catch {
                notifyError(error)
                os_log("Error completing backup: %{public}@", log: .schedule, type: .error, error.localizedDescription)
                completion(.deferred)
            }
        }

        guard let mountPoint = taskManager.mountPoint,
            FileManager.default.fileExists(atPath: mountPoint.path) else {
                taskManager.logBuffer.append("SCHEDULE: Unable to reach backup location - deferring\n")
                os_log("Unable to reach backup location - deferring.", log: .schedule, type: .error)
                completion(.deferred)
                return
        }
    }
    
    @objc func showSettings(_ sender: Any?) {
        guard let storyboard = NSStoryboard.main else {
            fatalError("There is no main storyboard, the app is in an illogical state")
        }
        
        guard let window = storyboard.instantiateController(withIdentifier: "mainWindow") as? NSWindowController else {
            fatalError("Unable to instantiate config window")
        }
        
        window.showWindow(self)
        window.window?.makeKeyAndOrderFront(self)
        window.window?.orderFrontRegardless()
    }
    
    func mountPointIsReachable() -> Bool {
        if configuration.sparseBundleURL == nil { return false }
        if let mountPoint = taskManager.mountPoint {
            return FileManager.default.fileExists(atPath: mountPoint.path)
        } else {
            return false
        }
    }
    
    
    @objc func runBackup(_ sender: Any?) {
        do {
            if mountPointIsReachable() {
                guard let library = configuration.photosLibraryURL,
                    let destination = taskManager.mountPoint else {throw Tasks.Error.MountPointNotReachable}
                setStatusBarIcon(to: .backup)
                
                DispatchQueue.global(qos: .background).async { [unowned self] in
                    do {
                        try self.taskManager.backupPhotosLibrary(at: library, to: destination)
                        os_log("Completed backup", log: .backup, type: .info)
                        DispatchQueue.main.async {
                            self.setStatusBarIcon(to: .standby)
                            notifyBackupCompletedSuccessfully(from: library,
                                                              to: destination)
                        }
                    } catch let error as NSError {
                        DispatchQueue.main.async { [unowned self] in
                            NSAlert(error: error).runModal()
                            self.setStatusBarIcon(to: .error)
                        }
                    }
                }
            } else {
                guard let configuredSparseBundle = configuration.sparseBundleURL else {
                    NSAlert.mountPointNotFound.runModal()
                    setStatusBarIcon(to: .error)
                    return
                }
                try taskManager.mountSparseBundle(atURL: configuredSparseBundle)
                setStatusBarIcon(to: .backup)
                runBackup(self)
                setStatusBarIcon(to: .standby)
                return
            }
        } catch Tasks.Error.CouldNotCreateSparseBundleDiskImage {
            let err = "Unable to create sparse bundle disk image"
            os_log("Error running backup: %{public}@", log: .backup, type: .error, err)
            DispatchQueue.main.async { [unowned self] in
                NSAlert.unableToCreateSparseBundle.runModal()
                self.setStatusBarIcon(to: .error)
            }
            return
        } catch let error as NSError {
            DispatchQueue.main.async { [unowned self] in
                NSAlert(error: error).runModal()
                self.setStatusBarIcon(to: .error)
            }
        }
    }
    
    @objc func quitApp(_ sender: Any?) {
        NSApp.terminate(sender)
    }
    
    func setStatusBarIcon(to state: AppState) {
        DispatchQueue.main.async { [statusItem] in
            switch state {
            case .standby:
                statusItem.button?.image = #imageLiteral(resourceName: "Empty")
            case .backup:
                statusItem.button?.image = #imageLiteral(resourceName: "Running")
            case .error:
                statusItem.button?.image = #imageLiteral(resourceName: "Error")
            }
        }
    }
}

enum AppState {
    case standby, backup, error
}

