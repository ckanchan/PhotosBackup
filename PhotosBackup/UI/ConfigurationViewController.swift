//
//  ConfigurationViewController.swift
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

class ConfigurationViewController: NSViewController {
    @IBOutlet weak var photosLibraryField: NSTextField!
    @IBOutlet weak var photosLibrarySize: NSTextField!
    @IBOutlet weak var sparseBundleField: NSTextField!
    @IBOutlet weak var sparseBundleSize: NSTextField!
    @IBOutlet weak var libStatus: NSLevelIndicator!
    @IBOutlet weak var mountStatus: NSLevelIndicator!
    @IBOutlet weak var backupStatus: NSLevelIndicator!
    @IBOutlet weak var backupStatusText: NSTextField!
    @IBOutlet weak var backupProgress: NSProgressIndicator!
    
    
    func updatePhotoFields() {
        self.photosLibraryField.attributedStringValue = NSAttributedString(string: "Updating", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        self.photosLibrarySize.attributedStringValue = NSAttributedString(string: "Updating", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        
        DispatchQueue.global().async { [weak self] in
            guard let vc = self else {return}
            let info = vc.configuration.getPhotosInfo()
            DispatchQueue.main.async {
                if let photosInfo = info {
                    vc.photosLibraryField.stringValue = photosInfo.url.path
                    vc.photosLibrarySize.stringValue = vc.formatSize(photosInfo.size)
                    vc.libStatus.criticalValue = 0
                } else {
                    vc.photosLibraryField.attributedStringValue = NSAttributedString(string: "No photos library selected", attributes: [.foregroundColor: NSColor.placeholderTextColor])
                    vc.photosLibrarySize.attributedStringValue = NSAttributedString(string: "Not available", attributes: [.foregroundColor: NSColor.placeholderTextColor])
                    vc.libStatus.criticalValue = 1
                }
            }
        }
    }
            
    func updateSparseBundleFields() {
        self.sparseBundleField.attributedStringValue = NSAttributedString(string: "Updating", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        self.sparseBundleSize.attributedStringValue = NSAttributedString(string: "Updating", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        if let sparseBundleURL = configuration.sparseBundleURL {
            sparseBundleField.stringValue = sparseBundleURL.path
            
            if let capacity = taskManager.mountCapacity {
                sparseBundleSize.stringValue = formatSize(capacity)
            } else {
                sparseBundleSize.attributedStringValue = NSAttributedString(string: "Not available", attributes: [.foregroundColor: NSColor.placeholderTextColor])
            }
        } else {
            sparseBundleField.attributedStringValue = NSAttributedString(string: "No backup destination available", attributes: [.foregroundColor: NSColor.placeholderTextColor])
            sparseBundleSize.attributedStringValue = NSAttributedString(string: "Not available", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        }
        
        setMountStatus()
    }
    
    @objc func setLastBackup() {
        let backupLabel: NSAttributedString
        
        if let lastBackupDate = configuration.lastBackupDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .short
            let dateStr = "Last Back Up: " + dateFormatter.string(from: lastBackupDate)
            backupLabel = NSAttributedString(string: dateStr, attributes: [.foregroundColor: NSColor.placeholderTextColor])
        } else {
            backupLabel = NSAttributedString(string: "No back ups found", attributes: [.foregroundColor: NSColor.placeholderTextColor])
        }
        
        DispatchQueue.main.async { [backupStatusText] in
            backupStatusText?.attributedStringValue = backupLabel
        }
    }
    
    @objc func setMountStatus() {
        DispatchQueue.main.async { [weak self] in
            if self?.taskManager.mountPoint != nil {
                self?.mountStatus.criticalValue = 0
            } else {
                self?.mountStatus.criticalValue = 1
            }
        }
    }
    
    override func viewDidLoad() {
        updatePhotoFields()
    }
    
    override func viewWillAppear() {
        updateSparseBundleFields()
        setMountStatus()
        setLastBackup()
        NotificationCenter.default.addObserver(self, selector: #selector(backupCompleted(_:)), name: .backupComplete, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProgress(_:)), name: .backupProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setMountStatus), name: .mountPointDidChange, object: nil)
    }
    
    override func viewWillDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func formatSize(_ size: Int64) -> String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: size)
    }
    
    @objc func backupCompleted(_ notification: Notification) {
        setLastBackup()
        
        DispatchQueue.main.async { [backupProgress] in
            backupProgress?.isHidden = true
        }
    }
    
    @objc func updateProgress(_ notification: Notification) {
        DispatchQueue.main.async { [backupProgress] in
            guard let backupProgress = backupProgress else {return}
            if backupProgress.isHidden {
                backupProgress.isHidden = false
            }
            
            guard let userInfo = notification.userInfo as? [String: Int],
                let percentComplete = userInfo["progress"] else {return}
            
            backupProgress.doubleValue = Double(percentComplete)
            
        }
    }
    
    @IBAction func setPhotosLibraryLocation(_ sender: Any) {
        let locatePhotoLibrary = NSOpenPanel()
        locatePhotoLibrary.message = "Select photos library"
        locatePhotoLibrary.prompt = "Set"
        locatePhotoLibrary.begin { [unowned self] response in
            if response == .OK,
                let url = locatePhotoLibrary.url,
                url.pathExtension == "photoslibrary" {
                self.configuration.savePhotosLibraryURL(url)
                self.updatePhotoFields()
            } else if response == .cancel {
                return
            } else {
                NSAlert.invalidPhotosLibrary.runModal()
            }
        }
    }
    
    @IBAction func setSparseBundleLocation(_ sender: Any) {
        let sparseBundlePanel = NSOpenPanel()
        sparseBundlePanel.message = "Select location of pre-existing .sparsebundle"
        sparseBundlePanel.prompt = "Set"
        sparseBundlePanel.beginSheetModal(for: self.view.window!) { [unowned self] response in
            if response == .OK,
                let url = sparseBundlePanel.url,
                url.pathExtension == "sparsebundle" {
                self.configuration.saveSparseBundleURL(url)
                self.updateSparseBundleFields()
                
                if !self.taskManager.isBackupPossible() {
                    NSAlert.capacityError.runModal()
                }
            } else if response == .cancel {
                return
            } else {
                NSAlert.invalidSparseBundle.runModal()
            }
        }
    }
    
    @IBAction func createSparseBundle(_ sender: Any) {
        let sparseBundlePanel = NSOpenPanel()
        sparseBundlePanel.canChooseFiles = false
        sparseBundlePanel.canChooseDirectories = true
        sparseBundlePanel.message = "Select directory in which to store a new backup archive"
        sparseBundlePanel.prompt = "Create"
        sparseBundlePanel.beginSheetModal(for: self.view.window!) { [unowned self] response in
            guard response == .OK,
                let selectedDirectory = sparseBundlePanel.url else { return }
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let configuration = self?.configuration,
                    let taskManager = self?.taskManager else { return }
                
                let size: Int64
                if let photosInfo = configuration.getPhotosInfo() {
                    size = Int64(Double(photosInfo.size/1_048_576) * 1.5)
                } else {
                    size = 20_480 //20 GiB
                }
                guard let url = try? taskManager.createSparseBundle(inDirectory: selectedDirectory, size: size) else {
                    DispatchQueue.main.async {
                        NSAlert.unableToCreateSparseBundle.runModal()
                    }
                    return
                }
                
                configuration.saveSparseBundleURL(url)
                DispatchQueue.main.async { [weak self] in
                    self?.updateSparseBundleFields()
                }
            }
        }
    }
    
    @IBAction func backupNowClicked(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async { [appDelegate] in
            appDelegate.runBackup(self)
        }
    }
}
