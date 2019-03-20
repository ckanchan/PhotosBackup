//
//  UserNotifications.swift
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
import UserNotifications

func notifyBackupCompletedSuccessfully(from: URL?, to: URL?) {
    let notification = UNMutableNotificationContent()
    notification.title = "Photos back up completed"
    notification.body = "Successfully backed up \(from?.path ?? "?") to \(to?.path ?? "?")"
    let request = UNNotificationRequest(identifier: "me.chaidk.photosBackup.didComplete", content: notification, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

func notifyNoDestinationConfigured() {
    let notification = UNMutableNotificationContent()
    notification.title = "Unable to back up photos library"
    notification.body = "No destination set. Please specify a target sparsebundle disk image in settings"
    let request = UNNotificationRequest(identifier: "me.chaidk.photosBackup.noSparseBundleSet", content: notification, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

func notifyError(_ error: Error) {
    let notification = UNMutableNotificationContent()
    notification.title = "Unable to back up photos library"
    notification.body = "An error occurred: \(error.localizedDescription)"
    let request = UNNotificationRequest(identifier: "me.chaidk.photosBackup.backupError", content: notification, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}

func notifyUnreachablePhotosLibrary() {
    let notification = UNMutableNotificationContent()
    notification.title = "Photos library unreachable"
    notification.body = "Could not find photos library at the specified location and could not continue with backup. Please check it exists and try again"
    let request = UNNotificationRequest(identifier: "me.chaidk.photosBackup.unreachablePhotosLibrary", content: notification, trigger: nil)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
}
