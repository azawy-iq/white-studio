import SwiftUI
import AVKit
import PhotosUI

// تأكد من إضافة هذا الخط إلى ملف Info.plist الخاص بك لدعم الخطوط المخصصة
// UIAppFonts -> MTLombardiaScribble.otf (اسم ملف الخط التقريبي)

struct MainView: View {
    @StateObject private var viewModel = StudioViewModel()
    @State private var showSettings = false
    @State private var showExportAlert = false

    var body: some View {
        ZStack {
            // الخلفية: صورة من الفيديو الحالي مع تأثير ضبابي وتعتيم
            if let player = viewModel.currentPlayer {
                ZStack {
                    VideoPlayer(player: player)
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 40)
                    // طبقة تعتيم لضمان وضوح الواجهة
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                }
            } else {
                // خلفية سوداء صلبة في حال عدم وجود فيديو
                Color.black.edgesIgnoringSafeArea(.all)
            }

            // المحتوى الأساسي للواجهة
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 1. شريط التنقل العلوي (زجاجي ومحمي أسفل النوتش)
                    HStack {
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 17))
                                .frame(width: 38, height: 38)
                                .background(Material.thinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                        }
                        .sheet(isPresented: $showSettings) {
                            SettingsView()
                        }

                        Spacer()

                        Text("WHITE STUDIO")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .tracking(3.5)
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            viewModel.exportProject()
                            showExportAlert = true
                        }) {
                            Text("EXPORT")
                                .font(.system(size: 13, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Material.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                                .foregroundColor(.white)
                        }
                        .alert("تصدير المشروع", isPresented: $showExportAlert) {
                            Button("موافق", role: .cancel) { }
                        } message: {
                            Text(viewModel.exportMessage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    // هذا الحشو (padding) هو مفتاح الحماية من النوتش
                    .padding(.top, geometry.safeAreaInsets.top) 
                    .background(Material.ultraThinMaterial)
                    .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.white.opacity(0.1)), alignment: .bottom)

                    Spacer()

                    // 2. مساحة العرض الرئيسية (Canvas) - ملء الشاشة بالكامل
                    ZStack(alignment: .bottom) {
                        // مشغل الفيديو الرئيسي (يملأ المساحة بالكامل)
                        if let player = viewModel.currentPlayer {
                            VideoPlayer(player: player)
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.55) // نسبة ذهبية للكاميرا
                                .clipped()
                                // إزالة الحدود الدائرية السابقة لجعلها ملء الشاشة الحقيقي
                        } else if let image = viewModel.currentImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.55)
                                .clipped()
                        } else {
                            // شاشة فارغة جذابة
                            VStack(spacing: 15) {
                                Image(systemName: "video.fill.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("أضف مقطع فيديو أو صورة للبدء")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.55)
                            .background(Color.black.opacity(0.2))
                        }

                        // طبقة عرض الكلام/الترجمة (فوق الفيديو بخلفية شفافة زجاجية)
                        if !viewModel.currentSubtitle.isEmpty {
                            Text(viewModel.currentSubtitle)
                                // استخدمت خطاً مشابهاً لـ Video Star المكتوب باليد (تأكد من إضافته للمشروع)
                                .font(.custom("MTLombardiaScribble", size: 24)) 
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Material.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                                .padding(.bottom, 20)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    // تمكين المساحة لتكون مرنة
                    .frame(maxHeight: .infinity)

                    Spacer()

                    // 3. شريط التايملاين وإدارة الطبقات (زجاجي)
                    VStack(spacing: 10) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.mediaItems.indices, id: \.self) { index in
                                    ZStack(alignment: .topTrailing) {
                                        // صورة مصغرة من الفيديو
                                        if case .video(let url) = viewModel.mediaItems[index] {
                                            VideoThumbView(url: url)
                                                .frame(width: 80, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else if case .image(let image) = viewModel.mediaItems[index] {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 50)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }

                                        // رقم المقطع
                                        Text("\(index + 1)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(4)
                                            .background(Color.white.opacity(0.8))
                                            .clipShape(Circle())
                                            .offset(x: -4, y: 4)

                                        // زر الحذف
                                        Button(action: { viewModel.removeMedia(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red.opacity(0.8))
                                                .font(.system(size: 16))
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                                    .onTapGesture {
                                        viewModel.playMedia(at: index)
                                    }
                                    // تأثير تحديد المقطع النشط
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(viewModel.currentIndex == index ? Color.white : Color.clear, lineWidth: 2))
                                }

                                // زر الإضافة (+)
                                PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.videos, .images])) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Material.thinMaterial)
                                        .frame(width: 80, height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        )
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.white.opacity(0.7))
                                                .font(.system(size: 22))
                                        )
                                }
                                .onChange(of: viewModel.selectedItem) { newItem in
                                    Task { await viewModel.loadMedia(from: newItem) }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        .background(Material.thinMaterial)

                        // 4. شريط الأدوات الاحترافي (زجاجي بالكامل ومفعل تماماً)
                        HStack(spacing: 12) {
                            ToolButton(icon: "scissors", label: "القص والمدة") { viewModel.activeTool = .duration }
                            ToolButton(icon: "wand.and.rays.inverse", label: "العزل والفلتر") { viewModel.toggleIsolation() }
                            ToolButton(icon: "textformat.alt", label: "الخطوط والكلام") { viewModel.activeTool = .lyrics }
                            ToolButton(icon: "waveform.path.ecg", label: "استخراج الصوت") { viewModel.extractAudioFromVideo() }
                            ToolButton(icon: "sparkles.square.filled.on.square", label: "مزامنة تلقائية") { viewModel.autoGenerateLyricsAndDialect() }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    }
                    .background(Material.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom) // تمديد الشريط السفلي خلف شريط الإيماءات
                }
            }
        }
        .statusBarHidden(false) // إظهار شريط الحالة (الساعة والبطارية) لتبدو كـ Native App
    }
}

// مساعد لعرض الصورة المصغرة للفيديو في التايملاين
struct VideoThumbView: View {
    let url: URL
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black.opacity(0.3)
                    .onAppear {
                        generateThumbnail()
                    }
            }
        }
    }

    func generateThumbnail() {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.5, preferredTimescale: 60)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                DispatchQueue.main.async {
                    self.image = UIImage(cgImage: cgImage)
                }
            } catch {
                print("Error generating thumbnail: \(error)")
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
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Material.thinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity) // توزيع الأزرار بالتساوي
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isHDExport") private var isHDExport = true
    @AppStorage("autoSubtitles") private var autoSubtitles = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("إعدادات التصدير")) {
                    Toggle("تصدير بجودة عالية (4K/HD)", isOn: $isHDExport)
                }
                Section(header: Text("إعدادات الكلام")) {
                    Toggle("التوليد التلقائي للكلمات والترجمة", isOn: $autoSubtitles)
                }
                Section(header: Text("معلومات")) {
                    HStack {
                        Text("الإصدار")
                        Spacer()
                        Text("1.1 (White Studio)")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }
}
