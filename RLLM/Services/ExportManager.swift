import Foundation
import UIKit

/// 导出管理器的错误类型
enum ExportError: LocalizedError {
    case emptyContent
    case fileCreationFailed
    case writeError(Error)
    case imageGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return NSLocalizedString("export.error.empty_content", comment: "No content to export")
        case .fileCreationFailed:
            return NSLocalizedString("export.error.file_creation", comment: "Failed to create export file")
        case .writeError(let error):
            return String(format: NSLocalizedString("export.error.write", comment: "Failed to write content"), error.localizedDescription)
        case .imageGenerationFailed:
            return NSLocalizedString("export.error.image_generation", comment: "Failed to generate image")
        }
    }
}

/// 导出管理器
/// 负责将选中的收藏内容导出为文本文件或图片
class ExportManager {
    /// 单例实例
    static let shared = ExportManager()

    private init() {}
    
    
    
    // MARK: - 图片导出
    
    /// 生成报纸风格的图片
    /// - Parameters:
    ///   - quotes: 要导出的收藏数组
    ///   - completion: 完成回调，返回生成的图片或错误
    func generateNewspaperImage(
        from quotes: [Quote],
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        // 检查是否有内容
        guard !quotes.isEmpty else {
            completion(.failure(ExportError.emptyContent))
            return
        }
        
        // 计算内容总高度
        let contentWidth: CGFloat = 800 // 基础宽度
        let titleHeight: CGFloat = 120 // 标题区域高度
        let dateHeight: CGFloat = 30 // 日期区域高度
        let topPadding: CGFloat = 40 // 顶部边距
        let bottomPadding: CGFloat = 40 // 底部边距
        let quoteSpacing: CGFloat = 20 // 引用之间的间距
        
        // 计算每个引用视图的高度
        var totalHeight: CGFloat = titleHeight + dateHeight + topPadding + bottomPadding
        let quoteViews = quotes.map { createQuoteView($0, width: contentWidth - 120) }
        totalHeight += quoteViews.reduce(0) { $0 + $1.bounds.height }
        totalHeight += CGFloat(quotes.count - 1) * quoteSpacing
        
        // 创建容器视图
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: totalHeight))
        containerView.backgroundColor = UIColor(red: 253/255, green: 246/255, blue: 227/255, alpha: 1.0) // 复古米黄色背景
        
        // 添加纸张纹理效果
        let noiseLayer = CALayer()
        noiseLayer.frame = containerView.bounds
        noiseLayer.backgroundColor = UIColor.black.cgColor
        noiseLayer.opacity = 0.03
        containerView.layer.addSublayer(noiseLayer)
        
        // 创建主标题容器
        let titleContainer = UIView(frame: CGRect(x: 60, y: topPadding, width: containerView.bounds.width - 120, height: titleHeight))
        titleContainer.backgroundColor = .clear
        
        // 添加装饰性边框
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8).cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
        borderLayer.path = UIBezierPath(roundedRect: titleContainer.bounds, cornerRadius: 4).cgPath
        
        // 添加双线边框效果
        let innerBorderLayer = CAShapeLayer()
        innerBorderLayer.strokeColor = borderLayer.strokeColor
        innerBorderLayer.fillColor = nil
        innerBorderLayer.lineWidth = 1
        innerBorderLayer.path = UIBezierPath(roundedRect: titleContainer.bounds.insetBy(dx: 6, dy: 6), cornerRadius: 2).cgPath
        
        titleContainer.layer.addSublayer(borderLayer)
        titleContainer.layer.addSublayer(innerBorderLayer)
        
        // 创建主标题
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("export.newspaper.title", comment: "Newspaper title")
        titleLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 48)
        titleLabel.textAlignment = .center
        titleLabel.frame = titleContainer.bounds.insetBy(dx: 20, dy: 20)
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // 固定使用深色文本
        titleContainer.addSubview(titleLabel)
        containerView.addSubview(titleContainer)
        
        // 添加日期
        let dateLabel = UILabel()
        dateLabel.text = String(format: NSLocalizedString("export.newspaper.date", comment: "Publish date"),
                              DateFormatter.yyyyMMdd.string(from: Date()))
        dateLabel.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 16)
        dateLabel.textAlignment = .center
        dateLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        dateLabel.frame = CGRect(x: 60, y: titleContainer.frame.maxY + 16, width: containerView.bounds.width - 120, height: dateHeight)
        dateLabel.backgroundColor = .clear
        containerView.addSubview(dateLabel)
        
        // 添加引用视图
        var currentY = dateLabel.frame.maxY + 30
        for (index, quoteView) in quoteViews.enumerated() {
            quoteView.frame.origin = CGPoint(x: 60, y: currentY)
            containerView.addSubview(quoteView)
            currentY = quoteView.frame.maxY + (index < quoteViews.count - 1 ? quoteSpacing : 0)
        }
        
        // 生成图片
        DispatchQueue.main.async {
            // 确保所有子视图都已布局
            containerView.layoutIfNeeded()
            
            // 创建图片上下文，背景透明
            UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            guard let context = UIGraphicsGetCurrentContext() else {
                completion(.failure(ExportError.imageGenerationFailed))
                return
            }
            
            // 渲染视图层级
            containerView.layer.render(in: context)
            
            guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                completion(.failure(ExportError.imageGenerationFailed))
                return
            }
            
            completion(.success(image))
        }
    }
    
    /// 创建单条引用视图
    /// - Parameters:
    ///   - quote: 引用内容
    ///   - width: 视图宽度
    /// - Returns: 包含引用内容的视图
    private func createQuoteView(_ quote: Quote, width: CGFloat) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        // 添加内容
        let contentLabel = UILabel()
        contentLabel.text = quote.content.removingHTMLTags()
        contentLabel.font = UIFont(name: "TimesNewRomanPS-BoldMT", size: 24)
        contentLabel.numberOfLines = 0
        contentLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        
        // 计算内容高度
        let contentSize = contentLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        contentLabel.frame = CGRect(x: 0, y: 0, width: width, height: contentSize.height)
        container.addSubview(contentLabel)
        
        // 添加来源信息
        let metaLabel = UILabel()
        metaLabel.text = "—— " + quote.articleTitle
        metaLabel.font = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 14)
        metaLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        metaLabel.textAlignment = .right
        metaLabel.frame = CGRect(x: 0, y: contentLabel.frame.maxY + 12, width: width, height: 20)
        container.addSubview(metaLabel)
        
        // 添加装饰性分隔线
        let separatorView = UIView(frame: CGRect(x: width * 0.1,
                                               y: metaLabel.frame.maxY + 24,
                                               width: width * 0.8,
                                               height: 1))
        separatorView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
        container.addSubview(separatorView)
        
        // 设置容器大小
        container.frame = CGRect(x: 0, y: 0,
                               width: width,
                               height: separatorView.frame.maxY)
        
        return container
    }
    
    // MARK: - OPML Export
    
    /// 导出订阅源列表为OPML格式
    /// - Parameter feeds: 要导出的订阅源列表
    /// - Returns: 导出文件的URL
    /// - Throws: ExportError
    func exportOPML(_ feeds: [Feed]) throws -> URL {
        // 检查是否有内容需要导出
        guard !feeds.isEmpty else {
            throw ExportError.emptyContent
        }
        
        // 生成OPML内容
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>RLLM Feeds</title>
                <dateCreated>\(Date().ISO8601Format())</dateCreated>
            </head>
            <body>
        """
        
        // 添加每个订阅源
        for feed in feeds {
            let escapedTitle = feed.title.replacingOccurrences(of: "\"", with: "&quot;")
            let escapedURL = feed.url.replacingOccurrences(of: "\"", with: "&quot;")
            opml += """
                    <outline text="\(escapedTitle)" type="rss" xmlUrl="\(escapedURL)"/>
            """
        }
        
        opml += """
            </body>
        </opml>
        """
        
        // 创建临时文件
        let fileName = "RLLM_Feeds_\(DateFormatter.yyyyMMdd.string(from: Date())).opml"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            // 写入文件
            try opml.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            throw ExportError.writeError(error)
        }
    }
} 