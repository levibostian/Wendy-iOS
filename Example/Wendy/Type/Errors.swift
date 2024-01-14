//
//  Errors.swift
//  Wendy_Example
//
//  Created by Levi Bostian on 1/14/24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

enum AddGroceryListItemPendingTaskError: Error {
    case randomError
}

// optional below
extension AddGroceryListItemPendingTaskError: LocalizedError {
    var errorDescription: String? {
        return localizedDescription
    }

    var localizedDescription: String {
        switch self {
        case .randomError: return "Random error message here"
        }
    }
}
