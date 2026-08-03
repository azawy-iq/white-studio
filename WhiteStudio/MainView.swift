import SwiftUI
import AVKit
import PhotosUI

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            // خلفية متدرجة عميقة وعصرية تمنح تباثاً للثيم الزجاجي
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), Color.black, Color(red: 0.05, green: 0.03, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                // شريط التنقل العلوي الزجاجي (مؤمن أسفل النوتش)
                HStack {
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
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
                        showExportAlert = true
                        viewModel.exportProject()
                    }) {
                        Text("EXPORT")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                            .foregroundColor(.white)
                    }
                    .alert("تصدير المشروع", isPresented: $showExportAlert) {
                        Button("حفظ في الاستوديو", role: .cancel) { }
                    } message: {
                        Text("تم معالجة وتصدير الفيديو بنجاح بدقة عالية!")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 12)
                .padding(.top, 44) // لحماية العناصر من التداخل مع النوتش والجزيرة الديناميكية

                // مساحة العرض الرئيسية (Canvas) - زجاجية بالكامل وبدون حواف سوداء
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)

                    if let player = viewModel.currentPlayer {
                        VideoPlayer(player: player)
                            .aspectRatio(contentMode: .fill)
                            .cornerRadius(20)
                            .clipped()
                            .padding(4)
                    } else if let image = viewModel.currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .cornerRadius(20)
                            .clipped()
                            .padding(4)
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.5))
                            Text("أضف مقاطع فيديو أو صور لبدء الإبداع")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // طبقة الكلمات التلقائية أو الترجمة فوق الميديا بخلفية شفافة
                    VStack {
                        Spacer()
                        if !viewModel.currentSubtitle.isEmpty {
                            Text(viewModel.currentSubtitle)
                                .font(.custom("MTLombardiaScribble", size: 22))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25), lineWidth: 1))
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)
                        }
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 12)

                // شريط التايملاين وإدارة المقاطع متعددة الطبقات
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 75, height: 45)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.25), lineWidth: 1))
                                        .overlay(
                                            Text("مقطع \(index + 1)")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        )

                                    Button(action: { viewModel.removeMedia(at: index) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.system(size: 14))
                                            .background(Circle().fill(.ultraThinMaterial))
                                    }
                                    .offset(x: 5, y: -5)
                                }
                            }

                            // زر إضافة مقطع أو صورة جديدة
                            PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 75, height: 45)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    )
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
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
                    .frame(height: 55)

                    // شريط الأدوات الاحترافي السفلي (زجاجي بالكامل ومفعل بالكامل)
                    HStack(spacing: 18) {
                        ToolButton(icon: "scissors", label: "القص والمدة") {
                            viewModel.activeTool = .duration
                        }
                        ToolButton(icon: "wand.and.rays", label: "العزل والفلتر") {
                            viewModel.toggleIsolation()
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
                    .padding(.vertical, 12)
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
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// نافذة الإعدادات لتفعيل خيار الإعدادات بالكامل
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isHDExport") private var isHDExport = true
    @AppStorage("autoSubtitles") private var autoSubtitles = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("إعدادات التطبيق")) {
                    Toggle("تصدير بجودة عالية (4K/HD)", isOn: $isHDExport)
                    Toggle("التوليد التلقائي للكلمات", isOn: $autoSubtitles)
                }
                Section(header: Text("حول التطبيق")) {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.0 (White Studio)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("تم") { dismiss() }
            }
        }
    }
}
