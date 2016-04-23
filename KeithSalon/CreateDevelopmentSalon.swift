//
//  CreateDevelopmentSalon.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa



class CreateDevelopmentSalon : NSWindowController {
    class func createDevelopmentSalon() {
        print("Creating development Salon")
        
        
        
        do {
            let developmentURL = try self.copySourceToDestination()
            print("Development Salon has been created at \(developmentURL)")
        } catch {
            if let error = error as? CreateDevelopmentSalonError {
                switch error {
                default:
                    break
                }
            } else {
                print("Unexpected exception: \(error)")
            }
        }
    }
    
    class private func copySourceToDestination() throws -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        let sourceFilePath = "/Users/Keith/Dropbox/Service at Claudia's Salon/com.Aldebaran.ClaudiasSalon/Production Database/Finchley/ClaudiasSalon Finchley.salon"
        
        guard fileManager.fileExistsAtPath(sourceFilePath) else {
            print("Development Salon cannot be created because the source Salon doesn't exist")
            throw CreateDevelopmentSalonError.SourceSalonNotFound
        }
        
        let destinationFilePath = "/Users/Keith/Downloads/Development2.salon"
        if fileManager.fileExistsAtPath(destinationFilePath) {
            print("Warning - a file with the same name and path as the required development salon already exists")
            do {
                try fileManager.removeItemAtPath(destinationFilePath)
            } catch {
                print("Unable to clear the destination for the development salon. Error was \(error)")
                throw CreateDevelopmentSalonError.DestinationOccupied
            }
        }
        
        let sourceURL = NSURL(fileURLWithPath: sourceFilePath, isDirectory: false)
        let destinationURL = NSURL(fileURLWithPath:destinationFilePath, isDirectory: false)
        
        do {
            try fileManager.copyItemAtURL(sourceURL, toURL: destinationURL)
        } catch {
            print("Unable to copy the production salon to the development destination. Error was: \(error)")
            throw CreateDevelopmentSalonError.CopyFailed
        }
        
        return destinationURL
    }
    
}
