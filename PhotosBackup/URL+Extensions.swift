//
//  URL+Extensions.swift
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

extension URL {
    func getRecursiveSize(_ fm: FileManager = FileManager.default) -> Int64? {
        var isDirectory = ObjCBool(booleanLiteral: false)
        guard fm.fileExists(atPath: self.path, isDirectory: &isDirectory),
            isDirectory.boolValue,
        let paths = try? fm.subpathsOfDirectory(atPath: self.path)
            else {return nil}
        
        let absolutePaths = paths.map { self.appendingPathComponent($0) }
        let size: Int64 = absolutePaths.reduce(0) { result, next in
            let nextSize = try? next.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0
            return result + Int64(nextSize ?? 0)
        }
        
        return size
    }
    
    func size() -> Int64 {
        let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: [.totalFileAllocatedSizeKey])!
        var size: Int64 = 0
        while let url = enumerator.nextObject() as? URL {
            guard let resourceValues = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]),
                let fSize = resourceValues.totalFileAllocatedSize else {continue}
            size += Int64(fSize)
        }
        return size
    }
}
