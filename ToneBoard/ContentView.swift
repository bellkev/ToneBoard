//
//  ContentView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/4/21.
//

import SwiftUI


class TutorialKeyboardViewController: SharedKeyboardViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // For some reason this is required for the keyboard in-app
        // but breaks the view as a keyboard extension. There must be
        // some difference in the containing window/view for in-app vs
        // extension keyboards.
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
}


class TutorialTextField: UITextField {
    
    override var inputViewController: UIInputViewController? {
        
        TutorialKeyboardViewController()
    }
    
}


struct TutorialTextFieldView: UIViewRepresentable {
        
    func makeUIView(context: Context) -> some UIView {
        let textField = TutorialTextField()
        textField.placeholder = "Custom"
        return textField
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}



struct TutorialView: View {
    
    @State var text: String = ""
    
    var body: some View {
        VStack {
            TutorialTextFieldView()
            TextField("Default", text: $text)
        }.frame(height: 100)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
