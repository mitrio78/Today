//
//  ReminderListDataSource.swift
//  Today
//
//  Created by Дмитрий Гришечко on 04.02.2022.
//

import UIKit
import EventKit

class ReminderListDataSource: NSObject {
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    typealias RemindersChangedAction = () -> Void
    
    enum Filter: Int {
        case today
        case future
        case all
        
        func shouldInclute(date: Date) -> Bool {
            let isInToday = Locale.current.calendar.isDateInToday(date)
            switch self {
            case .today:
                return isInToday
            case .future:
                return (date > Date()) && !isInToday
            case .all:
                return true
            }
        }
    }
    
    private let eventStore = EKEventStore()
    private var reminders: [Reminder] = []
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeleteAction: ReminderDeletedAction?
    private var remindersChangedAction: RemindersChangedAction?
    
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction, remindersChangedAction: @escaping RemindersChangedAction) {
        self.reminderDeleteAction = reminderDeletedAction
        self.reminderCompletedAction = reminderCompletedAction
        self.remindersChangedAction = remindersChangedAction
        super.init()
        
        requestAccess { (authorized) in
            if authorized {
                self.readAllReminders()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: self.eventStore)
    }
    
    var percentComplete: Double {
        guard filteredReminders.count > 0 else { return 1.0 }
        let numComplete: Double = filteredReminders.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        return numComplete / Double(filteredReminders.count)
    }
    
    var filter: Filter = .today
    
    var filteredReminders: [Reminder] {
        return reminders.filter { filter.shouldInclute(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
    }
    
    @objc
    func storeChanged(_ notification: NSNotification) {
        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
                NotificationCenter.default.addObserver(self, selector: #selector(self.storeChanged(_:)), name: .EKEventStoreChanged, object: self.eventStore)
            }
        }
    }
    
    func update(_ reminder: Reminder, at row: Int, complition: (Bool) -> Void) {
        saveReminder(reminder) { (id) in
            let success = id != nil
            let index = self.index(for: row)
            reminders[index] = reminder
            complition(success)
        }
    }
    
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    func add(_ reminder: Reminder, complition: (Int?) -> Void) {
        saveReminder(reminder) { (id) in
            if let id = id {
                let reminder = Reminder(id: id, title: reminder.title, dueDate: reminder.dueDate, notes: reminder.notes, isComplete: reminder.isComplete)
                reminders.insert(reminder, at: 0)
                let index = filteredReminders.firstIndex { $0.id == id }
                complition(index)
            } else {
                complition(nil)
            }
        }
    }
    
    func delete(at row: Int, complition: (Bool) -> Void) {
        let reminder = self.reminder(at: row)
        removeReminder(with: reminder.id) { (success) in
            if success {
                let index = self.index(for: row)
                reminders.remove(at: index)
            }
            complition(success)
        }
    }
    
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
        guard let index = reminders.firstIndex(where: { $0.id == filteredReminder.id } ) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index
    }
    
    private func showAlert(title: String, message: String) {
            let alertTitle = NSLocalizedString(title, comment: "error updating reminder title")
            let alertMessage = NSLocalizedString(message, comment: "error updating reminder message")
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            let actionTitle = NSLocalizedString("OK", comment: "ok action title")
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: nil))
    }
    
}

extension ReminderListDataSource: UITableViewDataSource {
    
    private static let reuseIdentifier = "ReminderListCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier, for: indexPath) as? ReminderListCell else { fatalError("Unable to dequeue ReminderCell") }
        let currentReminder = reminder(at: indexPath.row)
        let dateText = currentReminder.dueDateTimeText(for: filter)
        cell.configure(title: currentReminder.title, dateText: dateText, isDone: currentReminder.isComplete) {
            var modifiedReminder = currentReminder
            modifiedReminder.isComplete.toggle()
            self.update(modifiedReminder, at: indexPath.row) { success in
                if success {
                    self.reminderCompletedAction?(indexPath.row)
                }
            }
            self.reminderCompletedAction?(indexPath.row)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        delete(at: indexPath.row) { (success) in
            if success {
                DispatchQueue.main.async {
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }) { (_) in
                        tableView.reloadData()
                    }
                    self.reminderDeleteAction?()
                }
            }
        }
    }
}

