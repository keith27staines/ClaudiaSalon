//
//  CreateDevelopmentSalonWindowController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa

enum CreateDevelopmentSalonError: ErrorType {
    case SourceSalonNotFound
    case DestinationOccupied
    case CopyFailed
}

class CreateDevelopmentSalonWindowController: NSWindowController {

    override var windowNibName: String? { return "CreateDevelopmentSalonWindowController" }
    

    @IBOutlet weak var messageText: NSTextField!
    
    lazy var fileManager:NSFileManager = {return NSFileManager.defaultManager()}()
    
    lazy var defaultSourceURL:NSURL? = {
        let sourceFilePath = "/Users/Keith/Dropbox/Service at Claudia's Salon/com.Aldebaran.ClaudiasSalon/Production Database/Finchley/ClaudiasSalon Finchley.salon"
        
        guard self.fileManager.fileExistsAtPath(sourceFilePath) else {
            print("Development Salon cannot be created because the source Salon doesn't exist")
            return nil
        }
        let sourceURL = NSURL(fileURLWithPath: sourceFilePath, isDirectory: false)
        return sourceURL
    }()
    
    lazy var defaultSourceDirectoryURL:NSURL? = {
        let sourceFilePath = "/Users/Keith/Dropbox/Service at Claudia's Salon/com.Aldebaran.ClaudiasSalon/Production Database/Finchley/"
        guard self.fileManager.fileExistsAtPath(sourceFilePath) else {
            return nil
        }
        let sourceURL = NSURL(fileURLWithPath: sourceFilePath, isDirectory: false)
        return sourceURL
    }()
    
    lazy var defaultDestinationURL:NSURL = {
        let destinationFolderURL = self.documentsURL()
        var destinationURL = destinationFolderURL.URLByAppendingPathComponent("Development")
        destinationURL = destinationURL.URLByAppendingPathExtension("salon")
        return destinationURL
    }()
    
    var actualSourceURL:NSURL?
    var actualDestinationURL:NSURL?
    
    func documentsURL() -> NSURL {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        guard let documentsDir = paths.first else {
            fatalError("Expected a documents directory but none was found")
        }
        let documentsURL = NSURL(fileURLWithPath: documentsDir)
        return documentsURL
    }
    
    func downloadURL() -> NSURL {
        let fm = NSFileManager.defaultManager()
        let downloadURLs = fm.URLsForDirectory(.DownloadsDirectory, inDomains: .UserDomainMask)
        guard let downloadURL = downloadURLs.first?.filePathURL else {
            fatalError("Expected a downloads location but none was found")
        }
        return downloadURL
    }
    
    @IBAction func copyClicked(sender: AnyObject) {
        self.actualSourceURL = nil
        self.actualDestinationURL = nil
        self.chooseSource { (sourceSelected) in
            self.chooseDestination() { (destinationSelected) in
                if self.copyFromSourceToDestination() {
                    self.convertToDevelopment()
                }
            }
        }
    }
    
    func chooseSource(sourceSelected:(success:Bool)->Void) {
        if self.actualSourceURL != nil {
            sourceSelected(success: true)
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose the source Salon"
        openPanel.prompt = "Choose"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["salon"]
        openPanel.directoryURL = self.defaultSourceDirectoryURL
        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self.actualSourceURL = openPanel.URL
                sourceSelected(success: true)
            } else {
                sourceSelected(success: false)
            }
        }
    }

    func chooseDestination(destinationSelected:(success:Bool)->Void) {
        if self.actualDestinationURL != nil {
            destinationSelected(success: true)
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Location for Development Salon"
        savePanel.prompt = "Create Salon"
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["salon"]
        savePanel.directoryURL = self.documentsURL()
        savePanel.nameFieldStringValue = "Development.salon"
        savePanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let destinationURL = savePanel.URL!
                self.actualDestinationURL = destinationURL
                destinationSelected(success: true)
            } else {
                destinationSelected(success: false)
            }
        }
    }
    
    func copyFromSourceToDestination() -> Bool {
        guard let actualSourceURL = self.actualSourceURL else {
            return false
        }
        guard let actualDestinationURL = self.actualDestinationURL else {
            return false
        }
        
        let destinationPath = actualDestinationURL.path!
        if self.fileManager.fileExistsAtPath(destinationPath) {
            do {
                try self.fileManager.removeItemAtURL(actualDestinationURL)
            } catch {
                self.displayInfo("A file already exists at the destination and could not be deleted. Error was \(error)")
                return false
            }
        }
        
        do {
            try fileManager.copyItemAtURL(actualSourceURL, toURL: actualDestinationURL)
            return true
        } catch {
            self.displayInfo("The salon could not be copied - error was \(error)")
            return false
        }
    }
    
    func convertToDevelopment() {
        let documentController = NSDocumentController.sharedDocumentController()
        documentController.openDocumentWithContentsOfURL(self.actualDestinationURL!, display: true) { document, alreadyOpen, error in
            if error != nil {
                self.displayInfo("A copy of the source Salon was copied to the Development location but the file could not be opened. The error was: \(error)")
            } else {
                if alreadyOpen {
                    self.displayInfo("The salon was already open")
                } else {
                    self.displayInfo("A copy of the source salon \(self.actualSourceURL!.path) has been placed at \(self.actualDestinationURL!.path) and converted to a development salon")
                }
                if let salonDocument = document as? AMCSalonDocument {
                    salonDocument.suspendImportsAndExports(true)
                    let salon = salonDocument.salon
                    salon.salonName = "Development (Copy made \(NSDate().dateStringWithMediumDateFormatShortTimeFormat()))"
                    salon.addressLine1 = "1 Development Place"
                    salon.addressLine2 = "Development Street"
                    salon.postcode = "BR6 0HU"
                    //let extractController = BQFirstExtractController(salonDocument: salonDocument)
                    //extractController.prepareCoredataRecordsReadyForFirstExport()
                }
            }
        }
    }
    
    func displayInfo(textToDisplay:String) {
        self.messageText.stringValue = textToDisplay
        if let fieldEditor:NSText = self.window?.fieldEditor(false, forObject: self.messageText) {
            fieldEditor.alignLeft(self)
        }
        self.messageText.resignFirstResponder()
    }
    
}
