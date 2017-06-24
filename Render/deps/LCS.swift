//  Originally created by Jack Flintermann on 3/14/15.
//  Forked from github.com/jflinter/Dwifft
//  Copyright (c) 2015 jflinter. All rights reserved.

import Foundation

public struct Diff<Type> {
  public let results: [DiffStep<Type>]
  public var insertions: [DiffStep<Type>] {
    return results.filter({ $0.isInsertion }).sorted { $0.idx < $1.idx }
  }
  public var deletions: [DiffStep<Type>] {
    return results.filter({ !$0.isInsertion }).sorted { $0.idx > $1.idx }
  }
  public func reversed() -> Diff<Type> {
    let reversedResults = self.results.reversed().map {
      (result: DiffStep<Type>) -> DiffStep<Type> in
      switch result {
      case .insert(let i, let j): return .delete(i, j)
      case .delete(let i, let j): return .insert(i, j)
      }
    }
    return Diff<Type>(results: reversedResults)
  }
}
public func +<Type> (left: Diff<Type>, right: DiffStep<Type>) -> Diff<Type> {
  return Diff<Type>(results: left.results + [right])
}

/// These get returned from calls to Array.diff().
/// They represent insertions or deletions that need to happen to transform array A
/// into array A.
public enum DiffStep<Type>  {
  case insert(Int, Type)
  case delete(Int, Type)
  var isInsertion: Bool {
    switch(self) {
    case .insert: return true
    case .delete: return false
    }
  }
  public var idx: Int {
    switch(self) {
    case .insert(let i, _): return i
    case .delete(let i, _): return i
    }
  }
  public var value: Type {
    switch(self) {
    case .insert(let j): return j.1
    case .delete(let j): return j.1
    }
  }
}

private struct MemoizedSequenceComparison<Type: Equatable> {
  fileprivate static func buildTable(_ x: [Type], _ y: [Type], _ n: Int, _ m: Int) -> [[Int]] {
    var table = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
    for i in 0...n {
      for j in 0...m {
        if (i == 0 || j == 0) {
          table[i][j] = 0
        }
        else if x[i-1] == y[j-1] {
          table[i][j] = table[i-1][j-1] + 1
        } else {
          table[i][j] = max(table[i-1][j], table[i][j-1])
        }
      }
    }
    return table
  }
}

public extension Array where Element: Equatable {

  /// Returns the sequence of ArrayDiffResults required to transform one array into another.
  public func diff(_ other: [Element]) -> Diff<Element> {
    let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
    return Array.diffFromIndices(table, self, other, self.count, other.count)
  }

  /// Walks back through the generated table to generate the diff.
  fileprivate static func diffFromIndices(
    _ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {

    if i == 0 && j == 0 {
      return Diff<Element>(results: [])
    } else if i == 0 {
      return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
    } else if j == 0 {
      return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
    } else if table[i][j] == table[i][j-1] {
      return diffFromIndices(table, x, y, i, j-1) + DiffStep.insert(j-1, y[j-1])
    } else if table[i][j] == table[i-1][j] {
      return diffFromIndices(table, x, y, i - 1, j) + DiffStep.delete(i-1, x[i-1])
    } else {
      return diffFromIndices(table, x, y, i-1, j-1)
    }
  }

  /// Applies a generated diff to an array.
  /// Invariant: given x: [T], y: [T], x.apply(x.diff(y)) == y
  fileprivate func apply(_ diff: Diff<Element>) -> Array<Element> {
    var copy = self
    for result in diff.deletions {
      copy.remove(at: result.idx)
    }
    for result in diff.insertions {
      copy.insert(result.value, at: result.idx)
    }
    return copy
  }
}

public extension Array where Element: Equatable {

  /// Returns the longest common subsequence between two arrays.
  public func LCS(_ other: [Element]) -> [Element] {
    let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
    return Array.lcsFromIndices(table, self, other, self.count, other.count)
  }

  // Walks back through the generated table to generate the LCS.
  fileprivate static func lcsFromIndices(
    _ table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
    if i == 0 && j == 0 {
      return []
    } else if i == 0 {
      return lcsFromIndices(table, x, y, i, j - 1)
    } else if j == 0 {
      return lcsFromIndices(table, x, y, i - 1, j)
    } else if x[i-1] == y[j-1] {
      return lcsFromIndices(table, x, y, i - 1, j - 1) + [x[i - 1]]
    } else if table[i-1][j] > table[i][j-1] {
      return lcsFromIndices(table, x, y, i - 1, j)
    } else {
      return lcsFromIndices(table, x, y, i, j - 1)
    }
  }
}

