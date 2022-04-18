//
//  HelpView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        StaticContent("Help") {
            Header("Why isn't some character or word showing up?")
            Text("ToneBoard presents character and word choices based on data from the [CC-CEDICT](https://cc-cedict.org/) project. You can explore the data there to see what words and readings are available. You can also contribute new words to the project so that they can be included in a future version of ToneBoard. Note that ToneBoard does remove a few entries from the CC-CEDICT data. Specifically, it only includes words that are four or fewer characters, consisting only of 汉字 (_hànzì_, Chinese characters), and including a Pinyin reading in the normal format.")
            Header("Where's the spacebar?")
            Text("ToneBoard replaces the typical spacebar with tone buttons so you can easily type tone numbers. On newer devices with Face ID, there is a small space button (labeled \"空格\", read _kònggé_ meaning \"space\") to the left of the tone buttons. On devices without Face ID, this key is replaced with a ") +  Text(Image(systemName: "globe")) + Text(" key to switch keyboards, but you can always access a space bar with the ") + Text(Image(systemName: "shift")) + Text( " or \"123\" keys.")
            Header("What is the \"Indicate rare tones\" setting?")
            Text("This setting (available in the ToneBoard section of the Settings app) will make ToneBoard display an asterisk (\\*) next to characters for which a given tone is relatively rare. For example, if you type \"ma3\", you will see \"吗*\" as one of the options, indicating that while the character can be read this way, there is another reading that is much more common (in this case \"ma5\").")
            Header("I still need help.")
            Text("If you don't find an answer to your question above, you can open an issue in the public [issue list](https://github.com/bellkev/ToneBoard/issues) or contact [toneboard@bellkev.com](mailto:toneboard@bellkev.com).")
        }
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
