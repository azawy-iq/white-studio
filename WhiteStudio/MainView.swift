import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            // خلفية سوداء تملأ الشاشة بالكامل لتجنب أي حواف سوداء
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 1. شريط التنقل العلوي الزجاجي (محمي أسفل النوتش والجزيرة الديناميكية)
                    HStack {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .sheet(isPresented: $showSettings) {
                            SettingsView()
                        }

                        Spacer()

                        Text("WHITE STUDIO")
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            viewModel.exportProject()
                            showExportAlert = true
                        }) {
                            Text("EXPORT")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundColor(.white)
                        }
                        .alert("تصدير الفيديو", isPresented: $showExportAlert) {
                            Button("موافق", role: .cancel) { }
                        } message: {
                            Text("تم تصدير الفيديو بجودة عالية ونظيف بدون حواف!")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, geometry.safeAreaInsets.top)
                    .background(.ultraThinMaterial)

                    // 2. مساحة عرض الفيديو الأساسية (ملء الشاشة بالكامل وبدون حواف سوداء أو إطارات مصغرة)
                    ZStack {
                        if let player = viewModel.currentPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                                .clipped()
                                .edgesIgnoringSafeArea(.horizontal)
                        } else if let image = viewModel.currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                                .clipped()
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 45))
                                    .foregroundColor(.white.opacity(0.4))
                                Text("اضغط على (+) لإضافة مقطع فيديو أو صورة")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.62)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.05))
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // 3. شريط التايملاين والأدوات السفلي
                    VStack(spacing: 8) {
                        // شريط المقاطع
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 70, height: 45)
                                            .overlay(
                                                Text("مقطع \(index + 1)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )

                                        Button(action: { viewModel.removeMedia(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14))
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                    .onTapGesture { viewModel.playMedia(at: index) }
                                }

                                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 70, height: 45)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                        )
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16))
                                        )
                                }
                                .onChange(of: viewModel.selectedItem) { newItem in
                                    Task { await viewModel.loadMedia(from: newItem) }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .frame(height: 50)

                        // 4. شريط الأدوات السفلي التفاعلي الحقيقي (بدون أي نصوص مزعجة)
                        HStack(spacing: 14) {
                            ToolButton(icon: "scissors", label: "القص والمدة") {
                                viewModel.activeTool = .duration
                            }
                            ToolButton(icon: "wand.and.rays", label: "العزل والفلتر") {
                                viewModel.activeTool = .isolation
                                viewModel.toggleIsolation()
                            }
                            ToolButton(icon: "textformat", label: "الخطوط والكلام") {
                                viewModel.activeTool = .lyrics
                            }
                            ToolButton(icon: "waveform", label: "استخراج الصوت") {
                                viewModel.extractAudio()
                            }
                            ToolButton(icon: "sparkles", label: "مزامنة تلقائية") {
                                viewModel.autoSyncBeats()
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
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
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hdExport") var hdExport = true

    var body: some View {
        NavigationView {
            Form {
                Toggle("تصدير بجودة عالية (HD)", isOn: $hdExport)
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("تم") { dismiss() } }
        }
    }
}
