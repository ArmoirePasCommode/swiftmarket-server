import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post(use: create)
        users.get(use: index)
        users.group(":id") { user in
            user.get(use: show)
            user.get("listings", use: getListings)
        }
    }

    @Sendable
    func create(req: Request) async throws -> Response {
        try CreateUserRequest.validate(content: req)
        let createReq = try req.content.decode(CreateUserRequest.self)
        let user = User(username: createReq.username, email: createReq.email)
        try await user.save(on: req.db)
        
        let response = try UserResponse(user: user)
        return try await response.encodeResponse(status: .created, for: req)
    }

    @Sendable
    func index(req: Request) async throws -> [UserResponse] {
        let users = try await User.query(on: req.db).all()
        return try users.map { try UserResponse(user: $0) }
    }

    @Sendable
    func show(req: Request) async throws -> UserResponse {
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return try UserResponse(user: user)
    }

    @Sendable
    func getListings(req: Request) async throws -> [ListingResponse] {
        guard let user = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let listings = try await Listing.query(on: req.db)
            .filter(\.$seller.$id == user.requireID())
            .with(\.$seller)
            .all()
            
        return try listings.map { try ListingResponse(listing: $0) }
    }
}
