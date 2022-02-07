//
//  TitleCell.swift
//  Today
//
//  Created by Дмитрий Гришечко on 07.02.2022.
//

import UIKit

class TitleCell: UITableViewCell {
    
    @IBOutlet var titleTextField: UITextField!
    
    func configure(title: String) {
        titleTextField.text = title
    }
}
