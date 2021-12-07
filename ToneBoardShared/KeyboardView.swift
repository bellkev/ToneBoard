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
    let textColor = Color.white
    
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
        .foregroundColor(Color.white)
        .frame(minWidth: 0, maxWidth: 50, minHeight: 40)
        .background(Color.gray)
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
    
    @State private var marked = ""
    
    init(proxy: UITextDocumentProxy) {
        self.proxy = proxy
    }
    
    
    func updateMarked() {
        proxy.setMarkedText(marked, selectedRange: NSMakeRange(marked.count, 0))
    }
    
    func insertAction(_ s: String) -> Void {
        marked += s
        updateMarked()
    }
    
    func delete() {
        proxy.deleteBackward()
    }
    
    func commit() {
        // Unclear how unmarkText is actually supposed to work--unmarking does not update the UI, but this seems to behave as expected
        // TODO: Handle backspace while text is marked
        proxy.insertText(marked)
        self.marked = ""
    }

    
    var body: some View {
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
        }.frame(height:200)
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
        KeyboardView(proxy:p)
            .previewInterfaceOrientation(.portraitUpsideDown)
    }
}
