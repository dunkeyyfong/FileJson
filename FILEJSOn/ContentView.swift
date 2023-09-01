import SwiftUI
import UIKit
import QuickLook
import Combine

class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var downloadProgress: Double = 0.0
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handle the downloaded file here if needed
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
}

struct ContentView: View {
    @State private var appList: [AppInfo] = []
        @EnvironmentObject var downloadManager: DownloadManager // Injected downloadManager

        var body: some View {
            NavigationView {
                List(appList) { app in
                    NavigationLink(destination: DetailView(appInfo: app, downloadManager: _downloadManager)) {
                        ListCellRow(appInfo: app)
                    }
                }
                .navigationBarTitle("App List")
                .onAppear(perform: loadAppList)
            }
        }
    
    private func loadAppList() {
        guard let url = URL(string: "https://dunkeyyfong.click/repo.json") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let appListData = try JSONDecoder().decode(AppList.self, from: data)
                    DispatchQueue.main.async {
                        self.appList = appListData.apps
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
}

struct ListCellRow: View {
    let appInfo: AppInfo
    
    var body: some View {
        HStack {
            if let iconURL = appInfo.iconURL, let url = URL(string: iconURL), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "square.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading) {
                Text(appInfo.name)
                    .font(.headline)
                Text(appInfo.versionDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

import SwiftUI

struct DetailView: View {
    let appInfo: AppInfo
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        VStack {
            if let iconURL = appInfo.iconURL, let url = URL(string: iconURL ?? "") {
                URLImage(url: url)
                    .frame(width: 100, height: 100)
            } else {
                Image(systemName: "square.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
            }

            Text(appInfo.name)
                .font(.title)

            Text(appInfo.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                openDownloadURL()
            }) {
                Text("Tải về")
            }
        }
        .padding()
        .navigationBarTitle("App Detail")
    }

    private func openDownloadURL() {
        guard let url = URL(string: appInfo.downloadURL) else { return }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // Xử lý khi không thể mở URL
            showURLNotSupportedAlert()
        }
    }


    private func showURLNotSupportedAlert() {
        let alert = UIAlertController(title: "Lỗi", message: "Không thể mở đường dẫn tải về.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Đóng", style: .default, handler: nil))

        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }

}

struct URLImage: View {
    let url: URL
    @StateObject private var imageLoader = ImageLoader()

    var body: some View {
        Image(uiImage: imageLoader.image ?? UIImage(systemName: "square.fill")!)
            .resizable()
            .frame(width: 100, height: 100)
            .onAppear {
                imageLoader.loadImage(from: url)
            }
    }
}

class ImageLoader: ObservableObject {
    @Published var image: UIImage?

    private var cancellable: AnyCancellable?

    func loadImage(from url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

