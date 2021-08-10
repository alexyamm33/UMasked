//
//  Emailrobot.swift
//  UMasked?
//
//  Created by Alex Yeh on 2021-08-05.
//

import Foundation
import MessageUI

struct EmailRobot {
    let smtpSession = MCOSMTPSession()
    let builder = MCOMessageBuilder()

    var receiverName: String?
    var receiverEmail: String?
    var robotName: String?
    var robotEmail: String?
    var robotPassword: String?
    var header: String?
    var body: String?
    
    func sendEmail(){
        smtpSession.hostname = "smtp.gmail.com"
        smtpSession.username = robotEmail!
        smtpSession.password = robotPassword!
        smtpSession.port = 465
        smtpSession.timeout = 30
        smtpSession.authType = MCOAuthType.saslPlain
        smtpSession.connectionType = MCOConnectionType.TLS
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        builder.header.to = [MCOAddress(displayName: receiverName!, mailbox: receiverEmail!)!]
        builder.header.from = MCOAddress(displayName: robotName!, mailbox: robotEmail!)
        builder.header.subject = header!
        builder.htmlBody = body!
        
        let rfc822Data = builder.data()

        let sendOperation = smtpSession.sendOperation(with: rfc822Data)
        sendOperation?.start { (error) -> Void in
            if (error != nil) {
                NSLog("Error sending email: \(error)")
            } else {
                NSLog("Successful")
            }
        }
    }
}

