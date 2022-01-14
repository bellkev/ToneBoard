//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI


struct ToneBoardStyle {

    
    static let keyColor = Color.white
    static let specialKeyColor = Color(red: 0.66, green: 0.69, blue: 0.73)
    static let specialKeyColorTapped = Color.white
    static let keyColorDark = Color(hue: 0, saturation: 0, brightness: 0.3, opacity: 1)
    static let specialKeyColorDark = Color(hue: 0, saturation: 0, brightness: 0.1, opacity: 1)
    static let specialKeyColorTappedDark = Color(hue: 0, saturation: 0, brightness: 0.3, opacity: 1)
    static let candidateBackgroundColor = Color.black.opacity(0.05)
    static let candidateHighlightColor = Color.white
    static let candidateBackgroundColorDark = Color(hue: 0, saturation: 0, brightness: 0.05, opacity: 1)
    static let candidateHighlightColorDark = Color(hue: 0, saturation: 0, brightness: 0.2, opacity: 1)
    static let keyCornerRadius = 6.0
    static let keyPadding = EdgeInsets(top: 6, leading: 3, bottom: 5, trailing: 3)
    static let keyFontSizeSmall = 16.0
    static let keyFontSize = 24.0
    static let candidateFontSize = 24.0
    static var keyFont: UIFont {
        guard let ctFontChinese = CTFontCreateUIFontForLanguage(.system, keyFontSize, "zh-Hans" as CFString) else {
            return UIFont.systemFont(ofSize: keyFontSize)
        }
        return ctFontChinese as UIFont
    }
    
    static let keyFontSmall = keyFont.withSize(keyFontSizeSmall)
    static let candidateFont = keyFont.withSize(candidateFontSize)
}


struct CandidateView: View {
    let candidate: String
    let action: () -> Void
    var highlight = false
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var inputState: InputState
    
    var backgroundColor: Color {
        if colorScheme == .dark && highlight {
            return ToneBoardStyle.candidateHighlightColorDark
        } else if colorScheme == .dark {
            return ToneBoardStyle.candidateBackgroundColorDark
        } else if highlight {
            return ToneBoardStyle.candidateHighlightColor
        } else {
            return ToneBoardStyle.candidateBackgroundColor
        }
    }
    
    var verticalPadding: CGFloat {
        inputState.compact ? 5 : 8.5
    }
    
    var body: some View {
        Button(action: action) {
            Text(candidate)
                .font(Font(ToneBoardStyle.candidateFont))
                .foregroundColor(Color(UIColor.label))
                .padding(EdgeInsets(top: verticalPadding, leading: 12, bottom: verticalPadding, trailing: 12))
                .background(backgroundColor)
                .cornerRadius(4)
        }
    }
}


struct CandidatesView: View {
    
    @Namespace var candidateID
    @EnvironmentObject var inputState: InputState
    let selectCandidate: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 5) {
                    if inputState.candidates.isEmpty {
                        CandidateView(candidate: " ", action: {}).opacity(0)
                    }
                    ForEach(0..<inputState.candidates.count, id: \.self) { c in
                        CandidateView(candidate: inputState.candidates[c],
                                      action: {selectCandidate(inputState.candidates[c])},
                                      highlight: c == 0)
                    }
                }.id(candidateID)
                .onChange(of: inputState.candidates) { _ in
                    proxy.scrollTo(candidateID, anchor: .leading)
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
    let color: Color
    var small = false
            
    // Hardcoding this for now, should approximate half the width of full-width
    // glyph in a character used on a key
    let halfWidth = CGFloat(7)
    
    var xOffset: CGFloat {
        // Tweak full-width characters a bit so they are centered in keys
        if "（【｛《".contains(label) {
            return -halfWidth
        } else if "：；）。，、】｝》，、？！".contains(label) {
           return halfWidth
        }
        return 0
    }
    
    var scalar: UnicodeScalar {
        label.unicodeScalars.first!
    }
    
    var isLowercase: Bool {
        CharacterSet.lowercaseLetters.contains(label.unicodeScalars.first!)
    }
    
    var isUppercase: Bool {
        CharacterSet.uppercaseLetters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
    }
    
    var baselineOffset: CGFloat {
        // Tweaks to center labels in the keys better, especially for landscape
        if small {
            return 0
        } else if isLowercase {
            return 2
        } else if isUppercase {
            return -2
        } else {
            return 0
        }
    }
    
    var body: some View {
        Group {
            if label.starts(with: "SF:") {
                let name = label.split(separator: ":")[1]
                Image(systemName: String(name)).font(.system(size: 20, weight: .light))
            } else {
                Text(label)
                    .font(Font(small ? ToneBoardStyle.keyFontSmall : ToneBoardStyle.keyFont))
                    .baselineOffset(baselineOffset)
                    .offset(x: xOffset, y: 0)
            }
        }
        // Need to reduce the extra space above/below glyphs for landscape
        .padding(EdgeInsets(top: small ? 0 : -2.5, leading: 0, bottom: small ? 0 : -2.5, trailing: 0))
        .foregroundColor(Color(UIColor.label))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
        .cornerRadius(ToneBoardStyle.keyCornerRadius)
        .padding(ToneBoardStyle.keyPadding)
        // There seems to be a bug preventing contentShape from working normally in a custom keyboard.
        // It works for the in-app version of the keyboard but not in the systemwide mode.
        // Falling back on the not-quite-transparent hack to make the space around keys tappable.
        .background(.black.opacity(0.001))
    }

}


struct Key<Content: View>: View {
    
