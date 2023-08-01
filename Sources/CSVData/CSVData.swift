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

public class CSVData<T: CSVFormat> {
    // MARK: - Properties
    public var rows = [[T: String]]()

    // MARK: - Private properties
    private let separator: Character
    private let rowSeparator: Character

    // MARK: - Initializers
    public init<Item>(
        items: [Item],
        valueForItemInColumn: (_ item: Item, _ column: T) -> String,
        separator: Character = Character(";"),
        rowSeparator: Character = Character("\n")
    ) {
        self.separator = separator
        self.rowSeparator = rowSeparator

        for rowIndex in 0 ..< items.count {
            var row = [T: String]()

            for column in T.allCases {
                row[column] = valueForItemInColumn(items[rowIndex], column)
            }

            rows.append(row)
        }
    }

    public init(
        csvString: String,
        separator: Character = Character(";"),
        rowSeparator: Character = Character("\n"),
        continueOnInvalidRow: Bool = false
    ) throws {
        self.separator = separator
        self.rowSeparator = rowSeparator

        let numberOfColumns = T.allCases.count

        var rows = csvString.replacingOccurrences(of: "\r", with: "").split(separator: rowSeparator)

        let header = rows.removeFirst()

        guard header.split(separator: separator).count == numberOfColumns else {
            throw CSVParseError.invalidHeaderFormat
        }

        for rowString in rows {
            var row = [T: String]()
            let columns = rowString.split(separator: separator)

            if columns.count != numberOfColumns {
                if continueOnInvalidRow {
                    continue
                } else {
                    throw CSVParseError.invalidRowFormat
                }
            }

            for (index, column) in T.allCases.enumerated() {
                let value = String(columns[index])
                row[column] = value
            }

            self.rows.append(row)
        }
    }

    public convenience init(
        url: URL,
        separator: Character = Character(";"),
        rowSeparator: Character = Character("\n"),
        continueOnInvalidRow: Bool = false
    ) throws {
        let csvString = try String(contentsOf: url)
        try self.init(csvString: csvString, separator: separator, rowSeparator: rowSeparator, continueOnInvalidRow: continueOnInvalidRow)
    }

    // MARK: - Functions
    public func csvString() -> String {
        var csvString = ""

        // write header fields
        for (index, column) in T.allCases.enumerated() {
            csvString.append(column.title)
            if index < T.allCases.count - 1 {
                csvString.append(separator)
            }
        }
        csvString.append(rowSeparator)

        // write rows
        for row in rows {
            var rowString = ""

            for (index, column) in T.allCases.enumerated() {
                rowString.append(row[column] ?? "")
                if index < row.values.count - 1 {
                    rowString.append(separator)
                }
            }

            rowString.append(rowSeparator)
            csvString.append(rowString)
        }

        return csvString
    }
}
