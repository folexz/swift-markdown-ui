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
      ProgressiveMarkdown(Constants.sample)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct ProgressiveMarkdown: View {
  private let chunks: [MarkdownContent]
  @State private var shown = Constants.zero

  init(_ markdown: String) {
    let blocks = MarkdownContent(markdown).blocks
    chunks = Self.makeChunks(from: blocks)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      ForEach(Constants.zero..<shown, id: \.self) { i in
        Markdown(chunks[i])
      }
    }
    .task {
      for i in Constants.one...chunks.count {
        await Task.sleep(nanoseconds: Constants.delay)
        shown = i
      }
    }
  }

  private static func makeChunks(from blocks: [BlockNode]) -> [MarkdownContent] {
    var result: [MarkdownContent] = []
    for block in blocks {
      switch block {
      case .paragraph(let inlines):
        var partial: [InlineNode] = []
        for piece in split(inlines) {
          partial += piece
          result.append(MarkdownContent(block: .paragraph(content: partial)))
        }
      default:
        result.append(MarkdownContent(block: block))
      }
    }
    return result
  }

  private static func split(_ inlines: [InlineNode]) -> [[InlineNode]] {
    var pieces: [[InlineNode]] = []
    var current: [InlineNode] = []

    func flush() {
      guard !current.isEmpty else { return }
      pieces.append(current)
      current = []
    }

    for node in inlines {
      switch node {
      case .text(let str):
        var word = ""
        for ch in str {
          if ch.isWhitespace {
            if !word.isEmpty {
              current.append(.text(word))
              word = ""
            }
            flush()
          } else {
            word.append(ch)
          }
        }
        if !word.isEmpty { current.append(.text(word)) }

      case .emphasis(let children):
        for w in split(children) {
          current.append(.emphasis(children: w))
          flush()
        }

      case .strong(let children):
        for w in split(children) {
          current.append(.strong(children: w))
          flush()
        }

      case .strikethrough(let children):
        for w in split(children) {
          current.append(.strikethrough(children: w))
          flush()
        }

      case .link(let dst, let children):
        for w in split(children) {
          current.append(.link(destination: dst, children: w))
          flush()
        }

      case .image, .code, .html, .softBreak, .lineBreak:
        current.append(node)
        flush()
      }
    }
    flush()
    return pieces
  }
}

struct WordByWordView_Previews: PreviewProvider {
  static var previews: some View {
    WordByWordView()
  }
}
