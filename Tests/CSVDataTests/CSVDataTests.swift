import XCTest
@testable import CSVData

final class CSVDataTests: XCTestCase {
    private enum TestShoppingItem: String, CSVFormat {
        case id
        case name
        case price
    }

    private enum TestSimpleFormat: String, CSVFormat {
        case test
    }

    func testRead() throws {
        let testCSVString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"
        let csvData = try CSVData<TestShoppingItem>(csvString: testCSVString)

        XCTAssertEqual(csvData.rows.count, 3)

        XCTAssertEqual(csvData[2][.name], "Milk")

        XCTAssertEqual(
            csvData.csvString().trimmingCharacters(in: .whitespacesAndNewlines),
            testCSVString.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testWrite() throws {
        let csvData = CSVData<TestShoppingItem>(items: Array(0 ..< 10)) { index, column in
            switch column {
            case .id:
                return "\(index)"
            case .name:
                return "Item \(index + 1)"
            case .price:
                return "\(Double(index) * 1.5)"
            }
        }

        XCTAssertEqual(csvData.rows.count, 10)
    }

    func testManipulate() throws {
        let testCSVString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"
        let csvData = try CSVData<TestShoppingItem>(csvString: testCSVString)
        csvData[1][.name] = "Test"

        XCTAssertEqual(
            csvData.csvString().trimmingCharacters(in: .whitespacesAndNewlines),
            testCSVString.replacingOccurrences(of: "Sugar", with: "Test").trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testAddRemoveRows() throws {
        let csvData = CSVData<TestShoppingItem>()

        csvData.appendRow { column in
            switch column {
            case .id:
                return "0"
            case .name:
                return "TestAppend"
            case .price:
                return "3"
            }
        }

        XCTAssertEqual(csvData.rows.count, 1)

        csvData.appendRows(for: Array(0 ..< 10)) { index, column in
            switch column {
            case .id:
                return "\(index)"
            case .name:
                return "Item \(index + 1)"
            case .price:
                return "\(Double(index) * 1.5)"
            }
        }

        XCTAssertEqual(csvData.rows.count, 11)
        XCTAssertEqual(csvData[1][.name], "Item 1")
        XCTAssertEqual(csvData[10][.name], "Item 10")

        csvData.insertRow(at: 1) { column in
            switch column {
            case .id:
                return "99"
            case .name:
                return "TestInsert"
            case .price:
                return "3"
            }
        }

        XCTAssertEqual(csvData.rows.count, 12)
        XCTAssertEqual(csvData[1][.name], "TestInsert")

        csvData.insertRows(for: Array(0 ..< 10), at: 5) { index, column in
            switch column {
            case .id:
                return "\(index)"
            case .name:
                return "Item \(index + 100)"
            case .price:
                return "\(Double(index) * 1.5)"
            }
        }

        XCTAssertEqual(csvData.rows.count, 22)
        XCTAssertEqual(csvData[5][.name], "Item 100")
        XCTAssertEqual(csvData[14][.name], "Item 109")

        csvData.rows.remove(at: 5)

        XCTAssertEqual(csvData.rows.count, 21)
        XCTAssertEqual(csvData[5][.name], "Item 101")

        csvData.rows.removeAll { row in
            row[.name]?.contains("Item") ?? false
        }

        XCTAssertEqual(csvData.rows.count, 2)
        XCTAssertEqual(csvData[0][.name], "TestAppend")
        XCTAssertEqual(csvData[1][.name], "TestInsert")
    }

    func testGuessSeparators() throws {
        let testCSVString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"

        // guess both
        var csvData = try CSVData<TestShoppingItem>(csvString: testCSVString)
        XCTAssertEqual(csvData.rows.count, 3)

        // guess with row separator given
        csvData = try CSVData<TestShoppingItem>(csvString: testCSVString, rowSeparator: Character("\n"))
        XCTAssertEqual(csvData.rows.count, 3)

        // both given
        csvData = try CSVData<TestShoppingItem>(csvString: testCSVString, rowSeparator: Character("\n"), columnSeparator: Character(","))
        XCTAssertEqual(csvData.rows.count, 3)

        // test with different separators
        let testCustomSeperatorsCSVString = "id#name#price\t1#Bananas#1.20\t2#Sugar#2.30\t3#Milk#1.99"

        // guess both
        csvData = try CSVData<TestShoppingItem>(csvString: testCustomSeperatorsCSVString)
        XCTAssertEqual(csvData.rows.count, 3)

        // guess with row separator given
        csvData = try CSVData<TestShoppingItem>(csvString: testCustomSeperatorsCSVString, rowSeparator: Character("\t"))
        XCTAssertEqual(csvData.rows.count, 3)

        // both given
        csvData = try CSVData<TestShoppingItem>(csvString: testCustomSeperatorsCSVString, rowSeparator: Character("\t"), columnSeparator: Character("#"))
        XCTAssertEqual(csvData.rows.count, 3)

        let testEmptyCSVString = "test"

        var simpleCSVData = try CSVData<TestSimpleFormat>(csvString: testEmptyCSVString, rowSeparator: Character("\n"))
        XCTAssertEqual(simpleCSVData.rows.count, 0)

        simpleCSVData = try CSVData<TestSimpleFormat>(csvString: testEmptyCSVString)
        XCTAssertEqual(simpleCSVData.rows.count, 0)
    }

    func testInvalidHeader() throws {
        let testCSVString = "id,name,price,failing\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"

        XCTAssertThrowsError(try CSVData<TestShoppingItem>(csvString: testCSVString)) {
            XCTAssertEqual($0 as? CSVParseError, CSVParseError.invalidHeaderFormat)
        }
    }

    func testInvalidRow() throws {
        let testInvalidCSVString = "id,name,price\n1,Bananas,1.20,Invalid column\n2,Sugar,2.30\n3,Milk,1.99"

        XCTAssertThrowsError(try CSVData<TestShoppingItem>(csvString: testInvalidCSVString, continueOnInvalidRow: false)) {
            XCTAssertEqual($0 as? CSVParseError, CSVParseError.invalidRowFormat)
        }

        let csvData = try CSVData<TestShoppingItem>(csvString: testInvalidCSVString, continueOnInvalidRow: true)
        XCTAssertEqual(csvData.rows.count, 2) // 2 of 3 rows, 'Bananas' has invalid column
    }

    @available(macOS 13.0, *)
    func testReadFile() throws {
        let documentsFolder = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
        let csvUrl = documentsFolder.appending(path: "testCSV.csv")
        let testCSVString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"

        try testCSVString.write(to: csvUrl, atomically: true, encoding: .utf8)

        let csvData = try CSVData<TestShoppingItem>(url: csvUrl)
        XCTAssertEqual(csvData.rows.count, 3)
    }
}
