import XCTest
@testable import CSVData

final class CSVDataTests: XCTestCase {
    private enum TestShoppingItem: String, CSVFormat {
        case id
        case name
        case price
    }

    private static let testCSVString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"

    func testRead() throws {
        let csvData = try CSVData<TestShoppingItem>(csvString: Self.testCSVString, separator: ",")

        XCTAssertEqual(csvData.rows.count, 3)

        XCTAssertEqual(csvData[2][.name], "Milk")

        XCTAssertEqual(
            csvData.csvString().trimmingCharacters(in: .whitespacesAndNewlines),
            Self.testCSVString.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let csvData = try CSVData<TestShoppingItem>(csvString: Self.testCSVString, separator: ",")
        csvData[1][.name] = "Test"

        XCTAssertEqual(
            csvData.csvString().trimmingCharacters(in: .whitespacesAndNewlines),
            Self.testCSVString.replacingOccurrences(of: "Sugar", with: "Test").trimmingCharacters(in: .whitespacesAndNewlines)
        )

        print(csvData.csvString())
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
}
