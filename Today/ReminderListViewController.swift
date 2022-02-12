//
//  TableTableViewController.swift
//  Today
//
//  Created by Дмитрий Гришечко on 04.02.2022.
//

import UIKit

class ReminderListViewController: UITableViewController {
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var percentIncompleteView: UIView!
    @IBOutlet weak var percentCompleteView: UIView!
    @IBOutlet weak var percentIncompleteHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!

    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    static let mainStoryboardName = "Main"
    static let detailViewControllerIdentifier = "ReminderDetailViewController"
    
    private var reminderListDataSource: ReminderListDataSource?
    private var filter: ReminderListDataSource.Filter {
        return ReminderListDataSource.Filter(rawValue: filterSegmentedControl.selectedSegmentIndex) ?? .today
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Self.showDetailSegueIdentifier,
           let destination = segue.destination as? ReminderDetailViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            let rowIndex = indexPath.row
            guard let reminder = reminderListDataSource?.reminder(at: rowIndex) else {
                fatalError("Couldn't find data source for reminder list")
            }
            destination.configure(with: reminder, changeAction: {(reminder) in
                self.reminderListDataSource?.update(reminder, at: rowIndex)
                self.tableView.reloadData()
                self.updateProgressView()
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let radius = view.bounds.size.width * 0.5 * 0.7
        progressContainerView.layer.cornerRadius = radius
        progressContainerView.layer.masksToBounds = true
        updateProgressView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navigationController = navigationController,
           navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: animated)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reminderListDataSource = ReminderListDataSource(reminderCompletedAction: { reminderIndex in
            self.tableView.reloadRows(at: [IndexPath(row: reminderIndex, section: 0)], with: .automatic)
            self.updateProgressView()
        }, reminderDeletedAction: {
            self.updateProgressView()
        })
        tableView.dataSource = reminderListDataSource
    }
    
    @IBAction func addButtonTrigger(_ sender: Any) {
        addReminder()
    }
    
    private func addReminder() {
        let storyboard = UIStoryboard(name: Self.mainStoryboardName, bundle: nil)
        let detailViewController: ReminderDetailViewController = storyboard.instantiateViewController(identifier: Self.detailViewControllerIdentifier)
        let reminder = Reminder(id: UUID().uuidString, title: "New Reminder", dueDate: Date())
        detailViewController.configure(with: reminder, isNew: true, addAction: { reminder in
            if let index = self.reminderListDataSource?.add(reminder) {
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.updateProgressView()
            }
        })
        let navigationController = UINavigationController(rootViewController: detailViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func segmentControlChanged(_ sender: UISegmentedControl) {
        reminderListDataSource?.filter = filter
        tableView.reloadData()
        updateProgressView()
    }
    
    private func updateProgressView() {
        guard let percentComplete = reminderListDataSource?.percentComplete else {
            return
        }
        let totalHeight = progressContainerView.bounds.size.height
        percentIncompleteHeightConstraint.constant = totalHeight * CGFloat(percentComplete)
        UIView.animate(withDuration: 0.2) {
            self.progressContainerView.layoutSubviews()
        }
    }
}
