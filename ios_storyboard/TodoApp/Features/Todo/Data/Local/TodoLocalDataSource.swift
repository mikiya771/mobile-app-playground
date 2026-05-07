import CoreData

@MainActor
final class TodoLocalDataSource {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.context) {
        self.context = context
    }

    func fetchAll() -> [Todo] {
        let request = TodoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.map { $0.toDomain() }
    }

    func save(_ todo: Todo) {
        let request = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", todo.id)
        if let existing = try? context.fetch(request), let entity = existing.first {
            entity.update(from: todo)
        } else {
            _ = TodoEntity.from(todo, in: context)
        }
        try? context.save()
    }

    func delete(id: String) {
        let request = TodoEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        if let entity = try? context.fetch(request), let first = entity.first {
            context.delete(first)
            try? context.save()
        }
    }
}
