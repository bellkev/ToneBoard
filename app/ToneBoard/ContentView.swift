//
//  ContentView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/4/21.
//

import SwiftUI


struct Home: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("ToneBoard").font(.system(size: 50))
            Spacer()
            NavigationLink(destination: TutorialView()) {
                BigButton("Try Now", primary: true)
            }
            NavigationLink(destination: InstallView()) {
                BigButton("Install")
            }
            NavigationLink(destination: HelpView()) {
                BigButton("Help")
            }
            NavigationLink(destination: AboutView()) {
                BigButton("About")
            }
            Spacer()
            (Text("You can try ToneBoard with a quick tutorial in this app by selecting **Try Now**, or select **Install** to use it systemwide."))
                .multilineTextAlignment(.center)
                .font(.system(size: 20))
                .padding()
                .frame(maxWidth: 400)
                .layoutPriority(1)
            Spacer()
            

        }
        .navigationBarTitle("Home")
        .navigationBarHidden(true)
    }
}


struct ContentView: View {

    var body: some View {
        NavigationView {
            Home()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        .environment(\.sizeCategory, .extraExtraLarge)
        .previewDevice("iPhone SE (1st Generation)")
        ContentView()
        .environment(\.sizeCategory, .extraExtraLarge)
        .previewDevice("iPhone 11 Pro Max")
    }
}
