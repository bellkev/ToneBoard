//
//  SharedKeyboardViewController.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/15/21.
//

import Combine
import SwiftUI
import UIKit


class InputState: ObservableObject {
    
    @Published var needsInputModeSwitchKey = false
    @Published var rawInput = ""
    @Published var candidates: [String] = []
    @Published var compact = false
    
}


class SharedKeyboardViewController: UIInputViewController {
    
    var inputState = InputState()
    var bottomPadding = CGFloat(0)
    var heightConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    var candidateDict = SQLiteCandidateDict()
    var inputSubscriber: AnyCancellable?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Perform custom UI setup here
        let outer = self.inputView!
        outer.allowsSelfSizing = true
        
        inputSubscriber = inputState.$rawInput.sink { [unowned self] raw in
            self.updateCandidates(raw)
            self.updateMarked(raw)
        }
        let kbView = KeyboardView(proxy: self.textDocumentProxy, setupNextKeyboardButton: { [unowned self]
            (_ button: UIButton) -> Void in
            let action = #selector(self.handleInputModeList(from:with:))
            button.addTarget(self, action: action, for: .allTouchEvents)
        }).environmentObject(inputState)
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
        updateCompactness()
        heightConstraint!.isActive = true
        
        // Uncomment to access settings
//        let defaults = UserDefaults(suiteName: "group.com.bellkev.ToneBoard")!
        
    }
    
    override func viewWillLayoutSubviews() {
        updateBottomConstraint()
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        inputState.rawInput = ""
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Note that some apps like Safari seem to replace the keyboard instance on rotation
        // while others like Notes do not.
        updateHeightConstraint()
        updateCompactness()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        debugPrint("ToneBoardDebug: Received memory warning")
    }
    
    func updateHeightConstraint() {
        var constant = min(CGFloat(288), UIScreen.main.bounds.height * 0.45)
        if traitCollection.verticalSizeClass == .compact {
            constant = 205
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
    
    func updateCompactness() {
        if traitCollection.verticalSizeClass == .compact {
            self.inputState.compact = true
        } else {
            self.inputState.compact = false
        }
    }
    
    func updateMarked(_ raw: String) {
        let input = ToneBoardInput(raw)
        var temp = input.syllables
        if !input.remainder.isEmpty {
            temp += [input.remainder]
        }
        let tempStr = temp.joined(separator: " ")
        // unmarkText does not seem to update the UI correctly in some cases (e.g. Reminders app search bar or Safari location bar)
        // but works in other cases
        textDocumentProxy.setMarkedText(tempStr, selectedRange: NSMakeRange(tempStr.count, 0))
    }
    
    func updateCandidates(_ raw: String) {
        let input = ToneBoardInput(raw)
        self.inputState.candidates = candidateDict.candidates(input.syllables)
    }
}
