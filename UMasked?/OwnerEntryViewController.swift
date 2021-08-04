//
//  OwnerEntryViewController.swift
//  UMasked?
//
//  Created by Alex Yeh on 2021-08-03.
//

import UIKit
import Foundation

class OwnerEntryViewController: UIViewController {
    typealias MaskReq = ViewController.LowestMaskReq
    typealias Info = OwnerInfo
    
    @IBOutlet weak var ownerNameField: UITextField!
    @IBOutlet weak var ownerEmailField: UITextField!
    @IBOutlet weak var maskReqField: UITextField!
    
    let maskTypes = ["Any", "Surgical", "N95"]
    
    var pickerView = UIPickerView()
    var ownerInfo: Info?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OwnerEntryViewController.dismissKeyboard))

        self.hideKeyboardWhenTappedAround()
        ownerNameField.delegate = self
        ownerEmailField.delegate = self
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        maskReqField.inputView = pickerView
        
        view.addGestureRecognizer(tap)
        
    }
    
    @objc override func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func didPressStart(_ sender: Any) {
        
        var maskReq: MaskReq
        switch maskReqField.text {
        case "Any":
            maskReq = .cloth
        case "Surgical":
            maskReq = .surgical
        case "N95":
            maskReq = .n95
        default:
            maskReq = .cloth
        }
        
        ownerInfo = OwnerInfo(name: ownerNameField.text ?? "", email: ownerEmailField.text ?? "", maskReq: maskReq)
        self.dismiss(animated: true) {
            self.performSegue(withIdentifier: "goToCamera", sender: self)
        }
        
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCamera"{
            
            let destinationVC = segue.destination as! ViewController
            destinationVC.ownerInfo = ownerInfo ?? Info(name: "", email: "", maskReq: .cloth)
            
        }
    }

}

extension OwnerEntryViewController: UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return maskTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return maskTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        maskReqField.text = maskTypes[row]
        maskReqField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        textField.resignFirstResponder()
        return false
      }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
