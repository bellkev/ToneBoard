//
//  TutorialView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI


class TutorialKeyboardViewController: SharedKeyboardViewController {
    
    override func viewDidLoad() {
        self.bottomPadding = 60
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


struct ProgressBar: View {
    
    let numSteps: Int
    let currentStep: Int
    let size: CGFloat
    
    
    let progressColor = Color(UIColor.label)

    
    var body: some View {
        HStack(spacing: size) {
            ForEach(0..<numSteps, id: \.self) { step in
                Group {
                    if (step <= currentStep) {
                        Circle().fill(progressColor)
                    } else {
                        Circle().strokeBorder(progressColor, lineWidth: 2)
                    }

                }.frame(width: size, height: size)
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


struct Card: View {
    let step: Step
    let padding: CGFloat
    
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
                ZStack(alignment: .top) {
                    ForEach(0..<step.substeps.count, id: \.self) { substep in
                        Text(step.substeps[substep].instructions)
                            .multilineTextAlignment(.center)
                            .opacity(substep == currentSubstep ? 1 : 0)
                            .animation(.easeInOut(duration: 1), value: currentSubstep)
                    }
                }
            }
        }
        .padding(padding)
        // Will be placed in a fixed-size container
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    let steps: [Step]
    let cardPadding: CGFloat
    let cardSpacing: CGFloat


    @Binding var currentStep: Int
    @Binding var text: String
    
    @GestureState var offset = CGFloat(0)
    @State var isDone = false
    @State var bouncing = false
    @State var bounceTask: Task<Void, Error>? = nil
    
    let threshold = CGFloat(100)
    
    var cardWidth: CGFloat {
        UIScreen.main.bounds.width - cardPadding * 2 - cardSpacing * 2
    }
    
    var totalOffset: CGFloat {
        offset + cardPadding + cardSpacing - CGFloat(currentStep) * (cardWidth + cardSpacing) + CGFloat(bouncing ? -10 : 0)
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
        HStack(spacing: cardSpacing) {
            ForEach(0..<steps.count, id: \.self) { step in
                Card(step: steps[step], padding: cardPadding, isDone: $isDone, text: $text, currentStep: $currentStep)
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
        // Necessary to prevent cards overflowing onto Home page during
        // NavigationView transitions
        .mask(Rectangle())
        .onChange(of: isDone) { _ in
            if isDone {
                startBouncing()
            }
        }
    }
}


enum DeviceSize {
    case small, medium, large
}


struct TutorialView: View {
    
    @State var currentStep: Int = 0
    
    @State var text: String = ""
    
    var size: DeviceSize {
        if UIScreen.main.bounds.height < 600 {
            // Basically 1st gen SE and older
            return .small
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            return .large
        } else {
            return .medium
        }
    }
    
    var cardPadding: CGFloat {
        switch size {
        case .small:
            return 10
        case .medium:
            return 20
        case .large:
            return 50
        }
    }
    
    var cardSpacing: CGFloat {
        size == .large ? 200 : cardPadding
    }
    
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
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 25) {
                if (size == .large) {
                    Divider().padding(20)
                }
                if (size != .small) {
                    ProgressBar(numSteps: steps.count, currentStep: currentStep, size: size == .large ? 15 : 10)
                }
                Carousel(steps: steps, cardPadding: cardPadding, cardSpacing: cardSpacing, currentStep: $currentStep, text: $text)
                if (size == .large) {
                    Divider().padding(20)
                }
            }.frame(maxHeight: 400)
            Spacer(minLength: 20)
            Group {
                if lastStep {
                    NavigationLink(destination: InstallView()) {
                        BigButton("Install", primary: true)
                    }
                } else {
                    TutorialTextFieldView(text: $text).frame(height: size == .small ? 30 : 45)

                }
            }
            Spacer(minLength: 20)
        }
        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
        .navigationTitle("Try Now")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                TutorialView()
                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
            }
        }
        .previewDevice("iPhone SE (1st Generation)")
        NavigationView {
            VStack {
                TutorialView()
                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
            }
        }
        .previewDevice("iPhone 8")
        NavigationView {
            VStack {
                TutorialView()
                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        .previewDevice("iPad Pro (12.9-inch) (5th generation)")
    }
}
