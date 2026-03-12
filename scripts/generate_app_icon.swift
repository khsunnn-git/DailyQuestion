import AppKit

let fileManager = FileManager.default
let root = fileManager.currentDirectoryPath

func loadImage(at path: String) throws -> NSImage {
  let url = URL(fileURLWithPath: path)
  guard let image = NSImage(contentsOf: url) else {
    throw NSError(domain: "generate_app_icon", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Failed to load image at \(path)",
    ])
  }
  return image
}

func pngData(from image: NSImage, size: CGSize) -> Data? {
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  )
  guard let rep else {
    return nil
  }

  rep.size = size
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSColor.clear.setFill()
  NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
  image.draw(
    in: CGRect(origin: .zero, size: size),
    from: CGRect(origin: .zero, size: image.size),
    operation: .copy,
    fraction: 1.0
  )
  NSGraphicsContext.restoreGraphicsState()
  return rep.representation(using: .png, properties: [:])
}

func writeResizedImage(from sourcePath: String, to outputPath: String, size: CGSize) throws {
  let image = try loadImage(at: sourcePath)
  guard let data = pngData(from: image, size: size) else {
    throw NSError(domain: "generate_app_icon", code: 2, userInfo: [
      NSLocalizedDescriptionKey: "Failed to render image at \(sourcePath)",
    ])
  }

  let url = URL(fileURLWithPath: outputPath)
  try fileManager.createDirectory(
    at: url.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try data.write(to: url)
}

let iconSource = "\(root)/assets/icons/Icon.png"
let backgroundSource = "\(root)/assets/icons/source_bg.png"
let foregroundSource = "\(root)/assets/icons/source_mark.png"

try writeResizedImage(
  from: iconSource,
  to: "\(root)/assets/icons/app_icon.png",
  size: CGSize(width: 1024, height: 1024)
)
try writeResizedImage(
  from: backgroundSource,
  to: "\(root)/assets/icons/ic_launcher_background.png",
  size: CGSize(width: 1024, height: 1024)
)
try writeResizedImage(
  from: foregroundSource,
  to: "\(root)/assets/icons/ic_launcher_foreground.png",
  size: CGSize(width: 1024, height: 1024)
)

print("Generated icon assets in assets/icons from Icon.png/source_bg.png/source_mark.png")
