import AVFoundation
import os
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import UIKit

// switch to UniformTypeIdentifiers, once 14.0 is the minimum deploymnt target on expo (currently 13.4 in expo v50)
import MobileCoreServices

// if react native firebase is installed, we import and configure it
#if canImport(FirebaseCore)
    import FirebaseCore
#endif
#if canImport(FirebaseAuth)
    import FirebaseAuth
#endif

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
    override func sourceURL(for _: RCTBridge) -> URL? {
        bundleURL()
    }

    override func bundleURL() -> URL? {
        #if DEBUG
            let settings = RCTBundleURLProvider.sharedSettings()
            settings.enableDev = true
            settings.enableMinification = false
            if let bundleURL = settings.jsBundleURL(forBundleRoot: ".expo/.virtual-metro-entry") {
                if var components = URLComponents(url: bundleURL, resolvingAgainstBaseURL: false) {
                    components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "shareExtension", value: "true")]
                    return components.url ?? bundleURL
                }
                return bundleURL
            }
            fatalError("Could not create bundle URL")
        #else
            guard let bundleURL = Bundle.main.url(forResource: "main", withExtension: "jsbundle") else {
                fatalError("Could not load bundle URL")
            }
            return bundleURL
            Bundle.main.url(forResource: "main", withExtension: "jsbundle")
        #endif
    }
}

class ShareExtensionViewController: UIViewController {
    var reactNativeFactory: RCTReactNativeFactory?
    var reactNativeFactoryDelegate: RCTReactNativeFactoryDelegate?
    private var isCleanedUp = false

    private let logger = Logger()

