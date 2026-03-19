import Vapor

struct CreateListingRequest: Content, Validatable {
    var title: String
    var description: String
    var price: Double
    var category: String
    var sellerID: UUID

    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty, customFailureDescription: "title must not be empty")
        validations.add("price", as: Double.self, is: .range(0.01...), customFailureDescription: "price must be greater than 0")
        validations.add("category", as: String.self, is: .in("electronics", "clothing", "furniture", "other"))
    }
}

struct ListingResponse: Content {
    var id: UUID
    var title: String
    var description: String
    var price: Double
    var category: String
    var seller: UserResponse
    var createdAt: Date?

    init(listing: Listing) throws {
        self.id = try listing.requireID()
        self.title = listing.title
        self.description = listing.description
        self.price = listing.price
        self.category = listing.category
        self.seller = try UserResponse(user: listing.seller)
        self.createdAt = listing.createdAt
    }
}

struct PagedListingResponse: Content {
    var items: [ListingResponse]
    var page: Int
    var totalPages: Int
    var totalCount: Int
}
