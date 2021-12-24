//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI


struct ToneBoardStyle {
    static let keyColor = Color.gray
    static let keyColorTapped = Color.gray.opacity(0.7)
    static let keyCornerRadius = 4.0
    static let keyPadding = EdgeInsets(top: 5, leading: 2.5, bottom: 5, trailing: 2.5)
    static let keyFontSizeSmall = 16.0
    static let keyFontSize = 24.0
    static let candidateFontSize = 24.0
    static let uiFont = UIFont(name: "PingFangSC-Regular", size: keyFontSize) ?? UIFont.systemFont(ofSize: keyFontSize)
    static let keyFont = Font(uiFont)
    static let keyFontSmall = Font(uiFont.withSize(keyFontSizeSmall))
    static let candidateFont = Font(uiFont.withSize(candidateFontSize))
}


struct CandidateView: View {
    let candidate: String
    let action: () -> Void
    var highlight = false
    
    var body: some View {
        Button(action: action) {
            Text(candidate)
                .font(ToneBoardStyle.candidateFont)
                .foregroundColor(Color(UIColor.label))
                .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .background(.gray.opacity(highlight ? 0.3 : 0.1))
                .cornerRadius(4)
        }
    }
}


struct CandidatesView: View {
    
    @EnvironmentObject var inputState: InputState
    let selectCandidate: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                if inputState.candidates.isEmpty {
                    CandidateView(candidate: " ", action: {}).opacity(0)
                }
                ForEach(0..<inputState.candidates.count, id: \.self) { c in
                    CandidateView(candidate: inputState.candidates[c],
                                  action: {selectCandidate(inputState.candidates[c])},
                                  highlight: c == 0)
                }
            }
        }
    }
}


struct NextKeyboardButton: UIViewRepresentable {
    
    let button: UIButton
    
    init(setup: (UIButton) -> Void) {
        button = UIButton()
        button.backgroundColor = UIColor(ToneBoardStyle.keyColor)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.layer.cornerRadius = ToneBoardStyle.keyCornerRadius
        button.tintColor = .label
        setup(button)
    }
    
    func makeUIView(context: Context) -> some UIView {
        button
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}


struct KeyContent: View {
    let label: String
    let action: () -> Void
    var small = false
    var popUp = false
        
    @GestureState var isTapped = false
    
    // Hardcoding this for now, should approximate half the width of full-width
    // glyph in a character used on a key
    let halfWidth = CGFloat(7)
    
    var xOffset: CGFloat {
        // Tweak full-width characters a bit so they are centered in keys
        if "（【｛《".contains(label) {
            return -halfWidth
        } else if "）。，、】｝》，、？！".contains(label) {
           return halfWidth
        }
        return 0
    }
    
    
    var color: Color {
        (isTapped && !popUp) ? ToneBoardStyle.keyColorTapped : ToneBoardStyle.keyColor
    }
    
    var isPoppedUp: Bool {
        popUp && isTapped
    }

    
    var body: some View {
        Group {
            if label.starts(with: "SF:") {
                let name = label.split(separator: ":")[1]
                Image(systemName: String(name))
            } else {
                Text(label)
                    .font(small ? ToneBoardStyle.keyFontSmall : ToneBoardStyle.keyFont)
                    .offset(x: xOffset, y: 0)
            }
        }
        .foregroundColor(Color(UIColor.label))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
        .cornerRadius(ToneBoardStyle.keyCornerRadius)
        .padding(ToneBoardStyle.keyPadding)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTapped) { _, state, _ in
                    state = true
                }
                .onEnded { _ in
                    action()
                })
        // It's surprisingly hard to compose these modifiers conditionally with if/else,
        // as any branching results in a ConditionalContent view that does not have a single
        // consistent identity for the tap/release gesture
        .scaleEffect(isPoppedUp ? 1.3 : 1)
        .offset(x:0, y: isPoppedUp ? -40 : 0)
        .shadow(color: .black.opacity(isPoppedUp ? 1 : 0), radius: 2)
    }

}


struct StandardKey: View {
    let label: String
    let action: () -> Void
        
    var body: some View {
        KeyContent(label: label, action: action, popUp: true)

    }
}


struct SpecialKey: View {
    let label: String
    let action: () -> Void
        
    var body: some View {
        KeyContent(label: label, action: action, small: true)
    }
}


