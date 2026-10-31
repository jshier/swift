// RUN: %empty-directory(%t)

// A build system can pass `-Xcc -fmodules-ignore-search-path=<path>` for per-target search paths (e.g. directories for
// generated headers) so that they don't split Clang module contexts between targets.
// RUN: %target-swift-frontend -scan-dependencies -module-load-mode prefer-interface -module-cache-path %t/module-cache -clang-scanner-module-cache-path %t/scanner-cache %s -o %t/deps1.json -I %S/Inputs/CHeaders -I %S/Inputs/Swift -Xcc -I%t/target1/DerivedSources -Xcc -fmodules-ignore-search-path=%t/target1/DerivedSources
// RUN: %target-swift-frontend -scan-dependencies -module-load-mode prefer-interface -module-cache-path %t/module-cache -clang-scanner-module-cache-path %t/scanner-cache %s -o %t/deps2.json -I %S/Inputs/CHeaders -I %S/Inputs/Swift -Xcc -I%t/target2/DerivedSources -Xcc -fmodules-ignore-search-path=%t/target2/DerivedSources

// The flag refers to a search path, which Swift module dependencies don't get, so it isn't passed to them either,
// and doesn't make their hashes differ.
// RUN: %validate-json %t/deps1.json | %FileCheck %s
// RUN: grep -o 'A-[A-Z0-9]*\.swiftmodule' %t/deps1.json | sort -u > %t/hash1.txt
// RUN: grep -o 'A-[A-Z0-9]*\.swiftmodule' %t/deps2.json | sort -u > %t/hash2.txt
// RUN: diff %t/hash1.txt %t/hash2.txt

// REQUIRES: objc_interop

import C

// CHECK:          "modulePath": "{{.*}}{{/|\\}}A-{{[A-Z0-9]+}}.swiftmodule"
// CHECK:          "commandLine": [
// CHECK-NOT:        "-fmodules-ignore-search-path=
// CHECK-NOT:        DerivedSources
// CHECK:            "-o",
