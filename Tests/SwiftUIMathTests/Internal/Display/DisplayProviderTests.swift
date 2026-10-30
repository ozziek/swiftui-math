import Foundation
import Testing

@testable import SwiftUIMath

struct DisplayProviderTests {
  @Test(arguments: [Math.TypesettingStyle.text, .display])
  func dotsAliasRendersTheWholeSeries(style: Math.TypesettingStyle) throws {
    let provider = Math.DisplayProvider()
    let font = Math.Font(name: .latinModern, size: 20.4)
    let display = try #require(
      provider.display(
        for: #"1 + 2 + 4 + \dots + 2^{k-1}"#, font: font, style: style, proposedWidth: 0)
        as? Math.DisplayList)
    let reference = try #require(
      provider.display(
        for: #"1 + 2 + 4 + \ldots + 2^{k-1}"#, font: font, style: style, proposedWidth: 0)
        as? Math.DisplayList)

    #expect(display.bounds == reference.bounds)
    #expect(display.width > 100)
    #expect(
      display.children.compactMap { ($0 as? Math.DisplayTextRun)?.text }.joined()
        == "1+2+4+…+2")
    let script = try #require(display.children.compactMap { $0 as? Math.DisplayList }.first)
    #expect(script.children.compactMap { ($0 as? Math.DisplayTextRun)?.text }.joined() == "𝑘−1")
  }

  @Test(arguments: [CGFloat(1), 2, 3], [CGFloat(13.2), 16.8, 20.4, 24, 33.6, 49.2])
  func logarithmSurvivesPixelAlignment(scale: CGFloat, fontSize: CGFloat) throws {
    let provider = Math.DisplayProvider()
    let font = Math.Font(name: .latinModern, size: fontSize)
    let latex = #"O(n\log n)"#
    let measuredSize = provider.sizeThatFits(
      proposedWidth: 320, latex: latex, font: font, style: .text)
    let drawingWidth = (measuredSize.width * scale).rounded() / scale

    // Check both the cached layout and a fresh draw after cache eviction.
    for drawingProvider in [provider, Math.DisplayProvider()] {
      let display = try #require(
        drawingProvider.display(
          for: latex, font: font, style: .text, proposedWidth: drawingWidth)
          as? Math.DisplayList)
      let runs = display.children.compactMap { $0 as? Math.DisplayTextRun }

      #expect(display.bounds.size == measuredSize)
      #expect(runs.map(\.text).joined() == "𝑂(𝑛log𝑛)")
      #expect(runs.allSatisfy { $0.position.y == 0 })
    }
  }

  @Test
  func constrainedExpressionStillWraps() throws {
    let provider = Math.DisplayProvider()
    let font = Math.Font(name: .latinModern, size: 20.4)
    let latex = "a+b+c+d+e+f+g+h"
    let naturalSize = provider.sizeThatFits(
      proposedWidth: 0, latex: latex, font: font, style: .text)
    let wrapped = try #require(
      provider.display(for: latex, font: font, style: .text, proposedWidth: 60)
        as? Math.DisplayList)

    #expect(wrapped.bounds.height > naturalSize.height)
    #expect(wrapped.children.contains { $0.position.y < 0 })
    #expect(
      provider.sizeThatFits(
        proposedWidth: wrapped.width, latex: latex, font: font, style: .text)
        == wrapped.bounds.size)
  }
}
