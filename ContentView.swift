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
    @State private var appLists: [[AppInfo]] = [[]] // Khởi tạo mảng con trống
    @EnvironmentObject var downloadManager: DownloadManager // Injected downloadManager
    @State private var apiURLString = ""
    @State private var apiURLStrings = ["https://dunkeyyfong.click/repo.json"] // Một danh sách các liên kết API mặc định

    var body: some View {
        TabView {
            ForEach(apiURLStrings.indices, id: \.self) { index in
                NavigationView {
                    List(appLists[index], id: \.id) { app in
                        NavigationLink(destination: DetailView(appInfo: app, downloadManager: _downloadManager)) {
                            ListCellRow(appInfo: app)
                        }
                    }
                    .navigationBarTitle("App List")
                    .onAppear {
                        loadAppList(from: apiURLStrings[index], into: index)
                    }
                }
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Danh sách \(index + 1)")
                }
            }

            VStack {
                TextField("Nhập liên kết API", text: $apiURLString)
                    .padding()
                Button(action: {
                    addAPI(apiURLString)
                }) {
                    Text("Thêm API")
                        .padding()
                }
                Spacer()
            }
            .tabItem {
                Image(systemName: "arrow.down.doc")
                Text("Tải từ API")
            }
        }
    }

    private func loadAppList(from apiURLString: String, into index: Int) {
        guard let url = URL(string: apiURLString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let appListData = try JSONDecoder().decode(AppList.self, from: data)
                    DispatchQueue.main.async {
                        // Sử dụng index để lưu danh sách ứng dụng vào mảng tương ứng
                        while appLists.count <= index {
                            appLists.append([])
                        }
                        appLists[index] = appListData.apps
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }

    private func addAPI(_ apiURLString: String) {
        apiURLStrings.append(apiURLString)
        appLists.append([]) // Thêm một mảng con trống tương ứng với liên kết API mới
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

