import Foundation
import SwiftUI
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDarkMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 初始化主題設定
        self.isDarkMode = AppStorage.shared.getThemePreference()
        
        // 監聽搜尋文字變更
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.loadNotes(searchText: searchText)
            }
            .store(in: &cancellables)
        
        // 初始載入所有筆記
        loadNotes()
    }
    
    func loadNotes(searchText: String = "") {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global().async { [weak self] in
            do {
                let loadedNotes = try AppStorage.shared.getAllNotes(withTitle: searchText.isEmpty ? nil : searchText)
                
                DispatchQueue.main.async {
                    self?.notes = loadedNotes
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "載入筆記時發生錯誤: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }
        }
    }
    
    func saveNote(title: String, content: String, image: UIImage? = nil) {
        let newNote = Note(title: title, content: content)
        
        do {
            try AppStorage.shared.saveNote(newNote, image: image)
            loadNotes(searchText: searchText)
        } catch {
            errorMessage = "儲存筆記時發生錯誤: \(error.localizedDescription)"
        }
    }
    
    func deleteNote(_ note: Note) {
        do {
            try AppStorage.shared.deleteNote(note)
            
            // 從列表中移除已刪除的筆記
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes.remove(at: index)
            }
        } catch {
            errorMessage = "刪除筆記時發生錯誤: \(error.localizedDescription)"
        }
    }
    
    func getAttachmentImage(for note: Note) -> UIImage? {
        AppStorage.shared.getAttachmentImage(for: note)
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        AppStorage.shared.saveThemePreference(isDarkMode: isDarkMode)
    }
    
}
