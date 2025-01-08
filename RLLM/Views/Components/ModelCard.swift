import SwiftUI

struct ModelCard: View {
    let model: Model
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                HapticManager.shared.selection()
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let description = model.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        if model.isThinkingModel {
                            Text("⚠️ 此模型会输出思维过程，可能影响摘要质量")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                
                HStack(spacing: 12) {
                    if let provider = model.provider {
                        Label(provider, systemImage: "server.rack")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    if let contextLength = model.contextLength {
                        Label("\(contextLength) tokens", systemImage: "text.word.spacing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : 
                        Color.primary.opacity(colorScheme == .dark ? 0.1 : 0.05),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 