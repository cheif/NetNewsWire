import Account
import Articles
import AppIntents

@MainActor
struct AppIntentsDataManager {
	let accountManager: AccountManager
	let smartFeedsController: SmartFeedsController

	func allFeeds() async throws -> [FeedAppEntity] {
		let allFeeds = smartFeedsController.smartFeeds + accountManager.activeAccounts.flatMap(\.topLevelWebFeeds)
		return allFeeds.compactMap(FeedAppEntity.init(feed:))
	}

	func feeds(for identifiers: [FeedAppEntity.ID]) async throws -> [FeedAppEntity] {
		identifiers
			.compactMap { self.feed(for: $0) }
			.compactMap(FeedAppEntity.init(feed:))
	}

	func articles(in feed: FeedAppEntity) async throws -> [ArticleAppEntity] {
		guard let feed = self.feed(for: feed.id) else {
			return []
		}
		accountManager.resumeAll()
		let articles = try feed.fetchArticles()
		accountManager.suspendDatabaseAll()
		return articles.compactMap(ArticleAppEntity.init(article:))
	}

	func articles(for identifiers: [ArticleAppEntity.ID]) async throws -> [ArticleAppEntity] {
		accountManager.resumeAll()
		let articles = try accountManager.fetchArticles(.articleIDs(Set(identifiers)))
		accountManager.suspendDatabaseAll()
		return articles.compactMap(ArticleAppEntity.init(article:))
	}

	private func feed(for identifier: FeedIdentifier) -> Feed? {
		if let smartFeed = smartFeedsController.find(by: identifier) {
			return smartFeed
		} else if let webFeed = accountManager.existingFeed(with: identifier) {
			return webFeed
		} else {
			return nil
		}
	}
}

private extension FeedAppEntity {
	init?(feed: any Feed) {
		guard let id = feed.feedID else { return nil }
		self.init(
			id: id,
			name: feed.nameForDisplay,
			imageData: (feed as? SmallIconProvider)?.smallIcon?.image.dataRepresentation()
		)
	}
}

private extension ArticleAppEntity {
	init?(article: Article) {
		guard let title = article.title else { return nil }
		self.init(
			id: article.articleID,
			title: title,
			published: article.logicalDatePublished,
			content: article.contentHTML,
			imageData: article.iconImage()?.image.dataRepresentation()
		)
	}
}

extension AppIntentsDataManager {
	static func setup(
		accountManager: AccountManager,
		smartFeedsController: SmartFeedsController
	) {
		AppDependencyManager.shared.add {
			AppIntentsDataManager(
				accountManager: accountManager,
				smartFeedsController: smartFeedsController
			)
		}
	}
}
