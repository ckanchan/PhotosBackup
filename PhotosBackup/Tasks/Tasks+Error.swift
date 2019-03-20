//
//  Tasks+Error.swift
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

extension Tasks {
    enum `Error`: Swift.Error, LocalizedError {
        case CouldNotCreateSparseBundleDiskImage
        case UnableToMountSparseBundle
        case MountPointNotReachable
        case UnableToMountNetworkVolume
        case PhotosLibraryNotFound
        
        var errorDescription: String? {
            switch self {
            case .CouldNotCreateSparseBundleDiskImage:
                return "Could not create backup destination disk image at location specified."
            case .UnableToMountSparseBundle:
                return "Unable to mount backup destination disk image."
            case .MountPointNotReachable:
                return "The disk image mount point is not reachable."
            case .UnableToMountNetworkVolume:
                return "The network location where the backup image is located cannot be found."
            case .PhotosLibraryNotFound:
                return "The selected photos library could not be found at the specified location."
            }
        }
        
    }
}
