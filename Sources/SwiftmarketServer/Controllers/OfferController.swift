import Fluent
import Vapor

struct OfferController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        // POST /listings/:id/offers
        // GET  /listings/:id/offers
        let listings = routes.grouped("listings")
        listings.group(":id") { listing in
            listing.post("offers", use: createOffer)
            listing.get("offers", use: listOffers)
        }

        // PUT /offers/:id/accept
        // PUT /offers/:id/reject
        let offers = routes.grouped("offers")
        offers.group(":offerID") { offer in
            offer.put("accept", use: acceptOffer)
            offer.put("reject", use: rejectOffer)
        }
    }

    @Sendable
    func createOffer(req: Request) async throws -> Response {
        guard let listingID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let body = try req.content.decode(CreateOfferRequest.self)

        guard let listing = try await Listing.query(on: req.db)
            .filter(\.$id == listingID)
            .with(\.$seller)
            .first() else {
            throw Abort(.notFound, reason: "Listing not found")
        }

        // Cannot make offer on own listing
        if listing.$seller.id == body.buyerID {
            throw Abort(.badRequest, reason: "You cannot make an offer on your own listing.")
        }

        guard let _ = try await User.find(body.buyerID, on: req.db) else {
            throw Abort(.notFound, reason: "Buyer not found")
        }

        let offer = Offer(amount: body.amount, listingID: listingID, buyerID: body.buyerID)
        try await offer.save(on: req.db)

        try await offer.$buyer.load(on: req.db)
        try await offer.$listing.load(on: req.db)

        let response = try OfferResponse(offer: offer)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func listOffers(req: Request) async throws -> [OfferResponse] {
        guard let listingID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let offers = try await Offer.query(on: req.db)
            .filter(\.$listing.$id == listingID)
            .with(\.$buyer)
            .with(\.$listing, { $0.with(\.$seller) })
            .all()

        return try offers.map { try OfferResponse(offer: $0) }
    }

    @Sendable
    func acceptOffer(req: Request) async throws -> OfferResponse {
        guard let offerID = req.parameters.get("offerID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let offer = try await Offer.query(on: req.db)
            .filter(\.$id == offerID)
            .with(\.$buyer)
            .with(\.$listing, { $0.with(\.$seller) })
            .first() else {
            throw Abort(.notFound, reason: "Offer not found")
        }

        offer.status = "accepted"
        try await offer.save(on: req.db)

        // Reject all other offers on the same listing
        let others = try await Offer.query(on: req.db)
            .filter(\.$listing.$id == offer.$listing.id)
            .filter(\.$id != offerID)
            .all()
        for other in others {
            other.status = "rejected"
            try await other.save(on: req.db)
        }

        return try OfferResponse(offer: offer)
    }

    @Sendable
    func rejectOffer(req: Request) async throws -> OfferResponse {
        guard let offerID = req.parameters.get("offerID", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard let offer = try await Offer.query(on: req.db)
            .filter(\.$id == offerID)
            .with(\.$buyer)
            .with(\.$listing, { $0.with(\.$seller) })
            .first() else {
            throw Abort(.notFound, reason: "Offer not found")
        }

        offer.status = "rejected"
        try await offer.save(on: req.db)

        return try OfferResponse(offer: offer)
    }
}
