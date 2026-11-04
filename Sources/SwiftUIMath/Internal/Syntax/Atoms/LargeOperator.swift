import Foundation

extension Math {
  final class LargeOperator: Atom {
    var limits: Bool
    var isTextOperator = false

    init(_ largeOperator: LargeOperator) {
      self.limits = largeOperator.limits
      self.isTextOperator = largeOperator.isTextOperator
      super.init(largeOperator)
    }

    init(limits: Bool = false) {
      self.limits = limits
      super.init(type: .largeOperator)
    }
  }
}
