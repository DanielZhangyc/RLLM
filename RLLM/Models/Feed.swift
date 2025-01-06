import Foundation

/// 表示一个RSS订阅源的数据模型
struct Feed: Identifiable, Codable {
    // MARK: - Properties
    
    /// 订阅源的唯一标识符
    let id: UUID
    
    /// 订阅源的标题
    var title: String
    
    /// 订阅源的URL地址
    let url: String
    
    /// 订阅源的描述信息
    let description: String?
    
    /// 订阅源的图标名称
    var iconName: String
    
    /// 订阅源的图标颜色
    var iconColor: String?
    
    // MARK: - Initialization
    
    /// 创建一个新的Feed实例
    /// - Parameters:
    ///   - id: 唯一标识符，默认自动生成
    ///   - title: 订阅源标题
    ///   - url: 订阅源URL
    ///   - description: 订阅源描述
    ///   - iconName: 图标名称
    ///   - iconColor: 图标颜色
    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        description: String? = nil,
        iconName: String = "newspaper.fill",
        iconColor: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
        self.iconName = iconName
        self.iconColor = iconColor
    }
    
    // MARK: - Methods
    
    /// 更新Feed的属性并返回新的实例
    /// - Parameters:
    ///   - title: 新的标题，如果为nil则保持原值
    ///   - iconName: 新的图标名称，如果为nil则保持原值
    ///   - iconColor: 新的图标颜色，如果为nil则保持原值
    /// - Returns: 更新后的Feed实例
    func updating(title: String? = nil, iconName: String? = nil, iconColor: String? = nil) -> Feed {
        Feed(
            id: self.id,
            title: title ?? self.title,
            url: self.url,
            description: self.description,
            iconName: iconName ?? self.iconName,
            iconColor: iconColor ?? self.iconColor
        )
    }
} 