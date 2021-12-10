//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI


struct NextKeyboardButton: UIViewRepresentable {
    
    let button: UIButton
    
    init(setup: (UIButton) -> Void) {
        button = UIButton()
        button.backgroundColor = UIColor.red
        setup(button)
    }
    
    func makeUIView(context: Context) -> some UIView {
        button
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}


struct KeyView: View {
    let label: String
    let handler: () -> Void
    
    init(label: String, handler: @escaping () -> Void) {
        self.label = label
        self.handler = handler
    }
    
    var body: some View {
        Button(action: handler) {
            HStack {
                if label.starts(with: "SF:") {
                    let name = label.split(separator: ":")[1]
                    Image(systemName: String(name))
                } else {
                    Text(label)
                }
            }
            .foregroundColor(.white)
            .frame(minWidth: 0, maxWidth: 60, minHeight: 40)
            .background(.gray)
            .cornerRadius(4)
            .padding(5)
        }

    }
}


struct RowView: View {
    
    let keys: [(String, String)]
    
    let insert: (String) -> Void
    
    init(keys: String, insert: @escaping (String) -> Void) {
        self.insert = insert
        self.keys = keys.map {(String($0), String($0))}
    }
    
    init(keys: [(String, String)], insert: @escaping (String) -> Void) {
        self.insert = insert
        self.keys = keys
    }
    
    var body: some View {
        HStack(spacing: 0){
            ForEach(keys, id: \.0) { k in
                KeyView(label: k.0, handler: {insert(k.1)})
            }
        }
    }
}

struct KeyboardView: View {
    
    let proxy: UITextDocumentProxy
    
    var dict: CandidateDict
    
    @State var rawInput = ""
    
    let setupNextKeyboardButton: (UIButton) -> Void
    
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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(candidates, id: \.self) { c in
                        Button(action: {selectCandidate(c)}) {
                            Text(c)
                        }
                        .padding(10)
                        .foregroundColor(Color(UIColor.label))
                    }
                }.frame(height: 40)
            }
            GeometryReader {geo in
                VStack(spacing: 0) {
                    RowView(keys: "qwertyuiop", insert: insertAction)
                    RowView(keys: "asdfghjkl", insert: insertAction)
                        .frame(width: geo.size.width * 0.9)
                    HStack {
                        KeyView(label: "123", handler: {})
                        RowView(keys: "zxcvbnm", insert: insertAction)
                            .frame(width: geo.size.width * 0.7)
                        KeyView(label: "SF:delete.backward", handler: delete)
                    }
                    HStack {
//                        KeyView(label: "SF:globe", handler: newLine)
                        NextKeyboardButton(setup: setupNextKeyboardButton)
                            .frame(width: 75)
                        RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"),
                                       ("5", "5")], insert: insertAction)
                        KeyView(label: "return", handler: newLine)
                    }
                }
            }
        }.frame(height:250)
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
        KeyboardView(proxy: p, dict: d, rawInput: "foo1baz2abcas", setupNextKeyboardButton: {_ in})
    }
}
