import Foundation
import SwiftUI
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isDarkMode: Bool = false
    @Published var isExporting: Bool = false
    @Published var exportedZipURL: URL?
    @Published var showShareSheet: Bool = false
    
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
    
    // MARK: - 匯出與分享功能
    
    /// 創建文件備份並準備共享
    func prepareNotesExport() {
        // 確保上一次匯出已清理完畢
        if isExporting {
            return
        }
        
        // 清除先前設置的 URL
        exportedZipURL = nil
        showShareSheet = false
        
        isExporting = true
        errorMessage = nil
        
        DispatchQueue.global().async { [weak self] in
            do {
                let zipURL = try AppStorage.shared.createNotesZipArchive()
                
                // 確認文件已存在並可訪問
                let fileManager = FileManager.default
                guard fileManager.fileExists(atPath: zipURL.path),
                      fileManager.isReadableFile(atPath: zipURL.path) else {
                    throw NSError(domain: "ExportError", code: -1, 
                                 userInfo: [NSLocalizedDescriptionKey: "無法訪問創建的 ZIP 文件"])
                }
                
                // 檢查文件大小
                let attributes = try fileManager.attributesOfItem(atPath: zipURL.path)
                guard let fileSize = attributes[.size] as? NSNumber,
                      fileSize.intValue > 0 else {
                    throw NSError(domain: "ExportError", code: -2, 
                                 userInfo: [NSLocalizedDescriptionKey: "創建的 ZIP 文件無效或為空"])
                }
                
                DispatchQueue.main.async {
                    self?.exportedZipURL = zipURL
                    self?.isExporting = false
                    self?.showShareSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    print("備份錯誤: \(error)")
                    
                    let errorDescription: String
                    let nsError = error as NSError
                    errorDescription = "創建文件備份失敗 (錯誤代碼: \(nsError.code)): \(nsError.localizedDescription)"
                    
                    self?.errorMessage = errorDescription
                    self?.isExporting = false
                    self?.exportedZipURL = nil
                }
            }
        }
    }
    
    /// 清理导出的 ZIP 文件
    func cleanupExportedFile() {
        if let url = exportedZipURL {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("清理臨時檔案失敗: \(error)")
            }
        }
        exportedZipURL = nil
    }
}