    // Ensure values are not redacted and JSON when possible
    private func logPublic(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    private func warnPublic(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    private func stringify(_ value: Any?) -> String {
        guard let value = value else { return "null" }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value, options: []),
           let str = String(data: data, encoding: .utf8)
        {
            return str
        }
        if let url = value as? URL { return url.absoluteString }
        if let data = value as? Data { return "Data(\(data.count) bytes)" }
        if let data = value as? NSData { return "Data(\(data.length) bytes)" }
        return String(describing: value)
    }

    deinit {
        self.logger.info("🧹 ShareExtensionViewController deinit")
        cleanupAfterClose()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Start cleanup earlier to ensure proper surface teardown
        if isBeingDismissed {
            cleanupAfterClose()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isCleanedUp = false

        // Set the contentScaleFactor for the main view of this view controller
        view.contentScaleFactor = UIScreen.main.scale
        // Ensure transparent background
        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        #if canImport(FirebaseCore)
            if Bundle.main.object(forInfoDictionaryKey: "WithFirebase") as? Bool ?? false {
                FirebaseApp.configure()
            }
        #endif

        loadReactNativeContent()
        setupNotificationCenterObserver()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // we need to clean up when the view is closed via a swipe
        cleanupAfterClose()
    }

    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        // we need to clean up when the view is closed via the close() method in react native
        cleanupAfterClose()
    }

    private func loadReactNativeContent() {
        getShareData { [weak self] sharedData in
            guard let self = self else {
                print("❌ Self was deallocated")
                return
            }

            reactNativeFactoryDelegate = ReactNativeDelegate()
            reactNativeFactoryDelegate!.dependencyProvider = RCTAppDependencyProvider()
            reactNativeFactory = RCTReactNativeFactory(delegate: reactNativeFactoryDelegate!)

            var initialProps = sharedData ?? [:]

            // Capture current view's properties before replacing it
            let currentBounds = self.view.bounds
            let currentScale = UIScreen.main.scale

            // Log the scale of the parent view
            self.logger.info("[ShareExtension] self.view.contentScaleFactor before adding subview: \(self.view.contentScaleFactor)")
            self.logger.info("[ShareExtension] UIScreen.main.scale: \(currentScale)")

            // Add screen metrics to initial properties for React Native
            // These can be used by the JS side to understand its container size and scale
            initialProps["initialViewWidth"] = currentBounds.width
            initialProps["initialViewHeight"] = currentBounds.height
            initialProps["pixelRatio"] = currentScale
            // It's also good practice to pass the font scale for accessibility
            // Default body size on iOS is 17pt, used as a reference for calculating fontScale.
            initialProps["fontScale"] = UIFont.preferredFont(forTextStyle: .body).pointSize / 17.0

            // Create the React Native root view
            let reactNativeRootView = reactNativeFactory!.rootViewFactory.view(
                withModuleName: "shareExtension",
                initialProperties: initialProps
            )

            let heightFromInfoPlist = Bundle.main.object(forInfoDictionaryKey: "ShareExtensionHeight") as? CGFloat

            // Add React Native root view first
            view.addSubview(reactNativeRootView)
            configureRootView(reactNativeRootView, withHeight: heightFromInfoPlist)

            // Add white background view below the React view
            let whiteBackgroundView = UIView()
            whiteBackgroundView.backgroundColor = UIColor.white
            whiteBackgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(whiteBackgroundView)

            // Configure white background to overlap React view by 100px and fill to bottom of screen
            NSLayoutConstraint.activate([
                whiteBackgroundView.topAnchor.constraint(equalTo: reactNativeRootView.bottomAnchor, constant: -10),
                whiteBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                whiteBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                whiteBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    private func configureRootView(_ rootView: UIView, withHeight: CGFloat?) {
        rootView.backgroundColor = UIColor.clear
        rootView.translatesAutoresizingMaskIntoConstraints = false

        if let withHeight = withHeight {
            // Fixed height positioned at bottom of safe area
            NSLayoutConstraint.activate([
                rootView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                rootView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                rootView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                rootView.heightAnchor.constraint(equalToConstant: withHeight),
            ])
        } else {
            // Full safe area
            NSLayoutConstraint.activate([
                rootView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                rootView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                rootView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                rootView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
    }

    private func openHostApp(path: String?) {
        guard let scheme = Bundle.main.object(forInfoDictionaryKey: "HostAppScheme") as? String else { return }
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = ""

        if let path = path {
            let pathComponents = path.split(separator: "?", maxSplits: 1)
            let pathWithoutQuery = String(pathComponents[0])
            let queryString = pathComponents.count > 1 ? String(pathComponents[1]) : nil

            // Parse and set query items
            if let queryString = queryString {
                let queryItems = queryString.split(separator: "&").map { queryParam -> URLQueryItem in
                    let paramComponents = queryParam.split(separator: "=", maxSplits: 1)
                    let name = String(paramComponents[0])
                    let value = paramComponents.count > 1 ? String(paramComponents[1]) : nil
                    return URLQueryItem(name: name, value: value)
                }
                urlComponents.queryItems = queryItems
            }

            let pathWithSlashEnsured = pathWithoutQuery.hasPrefix("/") ? pathWithoutQuery : "/\(pathWithoutQuery)"
            urlComponents.path = pathWithSlashEnsured
        }

        guard let url = urlComponents.url else { return }
        openURL(url)
        close()
    }

    @objc @discardableResult private func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                if #available(iOS 18.0, *) {
                    application.open(url, options: [:], completionHandler: nil)
                    return true
                } else {
                    return application.perform(#selector(UIApplication.open(_:options:completionHandler:)), with: url, with: [:]) != nil
                }
            }
            responder = responder?.next
        }
        return false
    }

    private func setupNotificationCenterObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("close"), object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.close()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("openHostApp"), object: nil, queue: nil) { [weak self] notification in
            DispatchQueue.main.async {
                if let userInfo = notification.userInfo {
                    if let path = userInfo["path"] as? String {
                        self?.openHostApp(path: path)
                    }
                }
            }
        }
    }

    private func cleanupAfterClose() {
        if isCleanedUp { return }
        isCleanedUp = true

        NotificationCenter.default.removeObserver(self)

        // Remove React Native view and white background view, deallocate resources
        for subview in view.subviews {
            if subview is RCTRootView {
                subview.removeFromSuperview()
            }
        }

        // Remove white background view if it exists
        for subview in view.subviews {
            if subview.backgroundColor == UIColor.white, subview != view {
                subview.removeFromSuperview()
            }
        }

        reactNativeFactory = nil
        reactNativeFactoryDelegate = nil

        logger.info("🧹 ShareExtensionViewController cleaned up")
    }

    private func backgroundColor(from dict: [String: CGFloat]?) -> UIColor {
        guard let dict = dict else { return .clear }
        let red = dict["red"] ?? 255.0
        let green = dict["green"] ?? 255.0
        let blue = dict["blue"] ?? 255.0
        let alpha = dict["alpha"] ?? 1
        return UIColor(red: red / 255.0, green: green / 255.0, blue: blue / 255.0, alpha: alpha)
    }

    private func getShareData(completion: @escaping ([String: Any]?) -> Void) {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            logger.warning("SHARED: No extension items found")
            completion(nil)
            return
        }

        logPublic("SHARED: Raw extension items count: \(extensionItems.count)")
        for (index, item) in extensionItems.enumerated() {
            logPublic("SHARED: Extension item \(index): \(stringify(item))")
            logPublic("SHARED: Extension item \(index) attachments count: \(item.attachments?.count ?? 0)")
        }

        var sharedItems: [String: Any] = [:]

        let group = DispatchGroup()

        let fileManager = FileManager.default

        for item in extensionItems {
            for provider in item.attachments ?? [] {
                logPublic("SHARED: Provider registered type identifiers: \(stringify(provider.registeredTypeIdentifiers))")
                if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    logger.info("SHARED: Detected URL type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { urlItem, _ in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: URL raw: \(type(of: urlItem)) = \(self.stringify(urlItem))")

                            if let sharedURL = urlItem as? URL {
                                self.logPublic("SHARED: URL parsed as URL: \(sharedURL.absoluteString) (isFile: \(sharedURL.isFileURL))")
                                if sharedURL.isFileURL {
                                    if sharedItems["files"] == nil {
                                        sharedItems["files"] = [String]()
                                    }
                                    if var fileArray = sharedItems["files"] as? [String] {
                                        fileArray.append(sharedURL.absoluteString)
                                        sharedItems["files"] = fileArray
                                    }
                                } else {
                                    sharedItems["url"] = sharedURL.absoluteString
                                }
                            } else if let urlString = urlItem as? String {
                                self.logPublic("SHARED: URL parsed as String: \(urlString)")
                                if let url = URL(string: urlString) {
                                    sharedItems["url"] = url.absoluteString
                                } else {
                                    sharedItems["text"] = urlString
                                }
                            } else {
                                self.logger.warning("SHARED: URL parsing failed")
                            }
                            group.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                    logger.info("SHARED: Detected PropertyList type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil) { item, _ in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: PropertyList raw: \(type(of: item)) = \(self.stringify(item))")

                            if let itemDict = item as? NSDictionary,
                               let results = itemDict[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary
                            {
                                self.logPublic("SHARED: PropertyList parsed JS results: \(self.stringify(results))")
                                sharedItems["preprocessingResults"] = results
                            } else if let itemDict = item as? [String: Any] {
                                self.logPublic("SHARED: PropertyList parsed as Swift Dict: \(self.stringify(Array(itemDict.keys)))")
                            } else {
                                self.logger.warning("SHARED: PropertyList parsing failed")
                            }
                            group.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                    logger.info("SHARED: Detected Text type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { textItem, _ in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: Text raw: \(type(of: textItem)) = \(self.stringify(textItem))")

                            if let text = textItem as? String {
                                self.logPublic("SHARED: Text parsed as String: \(text.prefix(100))...")
                                if let url = URL(string: text), url.scheme != nil, sharedItems["url"] == nil {
                                    sharedItems["url"] = text
                                }
                                sharedItems["text"] = text
                            } else if let data = textItem as? Data,
                                      let text = String(data: data, encoding: .utf8)
                            {
                                self.logPublic("SHARED: Text parsed from Data: \(text.prefix(100))...")
                                sharedItems["text"] = text
                            } else {
                                self.logger.warning("SHARED: Text parsing failed")
                            }
                            group.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    logger.info("SHARED: Detected Image type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { imageItem, error in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: Image raw: \(type(of: imageItem)) = \(self.stringify(imageItem))")

                            // Ensure the array exists
                            if sharedItems["images"] == nil {
                                sharedItems["images"] = [String]()
                            }

                            guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String else {
                                self.logger.warning("Could not find AppGroup in info.plist")
                                return
                            }

                            guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
                                self.logger.warning("Could not set up file manager container URL for app group")
                                return
                            }

                            if let imageUri = imageItem as? NSURL {
                                self.logPublic("SHARED: Image parsed as NSURL: \(imageUri.absoluteString ?? "nil")")
                                if let tempFilePath = imageUri.path {
                                    let fileExtension = imageUri.pathExtension ?? "jpg"
                                    let fileName = UUID().uuidString + "." + fileExtension

                                    let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                    if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                        do {
                                            try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                        } catch {
                                            self.logger.warning("Failed to create sharedData directory: \(error)")
                                        }
                                    }

                                    let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                    do {
                                        try fileManager.copyItem(atPath: tempFilePath, toPath: persistentURL.path)
                                        if var videoArray = sharedItems["images"] as? [String] {
                                            videoArray.append(persistentURL.absoluteString)
                                            sharedItems["images"] = videoArray
                                        }
                                    } catch {
                                        self.logger.warning("Failed to copy image: \(error)")
                                    }
                                }
                            } else if let image = imageItem as? UIImage {
                                self.logPublic("SHARED: Image parsed as UIImage: \(NSCoder.string(for: image.size))")
                                // Handle UIImage if needed (e.g., save to disk and get the file path)
                                if let imageData = image.jpegData(compressionQuality: 1.0) {
                                    let fileName = UUID().uuidString + ".jpg"

                                    let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                    if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                        do {
                                            try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                        } catch {
                                            self.logger.warning("Failed to create sharedData directory: \(error)")
                                        }
                                    }

                                    let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                    do {
                                        try imageData.write(to: persistentURL)
                                        if var imageArray = sharedItems["images"] as? [String] {
                                            imageArray.append(persistentURL.absoluteString)
                                            sharedItems["images"] = imageArray
                                        }
                                    } catch {
                                        self.logger.warning("Failed to save image: \(error)")
                                    }
                                }
                            } else if let imageData = imageItem as? Data {
                                self.logger.info("SHARED: Image parsed as Data")

                                // Get the original file extension from the provider's registered type identifiers
                                let originalFileName = provider.registeredTypeIdentifiers.first ?? "image.jpg"
                                let originalFileExtension = originalFileName.components(separatedBy: ".").last ?? "jpg"
                                self.logger.info("Original shared file name: \(originalFileName)")

                                let fileName = UUID().uuidString + "." + originalFileExtension

                                let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                    do {
                                        try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                    } catch {
                                        self.logger.warning("Failed to create sharedData directory: \(error)")
                                    }
                                }

                                let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                do {
                                    try imageData.write(to: persistentURL)
                                    self.logger.info("Wrote shared image data to file: \(persistentURL.absoluteString)")
                                    if var imageArray = sharedItems["images"] as? [String] {
                                        imageArray.append(persistentURL.absoluteString)
                                        sharedItems["images"] = imageArray
                                    }
                                } catch {
                                    self.logger.warning("Failed to save image data: \(error)")
                                }
                            } else {
                                self.warnPublic("SHARED: Image parsing failed - unknown type: \(type(of: imageItem))")
                            }
                            group.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
                    logger.info("SHARED: Detected Movie type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypeMovie as String, options: nil) { videoItem, error in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: Movie raw: \(type(of: videoItem)) = \(self.stringify(videoItem))")

                            // Ensure the array exists
                            if sharedItems["videos"] == nil {
                                sharedItems["videos"] = [String]()
                            }

                            guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String else {
                                self.logger.warning("Could not find AppGroup in info.plist")
                                return
                            }

                            guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
                                self.logger.warning("Could not set up file manager container URL for app group")
                                return
                            }

                            // Check if videoItem is NSURL
                            if let videoUri = videoItem as? NSURL {
                                self.logPublic("SHARED: Movie parsed as NSURL: \(videoUri.absoluteString ?? "nil")")
                                if let tempFilePath = videoUri.path {
                                    let fileExtension = videoUri.pathExtension ?? "mov"
                                    let fileName = UUID().uuidString + "." + fileExtension

                                    let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                    if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                        do {
                                            try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                        } catch {
                                            self.logger.warning("Failed to create sharedData directory: \(error)")
                                        }
                                    }

                                    let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                    do {
                                        try fileManager.copyItem(atPath: tempFilePath, toPath: persistentURL.path)
                                        if var videoArray = sharedItems["videos"] as? [String] {
                                            videoArray.append(persistentURL.path)
                                            sharedItems["videos"] = videoArray
                                        }
                                    } catch {
                                        self.logger.warning("Failed to copy video: \(error)")
                                    }
                                }
                            }
                            // Check if videoItem is NSData
                            else if let videoData = videoItem as? NSData {
                                self.logPublic("SHARED: Movie parsed as NSData: \(videoData.length) bytes")
                                let fileExtension = "mov" // Using mov as default type extension
                                let fileName = UUID().uuidString + "." + fileExtension

                                let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                    do {
                                        try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                    } catch {
                                        self.logger.warning("Failed to create sharedData directory: \(error)")
                                    }
                                }

