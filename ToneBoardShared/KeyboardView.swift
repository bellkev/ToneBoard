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
}


struct CandidateView: View {
    let candidate: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(candidate)
                .font(.system(size: 20))
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
    let font: Font
    
    init(label: String, action: @escaping () -> Void, font: Font = .system(size: 20)) {
        self.label = label
        self.action = action
        self.font = font
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if label.starts(with: "SF:") {
                    let name = label.split(separator: ":")[1]
                    Image(systemName: String(name))
                } else {
                    Text(label)
                        .font(font)
                }
            }
            .foregroundColor(Color(UIColor.label))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ToneBoardStyle.keyColor)
            .cornerRadius(ToneBoardStyle.keyCornerRadius)
            .padding(ToneBoardStyle.keyPadding)
        }

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

struct QwertyView: View {
    
    let keyAction: (String) -> Void
    let returnAction: () -> Void
    let backspaceAction: () -> Void
    let setupNext: ((UIButton) -> Void)?
    
    var body: some View {
        GeometryReader {geo in
            VStack(spacing: 0) {
                RowView(keys: "qwertyuiop", keyAction: keyAction)
                RowView(keys: "asdfghjkl", keyAction: keyAction)
                    .frame(width: geo.size.width * 0.9)
                HStack {
                    KeyView(label: "SF:shift", action: {})
                    RowView(keys: "zxcvbnm", keyAction: keyAction)
                        .frame(width: geo.size.width * 0.7)
                    KeyView(label: "SF:delete.backward", action: backspaceAction)
                }
                HStack(spacing: 0) {
                    HStack(spacing: 0) {
                        KeyView(label: "123", action: {}, font: .system(size: 14)) //.frame(maxHeight: .infinity)
                        if let setup = setupNext {
                            NextKeyboardButton(setup: setup)
                                .padding(ToneBoardStyle.keyPadding)
                        }
                    }.frame(width: geo.size.width * 0.25)
                    RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"),
                                   ("5", "5")], keyAction: keyAction)
                        .frame(width: geo.size.width * 0.5)
                    KeyView(label: "return", action: returnAction, font: .system(size: 14))
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
