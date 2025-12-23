// FunSaverFilterPreview.swift
// SwiftUI preview for visually testing FunSaverFilter with any image from disk
// Change the file path below to match the location of your test.jpg on your system
import SwiftUI
import UniformTypeIdentifiers

struct PhotoFilterPreview: View {
    @State private var original: UIImage?
    @State private var filtered: UIImage?
    private let filter = PhotoFilter()
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                VStack {
                    Text("Original")
                        .font(.caption).bold()
                    if let original {
                        Image(uiImage: original)
                            .resizable()
                            .scaledToFit()
                            .background(Color.gray.opacity(0.15))
                            .frame(maxWidth: 200, maxHeight: 300)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 200, height: 300)
                        Text("Place test.jpg at ~/Desktop/test.jpg")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                VStack {
                    Text("Filtered")
                        .font(.caption).bold()
                    if let filtered {
                        Image(uiImage: filtered)
                            .resizable()
                            .scaledToFit()
                            .background(Color.gray.opacity(0.15))
                            .frame(maxWidth: 200, maxHeight: 300)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.15)).frame(width: 200, height: 300)
                        Text("Place test.jpg at ~/Desktop/test.jpg")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            let path = "/Users/carlos/Desktop/test.jpg"
            if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let image = UIImage(data: data) {
                self.original = image
                self.filtered = filter.process(image: image)
            }
        }
    }
}

#Preview("PhotoFilterPreview") {
    PhotoFilterPreview()
}
