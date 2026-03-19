import Fluent

struct CreateOffer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("offers")
            .id()
            .field("amount", .double, .required)
            .field("status", .string, .required)
            .field("listing_id", .uuid, .required, .references("listings", "id", onDelete: .cascade))
            .field("buyer_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("offers").delete()
    }
}
