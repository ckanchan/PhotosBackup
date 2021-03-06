//
//  LogViewController.swift
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

class LogViewController: NSViewController {

    @IBOutlet var textView: NSTextView!
    func updateTextView(_ str: String) {
        DispatchQueue.main.async { [weak self] in
            self?.textView.string = str
        }
    }
    
    @IBAction func saveToFile(_ sender: Any) {
        guard let data = textView.string.data(using: .utf8) else {
            NSAlert.logSaveError.runModal()
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["txt"]
        savePanel.beginSheetModal(for: view.window!){ response in
            guard response == .OK,
                let url = savePanel.url else {return}
            
            do {
                try data.write(to: url)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    override func viewDidAppear() {
        updateTextView(taskManager.logBuffer)
        taskManager.logObserver = updateTextView
    }
    
    override func viewWillDisappear() {
        taskManager.logObserver = nil
    }
}
