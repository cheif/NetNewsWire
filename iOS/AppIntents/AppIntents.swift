import AppIntents

// MARK: Intents
struct FetchArticlesIntent: AppIntent {
	static let title: LocalizedStringResource = "Fetch articles"

	@Parameter(title: "Feed", requestValueDialog: "Which feed?")
	var feed: FeedAppEntity

	@Dependency private var dataManager: AppIntentsDataManager

	func perform() async throws -> some IntentResult & ReturnsValue<[ArticleAppEntity]> {
		let articles = try await dataManager.articles(in: feed)
		return .result(value: articles)
	}
}

struct FetchArticleContentIntent: AppIntent {
	static let title: LocalizedStringResource = "Get article content"

	@Parameter(title: "Article", requestValueDialog: "Which article?")
	var article: ArticleAppEntity

	@Dependency private var dataManager: AppIntentsDataManager

	func perform() async throws -> some IntentResult & ReturnsValue<String> {
		guard let content = article.content else {
			return .result(value: "")
		}
		return .result(value: content)
	}
}

