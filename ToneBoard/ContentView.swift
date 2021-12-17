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



struct HomeButton: View {
    let title: String
    let primary: Bool
    
    init(_ title: String, primary: Bool = false) {
        self.title = title
        self.primary = primary
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: 20))
            .bold()
            .padding(15)
            .frame(width: 200)
            .background(primary ? .green : .gray)
            .cornerRadius(10)
            .foregroundColor(Color(UIColor.label))
            .opacity(0.8)
    }
}


class TutorialState: ObservableObject {
    let steps = [
        Step(title: "1. The Basics",
             substeps: [
                Substep("You can enter Chinese characters in ToneBoard by typing a syllable in Pinyin followed by a tone number. Give it a try by typing \"bu4\" here:", target: "bu4"),
                Substep("Great, you did it!")
             ]),
        Step(title: "2. Another step",
             substeps: [
                Substep("Foo")
             ])
    ]
    
    @Published var currentStep: Int = 0
    @Published var currentSubstep: Int = 0
    @Published var stepDone: Bool = false
    @Published var text: String = ""
    
    
    var numSteps: Int {
        self.steps.count
    }
    
    private func resetStep() {
        self.currentSubstep = 0
        self.stepDone = false
        self.text = ""
    }
    
    func next() {
        self.currentStep += 1
        resetStep()
    }
    
    func back() {
        self.currentStep -= 1
        resetStep()
    }
    
    func finishSubstep() {
        self.currentSubstep += 1
        if (currentSubstep == steps[currentStep].substeps.count - 1) {
            self.stepDone = true
        }
    }
}


struct ProgressBar: View {
    
    @ObservedObject var state: TutorialState
    
    @State var bouncing: Bool = false
    
    let progressColor = Color(UIColor.label)
    
    func bounce() async {
        try? await Task.sleep(nanoseconds: 500000000)
        bouncing = true
        try? await Task.sleep(nanoseconds: 100000000)
        bouncing = false
    }
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.left.2")
                .padding()
                .onTapGesture {
                    state.back()
                }.opacity(state.currentStep > 0 ? 1 : 0)
            ForEach(0..<state.numSteps, id: \.self) { step in
                Group {
                    if (state.currentStep == step) {
                        Circle().fill(progressColor)
                    } else {
                        Circle().strokeBorder(progressColor, lineWidth: 2)
                    }

                }.frame(width: 10, height: 10)
            }
            Image(systemName: "chevron.right.2")
                .padding()
                .onTapGesture {
                    state.next()
                }
                .offset(x: bouncing ? 10 : 0, y: 0)
                .animation(.easeInOut(duration: 0.1), value: bouncing)
                .opacity(state.currentStep < (state.numSteps - 1) ? 1 : 0)
        }
        .frame(height: 30)
        .onChange(of: state.stepDone) { _ in
            Task {
                await bounce()
                await bounce()
            }
        }
    }
}


struct Substep {
    let instructions: String
    let target: String?
    
    init(_ instructions: String, target: String? = nil) {
        self.instructions = instructions
        self.target = target
    }
}


struct Step {
    let title: String
    let substeps: [Substep]
}



struct Tutorial: View {
    
    @StateObject var state: TutorialState = TutorialState()
    
    var steps: [Step] {
        state.steps
    }
    
    var currentStep: Int {
        state.currentStep
    }
    
    var currentSubstep: Int {
        state.currentSubstep
    }
    
    var currentTitle: String {
        steps[currentStep].title
    }
    
    var currentInstructions: String {
        return steps[currentStep].substeps[currentSubstep].instructions
    }
    
    var currentTarget: String? {
        steps[currentStep].substeps[currentSubstep].target
    }
    
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack(spacing: 30) {
            Text(currentTitle).bold()
            ProgressBar(state: state)
            VStack {
                Text(currentInstructions)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .id(currentInstructions)
                Spacer()
            }
            Spacer()
            TextField("Type here...", text: $state.text)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0))
        }.frame(maxHeight: 600)
        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
        .navigationTitle("Try ToneBoard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
           ToolbarItem (placement: .navigation)  {
              Text("< Home")
              .onTapGesture {
                  self.presentation.wrappedValue.dismiss()
              }
           }
        })
        .navigationBarBackButtonHidden(true)
        .onChange(of: state.text) { newText in
            if (newText == currentTarget) {
                state.finishSubstep()
            }
        }
    }
}


struct Home: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("ToneBoard").font(.system(size: 50))
            Spacer()
            NavigationLink(destination: Tutorial()) {
                HomeButton("Try Now", primary: true)
            }
            HomeButton("Install")
            HomeButton("Help")
            HomeButton("About")
            Spacer()
            (Text("You can try ToneBoard with a quick tutorial in this app by selecting ") + Text("Try Now").bold() + Text(", or select ") + Text("Install").bold() + Text(" to see how to use it systemwide."))
                .multilineTextAlignment(.center)
                .font(.system(size: 20))
                .padding()
            Spacer()
            

        }
        .navigationBarHidden(true)
    }
}


struct ContentView: View {

    var body: some View {
        NavigationView {
            Home()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
