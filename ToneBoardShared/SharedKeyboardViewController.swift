//
//  SharedKeyboardViewController.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/15/21.
//

import UIKit
import SwiftUI


class DeviceState: ObservableObject {
    
    @Published var needsInputModeSwitchKey = false
    @Published var textLastChanged = Date()
    
}


class SharedKeyboardViewController: UIInputViewController {
    
    var deviceState = DeviceState()
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Perform custom UI setup here
        guard let outer = inputView else {
            return
        }
        
        outer.allowsSelfSizing = true
        
        let kbView = KeyboardView(proxy: self.textDocumentProxy, dict: LazyCandidateDict(), setupNextKeyboardButton: {
            [unowned self]
            (_ button: UIButton) -> Void in
            let action = #selector(self.handleInputModeList(from:with:))
            button.addTarget(self, action: action, for: .allTouchEvents)
        }).environmentObject(deviceState)
        let uhc = UIHostingController(rootView: kbView)
        self.addChild(uhc)
        outer.addSubview(uhc.view)
        uhc.didMove(toParent: self)
        uhc.view.backgroundColor = .clear
        uhc.view.translatesAutoresizingMaskIntoConstraints = false
        uhc.view.topAnchor.constraint(equalTo: outer.topAnchor).isActive = true
        uhc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        uhc.view.leftAnchor.constraint(equalTo: outer.leftAnchor).isActive = true
        uhc.view.rightAnchor.constraint(equalTo: outer.rightAnchor).isActive = true
        // TODO: Flexible height for orientation changes or different phones
        outer.heightAnchor.constraint(equalToConstant: 280).isActive = true
    }
    
    override func viewWillLayoutSubviews() {
        deviceState.needsInputModeSwitchKey = needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        deviceState.textLastChanged = Date()
    }

}
