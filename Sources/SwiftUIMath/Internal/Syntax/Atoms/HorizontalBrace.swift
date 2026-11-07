import Foundation

extension Math {
  final class HorizontalBrace: Atom {
    var innerList: AtomList?
    let isOver: Bool

    init(isOver: Bool = false, innerList: AtomList? = nil) {
      self.isOver = isOver
      self.innerList = innerList
      super.init(type: .horizontalBrace)
    }

    init(_ other: HorizontalBrace) {
      isOver = other.isOver
      innerList = other.innerList.map { AtomList($0) }
      super.init(other)
    }

    override var finalized: Atom {
      let result = super.finalized
      if let brace = result as? HorizontalBrace {
        brace.innerList = brace.innerList?.finalized
      }
      return result
    }
  }
}
