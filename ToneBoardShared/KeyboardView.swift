//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI


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
    let font: Font
    
    init(label: String, handler: @escaping () -> Void, font: Font = .system(size: 20)) {
        self.label = label
        self.handler = handler
        self.font = font
    }
    
    var body: some View {
        Button(action: handler) {
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
            .background(.gray.opacity(0.7))
            .cornerRadius(4)
            .padding(EdgeInsets(top: 5, leading: 2.5, bottom: 5, trailing: 2.5))
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
    
    @State private var rawInput = ""

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
            CandidatesView(candidates: candidates, selectCandidate: selectCandidate)
                .padding(EdgeInsets(top:10, leading: 5, bottom:0, trailing: 5))
                GeometryReader {geo in
                    VStack(spacing: 0) {
                        RowView(keys: "qwertyuiop", insert: insertAction)
                        RowView(keys: "asdfghjkl", insert: insertAction)
                            .frame(width: geo.size.width * 0.9)
                        HStack(spacing: 0) {
                            KeyView(label: "123", handler: {}, font: .system(size: 14)) //.frame(maxHeight: .infinity)
                            RowView(keys: "zxcvbnm", insert: insertAction)
                                .frame(width: geo.size.width * 0.7)
                            KeyView(label: "SF:delete.backward", handler: delete)
                        }
                        HStack {
    //                        KeyView(label: "SF:globe", handler: newLine)
                            NextKeyboardButton(setup: setupNextKeyboardButton)
                            RowView(keys: [("1̄", "1"), ("2́", "2"), ("3̌", "3"), ("4̀", "4"),
                                           ("5", "5")], insert: insertAction)
                                .frame(width: geo.size.width * 0.5)
                            KeyView(label: "return", handler: newLine, font: .system(size: 14))
                        }
                    }

                }
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
        let orientation = InterfaceOrientation.landscapeLeft
//        let orientation = InterfaceOrientation.portrait
        KeyboardView(proxy: p, dict: d, setupNextKeyboardButton: {_ in})
            .previewInterfaceOrientation(orientation)
            .previewDevice("iPhone 8")
        KeyboardView(proxy: p, dict: d, setupNextKeyboardButton: {_ in})
            .previewInterfaceOrientation(orientation)
            .previewDevice("iPhone 12")
        }
    
}
