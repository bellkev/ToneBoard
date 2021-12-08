//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI

struct KeyView: View {
    let label: String
    let handler: () -> Void
    
    init(label: String, handler: @escaping () -> Void) {
        self.label = label
        self.handler = handler
    }
    
    var body: some View {
        Button(action: handler) {
            if label.contains(".") {
                Image(systemName: label)
            } else {
                Text(label)
            }
        }
        .foregroundColor(.white)
        .frame(minWidth: 0, maxWidth: 50, minHeight: 40)
        .background(.gray)
        .cornerRadius(4)
        .padding(5)
    }
}


struct RowView: View {
    
    let keys: [String]
    let insert: (String) -> Void
    
    init(keys: String, insert: @escaping (String) -> Void) {
        self.keys = Array(keys).map {String($0)}
        self.insert = insert
    }
    
    
    var body: some View {
        HStack(spacing: 0){
            ForEach(keys, id: \.self) { k in
                KeyView(label: k, handler: {insert(k)})
            }
        }
    }
}

struct KeyboardView: View {
    
    let proxy: UITextDocumentProxy
    
    let dict: CandidateDict
    
    @State var rawInput = ""
    
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

    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
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
                        KeyView(label: "delete.backward", handler: delete)
                        RowView(keys: "zxcvbnm", insert: insertAction)
                            .frame(width: geo.size.width * 0.7)
                        KeyView(label: "delete.backward", handler: delete)
                    }
                    HStack {
                        RowView(keys: "12345", insert: insertAction)
                        Button("Commit", action: commit)
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
        KeyboardView(proxy: p, dict: d, rawInput: "foo1baz2abcas")
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
