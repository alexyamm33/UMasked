//
//  CompleteViewController.swift
//  UMasked?
//
//  Created by Alex Yeh on 2021-08-03.
//

import Foundation
import UIKit

class CompleteViewController: UIViewController {
    
    @IBOutlet weak var completeImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        completeImage.image = UIImage(named: "complete")
        completeImage.frame = CGRect(x: 0,
                                   y: self.view.frame.height/2 - self.view.frame.width/2,
                                     width: self.view.frame.width,
                                     height: self.view.frame.width)
    }
}
