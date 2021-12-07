//
//  KeyboardView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/5/21.
//

import SwiftUI

struct Key: Identifiable {
    let label: String
    let handler: () -> Void
    var id: String { label }
    
    init(label: String, insert: @escaping (String) -> Void) {
        self.label = label
        self.handler = {insert(label)}
    }
}


struct RowView: View {
    
    let keys: [Key]
    
    init(keys: String, insert: @escaping (String) -> Void) {
        self.keys = keys.map {Key(label: String($0), insert: insert)}
    }
    
    var body: some View {
        HStack(spacing: 0){
            ForEach(keys) { k in
                Button(action: k.handler) {
                    Text(k.label)
                        .foregroundColor(Color.white)
                        .frame(minWidth: 0, maxWidth: 50, minHeight: 40)
                        .background(Color.gray)
                        .cornerRadius(4)
                        .padding(5)
                }
            }
        }
    }
}

struct KeyboardView: View {
    private var insertAction: (String) -> Void
    
    init(insert: @escaping (String) -> Void) {
        self.insertAction = insert
    }
    
    func handler(_ string: String) -> (() -> Void){
        // TODO: Use a closure
        func _handler() {
            insertAction(string)
        }
        return _handler
    }
    
    var body: some View {
        GeometryReader {geo in
            VStack(spacing: 0) {
                RowView(keys: "qwertyuiop", insert: insertAction)
                RowView(keys: "asdfghjkl", insert: insertAction)
                    .frame(maxWidth: geo.size.width * 0.9)
                RowView(keys: "zxcvbnm", insert: insertAction)
                    .frame(maxWidth: geo.size.width * 0.7)
            }
        }.frame(height:200)
    }
    
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView(insert: {_ in})
.previewInterfaceOrientation(.portrait)
    }
}
