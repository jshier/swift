// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -enable-experimental-feature Lifetimes -parse-as-library \
// RUN:   -module-name Other -emit-module-path %t/Other.swiftmodule %S/Inputs/nonescapable_trivial_destroy_other.swift

// RUN: %target-swift-frontend -emit-ir -O -enable-experimental-feature Lifetimes -I %t %s | %FileCheck %s
// RUN: %target-swift-frontend -emit-ir -Onone -enable-experimental-feature Lifetimes -I %t %s | %FileCheck %s

// One module: the initializer is kept out of line.
// RUN: %target-swift-frontend -emit-ir -O -enable-experimental-feature Lifetimes -module-name Other \
// RUN:   -parse-as-library -D SAME_MODULE %S/Inputs/nonescapable_trivial_destroy_other.swift %s | %FileCheck %s

// REQUIRES: swift_feature_Lifetimes

// A non-Escapable struct whose fields are all trivial is non-trivial in SIL only so that OSSA tracks its lifetime.
// Destroying it does nothing, so IRGen must not call an outlined destroy (mangled with the `WOh` suffix) or its value
// witness `destroy`.

#if !SAME_MODULE
import Other
#endif

@inline(never)
func use(_ value: Int) { blackHole = blackHole &+ value }

nonisolated(unsafe) var blackHole = 0

// CHECK-LABEL: define {{.*}}@"$s{{[0-9a-zA-Z_]+}}11dropTrivialyySiF"(
// CHECK-NOT:     WOh"
// CHECK-NOT:     call void %Destroy
// CHECK:       {{^}}}
public func dropTrivial(_ x: Int) {
  let value = NonEscapableInts(x)
  use(value.h)
}

// CHECK-LABEL: define {{.*}}@"$s{{[0-9a-zA-Z_]+}}17dropWithReferenceyySi_yXltF"(
// CHECK:         call {{.*}}{{WOh"|swift_unknownObjectRelease}}
// CHECK:       {{^}}}
public func dropWithReference(_ x: Int, _ object: AnyObject) {
  let value = NonEscapableWithReference(x, object)
  use(value.g)
}
