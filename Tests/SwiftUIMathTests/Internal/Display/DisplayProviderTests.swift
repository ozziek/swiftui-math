import Foundation
import Testing

@testable import SwiftUIMath

struct DisplayProviderTests {
  @Test(arguments: ["underbrace", "overbrace"], [Math.TypesettingStyle.text, .display])
  func braceKeepsBodyAndCentersAnnotations(command: String, style: Math.TypesettingStyle) throws {
    let provider = Math.DisplayProvider()
    let source = "\\\(command){24:1}_{0.96\\text{ on half spam}}^{\\text{odds}}"
    let display = try #require(
      provider.display(
        for: source, font: .init(name: .latinModern, size: 24), style: style, proposedWidth: 0)
        as? Math.DisplayList)
    let brace = try #require(display.children.first as? Math.DisplayLargeOperator)
    let nucleus = try #require(brace.nucleus as? Math.DisplayList)
    let body = try #require(nucleus.children.first as? Math.DisplayList)
    let glyph = try #require(nucleus.children.last as? Math.DisplayGlyph)
    let label = try #require(brace.lowerLimit)
    #expect(glyph.glyph != 0)
    #expect(body.position.y == 0)
    #expect(glyph.width >= body.width)
    #expect(label.position.y + label.ascent < -nucleus.descent)
    #expect(abs(label.position.x + label.width / 2 - (brace.position.x + brace.width / 2)) < 0.01)
    #expect(display.width > 80)
    #expect(display.ascent > 0 && display.descent > 0)
    #expect((glyph.position.y > 0) == (command == "overbrace"))
  }

  @Test(arguments: [Math.TypesettingStyle.text, .display])
  func customOperatorRendersWithUprightText(style: Math.TypesettingStyle) throws {
    let display = try #require(
      Math.DisplayProvider().display(
        for: #"y = \operatorname{normalize}(z)"#,
        font: .init(name: .latinModern, size: 20.4), style: style, proposedWidth: 320)
        as? Math.DisplayList)
    #expect(display.width > 100)
    #expect(
      display.children.compactMap { ($0 as? Math.DisplayTextRun)?.text }.joined()
        == "𝑦=normalize(𝑧)")
  }

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
