//
//  ReminderListDataSource.swift
//  Today
//
//  Created by Дмитрий Гришечко on 04.02.2022.
//

import UIKit

class ReminderListDataSource: NSObject {
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    
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
    
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeleteAction: ReminderDeletedAction?
    
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction) {
        self.reminderDeleteAction = reminderDeletedAction
        self.reminderCompletedAction = reminderCompletedAction
        super.init()
    }
    
    var percentComplete: Double {
        guard filteredReminders.count > 0 else { return 1.0 }
        let numComplete: Double = filteredReminders.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        return numComplete / Double(filteredReminders.count)
    }
    
    var filter: Filter = .today
    
    var filteredReminders: [Reminder] {
        return Reminder.testData.filter { filter.shouldInclute(date: $0.dueDate) }.sorted { $0.dueDate < $1.dueDate }
    }
    
    func update(_ reminder: Reminder, at row: Int) {
        let index = self.index(for: row)
        Reminder.testData[index] = reminder
    }
    
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    func add(_ reminder: Reminder) -> Int? {
        Reminder.testData.insert(reminder, at: 0)
        return filteredReminders.firstIndex(where: { $0.id == reminder.id })
    }
    
    func delete(at row: Int) {
        let index = self.index(for: row)
        Reminder.testData.remove(at: index)
    }
    
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
        guard let index = Reminder.testData.firstIndex(where: { $0.id == filteredReminder.id } ) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index
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
            self.update(modifiedReminder, at: indexPath.row)
            self.reminderCompletedAction?(indexPath.row)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        delete(at: indexPath.row)
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }) { (_) in
            tableView.reloadData()
        }
        reminderDeleteAction?()
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
