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
    var bottomPadding = CGFloat(0)
    var heightConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    
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
        
        let kbView = KeyboardView(proxy: self.textDocumentProxy, dict: SQLiteCandidateDict(), setupNextKeyboardButton: {
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
        // Adding custom bottom padding because:
        // 1. There appear to be issues with UIHostController updating its content in response to changes in safe area
        // 2. It's nice to have some extra padding on phones with Face ID to match the normal system keyboard position
        bottomConstraint = uhc.view.bottomAnchor.constraint(equalTo: outer.bottomAnchor, constant: -bottomPadding)
        bottomConstraint!.isActive = true
        uhc.view.leftAnchor.constraint(equalTo: outer.leftAnchor).isActive = true
        uhc.view.rightAnchor.constraint(equalTo: outer.rightAnchor).isActive = true
        heightConstraint = uhc.view.heightAnchor.constraint(equalToConstant: 0)
        updateHeightConstraint()
        heightConstraint!.isActive = true
    }
    
    override func viewWillLayoutSubviews() {
        // Note that "was called before..." warnings appear to happen no matter what: https://github.com/KeyboardKit/KeyboardKit/issues/83
        // but at least this is where Apple says to call it in their sample extension
        deviceState.needsInputModeSwitchKey = needsInputModeSwitchKey
        updateBottomConstraint()
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        deviceState.textLastChanged = Date()
    }
    
    func updateHeightConstraint() {
        var constant = min(CGFloat(280), UIScreen.main.bounds.height * 0.45)
        if traitCollection.verticalSizeClass == .compact {
            constant = 230
        }
        heightConstraint!.constant = constant
    }
    
    func updateBottomConstraint() {
        var constant = CGFloat(-bottomPadding)
        if needsInputModeSwitchKey && UIDevice.current.userInterfaceIdiom != .pad {
            constant = 0
        }
        bottomConstraint!.constant = constant
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Note that some apps like Safari seem to replace the keyboard instance on rotation
        // while others like Notes do not.
        updateHeightConstraint()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        debugPrint("ToneBoardDebug: Received memory warning")
    }
}
