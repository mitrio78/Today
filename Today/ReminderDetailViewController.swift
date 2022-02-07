//
//  ReminderDetailViewController.swift
//  Today
//
//  Created by Дмитрий Гришечко on 04.02.2022.
//

import UIKit

class ReminderDetailViewController: UITableViewController {
    
    var reminder: Reminder?
    private var reminderDetailDataSource: ReminderDetailViewDataSource?
    
    func configure(with reminder: Reminder) {
        self.reminder = reminder
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let reminder = reminder else {
            fatalError("No reminder found for detail view")
        }
        reminderDetailDataSource = ReminderDetailViewDataSource(reminder: reminder)
        tableView.dataSource = reminderDetailDataSource
    }
    
}

extension ReminderDetailViewController {
    
    
}