                                let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                do {
                                    try videoData.write(to: persistentURL)
                                    if var videoArray = sharedItems["videos"] as? [String] {
                                        videoArray.append(persistentURL.path)
                                        sharedItems["videos"] = videoArray
                                    }
                                } catch {
                                    self.logger.warning("Failed to save video: \(error)")
                                }
                            }
                            // Check if videoItem is AVAsset
                            else if let asset = videoItem as? AVAsset {
                                self.logPublic("SHARED: Movie parsed as AVAsset: \(self.stringify(asset))")
                                let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)

                                let fileExtension = "mov" // Using mov as default type extension
                                let fileName = UUID().uuidString + "." + fileExtension

                                let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                                if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                    do {
                                        try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                    } catch {
                                        self.logger.warning("Failed to create sharedData directory: \(error)")
                                    }
                                }

                                let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                exportSession?.outputURL = persistentURL
                                exportSession?.outputFileType = .mov
                                exportSession?.exportAsynchronously {
                                    switch exportSession?.status {
                                    case .completed:
                                        if var videoArray = sharedItems["videos"] as? [String] {
                                            videoArray.append(persistentURL.absoluteString)
                                            sharedItems["videos"] = videoArray
                                        }
                                    case .failed:
                                        self.logger.warning("Failed to export video: \(String(describing: exportSession?.error))")
                                    default:
                                        break
                                    }
                                }
                            } else {
                                self.logger.warning("SHARED: Movie parsing failed")
                            }
                            group.leave()
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypePDF as String) {
                    logger.info("SHARED: Detected PDF type")
                    group.enter()
                    provider.loadItem(forTypeIdentifier: kUTTypePDF as String, options: nil) { pdfItem, error in
                        DispatchQueue.main.async {
                            self.logPublic("SHARED: PDF raw: \(type(of: pdfItem)) = \(self.stringify(pdfItem))")

                            // Ensure the files array exists
                            if sharedItems["files"] == nil {
                                sharedItems["files"] = [String]()
                            }

                            guard let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String else {
                                self.logger.warning("Could not find AppGroup in info.plist")
                                group.leave()
                                return
                            }

                            guard let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
                                self.logger.warning("Could not set up file manager container URL for app group")
                                group.leave()
                                return
                            }

                            let sharedDataUrl = containerUrl.appendingPathComponent("sharedData")

                            if !fileManager.fileExists(atPath: sharedDataUrl.path) {
                                do {
                                    try fileManager.createDirectory(at: sharedDataUrl, withIntermediateDirectories: true)
                                } catch {
                                    self.logger.warning("Failed to create sharedData directory: \(error)")
                                    group.leave()
                                    return
                                }
                            }

                            // Check if pdfItem is URL (existing PDF file)
                            if let pdfUrl = pdfItem as? URL {
                                self.logPublic("SHARED: PDF parsed as URL: \(pdfUrl.absoluteString)")
                                let fileName = UUID().uuidString + ".pdf"
                                let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                do {
                                    try fileManager.copyItem(at: pdfUrl, to: persistentURL)
                                    if var fileArray = sharedItems["files"] as? [String] {
                                        fileArray.append(persistentURL.absoluteString)
                                        sharedItems["files"] = fileArray
                                    }
                                } catch {
                                    self.logger.warning("Failed to copy PDF file: \(error)")
                                }
                            }
                            // Check if pdfItem is Data (inline PDF data)
                            else if let pdfData = pdfItem as? Data {
                                self.logPublic("SHARED: PDF parsed as Data: \(pdfData.count) bytes")
                                let fileName = UUID().uuidString + ".pdf"
                                let persistentURL = sharedDataUrl.appendingPathComponent(fileName)

                                do {
                                    try pdfData.write(to: persistentURL)
                                    self.logger.info("Wrote shared PDF to file: \(persistentURL.absoluteString)")
                                    if var fileArray = sharedItems["files"] as? [String] {
                                        fileArray.append(persistentURL.absoluteString)
                                        sharedItems["files"] = fileArray
                                    }
                                } catch {
                                    self.logger.warning("Failed to save PDF data: \(error)")
                                }
                            } else {
                                self.logger.warning("SHARED: PDF parsing failed")
                            }
                            group.leave()
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            self.logPublic("SHARED: Final parsed data: \(self.stringify(sharedItems))")
            self.logPublic("SHARED: Data keys found: \(self.stringify(Array(sharedItems.keys)))")
            for (key, value) in sharedItems {
                self.logPublic("SHARED: \(key): \(type(of: value)) = \(self.stringify(value))")
            }
            completion(sharedItems.isEmpty ? nil : sharedItems)
        }
    }
}
