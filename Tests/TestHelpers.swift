//
//  TestHelpers.swift
//  Wendy_Tests
//
//  Created by Levi Bostian on 2/4/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import XCTest

extension String {
    static var random: String {
        UUID().uuidString
    }
}

extension XCTest {
    func deleteAllFileSystemFiles() {
        let fileManager = FileManager.default
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        guard let fileUrls = try? fileManager.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: []) else {
            return
        }
        for fileUrl in fileUrls {
            try? fileManager.removeItem(at: fileUrl)
        }
    }
    
    func deleteKeyValueStore() {
        let userDefaults = UserDefaults.standard
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
