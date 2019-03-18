//
//  ScheduleViewController.swift
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

class ScheduleViewController: NSViewController {
    @IBOutlet weak var isEnabled: NSButton!
    @IBOutlet weak var isHourly: NSButton!
    @IBOutlet weak var isDaily: NSButton!
    @IBOutlet weak var isWeekly: NSButton!
    @IBOutlet weak var schedLabel: NSTextField!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let schedule = configuration.scheduleEnabled ?? .disabled
        setViewState(for: schedule)
        setNextBackupStatus()
    }
    
    func setViewState(for schedule: Schedule) {
        switch schedule {
        case .hourly:
            isEnabled.state = .on
            isHourly.state = .on
            isDaily.state = .off
            isWeekly.state = .off
        case .daily:
            isEnabled.state = .on
            isHourly.state = .off
            isDaily.state = .on
            isWeekly.state = .off
        case .weekly:
            isEnabled.state = .on
            isHourly.state = .off
            isDaily.state = .off
            isWeekly.state = .on
        case .disabled:
            isEnabled.state = .off
            isHourly.state = .off
            isDaily.state = .off
            isWeekly.state = .off
        }
    }
    
    func setNextBackupStatus() {
        let str: String
        if let scheduleConfiguration = configuration.scheduleEnabled {
            switch scheduleConfiguration {
            case .hourly:
                str = "every hour"
            case .daily:
                str = "every day"
            case .weekly:
                str = "every week"
            case .disabled:
                str = "no schedule specified"
            }
        } else {
            str = "error configuring schedule"
        }

        let attributedStr = NSAttributedString(string: str, attributes: [.foregroundColor: NSColor.placeholderTextColor])

        schedLabel.attributedStringValue = attributedStr
    }
    
    func switchRadioButtons(on: Bool){
        [isHourly, isDaily, isWeekly].forEach {button in button?.isEnabled = on}
    }
    
    @IBAction func activateSchedule(_ sender: NSButton) {
        switch sender.state {
        case .on:
            switchRadioButtons(on: true)
            radioButtonWasClicked(self.isDaily)
        default:
            switchRadioButtons(on: false)
            configuration.setSchedule(.disabled)
        }
        
        NotificationCenter.default.post(name: .scheduleDidChange, object: self)
        setNextBackupStatus()
    }
    
    @IBAction func radioButtonWasClicked(_ sender: NSButton) {
        switch sender.title {
        case "Hourly":
            configuration.setSchedule(.hourly)
            setViewState(for: .hourly)
        case "Daily":
            configuration.setSchedule(.daily)
            setViewState(for: .daily)
        case "Weekly":
            configuration.setSchedule(.weekly)
            setViewState(for: .weekly)
        default:
            return
        }
        
        NotificationCenter.default.post(name: .scheduleDidChange, object: self)
        setNextBackupStatus()
    }
    
}