    let action: () -> Void
    let content: (Bool) -> Content
    @GestureState var isTapped = false
    
    init(action: @escaping () -> Void, content: @escaping (Bool) -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        content(isTapped)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTapped) { _, state, _ in
                    state = true
                }
                .onEnded { _ in
                    action()
                })
    }
}

struct StandardKey: View {
    let label: String
    let action: () -> Void
    var small = false
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var inputState: InputState
    
    var color: Color {
        colorScheme == .dark ? ToneBoardStyle.keyColorDark : ToneBoardStyle.keyColor
    }

        
    var body: some View {
        Key(action: action) { isTapped in
            GeometryReader { geo in
                ZStack {
                    KeyContent(label: label, color: color, small: small)
                        .frame(width: geo.size.width, height: geo.size.height)
                    if isTapped {
                        ZStack(alignment: .top) {
                            Popup(innerWidth: geo.size.width - ToneBoardStyle.keyPadding.leading * 2,
                                              topRadius: 8, bottomRadius: ToneBoardStyle.keyCornerRadius)
                                .fill(color)
                                .frame(width: geo.size.width * 1.5,
                                       height: geo.size.height * 2 + (inputState.compact ? 8 : 0))
                            KeyContent(label: label, color: .clear)
                                .scaleEffect(1.5)
                                .frame(height: geo.size.height)
                        }
                        .offset(x: 0, y: -ToneBoardStyle.keyPadding.bottom)
                        // Avoid the label casting a shadow onto the overlay shape
                        .compositingGroup()
                        .shadow(color: .black, radius: 1)

                    }
                }
                // Just accept the size proposed by parent, do not expand to contain the overlay
                .frame(minWidth: 0, minHeight: 0, alignment: .bottom)
            }
       
        }
    }
}


struct SpecialKey: View {
    let label: String
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    func color(_ isTapped: Bool) -> Color {
        if colorScheme == .dark && isTapped {
            return ToneBoardStyle.specialKeyColorTappedDark
        } else if colorScheme == .dark {
            return ToneBoardStyle.specialKeyColorDark
        } else if isTapped {
            return ToneBoardStyle.specialKeyColorTapped
        } else {
            return ToneBoardStyle.specialKeyColor
        }
    }
        
    var body: some View {
        Key(action: action) { isTapped in
            KeyContent(label: label, color: color(isTapped), small: true)
        }
    }
}


struct RowView: View {
    
    let keys: [(String, String)]
    let keyAction: (String) -> Void
    let small: Bool
    
    init(keys: String, keyAction: @escaping (String) -> Void, small: Bool = false) {
        self.keyAction = keyAction
        self.keys = keys.map {(String($0), String($0))}
        self.small = small
    }
    
    init(keys: [(String, String)], keyAction: @escaping (String) -> Void, small: Bool = false) {
        self.keyAction = keyAction
        self.keys = keys
        self.small = small
    }
    
    var body: some View {
        HStack(spacing: 0){
            ForEach(keys, id: \.0) { k in
                StandardKey(label: k.0, action: {keyAction(k.1)}, small: small)
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
    
    var numberOrSymbol: Bool {
        [.number, .symbol].contains(qwertyState)
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
                    .frame(width: geo.size.width * (numberOrSymbol ? 1 : 0.9))
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
                        SpecialKey(label: numberOrSymbol ? "拼音" : "123",
                                   action: {nextState(.tapNum)})
                        if inputState.needsInputModeSwitchKey {
                            NextKeyboardButton(setup: setupNext)
                                .padding(ToneBoardStyle.keyPadding)
                        } else {
                            spaceButton
                        }
                    }.frame(width: geo.size.width * 0.25)
                    Group{
                        if qwertyState == .normal {
                            RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"), ("5", "5")],
                                    keyAction: toneAction, small: inputState.compact)
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
    
    var setupNextKeyboardButton: ((UIButton) -> Void)
        
    @EnvironmentObject var inputState: InputState
    
    @Environment(\.colorScheme) var colorScheme
    
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

    
    var inner: some View {
        VStack {
            CandidatesView(selectCandidate: selectCandidate)
                .padding(EdgeInsets(top:10, leading: 5, bottom:0, trailing: 5))
            QwertyView(keyAction: insertAction, symbolAction: symbol, toneAction: tone, returnAction: newLine, spaceAction: space, backspaceAction: delete, setupNext: setupNextKeyboardButton)

        }
        .padding(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1))
        .frame(maxWidth: 600)
    }
    
    var body: some View {
        if colorScheme == .dark {
            // The goal here is to replicate system dark keyboard behavior:
            // Labels are opaque white, keys are translucent, and popped-up keys have the same color/alpha values as other keys
            inner.compositingGroup().luminanceToAlpha().colorInvert()
        } else {
            inner
        }
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


struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        let p = MockTextProxy()
//        let orientation = InterfaceOrientation.landscapeLeft
        let orientation = InterfaceOrientation.portrait
        let state = InputState()
//        state.compact = true
        state.candidates = ["不", "部", "步", "布"]
        return ZStack {
            Rectangle().fill(.gray).opacity(0.5).frame(width:UIScreen.main.bounds.width, height: 300)
//            Rectangle().fill(.white.opacity(0.5)).frame(width:200, height: 300).offset(x:100, y: 0)
            KeyboardView(proxy: p, setupNextKeyboardButton: {_ in})
                                    .previewInterfaceOrientation(orientation)
                                    .previewDevice("iPhone 8")
                                    .environmentObject(state)
                                    .frame(height: 288)
//                                    .preferredColorScheme(.dark)
            }
        }
}
