import AppKit
import SwiftUI

extension Color {
    init(hexString: String, fallback: Color) {
        let cleanHex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleanHex.count == 6, let value = Int(cleanHex, radix: 16) else {
            self = fallback
            return
        }

        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255

        self = Color(red: red, green: green, blue: blue)
    }

    var hexString: String? {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else {
            return nil
        }

        let red = Int(round(color.redComponent * 255))
        let green = Int(round(color.greenComponent * 255))
        let blue = Int(round(color.blueComponent * 255))

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
