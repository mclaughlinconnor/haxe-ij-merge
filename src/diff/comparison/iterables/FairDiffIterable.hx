// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

/**
 * Marker interface indicating that elements are compared one-by-one.
 * <p>
 * If range [a, b) is equal to [a', b'), than element(a + i) is equal to element(a' + i) for all i in [0, b-a)
 * Therefore, {@link #unchanged} ranges are guaranteed to have {@link DiffIterableUtil#getRangeDelta(Range)} equal to 0.
 *
 * @see DiffIterableUtil#fair(DiffIterable)
 * @see DiffIterableUtil#verifyFair(DiffIterable)
 */
abstract class FairDiffIterable extends DiffIterable {}
