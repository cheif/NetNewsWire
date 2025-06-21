import Account
import AppIntents

// MARK: Entities
struct FeedAppEntity: AppEntity {
	let id: FeedIdentifier
	let name: String
	let imageData: Data?

	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Feed")
	}

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(name)",
			image: imageData.map { DisplayRepresentation.Image(data: $0) }
		)
	}
}

extension FeedAppEntity {
	static var defaultQuery = FeedQuery()
	struct FeedQuery: EntityQuery, EnumerableEntityQuery {
		@Dependency var dataManager: AppIntentsDataManager

		func entities(for identifiers: [FeedAppEntity.ID]) async throws -> [FeedAppEntity] {
			try await dataManager.feeds(for: identifiers)
		}

		func allEntities() async throws -> [FeedAppEntity] {
			try await dataManager.allFeeds()
		}
	}
}

enum ArticleEntityStatus: String, Codable, Sendable, AppEnum {
	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(
			name: "Article status"
		)
	}

	static var caseDisplayRepresentations: [ArticleEntityStatus: DisplayRepresentation] {
		[
			.unread: "Unread",
			.starred: "Starred",
		]
	}

	case unread
	case starred
}

struct ArticleAppEntity: AppEntity {
	let id: String
	let title: String
	let published: Date
	let content: String?
	let imageData: Data?

	static var typeDisplayRepresentation: TypeDisplayRepresentation {
		TypeDisplayRepresentation(name: "Article")
	}

	var displayRepresentation: DisplayRepresentation {
		DisplayRepresentation(
			title: "\(title)",
			subtitle: "Published: \(published, format: .dateTime)",
			image: imageData.map { DisplayRepresentation.Image(data: $0) }
		)
	}
}

extension ArticleAppEntity {
	static var defaultQuery = ArticleQuery()
	struct ArticleQuery: EntityQuery {
		@Dependency var dataManager: AppIntentsDataManager

		func entities(for identifiers: [ArticleAppEntity.ID]) async throws -> [ArticleAppEntity] {
			try await dataManager.articles(for: identifiers)
		}
	}
}

extension FeedIdentifier: AppIntents.EntityIdentifierConvertible {
	public var entityIdentifierString: String {
		switch self {
		case .smartFeed(let string):
			"smart-\(string)"
		case .script(let string):
			"script-\(string)"
		case .webFeed(let string, let string2):
			"web-\(string)-\(string2)"
		case .folder(let string, let string2):
			"folder-\(string)-\(string2)"
		}
	}

	public static func entityIdentifier(for entityIdentifierString: String) -> FeedIdentifier? {
		let parts = entityIdentifierString.split(separator: "-")
		guard
			let identifierPart = parts.dropFirst().first.map(String.init),
			let lastPart = parts.last.map(String.init)
		else {
			return nil
		}
		return switch parts[0] {
		case "smart": .smartFeed(identifierPart)
		case "script": .script(identifierPart)

			// NB: This logic isn't bulletproof, since it'll work correctly even with an identifier like web-foobar, identifierPart and lastPart will just be the same
		case "web": .webFeed(identifierPart, lastPart)
		case "folder": .folder(identifierPart, lastPart)

		default: nil
		}
	}
}
