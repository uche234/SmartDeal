//
//  Array.swift
//  Dilblitz
//
//  Created by Oleksiy Kryvtsov on 24.05.2024.
//

import Foundation

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}
