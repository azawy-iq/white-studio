import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Custom Navigation Bar (Video Star Style)
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                    
                    Spacer()
                    
                    Text("WHITE STUDIO")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { viewModel.exportProject() }) {
                        Text("EXPORT")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                
                // Canvas / Preview Area
                ZStack {
                    Rectangle()
                        .fill(Color(white: 0.04))
                    
                    if let player = viewModel.currentPlayer {
                        VideoPlayer(player: player)
                            .cornerRadius(12)
                            .padding(8)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("أضف مقاطع فيديو أو صور لبدء الإبداع")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Overlay active text elements / lyrics
                    VStack {
                        Spacer()
                        Text(viewModel.currentSubtitle)
                            .font(.custom("MTLombardiaScribble", size: 28))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 3, x: 0, y: 2)
                            .padding(.bottom, 40)
                    }
                }
                .frame(maxHeight: .infinity)
                .cornerRadius(16)
                .padding(10)
                
                // Timeline & Multi-clip / Layer Management
                VStack(spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.clips.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(white: 0.15))
                                        .frame(width: 80, height: 50)
                                        .overlay(
                                            Text("مقطع \(index + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Button(action: { viewModel.removeClip(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 14))
                                    }
                                    .offset(x: 5, y: -5)
                                }
                            }
                            
                            // Add Clip Button
                            PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundColor(.white)
                                    )
                            }
                            .onChange(of: viewModel.selectedItem) { newItem in
                                Task {
                                    await viewModel.loadMedia(from: newItem)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 65)
                    
                    // Professional Tools Toolbar (Video Star Style)
                    HStack(spacing: 24) {
                        ToolButton(icon: "scissors", label: "القص والمدة") {
                            viewModel.activeTool = .duration
                        }
                        ToolButton(icon: "wand.and.rays", label: "العزل والفلتر") {
                            viewModel.activeTool = .isolation
                        }
                        ToolButton(icon: "textformat", label: "الخطوط والكلام") {
                            viewModel.activeTool = .lyrics
                        }
                        ToolButton(icon: "waveform", label: "استخراج الصوت") {
                            viewModel.extractAudioFromVideo()
                        }
                        ToolButton(icon: "sparkles", label: "مزامنة تلقائية") {
                            viewModel.autoGenerateLyricsAndDialect()
                        }
                    }
                    .padding(.vertical, 10)
                    .background(Color(white: 0.08))
                }
            }
        }
    }
}

struct ToolButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
}
