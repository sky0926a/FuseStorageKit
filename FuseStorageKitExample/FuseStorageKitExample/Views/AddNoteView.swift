import SwiftUI
import PhotosUI

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NotesViewModel
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("筆記內容")) {
                    TextField("標題", text: $title)
                        .focused($isTitleFocused)
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("內容")
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 150)
                    }
                }
                
                Section(header: Text("附件")) {
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        HStack {
                            Label(
                                selectedImage == nil ? "新增圖片" : "更換圖片",
                                systemImage: "photo"
                            )
                            Spacer()
                            if selectedImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(8)
                            .padding(.vertical)
                            
                        Button("移除圖片", role: .destructive) {
                            self.selectedImage = nil
                        }
                    }
                }
            }
            .navigationTitle("新增筆記")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveNote()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                isTitleFocused = true
            }
        }
    }
    
    private func saveNote() {
        viewModel.saveNote(title: title, content: content, image: selectedImage)
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
} 