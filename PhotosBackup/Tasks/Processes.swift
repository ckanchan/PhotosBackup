//
//  Processes.swift
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

extension Process {
    static func createHdiutil() -> Process {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        return task
    }
    
    static func createRsync(from: URL, to: URL) -> Process {
        let rsyncURL = Bundle.main.url(forResource: "rsync", withExtension: nil)
        let task = Process()
        task.executableURL = rsyncURL
        task.arguments = [ "-aE",
                           "--info=progress2", // Output total backup % rather than per-file
                           "--outbuf=L",
                           from.path,
                           to.path
        ]
        return task
    }
}
