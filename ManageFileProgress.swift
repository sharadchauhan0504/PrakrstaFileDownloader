//
//  PrakrstaFileDownloader.swift
//  UrlSessionExample
//
//  Created by Sharad on 31/03/18.
//  Copyright © 2018 Sharad. All rights reserved.
//

import UIKit

let kDownloadedFileInfo = "DOWNLOADED_DATA_INFO"

class DownloadInfo: NSObject, NSCoding {
    var urlKey: String?
    var bytesWritten: Int64?
    var expectedBytes: Int64?
    // Can add more info about file
    
    override init() {
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(urlKey, forKey: "urlKey")
        aCoder.encode(expectedBytes, forKey: "expectedBytes")
        aCoder.encode(bytesWritten, forKey: "bytesWritten")
    }
    
    required init?(coder aDecoder: NSCoder) {
        urlKey = aDecoder.decodeObject(forKey: "urlKey") as? String
        expectedBytes = aDecoder.decodeObject(forKey: "expectedBytes") as? Int64
        bytesWritten = aDecoder.decodeObject(forKey: "bytesWritten") as? Int64
    }
}

class ManageFileProgress: NSObject {

    static var shared = ManageFileProgress()
    
    var downloadedDataInfo = [String: DownloadInfo]()
    
    override init() {
        super.init()
    }
    
    func storeInfoForFile(url: String, expectedBytes: Int64, bytesWritten: Int64) {
        if !downloadedDataInfo.contains(where: {$0.key == url.fileName()}){
            let downloadInfo = DownloadInfo()
            downloadInfo.urlKey = url
            downloadInfo.expectedBytes = expectedBytes
            downloadedDataInfo[url.fileName()] = downloadInfo
            saveDownloadInfo(downloadedInfo: downloadedDataInfo)
        }else{
            downloadedDataInfo[url.fileName()]?.bytesWritten = bytesWritten
            saveDownloadInfo(downloadedInfo: downloadedDataInfo)
        }
    }
    
    func getExpectedBytesFor(url: String) -> Int64 {
        let data = getSavedDownloedInfo()
        if data.contains(where: {$0.key == url.fileName()}){
            guard let expectedBytes = data[url.fileName()]?.expectedBytes else {return Int64(0.0)}
            return expectedBytes
        }
        return Int64(0.0)
    }
    
    func getBytesWrittenFor(url: String) -> Int64 {
        let data = getSavedDownloedInfo()
        if data.contains(where: {$0.key == url.fileName()}){
            guard let expectedBytes = data[url.fileName()]?.bytesWritten else {return Int64(0.0)}
            return expectedBytes
        }
        return Int64(0.0)
    }
    
    
    
    func removeFileInfoFor(url: String) {
        downloadedDataInfo = getSavedDownloedInfo()
        if downloadedDataInfo.contains(where: {$0.key == url.fileName()}){
            downloadedDataInfo.removeValue(forKey: url.fileName())
            saveDownloadInfo(downloadedInfo: ManageFileProgress.shared.downloadedDataInfo)
        }
    }
    
    private func saveDownloadInfo(downloadedInfo: [String: DownloadInfo]) {
        let encodeData = NSKeyedArchiver.archivedData(withRootObject: downloadedInfo)
        UserDefaults.standard.set(encodeData, forKey: kDownloadedFileInfo)
    }
    
    private func getSavedDownloedInfo() -> [String: DownloadInfo] {
        if isKeyPresentInUserDefaults(key: kDownloadedFileInfo){
            guard let decodedData = UserDefaults.standard.object(forKey: kDownloadedFileInfo) as? Data else {return [String: DownloadInfo]()}
            guard let downloadInfo = NSKeyedUnarchiver.unarchiveObject(with: decodedData) as? [String: DownloadInfo] else {return [String: DownloadInfo]()}
            return downloadInfo
        }
        return [String: DownloadInfo]()
    }
    
    private func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
