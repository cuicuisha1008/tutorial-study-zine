import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Vision

enum CutoutError: Error {
    case usage
    case cannotLoadImage
    case cannotCreateCGImage
    case noObservation
    case cannotRender
    case cannotEncode
}

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: extract_foreground.swift <input-image> <output-png>\n", stderr)
    throw CutoutError.usage
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let source = NSImage(contentsOf: inputURL) else {
    throw CutoutError.cannotLoadImage
}

var proposedRect = NSRect(origin: .zero, size: source.size)
guard let sourceCG = source.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
    throw CutoutError.cannotCreateCGImage
}

let request = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(cgImage: sourceCG, options: [:])
try handler.perform([request])

guard let observation = request.results?.first else {
    throw CutoutError.noObservation
}

let maskBuffer = try observation.generateScaledMaskForImage(
    forInstances: observation.allInstances,
    from: handler
)

let sourceCI = CIImage(cgImage: sourceCG)
let maskCI = CIImage(cvPixelBuffer: maskBuffer)

let transparent = CIImage(color: .clear).cropped(to: sourceCI.extent)
let blend = CIFilter.blendWithMask()
blend.inputImage = sourceCI
blend.backgroundImage = transparent
blend.maskImage = maskCI

guard let composited = blend.outputImage else {
    throw CutoutError.cannotRender
}

let context = CIContext(options: [
    .useSoftwareRenderer: false,
    .cacheIntermediates: false
])

guard let outputCG = context.createCGImage(composited, from: sourceCI.extent) else {
    throw CutoutError.cannotRender
}

let rep = NSBitmapImageRep(cgImage: outputCG)
guard let data = rep.representation(using: .png, properties: [:]) else {
    throw CutoutError.cannotEncode
}

try data.write(to: outputURL, options: .atomic)
print("Wrote \(outputURL.path) (\(outputCG.width)x\(outputCG.height))")
