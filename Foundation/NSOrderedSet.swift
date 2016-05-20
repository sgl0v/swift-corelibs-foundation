// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/****************       Immutable Ordered Set   ****************/
public class NSOrderedSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, ArrayLiteralConvertible {
    internal var _storage: NSMutableSet
    internal var _orderedStorage: NSMutableArray

    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSOrderedSet.self {
            // return self for immutable type
            return self
        } else if self.dynamicType === NSMutableOrderedSet.self {
            let orderedSet = NSOrderedSet()
            orderedSet._storage = self._storage
            orderedSet._orderedStorage = self._orderedStorage
            return orderedSet
        }
        return NSOrderedSet(array: self.array)
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }

    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSOrderedSet.self || self.dynamicType === NSMutableOrderedSet.self {
            // always create and return an NSMutableOrderedSet
            let mutableOrderedSet = NSMutableOrderedSet()
            mutableOrderedSet._storage = self._storage
            mutableOrderedSet._orderedStorage = self._orderedStorage
            return mutableOrderedSet
        }
        let mutableOrderedSet = NSMutableOrderedSet()
        mutableOrderedSet.addObjectsFromArray(self._orderedStorage.bridge())
        return mutableOrderedSet
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let orderedSet = object as? NSOrderedSet {
            return isEqualToOrderedSet(orderedSet)
        } else {
            return false
        }
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            for idx in 0..<self.count {
                aCoder.encodeObject(self.objectAtIndex(idx), forKey:"NS.object.\(idx)")
            }
        } else {
            NSUnimplemented()
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            var idx = 0
            var objects : [AnyObject] = []
            while aDecoder.containsValueForKey(("NS.object.\(idx)")) {
                guard let object = aDecoder.decodeObjectForKey("NS.object.\(idx)") else {
                    return nil
                }
                objects.append(object)
                idx += 1
            }
            self.init(array: objects)
        } else {
            NSUnimplemented()
        }
    }
    
    public var count: Int {
        return _storage.count
    }

    public func objectAtIndex(_ idx: Int) -> AnyObject {
        return _orderedStorage.objectAtIndex(idx)
    }

    public func indexOfObject(_ object: AnyObject) -> Int {
        guard let object = object as? NSObject else {
            return NSNotFound
        }

        return _orderedStorage.indexOfObject(object)
    }

    public convenience override init() {
        self.init(objects: [], count: 0)
    }

    public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _storage = NSMutableSet(objects: objects, count: cnt)
        _orderedStorage = NSMutableArray()
        let buffer = NSArray(objects: objects, count: cnt)
        for obj in buffer {
            if _orderedStorage.indexOfObject(obj) == NSNotFound {
                _orderedStorage.addObject(obj)
            }
        }

        super.init()
    }
    
    required public convenience init(arrayLiteral elements: AnyObject...) {
      self.init(array: elements)
    }

    public convenience init(objects elements: AnyObject...) {
      self.init(array: elements)
    }
    
    public subscript (idx: Int) -> AnyObject {
        return objectAtIndex(idx)
    }

}

extension NSOrderedSet : Sequence {
    /// Return a *generator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public typealias Iterator = NSEnumerator.Iterator
    public func makeIterator() -> Iterator {
        return self.objectEnumerator().makeIterator()
    }
}

extension NSOrderedSet {

    public func getObjects(_ objects: inout [AnyObject], range: NSRange) {
        for idx in range.location..<(range.location + range.length) {
            objects.append(_orderedStorage[idx])
        }
    }

    public func objectsAtIndexes(_ indexes: NSIndexSet) -> [AnyObject] {
        var entries = [AnyObject]()
        for idx in indexes {
            if idx >= count && idx < 0 {
                fatalError("\(self): Index out of bounds")
            }
            entries.append(objectAtIndex(idx))
        }
        return entries
    }

    public var firstObject: AnyObject? {
        return _orderedStorage.firstObject
    }

    public var lastObject: AnyObject? {
        return _orderedStorage.lastObject
    }

