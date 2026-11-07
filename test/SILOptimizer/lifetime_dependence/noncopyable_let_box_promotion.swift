// RUN: %target-swift-frontend %s -emit-sil -Onone \
// RUN:   -verify \
// RUN:   -sil-verify-all \
// RUN:   -enable-experimental-feature Lifetimes \
// RUN:   -disable-availability-checking \
// RUN:   -module-name test | %FileCheck %s

// RUN: %target-swift-frontend %s -emit-sil -O \
// RUN:   -verify \
// RUN:   -sil-verify-all \
// RUN:   -enable-experimental-feature Lifetimes \
// RUN:   -disable-availability-checking \
// RUN:   -module-name test | %FileCheck %s

// REQUIRES: swift_feature_Lifetimes

// A noncopyable 'let' and a 'consuming' parameter are boxed by SILGen. A lifetime dependence on them is a
// mark_dependence whose base is the box. AllocBoxToStack must still promote the box to the stack, and lifetime
// diagnostics must accept the dependence on the promoted stack location.

public struct Reader: ~Copyable, ~Escapable, Iterable {
  let span: Span<UInt8>

  @_lifetime(copy span)
  public init(_ span: Span<UInt8>) { self.span = span }

  @_lifetime(borrow self)
  public func makeBorrowingIterator() -> Span<UInt8>.BorrowingIterator { .init(span) }

  @_lifetime(borrow self)
  public func view() -> Span<UInt8> { span }
}

// CHECK-LABEL: sil {{.*}}@$s4test9letReaderys5UInt8Vs4SpanVyADGF :
// CHECK-NOT:   alloc_box
// CHECK-LABEL: } // end sil function '$s4test9letReaderys5UInt8Vs4SpanVyADGF'
public func letReader(_ span: Span<UInt8>) -> UInt8 {
  let reader = Reader(span)
  var sum: UInt8 = 0
  for byte in reader { sum &+= byte }
  return sum
}

// CHECK-LABEL: sil {{.*}}@$s4test9letBorrowys5UInt8Vs4SpanVyADGF :
// CHECK-NOT:   alloc_box
// CHECK-LABEL: } // end sil function '$s4test9letBorrowys5UInt8Vs4SpanVyADGF'
public func letBorrow(_ span: Span<UInt8>) -> UInt8 {
  let reader = Reader(span)
  let view = reader.view()
  return view[0]
}

public struct View: ~Escapable {
  let pointer: UnsafeRawPointer?

  @_lifetime(borrow pointer)
  init(_ pointer: UnsafeRawPointer?) { self.pointer = pointer }
}

// CHECK-LABEL: sil {{.*}}@$s4test14consumingParamyAA4ViewVADnF :
// CHECK-NOT:   alloc_box
// CHECK-LABEL: } // end sil function '$s4test14consumingParamyAA4ViewVADnF'
@_lifetime(copy view)
public func consumingParam(_ view: consuming View) -> View {
  _overrideLifetime(View(view.pointer), copying: view)
}
