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
    public typealias CSVRow = [T: String]

    public subscript(index: Int) -> CSVRow {
        get {
            rows[index]
        }

        set {
            rows[index] = newValue
        }
    }

    // MARK: - Properties
    public var rows = [CSVRow]()
    public let rowSeparator: Character
    public let columnSeparator: Character

    // MARK: - Initializers
    public init(rowSeparator: Character = CSVConstants.defaultRowSeparator, columnSeparator: Character = CSVConstants.defaultColumnSeparator) {
        self.rowSeparator = rowSeparator
        self.columnSeparator = columnSeparator
    }

    public convenience init<Item>(
        items: [Item],
        valueForItemInColumn: (_ item: Item, _ column: T) -> String,
        rowSeparator: Character = CSVConstants.defaultRowSeparator,
        columnSeparator: Character = CSVConstants.defaultColumnSeparator
    ) {
        self.init(rowSeparator: rowSeparator, columnSeparator: columnSeparator)
        appendRows(for: items, valueForItemInColumn: valueForItemInColumn)
    }

    public convenience init(
        csvString: String,
        rowSeparator: Character? = nil,
        columnSeparator: Character? = nil,
        continueOnInvalidRow: Bool = false
    ) throws {
        let actualRowSeparator: Character
        let actualColumnSeparator: Character

        if let rowSeparator, let columnSeparator {
            actualRowSeparator = rowSeparator
            actualColumnSeparator = columnSeparator
        } else if let rowSeparator, columnSeparator == nil {
            actualRowSeparator = rowSeparator
            actualColumnSeparator = Self.guessSeparatorForRowSeparator(rowSeparator, in: csvString)
        } else {
            (actualRowSeparator, actualColumnSeparator) = Self.guessSeparators(in: csvString)
        }

        self.init(rowSeparator: actualRowSeparator, columnSeparator: actualColumnSeparator)

        let numberOfColumns = T.allCases.count

        var rows = csvString.replacingOccurrences(of: "\r", with: "").split(separator: actualRowSeparator)

        let header = rows.removeFirst()

        guard header.split(separator: actualColumnSeparator).count == numberOfColumns else {
            throw CSVParseError.invalidHeaderFormat
        }

        for rowString in rows {
            var row = CSVRow()
            let columns = rowString.split(separator: actualColumnSeparator)

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
        columnSeparator: Character? = nil,
        rowSeparator: Character? = nil,
        continueOnInvalidRow: Bool = false
    ) throws {
        let csvString = try String(contentsOf: url)
        try self.init(
            csvString: csvString,
            rowSeparator: rowSeparator,
            columnSeparator: columnSeparator,
            continueOnInvalidRow: continueOnInvalidRow
        )
    }

    // MARK: - Functions
    public func appendRow(valueForColumn: (_ column: T) -> String) {
        appendRows(for: [0]) { _, column in
            valueForColumn(column)
        }
    }

    public func appendRows<Item>(for items: [Item], valueForItemInColumn: (_ item: Item, _ column: T) -> String) {
        rows.append(contentsOf: Self.makeRows(for: items, valueForItemInColumn: valueForItemInColumn))
    }

    public func insertRow(at index: Int, valueForColumn: (_ column: T) -> String) {
        rows.insert(contentsOf: Self.makeRows(for: [0], valueForItemInColumn: { _, column in
            valueForColumn(column)
        }), at: index)
    }

    public func insertRows<Item>(
        for items: [Item],
        at index: Int,
        valueForItemInColumn: (_ item: Item, _ column: T) -> String
    ) {
        rows.insert(contentsOf: Self.makeRows(for: items, valueForItemInColumn: valueForItemInColumn), at: index)
    }

    public func csvString() -> String {
        var csvString = ""

        // write header fields
        for (index, column) in T.allCases.enumerated() {
            csvString.append(column.title)
            if index < T.allCases.count - 1 {
                csvString.append(columnSeparator)
            }
        }
        csvString.append(rowSeparator)

        // write rows
        for row in rows {
            var rowString = ""

            for (index, column) in T.allCases.enumerated() {
                rowString.append(row[column] ?? "")
                if index < row.values.count - 1 {
                    rowString.append(columnSeparator)
                }
            }

            rowString.append(rowSeparator)
            csvString.append(rowString)
        }

        return csvString
    }

    // MARK: - Private functions
    private static func makeRows<Item>(
        for items: [Item],
        valueForItemInColumn: (_ item: Item, _ column: T) -> String
    ) -> [CSVRow] {
        var rows = [CSVRow]()

        for rowIndex in 0 ..< items.count {
            var row = CSVRow()

            for column in T.allCases {
                row[column] = valueForItemInColumn(items[rowIndex], column)
            }

            rows.append(row)
        }

        return rows
    }

    private static func guessSeparatorForRowSeparator(_ rowSeparator: Character, in csvString: String) -> Character {
        let rows = csvString.split(separator: rowSeparator)

        if rows.count <= 1 {
            return CSVConstants.defaultColumnSeparator
        }

        for separator in CSVConstants.possibleSeparators {
            let headerFields = rows[0].split(separator: separator)
            if headerFields.count > 1, headerFields.count == rows[1].split(separator: separator).count {
                return separator
            }
        }

        return CSVConstants.defaultColumnSeparator
    }

    private static func guessSeparators(in csvString: String) -> (row: Character, column: Character) {
        for rowSeparator in CSVConstants.possibleSeparators where csvString.split(separator: rowSeparator).count > 1 {
            return (rowSeparator, guessSeparatorForRowSeparator(rowSeparator, in: csvString))
        }

        return (CSVConstants.defaultRowSeparator, CSVConstants.defaultColumnSeparator)
    }
}
