/* MIT License (MIT)
 *
 * Copyright (c) 2023 Oliver Brehm
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

import Foundation

public protocol CSVFormat: RawRepresentable, CaseIterable, Hashable {
    var title: String { get }
}

public extension CSVFormat {
    var title: String {
        "\(rawValue)"
    }

    static func includedColumns(for columnConfiguration: CSVData<Self>.ColumnConfiguration<Self>) -> [Self] {
        switch columnConfiguration {
        case .all:
            return Array(allCases)
        case .allBut(columns: let columns):
            return Array(allCases).filter { !columns.contains($0) }
        case .includeOnly(columns: let columns):
            return columns
        }
    }
}
