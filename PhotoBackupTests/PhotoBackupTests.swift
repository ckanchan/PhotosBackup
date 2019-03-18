//
//  PhotoBackupTests.swift
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

import XCTest
@testable import PhotosBackup

class PhotoBackupTests: XCTestCase {
    private var userDefaults: UserDefaults!
    
    let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoBackupTests", isDirectory: true)

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if FileManager.default.fileExists(atPath: tmpDir.path) {
            try! FileManager.default.removeItem(at: tmpDir)
        }
        
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: false, attributes: nil)
        userDefaults = UserDefaults(suiteName: #file)!
        userDefaults.removePersistentDomain(forName: #file)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        if FileManager.default.fileExists(atPath: tmpDir.path) {
            try! FileManager.default.removeItem(at: tmpDir)
        }
    }

    func testCreateSparseBundle() throws {
        let configuration = Configuration(withUserDefaults: userDefaults)
        let tasks = Tasks(withConfiguration: configuration)
        _ = try tasks.createSparseBundle(inDirectory: tmpDir, size: 10)
        XCTAssertNotNil(tasks.mountPoint, "Creating a sparsebundle in an empty dir must also mount it")
        tasks.detachSparseBundle(atURL: tasks.mountPoint!)
        
        let log = XCTAttachment(string: tasks.logBuffer)
        log.lifetime = .keepAlways
        add(log)
    }
}
