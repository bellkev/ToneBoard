//
//  Components.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI


struct BigButton: View {
    let title: String
    let primary: Bool
    
    init(_ title: String, primary: Bool = false) {
        self.title = title
        self.primary = primary
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: 20))
            .bold()
            .padding(15)
            .frame(width: 200)
            .background(primary ? .green : .gray)
            .cornerRadius(10)
            .foregroundColor(Color(UIColor.label))
            .opacity(0.8)
    }
}


struct Header: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text).bold().padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 0))
    }
}


struct StaticContent<Content: View>: View {
    
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                content
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .padding()
        }
    }
}

