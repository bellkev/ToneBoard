//
//  AboutView.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/18/21.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        StaticContent("About") {
            Header("The ToneBoard Story")
            Text("The creator of ToneBoard found it difficult to remember Mandarin Chinese tones, especially when using language learning apps and typing with standard Pinyin keyboards. These keyboards don't require you to input tones, making it very easy to type the correct characters without knowing the correct tones. These keyboards also tend to remember your frequently used words or suggest complete phrases, which is not helpful for language learners.")
            Header("Data Sources")
            Text("ToneBoard gets Pinyin spellings and tones for words and characters from [CC-CEDICT](https://cc-cedict.org/). The word frequency data used to show the most common words first comes from the [Google Ngram data](https://books.google.com/ngrams/datasets).")
            Header("Source Code")
            Text("The ToneBoard keyboard is free and open-source software. You can find the source code on GitHub [here](https://github.com/bellkev/ToneBoard).")
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
