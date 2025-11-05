#!/usr/bin/swift

import AppKit  // NSRunningApplication, NSWorkspace
import ApplicationServices  // AXIsProcessTrustedWithOptions
import Carbon  // kVK_ANSI_* constants (可選)
import CoreGraphics  // CGEvent
import Foundation

let VERSION = "1.0.0"

// 先處理「-v / --version」參數
let rawArgs = CommandLine.arguments

if rawArgs.contains("-v") || rawArgs.contains("--version") {
    print("pbadds version \(VERSION)")
    exit(0)
}

let sourceFiles: [URL] = {
    // 取得所有參數，排除程式本身
    let args = CommandLine.arguments.dropFirst()

    // 如果沒有參數，直接回傳空陣列（或你想要的預設值）
    guard !args.isEmpty else {
        print("⚠️ No file path was passed in, exit program.")
        exit(0)
    }

    // 轉成 URL，並檢查路徑是否存在
    return args.compactMap { path -> URL? in
        let url = URL(fileURLWithPath: path)

        // 標準化（去除 ..、. 等）並解析 symlink
        let absoluteURL = url.standardizedFileURL  // 這一步已經把相對路徑轉成絕對

        guard FileManager.default.fileExists(atPath: absoluteURL.path) else {
            print("❌ path does not exist: \(path)")
            return nil
        }
        return absoluteURL
    }
}()

// 暫存資料夾：~/mytmp/tmp_clipboard_dir
let homeURL = FileManager.default.homeDirectoryForCurrentUser
let mytmpURL = homeURL.appendingPathComponent("mytmp")
let tmpFolder = mytmpURL.appendingPathComponent("tmp_clipboard_dir")

func requestAccessibilityPermission() {
    let options =
        [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
}

func sendCommandKey(_ keyCode: CGKeyCode) {
    guard let src = CGEventSource(stateID: .combinedSessionState) else { return }
    if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
    {
        let flags = CGEventFlags.maskCommand
        keyDown.flags = flags
        keyUp.flags = flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

func activateFinder() {
    // 只保留 .activateAllWindows，已不需要忽略其他程式
    if let finder = NSRunningApplication.runningApplications(
        withBundleIdentifier: "com.apple.finder"
    ).first {
        _ = finder.activate(options: [.activateAllWindows])
    }
}

// main
do {
    // 1. 建立 ~/mytmp (若不存在)
    try FileManager.default.createDirectory(
        at: mytmpURL,
        withIntermediateDirectories: true,
        attributes: nil)

    // 2. 刪除舊的 tmp_clipboard_dir (若存在)
    if FileManager.default.fileExists(atPath: tmpFolder.path) {
        try FileManager.default.removeItem(at: tmpFolder)
    }

    // 3. 建立新的 tmp_clipboard_dir
    try FileManager.default.createDirectory(
        at: tmpFolder,
        withIntermediateDirectories: true,
        attributes: nil)

    // 4. 複製檔案到 tmp_clipboard_dir
    for srcURL in sourceFiles {
        let dstURL = tmpFolder.appendingPathComponent(srcURL.lastPathComponent)
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    }

    // 5. 用 Finder 打開該資料夾
    NSWorkspace.shared.open(tmpFolder)  // 把 Finder 拉到前景

    // 6. 若想確保 Finder 前置（可選）
    activateFinder()

    // 7. 確認無障礙權限
    requestAccessibilityPermission()
    NSPasteboard.general.clearContents()  // 清空剪貼簿(不然有殘留，會影響到後面的內容)

    // 8. Cmd‑A (全選) → Cmd‑C (複製)
    // Warn: Finder中可能要用成只檢示該目錄(即: 沒有其它目錄的顯示, 不然可能也會沒複製到)
    // sendCommandKey(0x00)  // 'A'
    sendCommandKey(CGKeyCode(kVK_ANSI_A))
    // usleep(200_000) // Caution: 太快會不行複製成功
    usleep(900_000)
    sendCommandKey(CGKeyCode(kVK_ANSI_C))  // 'C' 0x08
    usleep(900_000)

    // 9. ~~(可選) 刪除暫存資料夾~~ 刪除之後貼上後就會變成檔案路徑
    // try FileManager.default.removeItem(at: tmpFolder)

    print("✅ OK")
} catch {
    print("❌ Error：\(error)")
}
