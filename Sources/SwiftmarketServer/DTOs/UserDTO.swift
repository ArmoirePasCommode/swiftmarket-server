import Vapor

struct CreateUserRequest: Content, Validatable {
    var username: String
    var email: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
    }
}

struct UserResponse: Content {
    var id: UUID
    var username: String
    var email: String
    var createdAt: Date?

    init(user: User) throws {
        self.id = try user.requireID()
        self.username = user.username
        self.email = user.email
        self.createdAt = user.createdAt
    }
}
