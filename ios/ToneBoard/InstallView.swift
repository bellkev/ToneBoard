//
//  InstallView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI


struct BulletedList: View {
    let items: [String]
    
    init(_ items: [String]) {
        self.items = items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(items, id: \.self) { i in
                HStack(alignment:.top) {
                    Text("•")
                    Text(i)
                }
            }

        }
    }
}


struct InstallView: View {
    var body: some View {
        StaticContent("Install") {
            Text("You can enable ToneBoard systemwide in your device's keyboard settings:")
            BulletedList(
                [
                    "Open the Settings app",
                    "Go to General > Keyboard > Keyboards",
                    "Select \"Add New Keyboard...\"",
                    "Select \"ToneBoard\" under \n\"THIRD-PARTY KEYBOARDS\""
                ])
                .padding()
        }
    }
}

struct InstallView_Previews: PreviewProvider {
    static var previews: some View {
        InstallView()
    }
}
