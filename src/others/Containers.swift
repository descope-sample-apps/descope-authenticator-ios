
class WeakCollection<T>: Sequence {
    
    typealias Element = T

    func makeIterator() -> IndexingIterator<[T]> {
        return references.compactMap { $0.element as? T }.makeIterator()
    }

    func add(_ element: AnyObject) {
        references.removeAll { $0.element == nil }
        references.append(WeakReference(to: element))
    }

    func remove(_ element: AnyObject) {
        if let index = references.firstIndex(where: { $0.element === element }) {
            references.remove(at: index)
        }
    }

    // Internal

    private var references: [WeakReference] = []

    private class WeakReference {
        weak var element: AnyObject?

        init(to element: AnyObject) {
            self.element = element
        }
    }
}
