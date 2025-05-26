import SwiftUI
import UniformTypeIdentifiers

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var isAddNotePresented = false
    @State private var showKeychainDemo = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主列表
                List {
                    ForEach(viewModel.notes) { note in
                        NoteRow(note: note, image: viewModel.getAttachmentImage(for: note))
                            .swipeActions {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteNote(note)
                                    }
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                
                // 載入中顯示
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
                
                // 沒有筆記時顯示
                if !viewModel.isLoading && viewModel.notes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("尚未有任何筆記")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Button {
                            isAddNotePresented = true
                        } label: {
                            Text("新增第一則筆記")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // 錯誤訊息顯示
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("錯誤")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button {
                            viewModel.errorMessage = nil
                        } label: {
                            Text("關閉")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()
                }
                
            }
            .navigationTitle("我的筆記")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.toggleTheme()
                    } label: {
                        Image(systemName: viewModel.isDarkMode ? "sun.max.fill" : "moon.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showKeychainDemo = true
                        } label: {
                            Image(systemName: "key.fill")
                        }
                        
                        Button {
                            isAddNotePresented = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "搜尋筆記")
            .refreshable {
                viewModel.loadNotes(searchText: viewModel.searchText)
            }
            .sheet(isPresented: $isAddNotePresented) {
                AddNoteView(viewModel: viewModel)
            }
            .sheet(isPresented: $showKeychainDemo) {
                KeychainDemoView()
            }
            .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        }
    }
}

// 系統分享表單的包裝器
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
