import SwiftUI

struct QuotesListView: View {
    @EnvironmentObject private var viewModel: QuotesViewModel
    @State private var isEditMode: Bool = false
    @State private var isAllSelected: Bool = false
    @State private var isExporting: Bool = false
    
    var body: some View {
        List {
            Group {
                if viewModel.quotes.isEmpty {
                    EmptyQuotesView()
                } else {
                    QuotesList(quotes: viewModel.quotes, isEditMode: $isEditMode, isAllSelected: $isAllSelected)
                }
            }
        }
        .navigationTitle(NSLocalizedString("quotes.title", comment: "Quotes title"))
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text(NSLocalizedString("export.generating", comment: "Generating newspaper style"))
                            .foregroundColor(.white)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .toolbar {
            if !viewModel.quotes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditMode ? NSLocalizedString("quotes.done", comment: "Done") : NSLocalizedString("quotes.edit", comment: "Edit")) {
                        withAnimation {
                            isEditMode.toggle()
                            if !isEditMode {
                                // 退出编辑模式时重置选择状态
                                isAllSelected = false
                                viewModel.resetSelection()
                            }
                        }
                    }
                }
                
                if isEditMode {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(isAllSelected ? NSLocalizedString("quotes.deselect_all", comment: "Deselect All") : NSLocalizedString("quotes.select_all", comment: "Select All")) {
                            withAnimation {
                                isAllSelected.toggle()
                                viewModel.toggleSelectAll(isAllSelected)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        if viewModel.hasSelectedQuotes {
                            HStack {
                                Spacer()
                                
                                Button(role: .destructive) {
                                    viewModel.deleteSelectedQuotes()
                                    if viewModel.quotes.isEmpty {
                                        isEditMode = false
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text(NSLocalizedString("quotes.delete_selected", comment: "Delete Selected"))
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Spacer()
                                    .frame(width: 20)
                                
                                Button {
                                    exportSelectedQuotes()
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(NSLocalizedString("share.button", comment: "Share"))
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isExporting)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    private func exportSelectedQuotes() {
        let selectedQuotes = viewModel.quotes.filter { $0.isSelected }
        
        withAnimation {
            isExporting = true
        }
        
        ExportManager.shared.generateNewspaperImage(from: selectedQuotes) { result in
            withAnimation {
                isExporting = false
            }
            
            switch result {
            case .success(let image):
                // 显示成功提示
                ToastManager.shared.showSuccess(
                    NSLocalizedString("export.success.title", comment: "Export success"),
                    message: NSLocalizedString("export.success.message", comment: "Export success message")
                )
                
                // 显示分享菜单
                let activityVC = UIActivityViewController(
                    activityItems: [image],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let viewController = window.rootViewController {
                    viewController.present(activityVC, animated: true)
                }
                
            case .failure(let error):
                // 显示错误提示
                ToastManager.shared.showError(
                    NSLocalizedString("export.error.title", comment: "Export error"),
                    message: String(format: NSLocalizedString("export.error.message", comment: "Export error message"), 
                                  error.localizedDescription)
                )
            }
        }
    }
}

private struct EmptyQuotesView: View {
    var body: some View {
        ContentUnavailableView {
            Label(NSLocalizedString("quotes.save_quote", comment: "Save quotes title"), systemImage: "quote.bubble")
                .font(.title2)
        } description: {
            VStack(spacing: 12) {
                Text(NSLocalizedString("quotes.save_instruction", comment: "Save quotes instruction"))
                Text(NSLocalizedString("quotes.saved_display", comment: "Saved quotes display"))
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

private struct QuotesList: View {
    let quotes: [Quote]
    @Binding var isEditMode: Bool
    @Binding var isAllSelected: Bool
    @EnvironmentObject private var viewModel: QuotesViewModel
    
    var body: some View {
        ForEach(quotes) { quote in
            HStack {
                if isEditMode {
                    Button {
                        withAnimation {
                            viewModel.toggleQuoteSelection(quote)
                            isAllSelected = viewModel.areAllQuotesSelected
                        }
                    } label: {
                        Image(systemName: quote.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(quote.isSelected ? .accentColor : .secondary)
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
                
                QuoteRowView(quote: quote)
                    .contentShape(Rectangle())
                    .background(
                        NavigationLink(destination: QuoteDetailView(quote: quote)) {
                            EmptyView()
                        }
                        .opacity(0)
                        .disabled(isEditMode)
                    )
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !isEditMode {
                    Button(role: .destructive) {
                        if let index = viewModel.quotes.firstIndex(where: { $0.id == quote.id }) {
                            viewModel.deleteQuotes(at: IndexSet([index]))
                        }
                    } label: {
                        VStack {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text(NSLocalizedString("quotes.delete", comment: "Delete quote"))
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
    }
} 