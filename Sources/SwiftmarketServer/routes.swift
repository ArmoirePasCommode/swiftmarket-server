import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: ListingController())
    try app.register(collection: OfferController())
}
