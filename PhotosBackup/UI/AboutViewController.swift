//
//  AboutViewController.swift
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

class AboutViewController: NSViewController {
    @IBOutlet var textField: NSTextView!
    @IBOutlet weak var buildInfo: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let info = Bundle.main.infoDictionary,
        let version = info["CFBundleShortVersionString"] as? String,
            let build = info["CFBundleVersion"] as? String {
            buildInfo.stringValue = "Version \(version), build \(build)"
        }
        
        
        guard let licenseURL = Bundle.main.url(forResource: "LICENSE", withExtension: nil),
            let str = try? String(contentsOf: licenseURL) else {return}
        
        textField.string = str
    }
    
}