extension Reminder {
    static let timeFormatter: DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        return timeFormatter
    }()
    
    static let futureDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    static let todayDateFormatter: DateFormatter = {
        let format = NSLocalizedString("'Today at '%@", comment: "format string for dates occuring time")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = String(format: format, "hh:mm a")
        return dateFormatter
    }()
    
    func dueDateTimeText(for filter: ReminderListDataSource.Filter) -> String {
        let isInToday = Locale.current.calendar.isDateInToday(dueDate)
        switch filter {
        case .today:
            return Self.timeFormatter.string(from: dueDate)
        case .future:
            return Self.futureDateFormatter.string(from: dueDate)
        case .all:
            if isInToday {
                return Self.todayDateFormatter.string(from: dueDate)
            } else {
                return Self.futureDateFormatter.string(from: dueDate)
            }
        }
    }
}

extension ReminderListDataSource {
    private var isAvailable: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    private func requestAccess(complition: @escaping (Bool) -> Void) {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard currentStatus == .notDetermined else {
            complition(currentStatus == .authorized)
            return
        }
        eventStore.requestAccess(to: .reminder) { (success, error) in
            complition(success)
        }
    }
    private func readAllReminders() {
        guard isAvailable else { return }
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { (ekReminders) in
            guard let ekReminders = ekReminders else {
                self.reminders = []
                return
            }
            self.reminders = ekReminders.compactMap {
                guard let dueDate = $0.alarms?.first?.absoluteDate else {
                    return nil
                }
                let reminder = Reminder(id: $0.calendarItemIdentifier,
                                        title: $0.title,
                                        dueDate: dueDate,
                                        notes: $0.notes,
                                        isComplete: $0.isCompleted)
                return reminder
            }
        }
        self.remindersChangedAction?()
    }
    private func saveReminder(_ reminder: Reminder, complition: (String?) -> Void) {
        guard isAvailable else {
            complition(nil)
            return
        }
        readReminder(with: reminder.id) { (ekReminder) in
            let ekReminder = ekReminder ?? EKReminder(eventStore: self.eventStore)
            ekReminder.title = reminder.title
            ekReminder.notes = reminder.notes
            ekReminder.isCompleted = reminder.isComplete
            ekReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            ekReminder.alarms?.forEach { alarm in
                if let absoluteDate = alarm.absoluteDate {
                    let comparison = Locale.current.calendar.compare(reminder.dueDate, to: absoluteDate, toGranularity: .minute)
                    if comparison != .orderedSame {
                        ekReminder.removeAlarm(alarm)
                    }
                }
            }
            if !ekReminder.hasAlarms {
                ekReminder.addAlarm(EKAlarm(absoluteDate: reminder.dueDate))
            }
            do {
                try eventStore.save(ekReminder, commit: true)
                complition(ekReminder.calendarItemIdentifier)
            } catch {
                complition(nil)
                DispatchQueue.main.async {
                    self.showAlert(title: "Error trying to save the reminder", message: "An error occured when trying to save the reminder")
                }
            }
        }
        
    }
    
    private func readReminder(with id: String, complition: (EKReminder?) -> Void) {
        guard isAvailable else {
            complition(nil)
            return
        }
        guard let calendarItem = eventStore.calendarItem(withIdentifier: id),
              let ekReminder = calendarItem as? EKReminder else {
                  complition(nil)
                  return
              }
        complition(ekReminder)
    }
    
    private func removeReminder(with id: String, complition: (Bool) -> Void) {
        guard isAvailable else {
            complition(false)
            return
        }
        readReminder(with: id) { (ekReminder) in
            if let ekReminder = ekReminder {
                do {
                    try self.eventStore.remove(ekReminder, commit: true)
                    complition(true)
                } catch {
                    complition(false)
                    DispatchQueue.main.async {
                        self.showAlert(title: "Error trying to remove the reminder", message: "An error occured when trying to remove the reminder")
                    }
                }
            } else {
                complition(false)
                DispatchQueue.main.async {
                    self.showAlert(title: "Error trying to remove the reminder", message: "An error occured when trying to remove the reminder")
                }
            }
        }
    }
}
