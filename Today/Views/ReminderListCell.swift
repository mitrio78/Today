//
//  ReminderListCell.swift
//  Today
//
//  Created by Дмитрий Гришечко on 04.02.2022.
//

import UIKit

class ReminderListCell: UITableViewCell {

    typealias DoneButtonAction = () -> Void
    
    private var doneButtonAction: DoneButtonAction?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBAction func doneButtonTriggered (_ sender: UIButton) {
        doneButtonAction?()
    }

    func configure(title: String, dateText: String, isDone: Bool, doneButtonAction: @escaping DoneButtonAction) {
        titleLabel.text = title
        dateLabel.text = dateText
        let image = isDone ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
        doneButton.setImage(image, for: .normal)
        self.doneButtonAction = doneButtonAction
        
    }
}
