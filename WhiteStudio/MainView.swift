import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Animated gradient background instead of flat black — glass needs depth behind it
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color.black, Color(red: 0.08, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Top Glass Navigation Bar
                HStack {
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    }

                    Spacer()

                    Text("WHITE STUDIO")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { viewModel.exportProject() }) {
                        Text("EXPORT")
                            .font(.system(size: 13, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal, 10)
                .padding(.top, 8)

                // Canvas / Preview Area — glass panel
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)

                    if let player = viewModel.currentPlayer {
                        VideoPlayer(player: player)
                            .cornerRadius(18)
                            .padding(6)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.6))
                            Text("أضف مقاطع فيديو أو صور لبدء الإبداع")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Overlay active text elements / lyrics
                    VStack {
                        Spacer()
                        Text(viewModel.currentSubtitle)
                            .font(.custom("MTLombardiaScribble", size: 26))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 10)

                // Timeline & Multi-clip / Layer Management
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.clips.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 80, height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                        .overlay(
                                            Text("مقطع \(index + 1)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                        )

                                    Button(action: { viewModel.removeClip(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 15))
                                            .background(Circle().fill(.ultraThinMaterial).frame(width: 16, height: 16))
                                    }
                                    .offset(x: 6, y: -6)
                                }
                            }

                            // Add Clip Button
                            PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 80, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    )
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

                    // Professional Tools Toolbar — glass card
                    HStack(spacing: 22) {
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
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}
