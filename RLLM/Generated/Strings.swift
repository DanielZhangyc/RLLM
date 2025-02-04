// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Cancel button
  internal static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  internal enum AddFeed {
    /// Add feed button
    internal static let add = L10n.tr("Localizable", "add_feed.add", fallback: "Add")
    /// Error alert title
    internal static let error = L10n.tr("Localizable", "add_feed.error", fallback: "Error")
    /// Feed name
    internal static let feedName = L10n.tr("Localizable", "add_feed.feed_name", fallback: "Feed Name (Optional)")
    /// OK button
    internal static let ok = L10n.tr("Localizable", "add_feed.ok", fallback: "OK")
    /// RSS feed URL
    internal static let rssUrl = L10n.tr("Localizable", "add_feed.rss_url", fallback: "RSS Feed URL")
    /// Add feed title
    internal static let title = L10n.tr("Localizable", "add_feed.title", fallback: "Add Feed")
    /// Unknown error message
    internal static let unknownError = L10n.tr("Localizable", "add_feed.unknown_error", fallback: "Unknown Error")
  }
  internal enum Ai {
    /// AI Insights
    internal static let analyzing = L10n.tr("Localizable", "ai.analyzing", fallback: "Analyzing...")
    /// Article count suffix
    internal static let articleCountSuffix = L10n.tr("Localizable", "ai.article_count_suffix", fallback: " articles")
    /// Configuration error
    internal static let configError = L10n.tr("Localizable", "ai.config_error", fallback: "Configuration Error")
    /// Daily summary
    internal static let dailySummary = L10n.tr("Localizable", "ai.daily_summary", fallback: "Daily Summary")
    /// Hot topics
    internal static let hotTopics = L10n.tr("Localizable", "ai.hot_topics", fallback: "Hot Topics")
    /// Key points
    internal static let keyPoints = L10n.tr("Localizable", "ai.key_points", fallback: "Key Points")
    /// Learning advice
    internal static let learningAdvice = L10n.tr("Localizable", "ai.learning_advice", fallback: "Learning Advice")
    /// No reading records
    internal static let noReadingRecords = L10n.tr("Localizable", "ai.no_reading_records", fallback: "No Reading Records")
    /// No reading records description
    internal static let noReadingRecordsDesc = L10n.tr("Localizable", "ai.no_reading_records_desc", fallback: "Start reading some articles, and AI will generate a daily reading summary for you")
    /// Reading time prefix
    internal static let readingTimePrefix = L10n.tr("Localizable", "ai.reading_time_prefix", fallback: "Reading Time: ")
    /// Refresh button
    internal static let refresh = L10n.tr("Localizable", "ai.refresh", fallback: "Refresh")
    /// Retry button
    internal static let retry = L10n.tr("Localizable", "ai.retry", fallback: "Retry")
    internal enum Section {
      /// Advice
      internal static let advice = L10n.tr("Localizable", "ai.section.advice", fallback: "Advice")
      /// Topic analysis section titles
      internal static let hotTopics = L10n.tr("Localizable", "ai.section.hot_topics", fallback: "Hot Topics")
      /// Key Points
      internal static let keyPoints = L10n.tr("Localizable", "ai.section.key_points", fallback: "Key Points")
      /// Daily summary section titles
      internal static let summary = L10n.tr("Localizable", "ai.section.summary", fallback: "Summary")
      /// Topic Distribution
      internal static let topicDistribution = L10n.tr("Localizable", "ai.section.topic_distribution", fallback: "Topic Distribution")
    }
  }
  internal enum AiCache {
    /// Cancel button
    internal static let cancel = L10n.tr("Localizable", "ai_cache.cancel", fallback: "Cancel")
    /// Clear button
    internal static let clear = L10n.tr("Localizable", "ai_cache.clear", fallback: "Clear")
    /// Clear all AI cache
    internal static let clearAll = L10n.tr("Localizable", "ai_cache.clear_all", fallback: "Clear All AI Cache")
    /// Clear all AI cache message
    internal static let clearAllMessage = L10n.tr("Localizable", "ai_cache.clear_all_message", fallback: "Are you sure you want to clear all AI cache?")
    /// Clear all AI cache confirmation
    internal static let clearAllTitle = L10n.tr("Localizable", "ai_cache.clear_all_title", fallback: "Clear All AI Cache")
    /// Clear daily summary cache message
    internal static let clearDailySummaryMessage = L10n.tr("Localizable", "ai_cache.clear_daily_summary_message", fallback: "Are you sure you want to clear daily summary cache?")
    /// Clear daily summary cache confirmation
    internal static let clearDailySummaryTitle = L10n.tr("Localizable", "ai_cache.clear_daily_summary_title", fallback: "Clear Daily Summary Cache")
    /// Clear insight cache message
    internal static let clearInsightMessage = L10n.tr("Localizable", "ai_cache.clear_insight_message", fallback: "Are you sure you want to clear insight cache?")
    /// Clear insight cache confirmation
    internal static let clearInsightTitle = L10n.tr("Localizable", "ai_cache.clear_insight_title", fallback: "Clear Insight Cache")
    /// Clear summary cache message
    internal static let clearSummaryMessage = L10n.tr("Localizable", "ai_cache.clear_summary_message", fallback: "Are you sure you want to clear summary cache?")
    /// Clear summary cache confirmation
    internal static let clearSummaryTitle = L10n.tr("Localizable", "ai_cache.clear_summary_title", fallback: "Clear Summary Cache")
    /// Daily summary cache
    internal static let dailySummaryCache = L10n.tr("Localizable", "ai_cache.daily_summary_cache", fallback: "Daily Summary Cache")
    /// Entry count and size
    internal static func entryCountSize(_ p1: Int, _ p2: Any) -> String {
      return L10n.tr("Localizable", "ai_cache.entry_count_size", p1, String(describing: p2), fallback: "%d entries • %@")
    }
    /// Expired entries
    internal static func expiredEntries(_ p1: Int) -> String {
      return L10n.tr("Localizable", "ai_cache.expired_entries", p1, fallback: "%d expired entries")
    }
    /// AI insight cache
    internal static let insightCache = L10n.tr("Localizable", "ai_cache.insight_cache", fallback: "AI Insight Cache")
    /// AI summary cache
    internal static let summaryCache = L10n.tr("Localizable", "ai_cache.summary_cache", fallback: "AI Summary Cache")
    /// AI cache management
    internal static let title = L10n.tr("Localizable", "ai_cache.title", fallback: "AI Cache Management")
  }
  internal enum Article {
    /// AI Deep Insight
    internal static let aiInsight = L10n.tr("Localizable", "article.ai_insight", fallback: "AI Deep Insight")
    /// AI Summary
    internal static let aiSummary = L10n.tr("Localizable", "article.ai_summary", fallback: "AI Summary")
    /// API key missing
    internal static let apiKeyMissing = L10n.tr("Localizable", "article.api_key_missing", fallback: "Please configure API Key in settings")
    /// Author with name
    internal static func author(_ p1: Any) -> String {
      return L10n.tr("Localizable", "article.author", String(describing: p1), fallback: "Author: %@")
    }
    /// Generate summary
    internal static let generate = L10n.tr("Localizable", "article.generate", fallback: "Generate")
    /// Generating summary
    internal static let generatingSummary = L10n.tr("Localizable", "article.generating_summary", fallback: "Generating summary...")
    /// LLM not configured
    internal static let llmNotConfigured = L10n.tr("Localizable", "article.llm_not_configured", fallback: "Please configure LLM in settings")
    /// Open in browser
    internal static let openInBrowser = L10n.tr("Localizable", "article.open_in_browser", fallback: "Open in Browser")
    /// Regenerate summary
    internal static let regenerate = L10n.tr("Localizable", "article.regenerate", fallback: "Regenerate")
    /// Save full article
    internal static let saveFull = L10n.tr("Localizable", "article.save_full", fallback: "Save Full Article")
    /// Summary generation error
    internal static func summaryError(_ p1: Any) -> String {
      return L10n.tr("Localizable", "article.summary_error", String(describing: p1), fallback: "Failed to generate summary: %@")
    }
    /// Unsave article
    internal static let unsave = L10n.tr("Localizable", "article.unsave", fallback: "Unsave")
  }
  internal enum ArticleInsight {
    /// Article Insight
    internal static let analyzing = L10n.tr("Localizable", "article_insight.analyzing", fallback: "Analyzing...")
    /// Background
    internal static let background = L10n.tr("Localizable", "article_insight.background", fallback: "Background")
    /// Click to start analysis
    internal static let clickToStart = L10n.tr("Localizable", "article_insight.click_to_start", fallback: "Click to Start Analysis")
    /// Core summary
    internal static let coreSummary = L10n.tr("Localizable", "article_insight.core_summary", fallback: "Core Summary")
    /// Key points
    internal static let keyPoints = L10n.tr("Localizable", "article_insight.key_points", fallback: "Key Points")
    /// Sentiment
    internal static let sentiment = L10n.tr("Localizable", "article_insight.sentiment", fallback: "Sentiment")
    /// Start analysis
    internal static let start = L10n.tr("Localizable", "article_insight.start", fallback: "Start Analysis")
    /// Topic tags
    internal static let topicTags = L10n.tr("Localizable", "article_insight.topic_tags", fallback: "Topic Tags")
  }
  internal enum Error {
    /// Retry button
    internal static let retry = L10n.tr("Localizable", "error.retry", fallback: "Retry")
  }
  internal enum Export {
    /// Generating newspaper style
    internal static let generating = L10n.tr("Localizable", "export.generating", fallback: "Generating newspaper style...")
    internal enum Error {
      /// Export related
      internal static let emptyContent = L10n.tr("Localizable", "export.error.empty_content", fallback: "No content to export")
      /// Failed to create export file
      internal static let fileCreation = L10n.tr("Localizable", "export.error.file_creation", fallback: "Failed to create export file")
      /// Failed to generate image
      internal static let imageGeneration = L10n.tr("Localizable", "export.error.image_generation", fallback: "Failed to generate image")
      /// Export error message
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "export.error.message", String(describing: p1), fallback: "Failed to generate image: %@")
      }
      /// Export error
      internal static let title = L10n.tr("Localizable", "export.error.title", fallback: "Export Failed")
      /// Failed to write content
      internal static func write(_ p1: Any) -> String {
        return L10n.tr("Localizable", "export.error.write", String(describing: p1), fallback: "Failed to write content: %@")
      }
    }
    internal enum Newspaper {
      /// By %@
      internal static func author(_ p1: Any) -> String {
        return L10n.tr("Localizable", "export.newspaper.author", String(describing: p1), fallback: "By %@")
      }
      /// Publish date
      internal static func date(_ p1: Any) -> String {
        return L10n.tr("Localizable", "export.newspaper.date", String(describing: p1), fallback: "Date: %@")
      }
      /// Source: %@
      internal static func source(_ p1: Any) -> String {
        return L10n.tr("Localizable", "export.newspaper.source", String(describing: p1), fallback: "Source: %@")
      }
      /// Newspaper title
      internal static let title = L10n.tr("Localizable", "export.newspaper.title", fallback: "RLLM Quotes")
    }
    internal enum Success {
      /// Export success message
      internal static let message = L10n.tr("Localizable", "export.success.message", fallback: "Quote image has been generated")
      /// Export success
      internal static let title = L10n.tr("Localizable", "export.success.title", fallback: "Export Success")
    }
  }
  internal enum Feed {
    /// Delete feed
    internal static let delete = L10n.tr("Localizable", "feed.delete", fallback: "Delete")
  }
  internal enum FeedEdit {
    /// Basic info section
    internal static let basicInfo = L10n.tr("Localizable", "feed_edit.basic_info", fallback: "Basic Info")
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "feed_edit.cancel", fallback: "Cancel")
    /// Done
    internal static let done = L10n.tr("Localizable", "feed_edit.done", fallback: "Done")
    /// Icon settings
    internal static let iconSettings = L10n.tr("Localizable", "feed_edit.icon_settings", fallback: "Icon Settings")
    /// Feed name field
    internal static let name = L10n.tr("Localizable", "feed_edit.name", fallback: "Name")
    /// Settings
    internal static let title = L10n.tr("Localizable", "feed_edit.title", fallback: "Settings")
  }
  internal enum FeedManagement {
    /// Error alert title
    internal static let error = L10n.tr("Localizable", "feed_management.error", fallback: "Error")
    /// OK button
    internal static let ok = L10n.tr("Localizable", "feed_management.ok", fallback: "OK")
    /// Feed management title
    internal static let title = L10n.tr("Localizable", "feed_management.title", fallback: "Feed Management")
    /// Unknown error message
    internal static let unknownError = L10n.tr("Localizable", "feed_management.unknown_error", fallback: "Unknown Error")
  }
  internal enum Llm {
    /// Language instruction for LLM
    internal static let languageInstruction = L10n.tr("Localizable", "llm.language_instruction", fallback: "Please respond in English. Keep all section titles and formatting markers unchanged.")
    internal enum Error {
      /// Authentication failed error
      internal static let authFailed = L10n.tr("Localizable", "llm.error.auth_failed", fallback: "Authentication failed, please check your API Key")
      /// Decoding error with description
      internal static func decoding(_ p1: Any) -> String {
        return L10n.tr("Localizable", "llm.error.decoding", String(describing: p1), fallback: "Decoding error: %@")
      }
      /// Invalid response error
      internal static let invalidResponse = L10n.tr("Localizable", "llm.error.invalid_response", fallback: "Invalid response")
      /// Invalid URL error
      internal static let invalidUrl = L10n.tr("Localizable", "llm.error.invalid_url", fallback: "Invalid URL")
      /// Network error with description
      internal static func network(_ p1: Any) -> String {
        return L10n.tr("Localizable", "llm.error.network", String(describing: p1), fallback: "Network error: %@")
      }
      /// No content error
      internal static let noContent = L10n.tr("Localizable", "llm.error.no_content", fallback: "No valid content received")
    }
  }
  internal enum Model {
    /// Error
    internal static let error = L10n.tr("Localizable", "model.error", fallback: "Error")
    /// OK
    internal static let ok = L10n.tr("Localizable", "model.ok", fallback: "OK")
    /// Search model
    internal static let search = L10n.tr("Localizable", "model.search", fallback: "Search Model")
    /// Select model
    internal static let select = L10n.tr("Localizable", "model.select", fallback: "Select Model")
    /// Model thinking warning
    internal static let thinkingWarning = L10n.tr("Localizable", "model.thinking_warning", fallback: "⚠️ This model outputs thinking process, which may affect summary quality")
    /// Unknown error
    internal static let unknownError = L10n.tr("Localizable", "model.unknown_error", fallback: "Unknown Error")
  }
  internal enum Provider {
    /// Custom provider
    internal static let custom = L10n.tr("Localizable", "provider.custom", fallback: "Custom")
  }
  internal enum Quote {
    /// Quote detail
    internal static let detail = L10n.tr("Localizable", "quote.detail", fallback: "Quote Detail")
    /// Full article saved
    internal static let fullArticle = L10n.tr("Localizable", "quote.full_article", fallback: "Full Article")
    /// Save quote menu item
    internal static let save = L10n.tr("Localizable", "quote.save", fallback: "Save Quote")
    /// Save time prefix
    internal static let saveTimePrefix = L10n.tr("Localizable", "quote.save_time_prefix", fallback: "Saved at: ")
    /// Source prefix
    internal static let sourcePrefix = L10n.tr("Localizable", "quote.source_prefix", fallback: "Source: ")
    /// View original
    internal static let viewOriginal = L10n.tr("Localizable", "quote.view_original", fallback: "View Original")
  }
  internal enum Quotes {
    /// Delete quote
    internal static let delete = L10n.tr("Localizable", "quotes.delete", fallback: "Delete")
    /// Delete Selected
    internal static let deleteSelected = L10n.tr("Localizable", "quotes.delete_selected", fallback: "Delete Selected")
    /// Deselect All
    internal static let deselectAll = L10n.tr("Localizable", "quotes.deselect_all", fallback: "Deselect All")
    /// Done
    internal static let done = L10n.tr("Localizable", "quotes.done", fallback: "Done")
    /// Multi-selection related
    internal static let edit = L10n.tr("Localizable", "quotes.edit", fallback: "Edit")
    /// Save quotes instruction
    internal static let saveInstruction = L10n.tr("Localizable", "quotes.save_instruction", fallback: "Long press to select text while reading to save quotes")
    /// Save quotes title
    internal static let saveQuote = L10n.tr("Localizable", "quotes.save_quote", fallback: "Save Quotes")
    /// Saved quotes display
    internal static let savedDisplay = L10n.tr("Localizable", "quotes.saved_display", fallback: "Saved quotes will be displayed here")
    /// Select All
    internal static let selectAll = L10n.tr("Localizable", "quotes.select_all", fallback: "Select All")
    /// Quotes title
    internal static let title = L10n.tr("Localizable", "quotes.title", fallback: "Quotes")
  }
  internal enum ReadingHistory {
    /// Article count
    internal static func articleCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "reading_history.article_count", p1, fallback: "%d Articles")
    }
    /// Articles read - singular
    internal static func articleRead(_ p1: Int) -> String {
      return L10n.tr("Localizable", "reading_history.article_read", p1, fallback: "%d article")
    }
    /// Articles read - plural
    internal static func articlesRead(_ p1: Int) -> String {
      return L10n.tr("Localizable", "reading_history.articles_read", p1, fallback: "%d articles")
    }
    /// Average per article
    internal static let averagePerArticle = L10n.tr("Localizable", "reading_history.average_per_article", fallback: "Average per Article")
    /// Daily average
    internal static let dailyAverage = L10n.tr("Localizable", "reading_history.daily_average", fallback: "Daily Average")
    /// Hours and minutes
    internal static func hoursMinutes(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "reading_history.hours_minutes", p1, p2, fallback: "%d hours %d minutes")
    }
    /// Reading time - singular
    internal static func minute(_ p1: Int) -> String {
      return L10n.tr("Localizable", "reading_history.minute", p1, fallback: "%d minute")
    }
    /// Reading time - plural
    internal static func minutes(_ p1: Int) -> String {
      return L10n.tr("Localizable", "reading_history.minutes", p1, fallback: "%d minutes")
    }
    /// No reading records
    internal static let noRecords = L10n.tr("Localizable", "reading_history.no_records", fallback: "No reading records")
    /// Reading time
    internal static let readingTime = L10n.tr("Localizable", "reading_history.reading_time", fallback: "Reading Time")
    /// Reading records
    internal static let records = L10n.tr("Localizable", "reading_history.records", fallback: "Reading Records")
    /// Reading statistics
    internal static let statistics = L10n.tr("Localizable", "reading_history.statistics", fallback: "Reading Statistics")
    /// This month
    internal static let thisMonth = L10n.tr("Localizable", "reading_history.this_month", fallback: "This Month")
    /// This week
    internal static let thisWeek = L10n.tr("Localizable", "reading_history.this_week", fallback: "This Week")
    /// Time range
    internal static let timeRange = L10n.tr("Localizable", "reading_history.time_range", fallback: "Time Range")
    /// Reading history
    internal static let title = L10n.tr("Localizable", "reading_history.title", fallback: "Reading History")
    /// Today
    internal static let today = L10n.tr("Localizable", "reading_history.today", fallback: "Today")
  }
  internal enum Settings {
    /// About section
    internal static let about = L10n.tr("Localizable", "settings.about", fallback: "About")
    /// About description
    internal static let aboutDescription = L10n.tr("Localizable", "settings.about_description", fallback: "RLLM is an open-source RSS reader with AI-powered analysis features.")
    /// AI cache management
    internal static let aiCache = L10n.tr("Localizable", "settings.ai_cache", fallback: "AI Cache Management")
    /// API Key
    internal static let apiKey = L10n.tr("Localizable", "settings.api_key", fallback: "API Key")
    /// Base URL
    internal static let baseUrl = L10n.tr("Localizable", "settings.base_url", fallback: "Base URL")
    /// Cancel button
    internal static let cancel = L10n.tr("Localizable", "settings.cancel", fallback: "Cancel")
    /// Clear button
    internal static let clear = L10n.tr("Localizable", "settings.clear", fallback: "Clear")
    /// Clear history
    internal static let clearHistory = L10n.tr("Localizable", "settings.clear_history", fallback: "Clear Reading History")
    /// Clear history confirmation message
    internal static let clearHistoryMessage = L10n.tr("Localizable", "settings.clear_history_message", fallback: "This will delete all reading history and statistics. This action cannot be undone.")
    /// Clear history confirmation title
    internal static let clearHistoryTitle = L10n.tr("Localizable", "settings.clear_history_title", fallback: "Confirm Clear Reading History")
    /// Clear history warning
    internal static let clearHistoryWarning = L10n.tr("Localizable", "settings.clear_history_warning", fallback: "This will delete all reading history and statistics. This action cannot be undone.")
    /// Data management section
    internal static let dataManagement = L10n.tr("Localizable", "settings.data_management", fallback: "Data Management")
    /// Feed count
    internal static func feedCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "settings.feed_count", p1, fallback: "%d Subscriptions")
    }
    /// Feed management section
    internal static let feedManagement = L10n.tr("Localizable", "settings.feed_management", fallback: "Feed Management")
    /// LLM settings section
    internal static let llm = L10n.tr("Localizable", "settings.llm", fallback: "LLM Settings")
    /// Loading models
    internal static let loadingModels = L10n.tr("Localizable", "settings.loading_models", fallback: "Loading models...")
    /// Manage feeds
    internal static let manageFeeds = L10n.tr("Localizable", "settings.manage_feeds", fallback: "Manage RSS Feeds")
    /// Model selection
    internal static let model = L10n.tr("Localizable", "settings.model", fallback: "Model")
    /// Provider picker
    internal static let provider = L10n.tr("Localizable", "settings.provider", fallback: "Provider")
    /// Reading settings section
    internal static let reading = L10n.tr("Localizable", "settings.reading", fallback: "Reading Settings")
    /// Reading history
    internal static let readingHistory = L10n.tr("Localizable", "settings.reading_history", fallback: "Reading History")
    /// Record count
    internal static func recordCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "settings.record_count", p1, fallback: "%d Records")
    }
    /// Source code
    internal static let sourceCode = L10n.tr("Localizable", "settings.source_code", fallback: "Source Code")
    /// Test connection button
    internal static let testConnection = L10n.tr("Localizable", "settings.test_connection", fallback: "Test Connection")
    /// Test connection failed
    internal static let testFailed = L10n.tr("Localizable", "settings.test_failed", fallback: "Connection failed")
    /// Test connection success
    internal static let testSuccess = L10n.tr("Localizable", "settings.test_success", fallback: "Connection successful")
    /// Settings title
    internal static let title = L10n.tr("Localizable", "settings.title", fallback: "Settings")
    /// Version
    internal static let version = L10n.tr("Localizable", "settings.version", fallback: "Version")
  }
  internal enum Share {
    /// Share
    internal static let button = L10n.tr("Localizable", "share.button", fallback: "Share")
  }
  internal enum Tab {
    /// AI Summary tab
    internal static let aiSummary = L10n.tr("Localizable", "tab.ai_summary", fallback: "AI Summary")
    /// Articles tab
    internal static let articles = L10n.tr("Localizable", "tab.articles", fallback: "Articles")
    /// Quotes tab
    internal static let quotes = L10n.tr("Localizable", "tab.quotes", fallback: "Quotes")
    /// Settings tab
    internal static let settings = L10n.tr("Localizable", "tab.settings", fallback: "Settings")
  }
  internal enum Time {
    /// Days ago
    internal static func daysAgo(_ p1: Int) -> String {
      return L10n.tr("Localizable", "time.days_ago", p1, fallback: "%d days ago")
    }
    /// Hours ago
    internal static func hoursAgo(_ p1: Int) -> String {
      return L10n.tr("Localizable", "time.hours_ago", p1, fallback: "%d hours ago")
    }
    /// Time ago display
    internal static let justNow = L10n.tr("Localizable", "time.just_now", fallback: "Just now")
    /// Minutes ago
    internal static func minutesAgo(_ p1: Int) -> String {
      return L10n.tr("Localizable", "time.minutes_ago", p1, fallback: "%d minutes ago")
    }
    /// One day ago
    internal static let oneDayAgo = L10n.tr("Localizable", "time.one_day_ago", fallback: "1 day ago")
  }
  internal enum Toast {
    /// Toast error
    internal static let error = L10n.tr("Localizable", "toast.error", fallback: "Error")
    /// Toast info
    internal static let info = L10n.tr("Localizable", "toast.info", fallback: "Info")
    /// Toast success
    internal static let success = L10n.tr("Localizable", "toast.success", fallback: "Success")
    /// Toast warning
    internal static let warning = L10n.tr("Localizable", "toast.warning", fallback: "Warning")
    internal enum Articles {
      internal enum AddFailed {
        /// Unable to save feed. Please try again.
        internal static let message = L10n.tr("Localizable", "toast.articles.add_failed.message", fallback: "Unable to save feed. Please try again.")
        /// Add Failed
        internal static let title = L10n.tr("Localizable", "toast.articles.add_failed.title", fallback: "Add Failed")
      }
      internal enum DeleteFailed {
        /// Delete failed message
        internal static let message = L10n.tr("Localizable", "toast.articles.delete_failed.message", fallback: "Unable to delete feed. Please try again.")
        /// Delete failed title
        internal static let title = L10n.tr("Localizable", "toast.articles.delete_failed.title", fallback: "Delete Failed")
      }
      internal enum Deleted {
        /// Deleted message
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "toast.articles.deleted.message", String(describing: p1), fallback: "Feed \"%@\" has been deleted")
        }
        /// Deleted title
        internal static let title = L10n.tr("Localizable", "toast.articles.deleted.title", fallback: "Deleted")
      }
      internal enum LoadFailed {
        /// Load failed message
        internal static let message = L10n.tr("Localizable", "toast.articles.load_failed.message", fallback: "Unable to load feed list. Please restart the app.")
        /// Toast messages - Articles
        internal static let title = L10n.tr("Localizable", "toast.articles.load_failed.title", fallback: "Load Failed")
      }
      internal enum RefreshFailed {
        /// Refresh failed message
        internal static func message(_ p1: Int, _ p2: Int) -> String {
          return L10n.tr("Localizable", "toast.articles.refresh_failed.message", p1, p2, fallback: "Success: %d, Failed: %d")
        }
        /// Refresh failed title
        internal static let title = L10n.tr("Localizable", "toast.articles.refresh_failed.title", fallback: "Refresh Failed")
      }
      internal enum RefreshSuccess {
        /// Refresh success message
        internal static func message(_ p1: Int) -> String {
          return L10n.tr("Localizable", "toast.articles.refresh_success.message", p1, fallback: "Updated content from %d feeds")
        }
        /// Refresh success title
        internal static let title = L10n.tr("Localizable", "toast.articles.refresh_success.title", fallback: "Refresh Success")
      }
      internal enum UpdateFailed {
        /// Update failed message
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "toast.articles.update_failed.message", String(describing: p1), fallback: "Unable to update feed \"%@\". Please check network connection.")
        }
        /// Update failed title
        internal static let title = L10n.tr("Localizable", "toast.articles.update_failed.title", fallback: "Update Failed")
      }
      internal enum Updated {
        /// Updated message
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "toast.articles.updated.message", String(describing: p1), fallback: "Settings for feed \"%@\" have been updated")
        }
        /// Updated title
        internal static let title = L10n.tr("Localizable", "toast.articles.updated.title", fallback: "Updated")
      }
    }
    internal enum Quotes {
      internal enum ArticleSaved {
        /// Full article has been added to favorites
        internal static let message = L10n.tr("Localizable", "toast.quotes.article_saved.message", fallback: "Full article has been added to favorites")
        /// Toast messages - Quotes
        internal static let title = L10n.tr("Localizable", "toast.quotes.article_saved.title", fallback: "Article Saved")
      }
      internal enum ArticleUnsaved {
        /// Article has been removed from favorites
        internal static let message = L10n.tr("Localizable", "toast.quotes.article_unsaved.message", fallback: "Article has been removed from favorites")
        /// Article Unsaved
        internal static let title = L10n.tr("Localizable", "toast.quotes.article_unsaved.title", fallback: "Article Unsaved")
      }
      internal enum Deleted {
        /// Quotes deleted message
        internal static func message(_ p1: Int) -> String {
          return L10n.tr("Localizable", "toast.quotes.deleted.message", p1, fallback: "Removed %d favorite items")
        }
        /// Quotes deleted title
        internal static let title = L10n.tr("Localizable", "toast.quotes.deleted.title", fallback: "Deleted")
      }
      internal enum TextSaved {
        /// Selected text has been added to favorites
        internal static let message = L10n.tr("Localizable", "toast.quotes.text_saved.message", fallback: "Selected text has been added to favorites")
        /// Text Saved
        internal static let title = L10n.tr("Localizable", "toast.quotes.text_saved.title", fallback: "Text Saved")
      }
      internal enum TextUnsaved {
        /// Text has been removed from favorites
        internal static let message = L10n.tr("Localizable", "toast.quotes.text_unsaved.message", fallback: "Text has been removed from favorites")
        /// Text Unsaved
        internal static let title = L10n.tr("Localizable", "toast.quotes.text_unsaved.title", fallback: "Text Unsaved")
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
