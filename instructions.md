Partie 1 — Serveur Vapor (matin)
Setup
vapor new swiftmarket-server --template=api
cd swiftmarket-server

Le template génère un exemple Todo complet. Supprimer ces fichiers avant de commencer :

Sources/SwiftmarketServer/Controllers/TodoController.swift
Sources/SwiftmarketServer/DTOs/TodoDTO.swift
Sources/SwiftmarketServer/Models/Todo.swift
Sources/SwiftmarketServer/Migrations/CreateTodo.swift

Vider ensuite routes.swift (garder seulement la fonction vide) et configure.swift.

Sources/SwiftmarketServer/configure.swift — remplacer par :

import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateListing())

    try await app.autoMigrate()

    try routes(app)
}

Package.swift et entrypoint.swift générés par le template ne sont pas à modifier.

Modèles
User

id: UUID
username: String (unique)
email: String (unique)
createdAt: Date

Listing

id: UUID
title: String
description: String
price: Double
category: String  // "electronics" | "clothing" | "furniture" | "other"
sellerID: UUID → User
createdAt: Date

Chaque modèle est une final class qui conforme à Model, Content et @unchecked Sendable.

Migrations
Créer CreateUser et CreateListing dans Sources/SwiftmarketServer/Migrations/.

Les deux conforment à AsyncMigration et implémentent prepare et revert.

CreateUser : contraintes unique sur username et email
CreateListing : clé étrangère seller_id → users.id avec onDelete: .cascade
DTOs
Placer les DTOs dans Sources/SwiftmarketServer/DTOs/.

// UserDTO.swift
struct CreateUserRequest: Content, Validatable {
    var username: String
    var email: String
    // validations : username non vide, email valide
}

struct UserResponse: Content {
    var id: UUID
    var username: String
    var email: String
    var createdAt: Date?
    // init(user: User) throws
}

// ListingDTO.swift
struct CreateListingRequest: Content, Validatable {
    var title: String
    var description: String
    var price: Double
    var category: String
    var sellerID: UUID
    // validations : title non vide, price > 0, category dans la liste
}

struct ListingResponse: Content {
    var id: UUID
    var title: String
    var description: String
    var price: Double
    var category: String
    var seller: UserResponse
    var createdAt: Date?
    // init(listing: Listing) throws — nécessite que $seller soit chargé
}

struct PagedListingResponse: Content {
    var items: [ListingResponse]
    var page: Int
    var totalPages: Int
    var totalCount: Int
}

Routes
Déclarer les routes dans deux RouteCollection distincts, enregistrés depuis routes.swift :

// routes.swift
func routes(_ app: Application) throws {
    try app.register(collection: UserController())
    try app.register(collection: ListingController())
}

Users
Méthode	Route	Description	Code succès
POST	/users	Crée un utilisateur	201
GET	/users	Liste tous les utilisateurs	200
GET	/users/:id	Profil d'un utilisateur	200
GET	/users/:id/listings	Annonces d'un utilisateur	200
Listings
Méthode	Route	Description	Code succès
GET	/listings	Liste paginée (?page=&per=)	200
GET	/listings?category=&q=	Filtres cumulables sur index	200
POST	/listings	Crée une annonce	201
GET	/listings/:id	Détail avec infos vendeur	200
DELETE	/listings/:id	Supprime une annonce	204
Contraintes
Validation avec Validatable : appeler try CreateXxxRequest.validate(content: req) en tête de handler
price > 0 et title non vide
category doit être l'une de : electronics, clothing, furniture, other
Pagination manuelle sur GET /listings : max 20 items par page, paramètre ?page= (défaut 1)
Codes HTTP : 201 (création), 204 (suppression), 404 (ressource introuvable), 422 (validation)
Test de l'API
Avant de passer au client CLI, vérifiez votre API avec curl :

# Créer un utilisateur
curl -s -X POST http://localhost:8080/users \
  -H "Content-Type: application/json" \
  -d '{"username":"sascha","email":"sascha@example.com"}'

# Créer un listing (remplacer <id> par l'id retourné)
curl -s -X POST http://localhost:8080/listings \
  -H "Content-Type: application/json" \
  -d '{"title":"MacBook Pro","description":"M3 chip","price":1999.99,"category":"electronics","sellerID":"<id>"}'

# Lister les annonces
curl -s http://localhost:8080/listings

# Supprimer (remplacer <listingID>)
curl -s -X DELETE http://localhost:8080/listings/<listingID> -w "%{http_code}"

Ne passez à la Partie 2 qu'une fois votre API validée.