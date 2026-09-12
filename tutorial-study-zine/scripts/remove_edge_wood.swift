import AppKit
import Foundation

enum WoodRemovalError: Error {
    case usage
    case cannotLoad
    case cannotCreateImage
    case cannotCreateContext
    case cannotEncode
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: remove_edge_wood.swift <masked-input-png> <output-png>\n", stderr)
    throw WoodRemovalError.usage
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let image = NSImage(contentsOf: inputURL) else { throw WoodRemovalError.cannotLoad }
var proposed = NSRect(origin: .zero, size: image.size)
guard let cg = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
    throw WoodRemovalError.cannotCreateImage
}

let width = cg.width
let height = cg.height
let bytesPerRow = width * 4
let totalBytes = bytesPerRow * height
let storage = UnsafeMutableRawPointer.allocate(byteCount: totalBytes, alignment: 64)
defer { storage.deallocate() }
storage.initializeMemory(as: UInt8.self, repeating: 0, count: totalBytes)

let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
guard let context = CGContext(
    data: storage,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: bitmapInfo
) else { throw WoodRemovalError.cannotCreateContext }
context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

let pixels = storage.bindMemory(to: UInt8.self, capacity: totalBytes)
var visited = [UInt8](repeating: 0, count: width * height)
var queue = [Int]()
queue.reserveCapacity(width * 6 + height * 6)

func isEdgeWood(_ index: Int) -> Bool {
    let p = index * 4
    let r = Int(pixels[p])
    let g = Int(pixels[p + 1])
    let b = Int(pixels[p + 2])
    let a = Int(pixels[p + 3])
    if a < 6 { return false }
    let maximum = max(r, max(g, b))
    let warmDark = r >= g - 4 && g >= b - 12
    return maximum < 169 && warmDark
}

func enqueue(_ index: Int) {
    guard visited[index] == 0, isEdgeWood(index) else { return }
    visited[index] = 1
    queue.append(index)
}

for x in 0..<width {
    enqueue(x)
    enqueue((height - 1) * width + x)
}
for y in 0..<height {
    enqueue(y * width)
    enqueue(y * width + width - 1)
}

var head = 0
while head < queue.count {
    let index = queue[head]
    head += 1
    let x = index % width
    let y = index / width
    if x > 0 { enqueue(index - 1) }
    if x + 1 < width { enqueue(index + 1) }
    if y > 0 { enqueue(index - width) }
    if y + 1 < height { enqueue(index + width) }
}

for index in queue {
    let p = index * 4
    pixels[p] = 0
    pixels[p + 1] = 0
    pixels[p + 2] = 0
    pixels[p + 3] = 0
}

guard let outputCG = context.makeImage() else { throw WoodRemovalError.cannotCreateImage }
let rep = NSBitmapImageRep(cgImage: outputCG)
guard let data = rep.representation(using: .png, properties: [:]) else {
    throw WoodRemovalError.cannotEncode
}
try data.write(to: outputURL, options: .atomic)
print("Removed \(queue.count) connected wood pixels; wrote \(outputURL.path)")
