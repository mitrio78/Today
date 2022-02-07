//
//  EditDateCell.swift
//  Today
//
//  Created by Дмитрий Гришечко on 07.02.2022.
//

import UIKit

class EditDateCell: UITableViewCell {
    
    @IBOutlet var datePicker: UIDatePicker!
    
    func configure(date: Date) {
        datePicker.date = date
    }
    
    
}
