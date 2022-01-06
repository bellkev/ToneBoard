//
//  TutorialView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI


enum DeviceSize {
    case small, medium, large
}


func deviceSize() -> DeviceSize {
    if UIScreen.main.bounds.height < 600 {
        // Basically 1st gen SE and older
        return .small
    } else if UIDevice.current.userInterfaceIdiom == .pad {
        return .large
    } else {
        return .medium
    }
}


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
    
    var controller: TutorialKeyboardViewController?
        
    override var inputViewController: UIInputViewController? {
        controller
    }
}


class TextFieldState: ObservableObject {
    
    @Published var text = ""
    @Published var rawInput = ""
    
}


struct TutorialTextFieldView: UIViewRepresentable {
        
    @EnvironmentObject var state: TextFieldState
    
    class Coordinator: NSObject {
        var parent: TutorialTextFieldView

        init(_ parent: TutorialTextFieldView) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(_ field: TutorialTextField) {
            let raw = field.controller?.inputState.rawInput ?? ""
            parent.state.text = field.text ?? ""
            parent.state.rawInput = field.controller?.inputState.rawInput ?? ""
        }
    }
        
    func makeUIView(context: Context) -> TutorialTextField {
        let textField = TutorialTextField()
        textField.controller = TutorialKeyboardViewController()
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.placeholder = "Type here..."
        textField.font = ToneBoardStyle.keyFont.withSize(25)
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.label.cgColor
        textField.layer.cornerRadius = 10
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }
    
    func updateUIView(_ textField: TutorialTextField, context: Context) {
        textField.text = state.text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


struct ProgressBar: View {
    
    let numSteps: Int
    let currentStep: Int
    let progressColor = Color(UIColor.label)
    
    var diameter: CGFloat {
        deviceSize() == .large ? 15 : 10
    }
    
    var body: some View {
        HStack(spacing: diameter) {
            ForEach(0..<numSteps, id: \.self) { step in
                Group {
                    if (step <= currentStep) {
                        Circle().fill(progressColor)
                    } else {
                        Circle().strokeBorder(progressColor, lineWidth: 2)
                    }

                }.frame(width: diameter, height: diameter)
            }
        }
    }
}


struct Substep {
    let instructions: String
    let target: String?
    let rawTarget: String?
    
    init(_ instructions: String, target: String? = nil, rawTarget: String? = nil) {
        self.instructions = instructions
        self.target = target
        self.rawTarget = rawTarget
    }
}


struct Step {
    let title: String
    let substeps: [Substep]
}


struct Card: View {
    let step: Step
    let index: Int
    let padding: CGFloat
    
    @Binding var isDone: Bool
    @EnvironmentObject var textFieldState: TextFieldState
    @Binding var currentStep: Int
    @State var currentSubstep = 0
    
    func finishSubstep() {
        currentSubstep += 1
        if (currentSubstep == step.substeps.count - 1) {
            isDone = true
        }
    }
    
    func maybeFinishSubstep() {
        if index != currentStep {
            return
        }
        if let raw = step.substeps[currentSubstep].rawTarget, textFieldState.rawInput != raw {
            return
        }
        if textFieldState.text == step.substeps[currentSubstep].target {
            finishSubstep()
        }
    }
    
    var body: some View {
        VStack {
            Text(step.title).bold()
            ScrollView {
                ScrollViewReader { proxy in
                    ZStack(alignment: .top) {
                        ForEach(0..<step.substeps.count, id: \.self) { substep in
                            Text(try! AttributedString(markdown: step.substeps[substep].instructions, options: AttributedString.MarkdownParsingOptions(languageCode: "zh-CN")))
                                .multilineTextAlignment(.center)
                                .opacity(substep == currentSubstep ? 1 : 0)
                                .animation(.easeInOut(duration: 1), value: currentSubstep)
                        }
                    }.id(1)
                    .onChange(of: currentSubstep) { _ in
                        proxy.scrollTo(1, anchor: .top)
                    }
                }
            }
        }
        .padding(padding)
        // Will be placed in a fixed-size container
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.5))
        .cornerRadius(10)
        // A bit of redundancy to work around the fact that there is no generic objectDidChange...
        // https://forums.swift.org/t/combine-observableobject-in-uikit/28433
        .onChange(of: textFieldState.text) { _ in
            maybeFinishSubstep()
        }
        .onChange(of: textFieldState.rawInput) { _ in
            maybeFinishSubstep()
        }
        .onChange(of: currentStep) { _ in
            currentSubstep = 0
        }
    }
}