    public func isEqualToOrderedSet(_ otherOrderedSet: NSOrderedSet) -> Bool {
        if count != otherOrderedSet.count {
            return false
        }
        
        for idx in 0..<count {
            let obj1 = objectAtIndex(idx) as! NSObject
            let obj2 = otherOrderedSet.objectAtIndex(idx) as! NSObject
            if obj1 === obj2 {
                continue
            }
            if !obj1.isEqual(obj2) {
                return false
            }
        }
        
        return true
    }

    public func containsObject(_ object: AnyObject) -> Bool {
        if let object = object as? NSObject {
            return _storage.containsObject(object)
        }
        return false
    }

    public func intersectsOrderedSet(_ other: NSOrderedSet) -> Bool {
        if count < other.count {
            return contains { obj in other.containsObject(obj as! NSObject) }
        } else {
            return other.contains { obj in containsObject(obj) }
        }
    }

    public func intersectsSet(_ set: Set<NSObject>) -> Bool {
        if count < set.count {
            return contains { obj in set.contains(obj as! NSObject) }
        } else {
            return set.contains { obj in containsObject(obj) }
        }
    }
    
    public func isSubsetOfOrderedSet(_ other: NSOrderedSet) -> Bool {
        return !self.contains { obj in
            !other.containsObject(obj as! NSObject)
        }
    }

    public func isSubsetOfSet(_ set: Set<NSObject>) -> Bool {
        return !self.contains { obj in
            !set.contains(obj as! NSObject)
        }
    }
    
    public func objectEnumerator() -> NSEnumerator {
        if self.dynamicType === NSOrderedSet.self || self.dynamicType === NSMutableOrderedSet.self {
            return NSGeneratorEnumerator(_orderedStorage.makeIterator())
        } else {
            NSRequiresConcreteImplementation()
        }
    }

    public func reverseObjectEnumerator() -> NSEnumerator {
        if self.dynamicType === NSOrderedSet.self || self.dynamicType === NSMutableOrderedSet.self {
            return _orderedStorage.reverseObjectEnumerator()
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    /*@NSCopying*/
    public var reversedOrderedSet: NSOrderedSet { return NSOrderedSet(array: _orderedStorage.reversed()) }
    
    // These two methods return a facade object for the receiving ordered set,
    // which acts like an immutable array or set (respectively).  Note that
    // while you cannot mutate the ordered set through these facades, mutations
    // to the original ordered set will "show through" the facade and it will
    // appear to change spontaneously, since a copy of the ordered set is not
    // being made.
    public var array: [AnyObject] { return _orderedStorage.bridge() }
    public var set: Set<NSObject> { return _storage.bridge() }

    public func enumerateObjectsUsingBlock(_ block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        _orderedStorage.enumerateObjectsUsingBlock(block)
    }

    public func enumerateObjectsWithOptions(_ opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        _orderedStorage.enumerateObjectsWithOptions(opts, usingBlock: block)
    }

    public func enumerateObjectsAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {
        _orderedStorage.enumerateObjectsAtIndexes(s, options: opts, usingBlock: block)
    }
    
    public func indexOfObjectPassingTest(_ predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObjectPassingTest(predicate)
    }

    public func indexOfObjectWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObjectWithOptions(opts, passingTest: predicate)
    }

    public func indexOfObjectAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObjectAtIndexes(s, options: opts, passingTest: predicate)
    }
    
    public func indexesOfObjectsPassingTest(_ predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return _orderedStorage.indexesOfObjectsPassingTest(predicate)
    }

    public func indexesOfObjectsWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return _orderedStorage.indexesOfObjectsWithOptions(opts, passingTest: predicate)
    }

    public func indexesOfObjectsAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet {
        return _orderedStorage.indexesOfObjectsAtIndexes(s, options: opts, passingTest: predicate)
    }
    
    public func indexOfObject(_ object: AnyObject, inSortedRange range: NSRange, options opts: NSBinarySearchingOptions, usingComparator cmp: NSComparator) -> Int {
        return _orderedStorage.indexOfObject(object, inSortedRange: range, options: opts, usingComparator: cmp)
    }
    
    public func sortedArrayUsingComparator(_ cmptr: NSComparator) -> [AnyObject] {
        return _orderedStorage.sortedArrayUsingComparator(cmptr)
    }

    public func sortedArrayWithOptions(_ opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        return _orderedStorage.sortedArrayWithOptions(opts, usingComparator: cmptr)
    }
    
    public func descriptionWithLocale(_ locale: AnyObject?) -> String { NSUnimplemented() }
    public func descriptionWithLocale(_ locale: AnyObject?, indent level: Int) -> String { NSUnimplemented() }
}

