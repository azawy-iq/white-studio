import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            // خلفية زجاجية متدرجة تملأ الشاشة بالكامل لإلغاء أي حواف سوداء
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.1), Color.black, Color(red: 0.08, green: 0.05, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // شريط التنقل العلوي الزجاجي (مؤمن أسفل النوتش والجزيرة الديناميكية)
                    HStack {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .frame(width: 38, height: 38)
                                .background(.ultraThinMaterial, in: Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
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
                            viewModel.exportProjectWithEmbeddedLyrics()
                            showExportAlert = true
                        }) {
                            Text("EXPORT")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                .foregroundColor(.white)
                        }
                        .alert("تصدير الفيديو", isPresented: $showExportAlert) {
                            Button("موافق", role: .cancel) { }
                        } message: {
                            Text(viewModel.exportStatusMessage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .padding(.top, geometry.safeAreaInsets.top) // حماية النوتش
                    .background(.ultraThinMaterial)

                    // مساحة العرض الرئيسية (Canvas) - ملء الشاشة وبدون حواف
                    ZStack {
                        if let player = viewModel.currentPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.58)
                                .clipped()
                                .cornerRadius(16)
                                .padding(.horizontal, 8)
                        } else if let image = viewModel.currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.58)
                                .clipped()
                                .cornerRadius(16)
                                .padding(.horizontal, 8)
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .frame(width: geometry.size.width - 16, height: geometry.size.height * 0.58)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "sparkles.tv")
                                            .font(.system(size: 36))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("أضف فيديو أو صور لدمج الكلمات والإيقاع")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                )
                        }

                        // الكلمات المدمجة (تظهر كجزء من الفيديو وليست مجرد ترجمة خارجية)
                        if !viewModel.embeddedLyricText.isEmpty {
                            VStack {
                                Spacer()
                                Text(viewModel.embeddedLyricText)
                                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 3, x: 0, y: 2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
                                    .padding(.bottom, 40)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                    // شريط التايملاين والأدوات
                    VStack(spacing: 8) {
                        // شريط المقاطع المصغرة
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.ultraThinMaterial)
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
                                                .background(Circle().fill(.white))
                                        }
                                        .offset(x: 4, y: -4)
                                    }
                                    .onTapGesture { viewModel.playMedia(at: index) }
                                }

                                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 70, height: 45)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
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

                        // شريط الأدوات الزجاجي السفلي
                        HStack(spacing: 16) {
                            ToolButton(icon: "scissors", label: "القص والمدة") { viewModel.activeTool = .duration }
                            ToolButton(icon: "wand.and.rays", label: "العزل والفلتر") { viewModel.toggleIsolation() }
                            ToolButton(icon: "textformat", label: "الخطوط والكلام") { viewModel.activeTool = .lyrics }
                            ToolButton(icon: "waveform", label: "استخراج الصوت") { viewModel.extractAudio() }
                            ToolButton(icon: "sparkles", label: "مزامنة تلقائية") { viewModel.autoSyncMediaAndLyrics() }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
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
                Toggle("تصدير بجودة عالية جداً (HD)", isOn: $hdExport)
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("تم") { dismiss() } }
        }
    }
}
