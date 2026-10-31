// REQUIRES: swift_swift_parser

// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: %swift-build-c-plugin -o %t/plugin-a %t/plugin-a.c
// RUN: %swift-build-c-plugin -o %t/plugin-b %t/plugin-b.c

// The first invocation sends every expansion request to the plugin.
// RUN: env SWIFT_DUMP_PLUGIN_MESSAGING=1 not %target-swift-frontend -typecheck -swift-version 5 \
// RUN:   -load-plugin-executable %t/plugin-a#TestPlugin -macro-expansion-cache-path %t/cache \
// RUN:   -module-name MyApp %t/test.swift > %t/first.txt 2>&1
// RUN: %FileCheck --check-prefixes=EXPANDED,FAILED,DIAGS-A %s < %t/first.txt

// The next one reuses the successful expansion, including its warning, but expands the failed one again.
// RUN: env SWIFT_DUMP_PLUGIN_MESSAGING=1 not %target-swift-frontend -typecheck -swift-version 5 \
// RUN:   -load-plugin-executable %t/plugin-a#TestPlugin -macro-expansion-cache-path %t/cache \
// RUN:   -module-name MyApp %t/test.swift > %t/second.txt 2>&1
// RUN: %FileCheck --check-prefixes=CACHED,FAILED,DIAGS-A %s < %t/second.txt

// A different plugin doesn't use the expansions of the first one.
// RUN: env SWIFT_DUMP_PLUGIN_MESSAGING=1 not %target-swift-frontend -typecheck -swift-version 5 \
// RUN:   -load-plugin-executable %t/plugin-b#TestPlugin -macro-expansion-cache-path %t/cache \
// RUN:   -module-name MyApp %t/test.swift > %t/other-plugin.txt 2>&1
// RUN: %FileCheck --check-prefixes=EXPANDED,FAILED,DIAGS-B %s < %t/other-plugin.txt

// RUN: env SWIFT_DUMP_PLUGIN_MESSAGING=1 not %target-swift-frontend -typecheck -swift-version 5 \
// RUN:   -load-plugin-executable %t/plugin-a#TestPlugin -macro-expansion-cache-path %t/cache \
// RUN:   -module-name MyApp %t/test.swift > %t/first-plugin-again.txt 2>&1
// RUN: %FileCheck --check-prefixes=CACHED,FAILED,DIAGS-A %s < %t/first-plugin-again.txt

// Without the option, nothing is cached.
// RUN: env SWIFT_DUMP_PLUGIN_MESSAGING=1 not %target-swift-frontend -typecheck -swift-version 5 \
// RUN:   -load-plugin-executable %t/plugin-a#TestPlugin \
// RUN:   -module-name MyApp %t/test.swift > %t/no-cache.txt 2>&1
// RUN: %FileCheck --check-prefixes=EXPANDED,FAILED,DIAGS-A %s < %t/no-cache.txt

// EXPANDED: ->(plugin:{{[0-9]+}}) {"expandFreestandingMacro":{{.*}}"typeName":"TestStringMacro"
// CACHED-NOT: "typeName":"TestStringMacro"
// FAILED: ->(plugin:{{[0-9]+}}) {"expandFreestandingMacro":{{.*}}"typeName":"TestStringWithErrorMacro"

// DIAGS-A-DAG: test.swift:5:19: warning: warning from plugin A
// DIAGS-B-DAG: test.swift:5:19: warning: warning from plugin B
// DIAGS-A-DAG: test.swift:6:19: error: error from plugin
// DIAGS-B-DAG: test.swift:6:19: error: error from plugin

//--- test.swift
@freestanding(expression) macro testString(_: Any) -> String = #externalMacro(module: "TestPlugin", type: "TestStringMacro")
@freestanding(expression) macro testStringWithError(_: Any) -> String = #externalMacro(module: "TestPlugin", type: "TestStringWithErrorMacro")

func test() {
  let _: String = #testString(123)
  let _: String = #testStringWithError(321)
}

//--- plugin-a.c
#include "swift-c/MockPlugin/MockPlugin.h"

MOCK_PLUGIN([
  {
    "expect": {"getCapability": {}},
    "response": {"getCapabilityResult": {"capability": {"protocolVersion": 1}}}
  },
  {
    "expect": {"expandFreestandingMacro": {
                "macro": {"moduleName": "TestPlugin", "typeName": "TestStringMacro"}}},
    "response": {"expandFreestandingMacroResult": {
                   "expandedSource": "\"a\"",
                   "diagnostics": [
                     {"severity": "warning",
                      "position": {"offset": "=req.expandFreestandingMacro.syntax.location.offset",
                                   "fileName": "=req.expandFreestandingMacro.syntax.location.fileName"},
                      "message": "warning from plugin A",
                      "highlights": [], "notes": [], "fixIts": []}
                   ]}}
  },
  {
    "expect": {"expandFreestandingMacro": {
                "macro": {"moduleName": "TestPlugin", "typeName": "TestStringWithErrorMacro"}}},
    "response": {"expandFreestandingMacroResult": {
                   "expandedSource": "\"error\"",
                   "diagnostics": [
                     {"severity": "error",
                      "position": {"offset": "=req.expandFreestandingMacro.syntax.location.offset",
                                   "fileName": "=req.expandFreestandingMacro.syntax.location.fileName"},
                      "message": "error from plugin",
                      "highlights": [], "notes": [], "fixIts": []}
                   ]}}
  }
])

//--- plugin-b.c
#include "swift-c/MockPlugin/MockPlugin.h"

MOCK_PLUGIN([
  {
    "expect": {"getCapability": {}},
    "response": {"getCapabilityResult": {"capability": {"protocolVersion": 1}}}
  },
  {
    "expect": {"expandFreestandingMacro": {
                "macro": {"moduleName": "TestPlugin", "typeName": "TestStringMacro"}}},
    "response": {"expandFreestandingMacroResult": {
                   "expandedSource": "\"b\"",
                   "diagnostics": [
                     {"severity": "warning",
                      "position": {"offset": "=req.expandFreestandingMacro.syntax.location.offset",
                                   "fileName": "=req.expandFreestandingMacro.syntax.location.fileName"},
                      "message": "warning from plugin B",
                      "highlights": [], "notes": [], "fixIts": []}
                   ]}}
  },
  {
    "expect": {"expandFreestandingMacro": {
                "macro": {"moduleName": "TestPlugin", "typeName": "TestStringWithErrorMacro"}}},
    "response": {"expandFreestandingMacroResult": {
                   "expandedSource": "\"error\"",
                   "diagnostics": [
                     {"severity": "error",
                      "position": {"offset": "=req.expandFreestandingMacro.syntax.location.offset",
                                   "fileName": "=req.expandFreestandingMacro.syntax.location.fileName"},
                      "message": "error from plugin",
                      "highlights": [], "notes": [], "fixIts": []}
                   ]}}
  }
])