extension NSOrderedSet {
    
    public convenience init(object: AnyObject) {
        self.init(array: [object])
    }
    
    public convenience init(orderedSet set: NSOrderedSet) {
        self.init(orderedSet: set, copyItems: false)
    }

    public convenience init(orderedSet set: NSOrderedSet, copyItems flag: Bool) {
        self.init(orderedSet: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(orderedSet set: NSOrderedSet, range: NSRange, copyItems flag: Bool) {
        self.init(array: set.array, range: range, copyItems: flag)
    }

    public convenience init(array: [AnyObject]) {
        self.init(array: array, copyItems: false)
    }

    public convenience init(array set: [AnyObject], copyItems flag: Bool) {
        self.init(array: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(array set: [AnyObject], range: NSRange, copyItems flag: Bool) {
        let filteredArray = set.bridge().subarrayWithRange(range)
        let optionalArray : [AnyObject?] = flag ?
                filteredArray.map { return Optional<AnyObject>(($0 as! NSObject).copy()) } :
                filteredArray.map { return Optional<AnyObject>($0) }

        let cnt = range.length

        let buffer = UnsafeMutablePointer<AnyObject?>(allocatingCapacity: cnt)
        buffer.initializeFrom(optionalArray)
        self.init(objects: buffer, count: cnt)
        buffer.deinitialize(count: array.count)
        buffer.deallocateCapacity(array.count)
    }

    public convenience init(set: Set<NSObject>) {
        self.init(set: set, copyItems: false)
    }

    public convenience init(set: Set<NSObject>, copyItems flag: Bool) {
        self.init(array: set.map { $0 as AnyObject }, copyItems: flag)
    }
}


/****************       Mutable Ordered Set     ****************/

public class NSMutableOrderedSet : NSOrderedSet {
    
    public func insertObject(_ object: AnyObject, atIndex idx: Int) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        if containsObject(object) {
            return
        }

        if let object = object as? NSObject {
            _storage.addObject(object)
            _orderedStorage.insertObject(object, atIndex: idx)
        }
    }

    public func removeObjectAtIndex(_ idx: Int) {
        _storage.removeObject(_orderedStorage[idx])
        _orderedStorage.removeObjectAtIndex(idx)
    }

    public func replaceObjectAtIndex(_ idx: Int, withObject object: AnyObject) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        let objectToReplace = _orderedStorage.objectAtIndex(idx)
        _orderedStorage.replaceObjectAtIndex(idx, withObject: object)
        _storage.removeObject(objectToReplace)
        _storage.addObject(object)
    }

    public init(capacity numItems: Int) {
        super.init(objects: [], count: 0)
    }

    required public convenience init(arrayLiteral elements: AnyObject...) {
        self.init(capacity: 0)

        addObjectsFromArray(elements)
    }

    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }

}

extension NSMutableOrderedSet {

    public func addObject(_ object: AnyObject) {
        _storage.addObject(object)
        _orderedStorage.addObject(object)
    }

    public func addObjects(_ objects: UnsafePointer<AnyObject?>, count: Int) {
        let inputArray = NSArray(objects: objects, count: count).bridge()
        _storage.addObjectsFromArray(inputArray)
        _orderedStorage.addObjectsFromArray(inputArray)
    }

    public func addObjectsFromArray(_ array: [AnyObject]) {
        _storage.addObjectsFromArray(array)
        _orderedStorage.addObjectsFromArray(array)
    }
    
    public func exchangeObjectAtIndex(_ idx1: Int, withObjectAtIndex idx2: Int) {
        _orderedStorage.exchangeObjectAtIndex(idx1, withObjectAtIndex: idx2)
    }

