import Fluent

struct CreateListing: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("listings")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("price", .double, .required)
            .field("category", .string, .required)
            .field("seller_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("listings").delete()
    }
}
