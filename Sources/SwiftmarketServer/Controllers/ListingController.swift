import Fluent
import Vapor

struct ListingController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let listings = routes.grouped("listings")
        listings.get(use: index)
        listings.post(use: create)
        listings.group(":id") { listing in
            listing.get(use: show)
            listing.delete(use: delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> PagedListingResponse {
        let page = req.query[Int.self, at: "page"] ?? 1
        let perReq = req.query[Int.self, at: "per"] ?? 20
        
        let per = min(perReq, 20)
        let actualPage = max(page, 1)

        var query = Listing.query(on: req.db).with(\.$seller)

        if let category = req.query[String.self, at: "category"] {
            query = query.filter(\.$category == category)
        }
        if let search = req.query[String.self, at: "q"] {
            query = query.filter(\.$title ~~ search)
        }

        let totalCount = try await query.count()
        let totalPages = max(1, Int(ceil(Double(totalCount) / Double(per))))
        
        let offset = (actualPage - 1) * per
        
        let fetchedListings = try await query
            .limit(per)
            .offset(offset)
            .all()

        let responses = try fetchedListings.map { try ListingResponse(listing: $0) }
        return PagedListingResponse(
            items: responses,
            page: actualPage,
            totalPages: totalPages,
            totalCount: totalCount
        )
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        do {
            try CreateListingRequest.validate(content: req)
        } catch let error as ValidationsError {
            throw Abort(.unprocessableEntity, reason: error.description)
        }
        
        let createReq = try req.content.decode(CreateListingRequest.self)
        
        guard let _ = try await User.find(createReq.sellerID, on: req.db) else {
            throw Abort(.badRequest, reason: "Seller not found")
        }

        let listing = Listing(
            title: createReq.title,
            description: createReq.description,
            price: createReq.price,
            category: createReq.category,
            sellerID: createReq.sellerID
        )

        try await listing.save(on: req.db)
        try await listing.$seller.load(on: req.db)

        let response = try ListingResponse(listing: listing)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func show(req: Request) async throws -> ListingResponse {
        guard let listingId = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let listing = try await Listing.query(on: req.db)
            .filter(\.$id == listingId)
            .with(\.$seller)
            .first() else {
            throw Abort(.notFound)
        }
        
        return try ListingResponse(listing: listing)
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let listing = try await Listing.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await listing.delete(on: req.db)
        return .noContent
    }
}
