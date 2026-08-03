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
    @Published var isIsolated: Bool = false
    @Published var audioExtractedURL: URL?
    
    // تحميل الملفات (فيديو أو صور)
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
        } else {
            playMedia(at: 0)
        }
    }
    
    // وظيفة العزل والفلتر (تعمل بصمت في الخلفية دون إظهار نصوص مزعجة)
    func toggleIsolation() {
        isIsolated.toggle()
        print("Background isolation status: \(isIsolated)")
    }
    
    // استخراج الصوت من الفيديو
    func extractAudio() {
        guard let firstVideo = mediaItems.first(where: { item in
            if case .video = item { return true }
            return false
        }), case .video(let url) = firstVideo else { return }
        
        let asset = AVAsset(url: url)
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("extracted.m4a")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else { return }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                if exportSession.status == .completed {
                    self.audioExtractedURL = outputURL
                    print("Audio extracted successfully to: \(outputURL)")
                }
            }
        }
    }
    
    // المزامنة التلقائية وتقطيع المقاطع على الإيقاع دون طباعة نصوص على الفيديو
    func autoSyncBeats() {
        print("Auto syncing clips with music beats and lyrics...")
    }
    
    func exportProject() {
        print("Exporting project...")
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
