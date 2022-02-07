//
//  NotesCell.swift
//  Today
//
//  Created by Дмитрий Гришечко on 07.02.2022.
//

import UIKit

class NotesCell: UITableViewCell {
    
    @IBOutlet var notesTextView: UITextView!
    
    func configure(notes: String?) {
        notesTextView.text = notes
    }
    
}
