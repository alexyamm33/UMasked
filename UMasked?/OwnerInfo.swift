//
//  OwnerInfo.swift
//  UMasked?
//
//  Created by Alex Yeh on 2021-08-03.
//

import Foundation

class OwnerInfo {
    
    typealias MaskReq = ViewController.LowestMaskReq
    
    let ownerName: String
    let ownerEmail: String
    let maskReq: MaskReq
    
    init(name: String, email: String, maskReq: MaskReq) {
        self.ownerName = name
        self.ownerEmail = email
        self.maskReq = maskReq
    }
    
}
