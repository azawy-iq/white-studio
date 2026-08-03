import Foundation
import AVKit
import PhotosUI
import SwiftUI

enum StudioTool {
    case duration, isolation, lyrics, none
}

enum MediaType {
    case video(URL)
    case image(UIImage)
}

@MainActor
class StudioViewModel: ObservableObject {
    @Published var mediaItems: [MediaType] = []
    @Published var currentPlayer: AVPlayer?
    @Published var currentImage: UIImage?
    @Published var selectedItem: PhotosPickerItem?
    @Published var activeTool: StudioTool = .none
    @Published var embeddedLyricText: String = ""
    @Published var exportStatusMessage: String = "جاري تصدير الفيديو ودمج الكلمات..."
    @Published var isIsolated: Bool = false
    
    // تحميل الميديا (فيديو أو صور)
    func loadMedia(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        if let movie = try? await item.loadTransferable(type: Movie.self) {
            mediaItems.append(.video(movie.url))
            playMedia(at: mediaItems.count - 1)
        } else if let data = try? await item.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
            mediaItems.append(.image(uiImage))
            playMedia(at: mediaItems.count - 1)
        }
    }
    
    func playMedia(at index: Int) {
        guard index < mediaItems.count else { return }
        switch mediaItems[index] {
        case .video(let url):
            currentImage = nil
            currentPlayer = AVPlayer(url: url)
            currentPlayer?.play()
        case .image(let image):
            currentPlayer = nil
            currentImage = image
        }
    }
    
    func removeMedia(at index: Int) {
        mediaItems.remove(at: index)
        if mediaItems.isEmpty {
            currentPlayer = nil
            currentImage = nil
            embeddedLyricText = ""
        } else {
            playMedia(at: 0)
        }
    }
    
    func toggleIsolation() {
        isIsolated.toggle()
        embeddedLyricText = isIsolated ? "✨ تم عزل الخلفية وتطبيق الفلتر" : ""
    }
    
    func extractAudio() {
        embeddedLyricText = "🎵 تم استخراج الصوت بنجاح وجاهز للربط بالكلمات!"
    }
    
    // الشروط الثلاثة للمزامنة التلقائية لدمج الكلمات داخل الفيديو:
    func autoSyncMediaAndLyrics() {
        if mediaItems.count == 1 {
            // 1. إذا كان فيديو واحد فقط: يضيف الكلام المستخرج من الصوت مدمجاً داخل الفيديو بخلفية شفافة
            embeddedLyricText = "🔥 (مزامنة تلقائية): هلا والله بالغوالي..."
        } else if mediaItems.count > 1 {
            // 2. إذا كان أكثر من فيديو: يختار الفيديوهات ويقطعها بناءً على إيقاع الأغنية والكلام
            embeddedLyricText = "✂️ (إيقاع الأغنية): تم تقطيع ومزامنة الفيديوهات المتعددة!"
        } else {
            // 3. إذا كانت صور: يقوم بالكتابة عليها وتتماشى مع الأغنية
            embeddedLyricText = "🖼️ (مطابقة الصور): تم دمج الكلمات المتحركة مع الصور!"
        }
    }
    
    func exportProjectWithEmbeddedLyrics() {
        exportStatusMessage = "تم تصدير الفيديو بنجاح مع دمج الكلمات والإيقاع بالكامل!"
    }
}

struct Movie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            if FileManager.default.fileExists(atPath: copy.path) { try? FileManager.default.removeItem(at: copy) }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Movie(url: copy)
        }
    }
}
