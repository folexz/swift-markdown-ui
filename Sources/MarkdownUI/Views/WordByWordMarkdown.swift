import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct WordByWordMarkdown: View {
  private let content: AttributedString
  private let boundaries: [AttributedString.Index]
  private let delay: UInt64
  @State private var visibleIndex: Int

  public init(_ markdown: String, delay: UInt64 = Constants.wordDelay) {
    self.content = (try? AttributedString(markdown: markdown)) ?? .init()
    self.boundaries = Self.makeBoundaries(for: self.content)
    self.delay = delay
    _visibleIndex = State(initialValue: self.boundaries.startIndex)
  }

  public var body: some View {
    Text(self.content[self.content.startIndex..<self.currentEnd])
      .task { await self.animate() }
  }

  private var currentEnd: AttributedString.Index {
    self.visibleIndex < self.boundaries.count ? self.boundaries[self.visibleIndex] : self.content.endIndex
  }

  @MainActor
  private func animate() async {
    for index in self.boundaries.indices {
      try? await Task.sleep(nanoseconds: self.delay)
      self.visibleIndex = self.boundaries.index(after: index)
    }
  }

  private static func makeBoundaries(for content: AttributedString) -> [AttributedString.Index] {
    var bounds: [AttributedString.Index] = []
    var index = content.startIndex
    while index < content.endIndex {
      while index < content.endIndex, !content.characters[index].isWhitespace {
        index = content.index(after: index)
      }
      while index < content.endIndex, content.characters[index].isWhitespace {
        index = content.index(after: index)
      }
      bounds.append(index)
    }
    return bounds
  }

  enum Constants {
    static let wordDelay: UInt64 = 300_000_000
  }
}
