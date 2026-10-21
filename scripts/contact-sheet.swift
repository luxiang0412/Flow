#!/usr/bin/env swift
// Build a labelled contact sheet from capture PNGs (macOS host tool).
// Usage: swift scripts/contact-sheet.swift out.png 'label:path' 'label:path' ...
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count >= 2 else { fatalError("need output path") }
let outPath = args[1]
let entries: [(String, NSImage)] = args.dropFirst(2).compactMap { raw in
    let parts = raw.split(separator: ":", maxSplits: 1)
    guard parts.count == 2, let img = NSImage(contentsOfFile: String(parts[1])) else {
        print("skip: \(raw)"); return nil
    }
    return (String(parts[0]), img)
}
guard !entries.isEmpty else { fatalError("no images") }

let cols = 3
let thumbW: CGFloat = 360
let pad: CGFloat = 12
let labelH: CGFloat = 34
let rows = Int(ceil(Double(entries.count) / Double(cols)))
let cellH = ceil(thumbW * 1113.0 / 512.0) + labelH + pad * 2
let W = CGFloat(cols) * (thumbW + pad) + pad
let H = CGFloat(rows) * cellH + pad

let canvas = NSImage(size: NSSize(width: W, height: H))
canvas.lockFocus()
NSColor.black.setFill()
NSRect(x: 0, y: 0, width: W, height: H).fill()
NSColor.white.setFill()
let font = NSFont.systemFont(ofSize: 18)

for (i, entry) in entries.enumerated() {
    let c = i % cols, r = i / cols
    let x = pad + CGFloat(c) * (thumbW + pad)
    let y = H - pad - CGFloat(r + 1) * cellH
    let aspect = entry.1.size.width / entry.1.size.height
    var w = thumbW
    var hh = thumbW / aspect
    if hh > cellH - labelH - pad * 2 { hh = cellH - labelH - pad * 2; w = hh * aspect }
    let rect = NSRect(x: x, y: y + labelH, width: w, height: hh)
    entry.1.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    let labelRect = NSRect(x: x + 2, y: y + labelH + hh - 22, width: w, height: 22)
    entry.0.draw(in: labelRect, withAttributes: [
        .font: font, .foregroundColor: NSColor.white,
        .backgroundColor: NSColor.black.withAlphaComponent(0.55)])
}
canvas.unlockFocus()
let tiff = canvas.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) (\(entries.count) frames)")