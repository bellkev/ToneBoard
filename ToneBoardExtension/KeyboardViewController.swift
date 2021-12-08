//
//  KeyboardViewController.swift
//  ToneBoardExtension
//
//  Created by Kevin Bell on 12/4/21.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

//    @IBOutlet var nextKeyboardButton: UIButton!
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Perform custom UI setup here
        let kbView = KeyboardView(proxy: self.textDocumentProxy)
        let uhc = UIHostingController(rootView: kbView)
        self.view.addSubview(uhc.view)
        

        
        let nextKeyboardAction = #selector(handleInputModeList(from:with:))

        uhc.view.translatesAutoresizingMaskIntoConstraints = false
        uhc.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        uhc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        uhc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        uhc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true        
    }
    
    override func viewWillLayoutSubviews() {
//        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
//        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }

}
