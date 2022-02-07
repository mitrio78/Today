//
//  ReminderDetailEditDataSource.swift
//  Today
//
//  Created by Дмитрий Гришечко on 07.02.2022.
//

import UIKit

class ReminderDetailEditDataSource: NSObject {
    typealias ReminderChangeAction = (Reminder) -> Void
    
    private var reminder: Reminder
    
    private var reminderChangeAction: ReminderChangeAction?
    init(reminder: Reminder, changeAction: @escaping ReminderChangeAction) {
        self.reminder = reminder
        self.reminderChangeAction = changeAction
    }
    
    private lazy var formatter: DateFormatter = {
       let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static var dateLabelCellIdentifier: String {
        return ReminderSection.dueDate.cellIdentifier(for: 0)
    }
    
    private func dequeueAndConfigureCell(for indexPath: IndexPath, from tableView: UITableView) -> UITableViewCell {
        guard let section = ReminderSection(rawValue: indexPath.section) else {
            fatalError("Section index out of range")
        }
        let identifier = section.cellIdentifier(for: indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        switch section {
        case .title:
            if let titleCell = cell as? EditTitleCell {
                titleCell.configure(title: reminder.title) { title in
                    self.reminder.title = title
                }
            }
        case .dueDate:
            if indexPath.row == 0 {
                cell.textLabel?.text = formatter.string(from: reminder.dueDate)
            } else {
                if let dueDateCell = cell as? EditDateCell {
                    dueDateCell.configure(date: reminder.dueDate) { date in
                        self.reminder.dueDate = date
                        self.reminderChangeAction?(self.reminder)
                        let indexPath = IndexPath(row: 0, section: section.rawValue)
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                    }
                }
            }
        case .notes:
            if let notesCell = cell as? EditNotesCell {
                notesCell.configure(notes: reminder.notes) { notes in
                    self.reminder.notes = notes
                    self.reminderChangeAction?(self.reminder)
                }
            }
        }
        
        return cell
    }
    
    enum ReminderSection: Int, CaseIterable {
        case title
        case dueDate
        case notes
        
        var numRows: Int {
            switch self {
            case .title, .notes:
                return 1
            case .dueDate:
                return 2
            }
        }
        
        var displayText: String {
            switch self {
            case .title:
                return "Title"
            case .dueDate:
                return "Date"
            case .notes:
                return "Notes"
            }
        }
        
        func cellIdentifier(for row: Int) -> String {
            switch self {
            case .title:
                return "EditTitleCell"
            case .dueDate:
                return row == 0 ? "EditDateLabelCell" : "EditDateCell"
            case .notes:
                return "EditNotesCell"
            }
        }
        
    }
}

extension ReminderDetailEditDataSource: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ReminderSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ReminderSection(rawValue: section)?.numRows ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dequeueAndConfigureCell(for: indexPath, from: tableView)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = ReminderSection(rawValue: section) else {
            fatalError("Section index out of range")
        }
        return section.displayText
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}
