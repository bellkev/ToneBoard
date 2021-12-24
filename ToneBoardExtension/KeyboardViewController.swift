//
//  KeyboardViewController.swift
//  ToneBoardExtension
//
//  Created by Kevin Bell on 12/4/21.
//

import UIKit
import SwiftUI

class KeyboardViewController: SharedKeyboardViewController {
    override func viewWillLayoutSubviews() {
        // Only do this in extension keyboard, as it will never be necessary to switch with the in-app keyboard
        // Note that "was called before..." warnings appear to happen no matter what: https://github.com/KeyboardKit/KeyboardKit/issues/83
        // but at least this is where Apple says to call it in their sample extension
        inputState.needsInputModeSwitchKey = needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
}