struct Carousel: View {
    
    let steps: [Step]

    @Binding var currentStep: Int
    @EnvironmentObject var textFieldState: TextFieldState
    @GestureState var offset = CGFloat(0)
    @State var isDone = false
    @State var bouncing = false
    @State var bounceTask: Task<Void, Error>? = nil
    
    var cardPadding: CGFloat {
        switch deviceSize() {
        case .small:
            return 10
        case .medium:
            return 20
        case .large:
            return 50
        }
    }
    
    var cardSpacing: CGFloat {
        deviceSize() == .large ? UIScreen.main.bounds.width * 0.1 : cardPadding
    }
    
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
        textFieldState.text = ""
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
                Card(step: steps[step], index: step, padding: cardPadding, isDone: $isDone, currentStep: $currentStep)
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


struct TutorialView: View {
    
    @State var currentStep = 0
    @StateObject var textFieldState = TextFieldState()
    
    var size: DeviceSize {
        deviceSize()
    }
    
    let steps = [
        Step(title: "The Basics",
             substeps: [
                Substep("Input Chinese characters by typing a syllable in Pinyin followed by a tone number. Try entering 好 (_hǎo_, good) by typing \"hao3\".", target: "hao3"),
                Substep("Great! Now you can select from characters with the reading \"hao3\" above the keyboard, ordered by frequency. Try tapping on \"好\".", target: "好"),
                Substep("Alright, you input your first character! Now swipe to the next step.")
             ]),
        Step(title: "The Return Key",
             substeps: [
                Substep("The return key is normally labeled \"换行\" (_huànháng_, line feed), but if you input some characters, the label changes to \"确认\" (_quèrèn_, confirm), allowing you to directly input text. Try it by typing \"hello\".", target: "hello"),
                Substep("Good. Notice the highlighting indicating that the word isn't fully entered yet. Now hit \"确认\".", target: "hello", rawTarget: ""),
                Substep("Great! Notice that the highlighting disappears, indicating that the text is fully entered, and the \"确认\" key goes back to \"换行\".")
             ]),
        Step(title: "The Space Key", substeps: [
            Substep("In ToneBoard, the tone buttons take the normal place of the space bar, but there is still a small space key available labeled \"空格\" (_kòng gé_, space). Try using it to type \"hello world\".", target: "hello world"),
            Substep("Good job! (Note that some devices may replace the space key with a keyboard selection button, but you can always access a space key using the shift key.)")
            ]),
        Step(title: "Character Selection", substeps: [
            Substep("The space key has one more function–when there are character choices displayed in the top bar, the space key's label changes to \"选定\" (_xuǎn dìng_, select) and lets you input the first character choice. Try typing \"wo3\" and using this key to select the first choice of \"我\".", target: "wo3"),
            Substep("Good, now tap \"选定\" to input the character \"我\".", target: "我"),
            Substep("Good work! Now you know how to use every key on the keyboard.")
            ]),
        Step(title: "Words",
             substeps: [
                Substep("Now try inputting a compound word. Try entering \"可爱\" (_kě ài_, cute) by typing \"ke3ai4\".", target: "ke3 ai4"),
                Substep("Good! Notice that the syllables \"ke3 ai4\" are displayed with a space between them for easier reading. Now select \"可爱\".", target: "可爱"),
                Substep("Great! You input your first compound word.")
             ]),
        Step(title: "Sentences",
             substeps: [
                Substep("ToneBoard does not try to make complete sentences for you, so you will need to input them one word at a time. Try inputting \"我喝水\" (_wǒ hē shuǐ_, or \"I drink water\"). First type \"wo3\".", target: "wo3"),
                Substep("Good, now see what happens if you continue to type \"he1\".", target: "wo3 he1"),
                Substep("Notice how there are no character choices for the input \"wo3he1\", because \"我喝\" is two words. Now try deleting \"he1\" and selecting the character \"我\".", target: "我"),
                Substep("Good, now type \"he1\" and select \"喝\" (_hē_, drink).", target: "我喝"),
                Substep("Alright! Now continue with \"shui3\" to input \"水\" (_shuǐ_, drink).", target: "我喝水"),
                Substep("Good! Now finish the sentence with a Chinese full stop \"。\", which you can find by tapping \"123\".", target: "我喝水。"),
                Substep("Good job! You typed a complete sentence.")
             ]),
        Step(title: "Changing Tones",
             substeps: [
                Substep("If you want to revise your tone selection, you can just tap another tone without using backspace. Try typing \"yao2\" and seeing what character choices appear.", target: "yao2"),
                Substep("Now try finding the character \"要\" (_yào_, want) by modifying the tone to 4. Just tap \"4\".", target: "yao4"),
                Substep("Great, now select the character \"要\".", target: "要"),
                Substep("Good, this will make it easier for you to confirm the correct tone for a character you're looking for.")
             ]),
        Step(title: "The Fifth Tone",
             substeps: [
                Substep("The so-called \"neutral tone\" or \"fifth tone\" is represented by the number 5. Try typing \"de5\" to input the common fifth-tone word \"的\" (_de_, possessive particle).", target: "de5"),
                Substep("Good, now select the character \"的\".", target: "的"),
                Substep("Good work!")
             ]),
        Step(title: "Typing \"Ü\"",
             substeps: [
                Substep("You can represent the \"ü\" Pinyin character with \"v\". Go ahead and try inputting \"女\" (_nǚ_, woman) by typing \"nv3\".", target: "nv3"),
                Substep("Good, now select the character \"女\".", target: "女"),
                Substep("Great job!")
             ]),
        Step(title: "Erhua",
             substeps: [
                Substep("You can input words featuring 儿化 (_ér huà_) by adding \"r5\". Try inputting 哪儿 (_nǎr_, where), by typing \"na3r5\".", target: "na3 r5"),
                Substep("Good, now select \"哪儿\".", target: "哪儿"),
                Substep("Great, now you know how to input any possible Chinese word!")
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
                    ProgressBar(numSteps: steps.count, currentStep: currentStep)
                }
                Carousel(steps: steps, currentStep: $currentStep)
                if (size == .large) {
                    Divider().padding(20)
                }
            }.frame(maxHeight: 600)
            Spacer(minLength: 20)
            Group {
                if lastStep {
                    NavigationLink(destination: InstallView()) {
                        BigButton("Install", primary: true)
                    }
                } else {
                    TutorialTextFieldView()
                        .frame(height: size == .small ? 30 : 45)
                        .frame(maxWidth: 300)

                }
            }
            Spacer(minLength: 20)
        }
        .padding(EdgeInsets(top: 0, leading: 50, bottom: 0, trailing: 50))
        .navigationTitle("Try Now")
        .navigationBarTitleDisplayMode(.inline)
        .environmentObject(textFieldState)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
//            VStack {
//                TutorialView()
//                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
//            }
//        }
//        .previewDevice("iPhone SE (1st Generation)")
        NavigationView {
            VStack {
                TutorialView()
                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
            }
        }
        .previewDevice("iPhone 8")
//        NavigationView {
//            VStack {
//                TutorialView()
//                Rectangle().frame(width:UIScreen.main.bounds.height, height: 280)
//            }
//        }.navigationViewStyle(StackNavigationViewStyle())
//        .previewDevice("iPad Mini (6th generation)")
    }
}
