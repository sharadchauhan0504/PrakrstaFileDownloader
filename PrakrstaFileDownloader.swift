//
//  PrakrstaFileDownloader.swift
//  UrlSessionExample
//
//  Created by Sharad on 31/03/18.
//  Copyright © 2018 Sharad. All rights reserved.
//

import UIKit

class DownloadData {
    var isDownloading: Bool?
    var isDownloaded: Bool?
    var percentDownloaded: Double?
}

class PrakrstaFileDownloader: NSObject {

    static let shared = PrakrstaFileDownloader()
    
    private var backgroundCompletionHandler: (() -> Void)?
    
    private var urlSession: URLSession! = nil
    
    var downloadTask:URLSessionDownloadTask!
    private var downloadProgressQueue =  [String: DownloadData]()
    var progressCallback: ((Double, String) -> Void)?
    var completionDownload: ((Bool, String) -> Void)?
    
    override init() {
        super.init()
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.company.identifier")
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func isDownloadQueued(url: String) -> Bool {
        return downloadProgressQueue.contains { $0.key == url }
    }
    
    func startDownload(url: String) {
        createDownloadObject(url: url)
        requestDownload(urlString: url)
    }
    
    func createDownloadObject(url: String) {
        let downloadData = DownloadData()
        downloadData.isDownloading = true
        downloadData.isDownloaded = false
        downloadData.percentDownloaded = 0.0
        let id = url.fileName()
        downloadProgressQueue[id] = downloadData
    }
    
    func requestDownload(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        downloadTask = urlSession.downloadTask(with: url)
        downloadTask.taskDescription = urlString
        downloadTask.resume()
    }
    
    func removeIdFromQueue(url: String) {
        if downloadProgressQueue.contains(where: {$0.key == url}){
            downloadProgressQueue.removeValue(forKey: url)
        }
    }
    
    func isDownloading(url: String) -> Bool{
        if !downloadProgressQueue.isEmpty {
            guard let progress = downloadProgressQueue[url]?.isDownloading else {return false}
            return progress
        }else{
            return false
        }
    }
    
    func getProgressFor(url: String) -> Double{
        if !downloadProgressQueue.isEmpty {
            guard let progress = downloadProgressQueue[url]?.percentDownloaded else { return 0.0 }
            return progress
        }else{
            return 0.0
        }
    }
    
    func cancelDownload(url: String){
        urlSession.getAllTasks { (urlSessionTasks) in
            for task in urlSessionTasks{
                if let taskDescription = task.taskDescription, taskDescription == url{
                    task.cancel()
                }
            }
        }
    }
    
    /// Save the background session completion handler
    ///
    /// - Note: Your app delegate must implement `handleEventsForBackgroundURLSession`, saving the completion handler:
    ///
    ///       func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
    ///           PrakrstaFileDownloader.shared.saveCompletionHandler(completionHandler)
    ///       }
    ///
    /// - Parameter completionHandler: The completion handler provided by `handleEventsForBackgroundURLSession`
    
    func saveCompletionHandler(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
    
    func resetInstances() {
        downloadProgressQueue = [String: DownloadData]()
    }
    
}

extension PrakrstaFileDownloader: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}

extension PrakrstaFileDownloader: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil{
            let errorString = (error! as NSError).userInfo
            if let resumeData = errorString["NSURLSessionDownloadTaskResumeData"] as? Data, let urlKey = errorString["NSErrorFailingURLStringKey"] as? String {
                createDownloadObject(url: urlKey)
                
                // If you want to show progress asap uncomment these lines (To retrieve progress)
                
                //                let progress =  ( Double(ManageFileProgress.shared.getBytesWrittenFor(url: urlKey))/Double(ManageFileProgress.shared.getExpectedBytesFor(url: urlKey)) ) * 100
                //                let fileName                                            = urlKey.fileName()
                //                downloadProgressQueue[fileName]?.percentDownloaded = progress
                
                
                
                downloadTask = urlSession.downloadTask(withResumeData: resumeData)
                downloadTask.taskDescription = urlKey
                downloadTask.resume()
            }
        }
    }
}

extension PrakrstaFileDownloader : URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let httpResponse = downloadTask.response as? HTTPURLResponse,
            (200..<300) ~= httpResponse.statusCode,
            let downloadTaskDescription = downloadTask.taskDescription else {
                print ("server error")
                return
        }
        
        let fileName = downloadTaskDescription.fileName()
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            
            
            let savedURL = documentsURL.appendingPathComponent("\(fileName).mp4")
            try FileManager.default.moveItem(at: location, to: savedURL)
                DispatchQueue.main.async {
                    if let callBack = self.completionDownload{
                        self.downloadProgressQueue[fileName]?.isDownloading = false
                        self.downloadProgressQueue[fileName]?.isDownloaded = true
                        callBack(true, fileName)
                    }
                }
            
        } catch {
            DispatchQueue.main.async {
                if let callBack = self.completionDownload {
                    self.downloadProgressQueue[fileName]?.isDownloading = false
                    self.downloadProgressQueue[fileName]?.isDownloaded = false
                    callBack(false, fileName)
                }
            }
            print ("file error: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress =  ( Double(totalBytesWritten)/Double(totalBytesExpectedToWrite) ) * 100
        if let downloadTaskDescription = downloadTask.taskDescription{
            
            //            If you to show progress asap (uncomment this line), you need to store downloaded bytes
            //            ManageFileProgress.shared.storeInfoForFile(url: downloadTaskDescription, expectedBytes: totalBytesExpectedToWrite, bytesWritten: totalBytesWritten)
            //
            
            let fileName = downloadTaskDescription.fileName()
            downloadProgressQueue[fileName]?.percentDownloaded = progress
            DispatchQueue.main.async {
                if let callBack = self.progressCallback{
                    callBack(progress, fileName)
                }
            }
            
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        print("fileOffset  \(fileOffset) , expectedTotalBytes : \(expectedTotalBytes)")
    }
}

// To convert URL to normal string
extension String {
    func fileName() -> String {
        return self.replacingOccurrences(of: "[/+.:.-]", with: "", options: .regularExpression, range: nil)
    }
}
