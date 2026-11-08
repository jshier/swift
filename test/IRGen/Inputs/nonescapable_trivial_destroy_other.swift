// A non-Escapable struct of trivial fields, with more leaf fields than the optimizer expands, and an initializer that
// isn't inlinable, so a client gets the value in memory and has to end its lifetime.
public struct NonEscapableInts: ~Escapable {
  public var a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int, h: Int

  @_lifetime(immortal)
  public init(_ x: Int) { a = x; b = x; c = x; d = x; e = x; f = x; g = x; h = x }
}

// The same with a reference: it must still be destroyed.
public struct NonEscapableWithReference: ~Escapable {
  public var a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, g: Int
  public var object: AnyObject

  @_lifetime(immortal)
  public init(_ x: Int, _ object: AnyObject) { a = x; b = x; c = x; d = x; e = x; f = x; g = x; self.object = object }
}