    public func moveObjectsAtIndexes(_ indexes: NSIndexSet, toIndex idx: Int) {
        var removedObjects = [NSObject]()
        for index in indexes.lazy.reversed() {
            if let object = objectAtIndex(index) as? NSObject {
                removedObjects.append(object)
                removeObjectAtIndex(index)
            }
        }
        for removedObject in removedObjects {
            insertObject(removedObject, atIndex: idx)
        }
    }

    public func insertObjects(_ objects: [AnyObject], atIndexes indexes: NSIndexSet) {
        _storage.addObjectsFromArray(objects)
        _orderedStorage.insertObjects(objects, atIndexes: indexes)
    }
    
    public func setObject(_ obj: AnyObject, atIndex idx: Int) {
        if let object = obj as? NSObject {
            _storage.addObject(obj)
            if idx == _orderedStorage.count {
                _orderedStorage.addObject(object)
            } else {
                _orderedStorage[idx] = object
            }
        }
    }
    
    public func replaceObjectsInRange(_ range: NSRange, withObjects objects: UnsafePointer<AnyObject?>, count: Int) {
        if let range = range.toRange() {
            let buffer = UnsafeBufferPointer(start: objects, count: count)
            for (indexLocation, index) in range.indices.lazy.reversed().enumerated() {
                if let object = buffer[indexLocation] as? NSObject {
                    replaceObjectAtIndex(index, withObject: object)
                }
            }
        }
    }

    public func replaceObjectsAtIndexes(_ indexes: NSIndexSet, withObjects objects: [AnyObject]) {
        for (indexLocation, index) in indexes.enumerated() {
            if let object = objects[indexLocation] as? NSObject {
                replaceObjectAtIndex(index, withObject: object)
            }
        }
    }
    
    public func removeObjectsInRange(_ range: NSRange) {
        if let range = range.toRange() {
            for index in range.indices.lazy.reversed() {
                removeObjectAtIndex(index)
            }
        }
    }

    public func removeObjectsAtIndexes(_ indexes: NSIndexSet) {
        for index in indexes.lazy.reversed() {
            removeObjectAtIndex(index)
        }
    }

    public func removeAllObjects() {
        _storage.removeAllObjects()
        _orderedStorage.removeAllObjects()
    }

    public func removeObject(_ object: AnyObject) {
        if let object = object as? NSObject {
            _storage.removeObject(object)
            _orderedStorage.removeObject(object)
        }
    }

    public func removeObjectsInArray(_ array: [AnyObject]) {
        array.forEach(removeObject)
    }

    public func intersectOrderedSet(_ other: NSOrderedSet) {
        intersectSet(other.set)
    }

    public func minusOrderedSet(_ other: NSOrderedSet) {
        _storage.minusSet(other.set)
        _orderedStorage.removeObjectsInArray(other.array)
    }

    public func unionOrderedSet(_ other: NSOrderedSet) {
        _storage.unionSet(other.set)
        let objectsToAdd = other.filter({ return _orderedStorage.indexOfObject($0) == NSNotFound })
        _orderedStorage.addObjectsFromArray(objectsToAdd)
    }
    
    public func intersectSet(_ other: Set<NSObject>) {
        let objectsToRemove = self.array.filter({ return !other.contains($0 as! NSObject)})
        _storage.intersectSet(other)
        _orderedStorage.removeObjectsInArray(objectsToRemove)
    }

    public func minusSet(_ other: Set<NSObject>) {
        _storage.minusSet(other)
        _orderedStorage.removeObjectsInArray(other.bridge().allObjects)
    }

    public func unionSet(_ other: Set<NSObject>) {
        other.forEach(addObject)
    }
    
    public func sortUsingComparator(_ cmptr: NSComparator) {
        sortRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    public func sortWithOptions(_ opts: NSSortOptions, usingComparator cmptr: NSComparator) {
        sortRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    public func sortRange(_ range: NSRange, options opts: NSSortOptions, usingComparator cmptr: NSComparator) {
        let indexSet = NSIndexSet(indexesInRange: range)
        let objectToSort = _orderedStorage.objectsAtIndexes(indexSet).bridge()
        let sortedObjects = objectToSort.sortedArrayWithOptions(opts, usingComparator: cmptr)
        _orderedStorage.replaceObjectsAtIndexes(indexSet, withObjects: sortedObjects)
    }
}
