//
//  LCS.swift
//  Dwifft
//
//  Created by Jack Flintermann on 3/14/15.
//  github.com/jflinter/Dwifft
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit

public struct Diff<T> {
    public let results: [DiffStep<T>]
    public var insertions: [DiffStep<T>] {
        return results.filter({ $0.isInsertion }).sort { $0.idx < $1.idx }
    }
    public var deletions: [DiffStep<T>] {
        return results.filter({ !$0.isInsertion }).sort { $0.idx > $1.idx }
    }
    public func reversed() -> Diff<T> {
        let reversedResults = self.results.reverse().map { (result: DiffStep<T>) -> DiffStep<T> in
            switch result {
            case .Insert(let i, let j):
                return .Delete(i, j)
            case .Delete(let i, let j):
                return .Insert(i, j)
            }
        }
        return Diff<T>(results: reversedResults)
    }
}

public func +<T> (left: Diff<T>, right: DiffStep<T>) -> Diff<T> {
    return Diff<T>(results: left.results + [right])
}

/// These get returned from calls to Array.diff(). They represent insertions or deletions that need to happen to transform array a into array b.
public enum DiffStep<T> : CustomDebugStringConvertible {
    case Insert(Int, T)
    case Delete(Int, T)
    var isInsertion: Bool {
        switch(self) {
        case .Insert:
            return true
        case .Delete:
            return false
        }
    }
    public var debugDescription: String {
        switch(self) {
        case .Insert(let i, let j):
            return "+\(j)@\(i)"
        case .Delete(let i, let j):
            return "-\(j)@\(i)"
        }
    }
    public var idx: Int {
        switch(self) {
        case .Insert(let i, _):
            return i
        case .Delete(let i, _):
            return i
        }
    }
    public var value: T {
        switch(self) {
        case .Insert(let j):
            return j.1
        case .Delete(let j):
            return j.1
        }
    }
}

public extension Array where Element: Equatable {
    
    /// Returns the sequence of ArrayDiffResults required to transform one array into another.
    public func diff(other: [Element]) -> Diff<Element> {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.diffFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the diff.
    private static func diffFromIndices(table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> Diff<Element> {
        if i == 0 && j == 0 {
            return Diff<Element>(results: [])
        } else if i == 0 {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.Insert(j-1, y[j-1])
        } else if j == 0 {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.Delete(i-1, x[i-1])
        } else if table[i][j] == table[i][j-1] {
            return diffFromIndices(table, x, y, i, j-1) + DiffStep.Insert(j-1, y[j-1])
        } else if table[i][j] == table[i-1][j] {
            return diffFromIndices(table, x, y, i - 1, j) + DiffStep.Delete(i-1, x[i-1])
        } else {
            return diffFromIndices(table, x, y, i-1, j-1)
        }
    }
    
    /// Applies a generated diff to an array. The following should always be true:
    /// Given x: [T], y: [T], x.apply(x.diff(y)) == y
    public func apply(diff: Diff<Element>) -> Array<Element> {
        var copy = self
        for result in diff.deletions {
            copy.removeAtIndex(result.idx)
        }
        for result in diff.insertions {
            copy.insert(result.value, atIndex: result.idx)
        }
        return copy
    }
}

public extension Array where Element: Equatable {
    
    /// Returns the longest common subsequence between two arrays.
    public func LCS(other: [Element]) -> [Element] {
        let table = MemoizedSequenceComparison.buildTable(self, other, self.count, other.count)
        return Array.lcsFromIndices(table, self, other, self.count, other.count)
    }
    
    /// Walks back through the generated table to generate the LCS.
    private static func lcsFromIndices(table: [[Int]], _ x: [Element], _ y: [Element], _ i: Int, _ j: Int) -> [Element] {
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

internal struct MemoizedSequenceComparison<T: Equatable> {
    
    static func buildTable(x: [T], _ y: [T], _ n: Int, _ m: Int) -> [[Int]] {
        var table = Array(count: n + 1, repeatedValue: Array(count: m + 1, repeatedValue: 0))
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

public class TableViewDiffCalculator<T: Equatable> {
    
    public weak var tableView: UITableView?
    
    public init(tableView: UITableView, initialRows: [T] = []) {
        self.tableView = tableView
        self.rows = initialRows
    }
    
    /// Right now this only works on a single section of a tableView.
    /// If your tableView has multiple sections, though, you can just use multiple 
    /// TableViewDiffCalculators, one per section, and set this value appropriately on each one.
    public var sectionIndex: Int = 0
    
    /// You can change insertion/deletion animations like this! Fade works well. So does Top/Bottom. Left/Right/Middle are a little weird, but hey, do your thing.
    public var insertionAnimation = UITableViewRowAnimation.Fade, deletionAnimation = UITableViewRowAnimation.Fade
    
    /// Change this value to trigger animations on the table view.
    public var rows : [T] {
        didSet {
            
            let oldRows = oldValue
            let newRows = self.rows
            let diff = oldRows.diff(newRows)
            if (diff.results.count > 0) {
                tableView?.beginUpdates()
                
                let insertionIndexPaths = diff.insertions.map({ NSIndexPath(forRow: $0.idx, inSection: self.sectionIndex) })
                let deletionIndexPaths = diff.deletions.map({ NSIndexPath(forRow: $0.idx, inSection: self.sectionIndex) })
                
                tableView?.insertRowsAtIndexPaths(insertionIndexPaths, withRowAnimation: insertionAnimation)
                tableView?.deleteRowsAtIndexPaths(deletionIndexPaths, withRowAnimation: deletionAnimation)
                
                tableView?.endUpdates()
            }

        }
    }
}
    
public class CollectionViewDiffCalculator<T: Equatable> {
    
    public weak var collectionView: UICollectionView?
    
    public init(collectionView: UICollectionView, initialRows: [T] = []) {
        self.collectionView = collectionView
        self.rows = initialRows
    }
    
    /// Right now this only works on a single section of a collectionView. 
    /// If your collectionView has multiple sections, though, you can just use multiple 
    /// CollectionViewDiffCalculators, one per section, and set this value appropriately on each one.
    public var sectionIndex: Int = 0
    
    /// Change this value to trigger animations on the collection view.
    public var rows : [T] {
        didSet {
            
            let oldRows = oldValue
            let newRows = self.rows
            
            if newRows.count > 100 {
                self.collectionView?.reloadData()
                return
            }
            
            let diff = oldRows.diff(newRows)
            if (diff.results.count > 0) {
                let insertionIndexPaths = diff.insertions.map({ NSIndexPath(forItem: $0.idx, inSection: self.sectionIndex) })
                let deletionIndexPaths = diff.deletions.map({ NSIndexPath(forItem: $0.idx, inSection: self.sectionIndex) })
                
                collectionView?.performBatchUpdates({ () -> Void in
                    self.collectionView?.insertItemsAtIndexPaths(insertionIndexPaths)
                    self.collectionView?.deleteItemsAtIndexPaths(deletionIndexPaths)
                }, completion: nil)
            }
            
        }
    }
}
