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
        
    @Binding var text: String
    
    class Coordinator: NSObject {
        var parent: TutorialTextFieldView

        init(_ parent: TutorialTextFieldView) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ field: TutorialTextField) {
            parent.text = field.text ?? ""
        }
    }
        
    func makeUIView(context: Context) -> TutorialTextField {
        let textField = TutorialTextField()
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.placeholder = "Type here..."
        textField.font = .systemFont(ofSize: 25)
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.label.cgColor
        textField.layer.cornerRadius = 10
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ textField: TutorialTextField, context: Context) {
        textField.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}



struct BigButton: View {
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


struct ProgressBar: View {
    
    let numSteps: Int
    let currentStep: Int
    
    
    let progressColor = Color(UIColor.label)

    
    var body: some View {
        HStack {
            ForEach(0..<numSteps, id: \.self) { step in
                Group {
                    if (currentStep == step) {
                        Circle().fill(progressColor)
                    } else {
                        Circle().strokeBorder(progressColor, lineWidth: 2)
                    }

                }.frame(width: 10, height: 10)
            }
        }
        .frame(height: 20)
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


struct Card: View {
    let step: Step
    
    @Binding var isDone: Bool
    @Binding var text: String
    @Binding var currentStep: Int
    
    @State var currentSubstep = 0
    
    func finishSubstep() {
        currentSubstep += 1
        if (currentSubstep == step.substeps.count - 1) {
            isDone = true
        }
    }
    
    var body: some View {
        VStack {
            Text(step.title).bold()
            ScrollView {
                Text(step.substeps[currentSubstep].instructions)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.animation(.easeInOut(duration: 1)))
                    .id(step.substeps[currentSubstep].instructions)
            }
        }
        .padding()
        // Will be placed in a fixed-size container
        .frame(maxWidth: .infinity, maxHeight: 350)
        .background(.gray.opacity(0.5))
        .cornerRadius(10)
        .onChange(of: text) { newText in
            if newText == step.substeps[currentSubstep].target {
                finishSubstep()
            }
        }
        .onChange(of: currentStep) { _ in
            currentSubstep = 0
        }
    }
}


struct Carousel: View {
    
    let spacing = CGFloat(20)
    let threshold = CGFloat(100)
    
    let steps: [Step]

    @Binding var currentStep: Int
    @Binding var text: String
    
    @GestureState var offset = CGFloat(0)
    @State var isDone = false
    @State var bouncing = false
    @State var bounceTask: Task<Void, Error>? = nil
    
    var cardWidth: CGFloat {
        UIScreen.main.bounds.width - spacing * 4
    }
    
    var totalOffset: CGFloat {
        offset + spacing * 2 - CGFloat(currentStep) * (cardWidth + spacing) + CGFloat(bouncing ? -10 : 0)
    }
    
    var firstStep: Bool {
        currentStep == 0
    }
    
    var lastStep: Bool {
        currentStep == steps.count - 1
    }
    
    func resetStep() {
        isDone = false
        text = ""
        bounceTask?.cancel()
    }
    
    func bounce() async {
        bouncing = true
        try? await Task.sleep(nanoseconds: 250000000)
        bouncing = false
        try? await Task.sleep(nanoseconds: 250000000)
    }
    
    func startBouncing() {
        bounceTask = Task {
            while true {
                try? await Task.sleep(nanoseconds: 2000000000)
                await bounce()
                await bounce()
                if Task.isCancelled {
                    return
                }
            }
        }
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<steps.count, id: \.self) { step in
                Card(step: steps[step], isDone: $isDone, text: $text, currentStep: $currentStep)
                    .frame(width: cardWidth)
                    .offset(x: totalOffset, y: 0)
                    .animation(.easeOut(duration: 0.2), value: totalOffset)
                    .gesture(
                        DragGesture()
                            .updating($offset) { value, gestureState, transaction in
                                transaction.disablesAnimations = true
                                gestureState = value.translation.width
                            }
                            .onEnded { value in
                                if value.translation.width < -threshold && !lastStep {
                                    currentStep += 1
                                    resetStep()
                                } else if value.translation.width > threshold && !firstStep {
                                    currentStep -= 1
                                    resetStep()
                                }
                            }
                    )
            }
        }
        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
        .onChange(of: isDone) { _ in
            if isDone {
                startBouncing()
            }
        }
    }
}


struct Tutorial: View {
    
    @State var currentStep: Int = 0
    
    @State var text: String = ""
    
    let steps = [
        Step(title: "The Basics",
             substeps: [
                Substep("Input Chinese characters by typing a syllable in Pinyin followed by a tone number. Try typing \"bu4\".", target: "bu4"),
                Substep("Great! Now you can select from characters with the reading \"bu4\", ordered by frequency. Try selecting \"不\".", target: "不"),
                Substep("Alright, you input your first character! Now swipe to the next step.")
             ]),
        Step(title: "Words",
             substeps: [
                Substep("Now try inputting a multi-character word. Try typing \"fei1chang2\".", target: "fei1 chang2"),
                Substep("Good! Notice that the syllables are displayed with a space between them for easier reading. Now select \"非常\".", target: "非常"),
                Substep("Great! You input your first multi-character word.")
             ]),
        Step(title: "The End", substeps: [Substep("That's it for the tutorial! Now that you know how to use ToneBoard, you can install it to use in other apps.")])
    ]
    
    var lastStep: Bool {
        currentStep == steps.count - 1
    }
        
    var body: some View {
        VStack(spacing: 20) {
            ProgressBar(numSteps: steps.count, currentStep: currentStep)
            Carousel(steps: steps, currentStep: $currentStep, text: $text)
            Spacer()
            Group {
                if lastStep {
                    NavigationLink(destination: Install()) {
                        BigButton("Install", primary: true)
                    }
                } else {
                    TutorialTextFieldView(text: $text).frame(height: 45)

                }
            }
            Spacer()
        }
        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
        .navigationTitle("Try ToneBoard")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct Install: View {
    var body: some View {
        Text("Install it!")
    }
}

struct Home: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("ToneBoard").font(.system(size: 50))
            Spacer()
            NavigationLink(destination: Tutorial()) {
                BigButton("Try Now", primary: true)
            }
            NavigationLink(destination: Install()) {
                BigButton("Install")
            }
            BigButton("Help")
            BigButton("About")
            Spacer()
            (Text("You can try ToneBoard with a quick tutorial in this app by selecting ") + Text("Try Now").bold() + Text(", or select ") + Text("Install").bold() + Text(" to see how to use it systemwide."))
                .multilineTextAlignment(.center)
                .font(.system(size: 20))
                .padding()
            Spacer()
            

        }
        .navigationBarTitle("Home")
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
        .environment(\.sizeCategory, .extraExtraLarge)
        .previewDevice("iPhone 8")
    }
}
