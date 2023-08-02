# Haxe IJ Merge

A Haxe port of IntelliJ's cool diff merging algorithm.

A demo can be found here: [demo](https://mclaughlinconnor.github.io/haxe-ij-merge/)

Haxe can target JavaScript, JVM, C++, and others listed [here](https://haxe.org/documentation/introduction/compiler-targets.html).

Regular merging will merge all non-conflicting changes, in a similar way to how Git's `recursive` or `ort` algorithms work, but working on word level, rather than a hunk level.

Greedy merging assumes that all resolve results are validated by the user, so trades some accuracy for a higher chance of a good resolve.
It works by assuming that `A-X-B` and `B-X-A` conflicts should have equal results, meaning that `insert-insert` conflicts cannot be merged because we don't know the insertion order.
Therefore, merge `delete-insert` by applying both, `delete-delete` by merging deleted intervals, and modifications the same as `delete-insert` changes.

All merges match the original IntelliJ implementation, but greedy merging sometimes produces slightly weird results.
