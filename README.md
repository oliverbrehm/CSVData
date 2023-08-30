# CSVData

A Swift package for reading and writing CSV using an enum typed format.

## Features

- Importing of CSV files and strings
- Exporting to string
- Automatic separator guessing
- Manual selection of exported columns
- All field access in rows is managed by a custom CSVFormat enumeration and **typesafe**

## Usage

### Row format definition

Import and export rely on a customly defined format enumeration, impementing the **CSVFormat** protocol. This format should correspond to the CSV row format you want to import or export.

```swift
private enum TestShoppingItem: String, CSVFormat {
    case id
    case name
    case price

    var title: String {
        rawValue.capitalized
    }
}
```

### Import

To read a CSV string or file, you initialize a CSVData object with a CSV string or url and the previously defined **CSVFormat** enumeration. The separators for rows and columns are guessed automatically, but you can also manually set the properties **rowSeparator** and **columnSeparator**.

```swift
func read() {
    // read CSV string
    let testCSVString = "id,name,Price\n1,Bananas,1.20\n2,Sugar,2.30\n3,Milk,1.99"
    let csvData = try CSVData<TestShoppingItem>(csvString: testCSVString)
    
    // read CSV file on disk
    let documentsFolder = try XCTUnwrap(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first)
    let csvUrl = documentsFolder.appending(path: "testCSV.csv")
    let csvData = try CSVData<TestShoppingItem>(url: csvUrl)
}
```

### Initialization and manipulation

To initialize a CSVData object with your own data, call the initializer with an array of any kind of data. Provide a closure as the data source to initialize each value of all column columns.

```swift
func createCSVData() -> CSVData {
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
    
    return csvData
}
```

You can manipulate the csv data object later in a typesafe way.
```swift
func manipulateCSVData() {
    let csvData = createCSVData()
    csvData[1][.name] = "Test"
}
```

### Export

The CSVData can be exported to a string. Using the **columnConfiguration** argument, you can manually select columns to export.

```swift
func export() {
    let csvData = createCSVData()
    
    // export complete CSV string
    let csvString = csvData.csvString()
    
    // export only name column
    let csvStringOnlyName = csvData.csvString(columnConfiguration: .includeOnly(columns: [.name]))
            
    // export all columns but price
    let csvStringAllButPrice = csvData.csvString(columnConfiguration: .allBut(columns: [.price]))
}
```

## Installation

The library can be used with [Swift Package Manager](https://swift.org/package-manager/) in XCode or manually added as a package dependency.
