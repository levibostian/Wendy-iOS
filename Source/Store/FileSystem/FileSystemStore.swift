//
//  FileSystemStore.swift
//  Wendy
//
//  Created by Levi Bostian on 1/27/24.
//

import Foundation

// Abstraction around iOS FileManager framework to allow mocking and easier to use API.
internal protocol FileSystemStore {
    // filePath array will be joined into a string where each array item is a directory. Last item in array is the file name.
    func saveFile(_ data: Data, filePath: [String]) -> Bool
    // Returns nil if file does not exist.
    func readFile(_ filePath: [String]) -> Data?
}

internal class FileManagerFileSystemStore: FileSystemStore {

    // This class makes sure that all files created in SDK are in the same directory
    private lazy var rootSdkDirectoryPath: URL = {
        let rootAppDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return rootAppDirectory.appendingPathComponent("wendy", isDirectory: false)
    }()
    
    func saveFile(_ data: Data, filePath: [String]) -> Bool {
        guard !filePath.isEmpty else {
            return false
        }
        
        let fileName = filePath.last!
        let fileDirectoryNames = Array(filePath.dropLast())
        
        let fullDirectoryPath: URL = rootSdkDirectoryPath.appending(components: fileDirectoryNames, isDirectory: true)
        let fullFilePath = fullDirectoryPath.appending(components: filePath)
        
        do {
            try FileManager.default.createDirectory(at: fullDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            
            return FileManager.default.createFile(atPath: fullFilePath.path, contents: data, attributes: nil)
        } catch {
            return false
        }
    }
    
    func readFile(_ filePath: [String]) -> Data? {
        let filePath = URL(fileURLWithPath: filePath.joined(separator: "/"))
        return FileManager.default.contents(atPath: filePath.path)
    }
    
}

extension URL {
    func appending(components: [String], isDirectory: Bool? = nil) -> URL {
        var finalPath = self
        
        components.forEach { component in
            if let isDirectory = isDirectory {
                finalPath = finalPath.appendingPathComponent(component, isDirectory: isDirectory)
            } else {
                finalPath = finalPath.appendingPathComponent(component)
            }
        }
        
        return finalPath
    }
}