struct RowView: View {
    
    let keys: [(String, String)]
    
    let keyAction: (String) -> Void
    
    init(keys: String, keyAction: @escaping (String) -> Void) {
        self.keyAction = keyAction
        self.keys = keys.map {(String($0), String($0))}
    }
    
    init(keys: [(String, String)], keyAction: @escaping (String) -> Void) {
        self.keyAction = keyAction
        self.keys = keys
    }
    
    var body: some View {
        HStack(spacing: 0){
            ForEach(keys, id: \.0) { k in
                StandardKey(label: k.0, action: {keyAction(k.1)})
            }
        }
    }
}


enum QwertyState {
    case normal, justShift, shift, capsLock, number, symbol
}


enum QwertyEvent {
    case tapShift, tapNum, tapAnyKey, shiftDelay
}


struct QwertyView: View {
    
    let keyAction: (String) -> Void
    let symbolAction: (String) -> Void
    let toneAction: (String) -> Void
    let returnAction: () -> Void
    let spaceAction: () -> Void
    let backspaceAction: () -> Void
    let setupNext: ((UIButton) -> Void)
    
    @State private var qwertyState: QwertyState = .normal
    
    @EnvironmentObject var inputState: InputState
    
    var rows: [String] {
        switch qwertyState {
        case .normal:
            return ["qwertyuiop", "asdfghjkl", "zxcvbnm"]
        case .shift, .justShift, .capsLock:
            return ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
        case .number:
            return ["1234567890", "-/：；（）$@“”", "。，、？！."]
        case .symbol:
            return ["【】｛｝#%^*+=", "_—\\｜～《》€&·", "…，、？！‘"]
        }
    }
    
    func tapKey(_ s: String) {
        nextState(.tapAnyKey)
        if [.number, .symbol].contains(qwertyState) {
            symbolAction(s)
        } else {
            keyAction(s)
        }
    }
    
    // FSM to control transitions between shift/numlock/etc states
    func nextState(_ e: QwertyEvent) {
        switch (qwertyState, e) {
        case (.normal, .tapShift): qwertyState = .justShift
            Task {
                await Task.sleep(NSEC_PER_SEC / 2)
                nextState(.shiftDelay)
            }
        case (.normal, .tapNum): qwertyState = .number
        case (.justShift, .tapNum): qwertyState = .number
        case (.justShift, .tapShift): qwertyState = .capsLock
        case (.justShift, .shiftDelay): qwertyState = .shift
        case (.justShift, .tapAnyKey): qwertyState = .normal
        case (.shift, .tapShift): qwertyState = .normal
        case (.shift, .tapNum): qwertyState = .number
        case (.shift, .tapAnyKey): qwertyState = .normal
        case (.capsLock, .tapShift): qwertyState = .normal
        case (.capsLock, .tapNum): qwertyState = .number
        case (.number, .tapNum): qwertyState = .normal
        case (.number, .tapShift): qwertyState = .symbol
        case (.symbol, .tapShift): qwertyState = .number
        case (.symbol, .tapNum): qwertyState = .normal
        default: break
        }
    }
    
    var shiftContent: String {
        switch qwertyState {
        case .normal:
            return "SF:shift"
        case .justShift, .shift:
            return "SF:shift.fill"
        case .capsLock:
            return "SF:capslock.fill"
        case .number:
            return "#+="
        case .symbol:
            return "123"
        }
    }
    
    var numContent: String {
        switch qwertyState {
        case .normal, .justShift, .shift, .capsLock:
            return "123"
        case .number, .symbol:
            return "ABC"
        }
    }
    
    var spaceButton: some View {
        SpecialKey(label: inputState.candidates.isEmpty ? "空格" : "选定", action: {
            nextState(.tapAnyKey)
            spaceAction()
        })
    }
    
