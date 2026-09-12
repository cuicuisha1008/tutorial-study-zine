import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum MaskError: Error {
    case usage
    case cannotLoad
    case cannotCreateImage
    case cannotCreateContext
    case cannotRender
    case cannotEncode
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: mask_notebook_pages.swift <input-image> <output-png>\n", stderr)
    throw MaskError.usage
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let image = NSImage(contentsOf: inputURL) else { throw MaskError.cannotLoad }
var proposed = NSRect(origin: .zero, size: image.size)
guard let sourceCG = image.cgImage(forProposedRect: &proposed, context: nil, hints: nil) else {
    throw MaskError.cannotCreateImage
}

let width = sourceCG.width
let height = sourceCG.height
let colorSpace = CGColorSpaceCreateDeviceGray()
guard let maskContext = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.none.rawValue
) else { throw MaskError.cannotCreateContext }

maskContext.setFillColor(gray: 0, alpha: 1)
maskContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
maskContext.setFillColor(gray: 1, alpha: 1)
maskContext.setAllowsAntialiasing(true)
maskContext.setShouldAntialias(true)

func point(_ x: CGFloat, _ topY: CGFloat) -> CGPoint {
    CGPoint(x: x * CGFloat(width), y: (1 - topY) * CGFloat(height))
}

func fillPolygon(_ points: [(CGFloat, CGFloat)]) {
    guard let first = points.first else { return }
    let path = CGMutablePath()
    path.move(to: point(first.0, first.1))
    for p in points.dropFirst() { path.addLine(to: point(p.0, p.1)) }
    path.closeSubpath()
    maskContext.addPath(path)
    maskContext.fillPath()
}

// 两张纸页分别描边，避开深色桌面；细长中缝保留活页环与装订阴影。
fillPolygon([
    (0.000, 0.078), (0.221, 0.098), (0.225, 0.810),
    (0.154, 0.872), (0.000, 0.842)
])
fillPolygon([
    (0.250, 0.096), (0.905, 0.128), (0.927, 0.862),
    (0.870, 0.892), (0.154, 0.872), (0.232, 0.790)
])
fillPolygon([
    (0.168, 0.155), (0.275, 0.155), (0.266, 0.787), (0.148, 0.787)
])

guard let maskCG = maskContext.makeImage() else { throw MaskError.cannotCreateImage }
let sourceCI = CIImage(cgImage: sourceCG)
let maskCI = CIImage(cgImage: maskCG)
let transparent = CIImage(color: .clear).cropped(to: sourceCI.extent)
let blend = CIFilter.blendWithMask()
blend.inputImage = sourceCI
blend.backgroundImage = transparent
blend.maskImage = maskCI
guard let outputCI = blend.outputImage else { throw MaskError.cannotRender }

let context = CIContext(options: [.cacheIntermediates: false])
guard let outputCG = context.createCGImage(outputCI, from: sourceCI.extent) else {
    throw MaskError.cannotRender
}
let rep = NSBitmapImageRep(cgImage: outputCG)
guard let data = rep.representation(using: .png, properties: [:]) else {
    throw MaskError.cannotEncode
}
try data.write(to: outputURL, options: .atomic)
print("Wrote \(outputURL.path) (\(outputCG.width)x\(outputCG.height))")
