import XCTest
@testable import CSVData

private enum TestSoppingItem: String, CSVFormat {
    case id
    case name
    case price
}

final class CSVDataTests: XCTestCase {
    func testRead() throws {
        let csvString = "id,name,price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"

        let csvData = try CSVData<TestSoppingItem>(csvString: csvString, separator: ",")

        XCTAssertEqual(csvData.rows.count, 3)

        XCTAssertEqual(csvData.rows[2][.name], "Milk")

        XCTAssertEqual(
            csvData.csvString().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            csvString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        )
    }

    func testWrite() throws {
        let csvData = CSVData<TestSoppingItem>(items: Array(0 ..< 10)) { item, column in
            switch column {
            case .id:
                return "\(item)"
            case .name:
                return "Item \(item + 1)"
            case .price:
                return "\(Double(item) * 1.5)"
            }
        }

        XCTAssertEqual(csvData.rows.count, 10)

        print(csvData.csvString())
    }
}
