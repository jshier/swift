//===--- SILOptions.h - Swift Language SILGen and SIL options ---*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file defines the options which control the generation, processing,
// and optimization of SIL.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_AST_SILOPTIONS_H
#define SWIFT_AST_SILOPTIONS_H

#include <string>

namespace swift {

class SILOptions {
public:
  /// Controls the aggressiveness of the performance inliner.
  unsigned InlineThreshold = 50;

  enum LinkingMode {
    /// Skip SIL linking.
    LinkNone,

    /// Perform normal SIL linking.
    LinkNormal,

    /// Link all functions during SIL linking.
    LinkAll
  };

  /// Controls how  perform SIL linking.
  LinkingMode LinkMode = LinkNormal;
};

} // end namespace swift

#endif
