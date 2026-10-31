// RUN: %empty-directory(%t)
// RUN: split-file %s %t

// RUN: %target-swift-frontend -scan-dependencies -module-name Test -O \
// RUN:   -disable-implicit-string-processing-module-import -disable-implicit-concurrency-module-import -parse-stdlib \
// RUN:   %t/a.swift -o %t/deps.json -cache-compile-job -cas-path %t/cas

// RUN: %{python} %S/Inputs/BuildCommandExtractor.py %t/deps.json Test > %t/MyApp.cmd
// RUN: echo "\"-disable-implicit-string-processing-module-import\"" >> %t/MyApp.cmd
// RUN: echo "\"-disable-implicit-concurrency-module-import\"" >> %t/MyApp.cmd
// RUN: echo "\"-parse-stdlib\"" >> %t/MyApp.cmd

/// Which supplementary outputs are requested changes the key, but their paths don't.
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd > %t/none.casid
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd \
// RUN:   -emit-dependencies-path %t/a.d > %t/deps.casid
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd \
// RUN:   -emit-dependencies-path %t/other.d > %t/deps-other-path.casid
// RUN: not diff %t/none.casid %t/deps.casid
// RUN: diff %t/deps.casid %t/deps-other-path.casid

/// The same applies to outputs requested through a supplementary output file map.
// RUN: sed -e "s|INPUT|%/t/a.swift|" -e "s|OUTPUT|%/t/a.d|" %t/deps-map.yaml.in > %t/deps-map.yaml
// RUN: sed -e "s|INPUT|%/t/a.swift|" -e "s|OUTPUT|%/t/other.d|" %t/deps-map.yaml.in > %t/deps-map-other-path.yaml
// RUN: sed -e "s|INPUT|%/t/a.swift|" %t/empty-map.yaml.in > %t/empty-map.yaml
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd \
// RUN:   -supplementary-output-file-map %t/deps-map.yaml > %t/map-deps.casid
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd \
// RUN:   -supplementary-output-file-map %t/deps-map-other-path.yaml > %t/map-deps-other-path.casid
// RUN: %cache-tool -cas-path %t/cas -cache-tool-action print-base-key -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o @%t/MyApp.cmd \
// RUN:   -supplementary-output-file-map %t/empty-map.yaml > %t/map-none.casid
// RUN: diff %t/map-deps.casid %t/map-deps-other-path.casid
// RUN: diff %t/map-deps.casid %t/deps.casid
// RUN: diff %t/map-none.casid %t/none.casid

/// Compiling without the dependencies file after compiling with it is a cache miss, not a failed replay.
// RUN: %target-swift-frontend-plain -cache-compile-job -Rcache-compile-job -primary-file %t/a.swift -c -o %t/a.o \
// RUN:   -emit-dependencies-path %t/a.d -cas-path %t/cas @%t/MyApp.cmd 2>&1 | %FileCheck --check-prefix=CACHE-MISS %s
// RUN: %target-swift-frontend-plain -cache-compile-job -Rcache-compile-job -primary-file %t/a.swift -c -o %t/a.o \
// RUN:   -cas-path %t/cas @%t/MyApp.cmd 2>&1 | %FileCheck --check-prefix=CACHE-MISS %s

/// Requesting it again, at another path, replays it.
// RUN: %target-swift-frontend-plain -cache-compile-job -Rcache-compile-job -primary-file %t/a.swift -c -o %t/a.o \
// RUN:   -emit-dependencies-path %t/other.d -cas-path %t/cas @%t/MyApp.cmd 2>&1 | %FileCheck --check-prefix=CACHE-HIT %s
// RUN: test -f %t/other.d

/// libSwiftScan reports a replay that can't provide the requested outputs as a failure, so that the client compiles
/// instead. Replay a result that has a dependencies file for a command line that doesn't request one.
// RUN: %swift-scan-test -action compute_cache_key -cas-path %t/cas -input %t/a.swift -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o \
// RUN:   -emit-dependencies-path %t/a.d -cas-path %t/cas @%t/MyApp.cmd > %t/deps-key.casid
// RUN: not %swift-scan-test -action replay_result -cas-path %t/cas -id @%t/deps-key.casid -- \
// RUN:   %target-swift-frontend-plain -cache-compile-job -primary-file %t/a.swift -c -o %t/a.o \
// RUN:   -cas-path %t/cas @%t/MyApp.cmd 2>&1 | %FileCheck --check-prefix=REPLAY-FAILED %s

// REPLAY-FAILED: cache replay failed: failed to load all outputs

// CACHE-MISS-NOT: replay failed
// CACHE-MISS: remark: cache miss for input
// CACHE-MISS-NOT: replay failed
// CACHE-MISS-NOT: cache poisoned

// CACHE-HIT-NOT: replay failed
// CACHE-HIT: remark: replay output file
// CACHE-HIT-NOT: replay failed

//--- a.swift
func testFunc() {}

//--- deps-map.yaml.in
"INPUT":
  dependencies: "OUTPUT"

//--- empty-map.yaml.in
"INPUT":
  object: "unused.o"
