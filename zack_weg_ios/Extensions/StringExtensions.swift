import Foundation

extension String {
    /// Formats a price string (e.g., "1500.50") as Euro in German format
    /// - Returns: A formatted price string with Euro symbol
    func asPriceText() -> String {
        // Try to convert the string to a decimal number
        guard let price = Double(self) else {
            return self
        }
        
        // Create a number formatter configured for Euro in German format
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        formatter.currencyCode = "EUR"
        
        // Format the price
        if let formattedPrice = formatter.string(from: NSNumber(value: price)) {
            return formattedPrice
        }
        
        return self
    }
} 