# PrakrstaFileDownloader

This is a download helper written in swift 4 to download files with progress and completion callbacks. This resumes the download even if user kills the app. There is one more file to manage file progress if you want to fetch progress asap.

To use this file, just add it on your project and call the fucntions mentioned in the file. 

## Requirements :
1. Pass URL to download as the key, so for different files URL must be unique.
2. In this file I have added an extension in which I am converting URL String to normal string by removing [/.:-] kind of characters and using that string to save the file.


## Usage :

```
//To start a download
PrakrstaFileDownloader.shared.startDownload(url: "your unique video url", id: "This is nothing, you can remove it from downloader class.")
PrakrstaFileDownloader.shared.isDownloading(url: "your unique video url")

override func viewWillAppear(){
    PrakrstaFileDownloader.shared.progressCallback   = downloadProgress(progress:id:)
    PrakrstaFileDownloader.shared.completionDownload = downloadCompleted(success:id:)
}

func downloadProgress(progress: Double, id: String){
    print("Progress \(progress) for id : \(id)")
}
    
func downloadCompleted(success: Bool, id: String){
    print("downloadCompleted \(success) for id : \(id)")
}
```