    var body: some View {
        GeometryReader {geo in
            VStack(spacing: 0) {
                RowView(keys: rows[0], keyAction: tapKey)
                RowView(keys: rows[1], keyAction: tapKey)
                    .frame(width: geo.size.width * (qwertyState == .normal ? 0.9 : 1.0))
                HStack {
                    SpecialKey(label: shiftContent, action: {nextState(.tapShift)})
                    RowView(keys: rows[2], keyAction: tapKey)
                        .frame(width: geo.size.width * 0.7)
                    SpecialKey(label: "SF:delete.backward", action: {
                        nextState(.tapAnyKey)
                        backspaceAction()
                    })
                }
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        SpecialKey(label: numContent, action: {nextState(.tapNum)})
                        if inputState.needsInputModeSwitchKey {
                            NextKeyboardButton(setup: setupNext)
                                .padding(ToneBoardStyle.keyPadding)
                        } else {
                            spaceButton
                        }
                    }.frame(width: geo.size.width * 0.25)
                    Group{
                        if (qwertyState == .normal) {
                            RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"),
                                           ("5", "5")], keyAction: toneAction)
                        } else {
                            spaceButton
                        }
                    }
                    .frame(width: geo.size.width * 0.5)
                    SpecialKey(label: inputState.rawInput.isEmpty ? "换行" : "确认", action: {
                        nextState(.tapAnyKey)
                        returnAction()
                    })
                        .frame(width: geo.size.width * 0.25)
                }
            }
        }
    }
}

struct KeyboardView: View {
    
    let proxy: UITextDocumentProxy
        
    @EnvironmentObject var inputState: InputState

    var setupNextKeyboardButton: ((UIButton) -> Void)
    
    func insertAction(_ s: String) -> Void {
        inputState.rawInput += s
    }
    
    func symbol(_ s: String) -> Void {
        if inputState.rawInput.isEmpty {
            proxy.insertText(s)
        } else {
            inputState.rawInput += s
        }
    }
    
    func delete() {
        if inputState.rawInput.isEmpty {
            proxy.deleteBackward()
        } else {
            inputState.rawInput.remove(at: inputState.rawInput.index(before: inputState.rawInput.endIndex))
        }
    }
    
    func tone(_ s: String) -> Void {
        // If a tone was the last thing entered, replace it
        let input = ToneBoardInput(inputState.rawInput)
        if !input.syllables.isEmpty && input.remainder.isEmpty {
            delete()
        }
        inputState.rawInput += s
    }
    
    func commit() {
        proxy.insertText(inputState.rawInput)
        inputState.rawInput = ""
    }
    
    func selectCandidate(_ candidate: String) {
        proxy.insertText(candidate)
        inputState.rawInput = ""
    }
    
    func newLine() {
        if inputState.rawInput.isEmpty {
            proxy.insertText("\n")
        } else {
            commit()
        }
    }
    
    func space() {
        if inputState.candidates.isEmpty {
            symbol(" ")
        } else {
            selectCandidate(inputState.candidates[0])
        }
    }

    
    var body: some View {
        VStack {
            CandidatesView(selectCandidate: selectCandidate)
                .padding(EdgeInsets(top:10, leading: 5, bottom:0, trailing: 5))
            QwertyView(keyAction: insertAction, symbolAction: symbol, toneAction: tone, returnAction: newLine, spaceAction: space, backspaceAction: delete, setupNext: setupNextKeyboardButton)

        }
        .frame(maxWidth: 600)
    }
    
}

class MockTextProxy: NSObject, UITextDocumentProxy {
    
    override init() {
        self.documentIdentifier = UUID()
        self.hasText = false
    }
    
    var documentContextBeforeInput: String?
    
    var documentContextAfterInput: String?
    
    var selectedText: String?
    
    var documentInputMode: UITextInputMode?
    
    var documentIdentifier: UUID
    
    func adjustTextPosition(byCharacterOffset offset: Int) {
    }
    
    func setMarkedText(_ markedText: String, selectedRange: NSRange) {
    }
    
    func unmarkText() {
    }
    
    var hasText: Bool
    
    func insertText(_ text: String) {
    }
    
    func deleteBackward() {
    }
}

struct MockDict: CandidateDict {
    func candidates(_ syllables: [String]) -> [String] {
        ["不", "部", "步", "布", "簿", "埔", "歩", "怖", "埠", "埗", "鈈", "蔀", "吥", "鈽", "佈", "歨", "餔", "篰", "悑", "捗", "瓿"]
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        let p = MockTextProxy()
//        let orientation = InterfaceOrientation.landscapeLeft
        let orientation = InterfaceOrientation.portrait
        KeyboardView(proxy: p, setupNextKeyboardButton: {_ in})
                                .previewInterfaceOrientation(orientation)
                                .previewDevice("iPhone 8")
                                .environmentObject(InputState())
                                .frame(height: 285)
        
        }
    
}
