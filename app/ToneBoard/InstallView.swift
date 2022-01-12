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
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("You can enable ToneBoard systemwide in the Settings app:")
                BulletedList(
                    [
                        "Go to the ToneBoard section in the Settings app",
                        "Select \"Keyboards\"",
                        "Switch on the \"ToneBoard\" keyboard"
                    ])
                    .padding()
                Text("Here is a shortcut to go straight to the ToneBoard section of the Settings app:")
            }.padding()
            Button {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                BigButton("Open Settings", primary: true)
            }.padding()
            Spacer()
        }
        .navigationTitle("Install")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InstallView_Previews: PreviewProvider {
    static var previews: some View {
        InstallView()
    }
}
