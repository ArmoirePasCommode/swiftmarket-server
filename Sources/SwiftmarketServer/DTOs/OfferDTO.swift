import Vapor

struct CreateOfferRequest: Content {
    var amount: Double
    var buyerID: UUID
}

struct OfferResponse: Content {
    var id: UUID
    var amount: Double
    var status: String
    var listingID: UUID
    var buyerID: UUID
    var buyer: UserResponse
    var listing: ListingResponse

    init(offer: Offer) throws {
        self.id = try offer.requireID()
        self.amount = offer.amount
        self.status = offer.status
        self.listingID = offer.$listing.id
        self.buyerID = offer.$buyer.id
        self.buyer = try UserResponse(user: offer.buyer)
        self.listing = try ListingResponse(listing: offer.listing)
    }
}
