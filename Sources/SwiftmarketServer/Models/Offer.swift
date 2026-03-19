import Fluent
import Vapor

final class Offer: Model, Content, @unchecked Sendable {
    static let schema = "offers"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "amount")
    var amount: Double

    @Field(key: "status")
    var status: String

    @Parent(key: "listing_id")
    var listing: Listing

    @Parent(key: "buyer_id")
    var buyer: User

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, amount: Double, status: String = "pending", listingID: UUID, buyerID: UUID) {
        self.id = id
        self.amount = amount
        self.status = status
        self.$listing.id = listingID
        self.$buyer.id = buyerID
    }
}
