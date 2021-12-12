//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI


struct ToneBoardStyle {
    static let keyColor = Color.gray.opacity(0.7)
    static let keyCornerRadius = 4.0
    static let keyPadding = EdgeInsets(top: 5, leading: 2.5, bottom: 5, trailing: 2.5)
    static let keyFontSizeSmall = 16.0
    static let keyFontSize = 24.0
}


struct CandidateView: View {
    let candidate: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(candidate)
                .font(.system(size: 24))
                .foregroundColor(Color(UIColor.label))
                .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .background(.gray.opacity(0.2))
                .cornerRadius(4)
        }
    }
}


struct CandidatesView: View {
    
    let candidates: [String]
    
    let selectCandidate: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Group {
                if (candidates.count > 0) {
                    HStack {
                        ForEach(candidates, id: \.self) { c in
                            CandidateView(candidate: c, action: {selectCandidate(c)})
                        }
                    }
                } else {
                    CandidateView(candidate: " ", action: {}).opacity(0)
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


struct KeyView: View {
    let label: String
    let action: () -> Void
    var small: Bool = false
    
    var body: some View {
        Group {
            if label.starts(with: "SF:") {
                let name = label.split(separator: ":")[1]
                Image(systemName: String(name))
            } else {
                Text(label)
                    .font(.system(size: small ? ToneBoardStyle.keyFontSizeSmall : ToneBoardStyle.keyFontSize))
            }
        }
        .foregroundColor(Color(UIColor.label))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ToneBoardStyle.keyColor)
        .cornerRadius(ToneBoardStyle.keyCornerRadius)
        .padding(ToneBoardStyle.keyPadding)
        .onTapGesture(perform: action)

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
                KeyView(label: k.0, action: {keyAction(k.1)})
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
    let returnAction: () -> Void
    let backspaceAction: () -> Void
    let setupNext: ((UIButton) -> Void)?
    
    @State private var qwertyState: QwertyState = .normal
    
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
        keyAction(s)
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
        default: debugPrint("Default")
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
    
    var body: some View {
        GeometryReader {geo in
            VStack(spacing: 0) {
                RowView(keys: rows[0], keyAction: tapKey)
                RowView(keys: rows[1], keyAction: tapKey)
                    .frame(width: geo.size.width * (qwertyState == .normal ? 0.9 : 1.0))
                HStack {
                    KeyView(label: shiftContent, action: {nextState(.tapShift)}, small: true)
                    RowView(keys: rows[2], keyAction: tapKey)
                        .frame(width: geo.size.width * 0.7)
                    KeyView(label: "SF:delete.backward", action: {
                        nextState(.tapAnyKey)
                        backspaceAction()
                    })
                }
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        KeyView(label: numContent, action: {nextState(.tapNum)}, small: true)
                        if let setup = setupNext {
                            NextKeyboardButton(setup: setup)
                                .padding(ToneBoardStyle.keyPadding)
                        }
                    }.frame(width: geo.size.width * 0.25)
                    Group{
                        if (qwertyState == .normal) {
                            RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"),
                                           ("5", "5")], keyAction: keyAction)
                        } else {
                            KeyView(label: "space", action: {tapKey(" ")}, small: true)
                        }
                    }
                    .frame(width: geo.size.width * 0.5)
                    KeyView(label: "return", action: {
                        nextState(.tapAnyKey)
                        returnAction()
                    }, small: true)
                        .frame(width: geo.size.width * 0.25)
                }
            }
        }
    }
}

struct KeyboardView: View {
    
    let proxy: UITextDocumentProxy
    
    let dict: CandidateDict
    
    @State private var rawInput = ""

    var setupNextKeyboardButton: ((UIButton) -> Void)?
    
    var candidates: [String] {
        let input = ToneBoardInput(rawInput)
        return dict.candidates(input.syllables)
    }
    
    func updateMarked() {
        let input = ToneBoardInput(rawInput)
        var temp = input.syllables
        if !input.remainder.isEmpty {
            temp += [input.remainder]
        }
        let tempStr = temp.joined(separator: " ")
        proxy.setMarkedText(tempStr, selectedRange: NSMakeRange(tempStr.count, 0))
    }
    
    func insertAction(_ s: String) -> Void {
        rawInput += s
        updateMarked()
    }
    
    func delete() {
        if rawInput.isEmpty {
            proxy.deleteBackward()
        } else {
            rawInput.remove(at: rawInput.index(before: rawInput.endIndex))
            updateMarked()
        }
    }
    
    func commit() {
        // unmarkText does not seem to update the UI correctly in some cases (e.g. Reminders app search bar or Safari location bar)
        // but works in other cases
        proxy.insertText(rawInput)
        rawInput = ""
        updateMarked()
    }
    
    func selectCandidate(_ candidate: String) {
        proxy.insertText(candidate)
        rawInput = ""
        updateMarked()
    }
    
    func newLine() {
        if rawInput.isEmpty {
            proxy.insertText("\n")
        } else {
            commit()
        }
    }

    
    var body: some View {
        VStack {
            CandidatesView(candidates: candidates, selectCandidate: selectCandidate)
                .padding(EdgeInsets(top:10, leading: 5, bottom:0, trailing: 5))
            QwertyView(keyAction: insertAction, returnAction: newLine, backspaceAction: delete, setupNext: setupNextKeyboardButton)

        }
        .frame(maxWidth: 600)
        .frame(height: 280)
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
        let d = MockDict()
//        let orientation = InterfaceOrientation.landscapeLeft
        let orientation = InterfaceOrientation.portrait
        KeyboardView(proxy: p, dict: d, setupNextKeyboardButton: {_ in})
            .previewInterfaceOrientation(orientation)
            .previewDevice("iPhone 8")
//        KeyboardView(proxy: p, dict: d)
//            .previewInterfaceOrientation(orientation)
//            .previewDevice("iPhone 12")
        }
    
}
