import FuseStorageKit
import Foundation

// Simple Note model based on the actual Example App
struct Note: FuseDatabaseRecord {
    static var _fuseidField: String = "id"
    static var databaseTableName: String = "notes"
    
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let hasAttachment: Bool
    let attachmentPath: String?
    
    init(id: String = UUID().uuidString, 
         title: String, 
         content: String, 
         createdAt: Date = Date(),
         hasAttachment: Bool = false,
         attachmentPath: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.hasAttachment = hasAttachment
        self.attachmentPath = attachmentPath
    }
    
    static func tableDefinition() -> FuseTableDefinition {
        return FuseTableDefinition(
            name: databaseTableName,
            columns: [
                FuseColumnDefinition(name: "id", type: .text, isPrimaryKey: true, isNotNull: true),
                FuseColumnDefinition(name: "title", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "content", type: .text, isNotNull: true),
                FuseColumnDefinition(name: "createdAt", type: .date, isNotNull: true),
                FuseColumnDefinition(name: "hasAttachment", type: .boolean, isNotNull: true, defaultValue: "0"),
                FuseColumnDefinition(name: "attachmentPath", type: .text)
            ]
        )
    }
}

// Usage example: Note taking app
func noteAppExample() throws {
    // 1. Build storage
    let storage = try FuseStorageBuilder()
        .with(database: .sqlite("notes.db"))
        .with(file: .document("NoteAttachments"))
        .build()
    
    let database = storage.db(.sqlite("notes.db"))!
    let fileManager = storage.file(.document("NoteAttachments"))!
    
    // 2. Create table
    try database.createTable(Note.tableDefinition())
    
    // 3. Create notes
    let note1 = Note(title: "Meeting Notes", content: "Important meeting discussion points...")
    let note2 = Note(title: "Shopping List", content: "Milk, Bread, Eggs")
    let note3 = Note(title: "Project Ideas", content: "New app features to implement")
    
    // 4. Save notes
    try database.add([note1, note2, note3])
    print("✅ Saved 3 notes")
    
    // 5. Fetch all notes
    let allNotes: [Note] = try database.fetch(
        of: Note.self,
        filters: [],
        sort: FuseQuerySort(field: "createdAt", order: .descending),
        limit: nil,
        offset: nil
    )
    print("📝 Total notes: \(allNotes.count)")
    
    // 6. Search notes by title
    let searchResults: [Note] = try database.fetch(
        of: Note.self,
        filters: [FuseQueryFilter.like(field: "title", value: "%Meeting%")],
        sort: nil,
        limit: nil,
        offset: nil
    )
    print("🔍 Found \(searchResults.count) notes matching 'Meeting'")
    
    // 7. Save attachment for a note
    let attachmentData = "Sample attachment content".data(using: .utf8)!
    let attachmentURL = try fileManager.save(
        data: attachmentData, 
        relativePath: "attachments/\(note1.id)/document.txt"
    )
    print("📎 Attachment saved to: \(attachmentURL)")
    
    // 8. Update note with attachment
    let updatedNote = Note(
        id: note1.id,
        title: note1.title,
        content: note1.content,
        createdAt: note1.createdAt,
        hasAttachment: true,
        attachmentPath: "attachments/\(note1.id)/document.txt"
    )
    try database.add(updatedNote)  // This will update the existing note
    print("✏️ Note updated with attachment")
    
    // 9. Delete a note
    try database.delete(note2)
    print("🗑️ Deleted note: \(note2.title)")
    
    print("Note app example completed successfully!")
} 