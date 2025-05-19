// VideoPlayerView.swift
import SwiftUI
import AVKit // For VideoPlayer

struct VideoPlayerView: View {
    let videoURL: URL
    @Binding var isPresented: Bool // To allow custom dismiss

    var body: some View {
        VStack {
            HStack {
                Text("Playing Video") // Optional Title
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false // Dismiss the sheet
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            VideoPlayer(player: AVPlayer(url: videoURL))
                .onAppear {
                    print("VideoPlayerView: Playing from URL: \(videoURL.absoluteString)")
                }
        }
    }
}


struct VideoPlayerView_Previews: PreviewProvider {
    // Create a sample URL (ensure this URL works or use a local asset for preview)
    static let sampleURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")

    // Create a @State variable for the preview's binding
    // This wrapper is needed because previews are static contexts.
    struct PreviewWrapper: View {
        @State var isSheetPresented: Bool = true // Start presented for preview
        let url: URL?

        var body: some View {
            if let url = url {
                VideoPlayerView(videoURL: url, isPresented: $isSheetPresented)
            } else {
                Text("Sample video URL for preview is invalid.")
            }
        }
    }
    
    static var previews: some View {
        // Use the wrapper to provide the @State for the binding
        PreviewWrapper(url: sampleURL)
        // Or if you want to test the "no URL" case, though VideoPlayerView expects a non-optional URL
        // PreviewWrapper(url: nil)
    }
}
