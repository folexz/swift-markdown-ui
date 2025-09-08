import MarkdownUI
import SwiftUI

private enum Constants {
  static let delay: UInt64 = 300_000_000
  static let zero = 0
  static let one = 1
  static let sample = """
    # Word by Word
    This demo renders markdown content word by word using async/await.
    """
}

struct WordByWordView: View {
  var body: some View {
    DemoView {
      WordByWordMarkdown(Constants.sample)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct WordByWordMarkdown: View {
  private let words: [Substring]
  @State private var shown = Constants.zero

  init(_ markdown: String) {
    let attr = (try? AttributedString(markdown: markdown)) ?? AttributedString()
    let plain = String(attr.characters)
    words = plain.split { $0.isWhitespace }
  }

  var body: some View {
    Text(words.prefix(shown).joined(separator: " "))
      .task {
        for i in Constants.one...words.count {
          await Task.sleep(nanoseconds: Constants.delay)
          shown = i
        }
      }
  }
}

struct WordByWordView_Previews: PreviewProvider {
  static var previews: some View {
    WordByWordView()
  }
}
