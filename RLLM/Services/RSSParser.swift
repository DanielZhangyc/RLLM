import Foundation

/// RSS解析器，负责解析RSS和Atom格式的Feed
final class RSSParser: NSObject, XMLParserDelegate {
    // MARK: - Properties
    
    /// 当前正在解析的XML元素名称
    private var currentElement = ""
    
    /// 当前文章的标题
    private var currentTitle: String?
    
    /// 当前文章的描述
    private var currentDescription: String?
    
    /// 当前文章的链接
    private var currentLink: String?
    
    /// 当前文章的发布日期
    private var currentPubDate: Date?
    
    /// 当前文章的内容
    private var currentContent: String?
    
    /// 当前文章的作者
    private var currentAuthor: String?
    
    /// 标记是否在 item/entry 元素内
    private var isInItem = false
    
    /// 解析得到的文章列表
    private var items: [Article] = []
    
    /// Feed的标题
    private var feedTitle: String?
    
    /// Feed的描述
    private var feedDescription: String?
    
    /// 解析过程中的错误
    private var parserError: Error?
    
    // MARK: - Date Formatting
    
    /// 日期格式化器
    private let dateFormatter: DateFormatter
    
    /// 支持的日期格式列表
    private let alternateFormats = [
        // RFC 822, RFC 2822
        "EEE, dd MMM yyyy HH:mm:ss Z",
        "EEE, dd MMM yyyy HH:mm Z",
        "dd MMM yyyy HH:mm:ss Z",
        "dd MMM yyyy HH:mm Z",
        
        // ISO 8601
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
        
        // 常见格式
        "yyyy-MM-dd HH:mm:ss Z",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy.MM.dd HH:mm:ss",
        "yyyy年MM月dd日 HH:mm:ss",
        
        // 简单日期格式
        "yyyy-MM-dd",
        "yyyy/MM/dd",
        "yyyy.MM.dd",
        "yyyy年MM月dd日"
    ]
    
    // MARK: - Initialization
    
    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 解析RSS数据
    /// - Parameter data: RSS数据
    /// - Returns: 包含Feed信息和文章列表的元组
    /// - Throws: RSSError.parseError 当解析失败时
    ///          RSSError.invalidFeed 当Feed数据无效时
    func parse(data: Data) throws -> (feed: Feed, articles: [Article]) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        // 重置状态
        resetParserState()
        
        guard parser.parse() else {
            throw parserError ?? RSSError.parseError(parser.parserError ?? NSError())
        }
        
        guard let title = feedTitle else {
            throw RSSError.invalidFeed
        }
        
        let feed = Feed(
            title: title,
            url: "",  // URL将在外部设置
            description: feedDescription
        )
        
        return (feed, items)
    }
    
    // MARK: - Private Methods
    
    /// 重置解析器状态
    private func resetParserState() {
        items = []
        feedTitle = nil
        feedDescription = nil
        parserError = nil
        currentElement = ""
        isInItem = false
    }
    
    /// 解析日期字符串
    /// - Parameter dateString: 日期字符串
    /// - Returns: 解析后的Date对象，如果解析失败则返回nil
    private func parseDate(_ dateString: String) -> Date? {
        // 首先尝试默认格式
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // 尝试其他格式
        let originalFormat = dateFormatter.dateFormat
        defer { dateFormatter.dateFormat = originalFormat }
        
        for format in alternateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        if elementName == "item" || elementName == "entry" {
            isInItem = true
            resetCurrentItemState()
        }
        
        // 处理Atom格式的链接
        if elementName == "link", let href = attributeDict["href"] {
            currentLink = href
        }
    }
    
    /// 重置当前项的状态
    private func resetCurrentItemState() {
        currentTitle = nil
        currentDescription = nil
        currentLink = nil
        currentPubDate = nil
        currentContent = nil
        currentAuthor = nil
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !content.isEmpty else { return }
        
        switch currentElement {
        case "title":
            if isInItem {
                currentTitle = (currentTitle ?? "") + content
            } else {
                feedTitle = (feedTitle ?? "") + content
            }
            
        case "description", "summary", "subtitle":
            if isInItem {
                currentDescription = (currentDescription ?? "") + content
            } else {
                feedDescription = (feedDescription ?? "") + content
            }
            
        case "link":
            if currentLink == nil {
                currentLink = content
            }
            
        case "pubDate", "published", "updated", "lastBuildDate", "dc:date":
            if currentPubDate == nil {
                currentPubDate = parseDate(content)
            }
            
        case "content:encoded", "content":
            currentContent = (currentContent ?? "") + content
            
        case "author", "dc:creator":
            if currentAuthor == nil {
                currentAuthor = content
            }
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            isInItem = false
            let article = createArticle()
            items.append(article)
        }
    }
    
    /// 创建文章对象
    /// - Returns: 根据当前解析状态创建的Article对象
    private func createArticle() -> Article {
        Article(
            title: currentTitle ?? "无标题",
            content: currentContent ?? currentDescription ?? "",
            url: currentLink ?? "",
            publishDate: currentPubDate ?? Date(),
            feedTitle: feedTitle ?? "未知源",
            author: currentAuthor
        )
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }
} 