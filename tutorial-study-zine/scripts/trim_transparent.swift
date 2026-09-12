import AppKit
import Foundation

enum TrimError: Error {
    case usage
    case cannotLoad
    case cannotCreateImage
    case noVisiblePixels
    case cannotEncode
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: trim_transparent.swift <input-png> <output-png>\n", stderr)
    throw TrimError.usage
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let image = NSImage(contentsOf: inputURL) else { throw TrimError.cannotLoad }
var proposed = NSRect(origin: .zero, size: image.size)
guard let cg = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
    throw TrimError.cannotCreateImage
}

let rep = NSBitmapImageRep(cgImage: cg)
let width = rep.pixelsWide
let height = rep.pixelsHigh
var minX = width
var minY = height
var maxX = -1
var maxY = -1

for y in 0..<height {
    for x in 0..<width {
        if let color = rep.colorAt(x: x, y: y), color.alphaComponent > 0.02 {
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
    }
}

guard maxX >= minX, maxY >= minY else { throw TrimError.noVisiblePixels }
let padding = 8
minX = max(0, minX - padding)
minY = max(0, minY - padding)
maxX = min(width - 1, maxX + padding)
maxY = min(height - 1, maxY + padding)

let cropRect = CGRect(
    x: minX,
    y: height - 1 - maxY,
    width: maxX - minX + 1,
    height: maxY - minY + 1
)
guard let cropped = cg.cropping(to: cropRect) else { throw TrimError.cannotCreateImage }
let outputRep = NSBitmapImageRep(cgImage: cropped)
guard let data = outputRep.representation(using: .png, properties: [:]) else {
    throw TrimError.cannotEncode
}
try data.write(to: outputURL, options: .atomic)
print("Wrote \(outputURL.path) (\(cropped.width)x\(cropped.height))")
