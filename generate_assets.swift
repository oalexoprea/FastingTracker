import Foundation
import AppKit
import CoreGraphics

func createFolder(at path: String) {
    try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
}

func generateAppIcon(size: CGFloat, outputPath: String) {
    let imageSize = NSSize(width: size, height: size)
    let image = NSImage(size: imageSize)
    
    image.lockFocus()
    
    // Draw a beautiful orange to red gradient
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        NSColor.orange.cgColor,
        NSColor.red.cgColor
    ] as CFArray
    
    let locations: [CGFloat] = [0.0, 1.0]
    guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }
    
    let startPoint = CGPoint(x: 0, y: size)
    let endPoint = CGPoint(x: size, y: 0)
    
    context.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: [])
    
    // Draw a simple white circle representing a progress ring/timer in the center
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(size * 0.08)
    let center = CGPoint(x: size / 2, y: size / 2)
    let radius = size * 0.3
    context.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 1.5, clockwise: false)
    context.strokePath()
    
    image.unlockFocus()
    
    // Save to PNG
    if let tiffData = image.tiffRepresentation,
       let bitmapRep = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
    }
}

// Create asset catalog folders
let assetsPath = "Assets.xcassets"
let appIconPath = "\(assetsPath)/AppIcon.appiconset"
createFolder(at: appIconPath)

// Generate the required icon sizes for iPhone App Store build:
// 1. 120x120 pixels (60x60@2x)
// 2. 180x180 pixels (60x60@3x)
// 3. 1024x1024 pixels (App Store)
generateAppIcon(size: 120, outputPath: "\(appIconPath)/icon_120.png")
generateAppIcon(size: 180, outputPath: "\(appIconPath)/icon_180.png")
generateAppIcon(size: 1024, outputPath: "\(appIconPath)/icon_1024.png")

// Write Contents.json
let contentsJson = """
{
  "images" : [
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_120.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon_180.png",
      "scale" : "3x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "icon_1024.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
"""

try? contentsJson.write(toFile: "\(appIconPath)/Contents.json", atomically: true, encoding: .utf8)
print("Asset Catalog dynamically generated with beautiful iOS App Icons!")
