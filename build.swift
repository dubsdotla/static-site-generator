#!/bin/swift

import Foundation

let sendOutputToBrowser = true

let fileManager = FileManager.default
let currentDirectoryPath = fileManager.currentDirectoryPath
let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
let docsURL = currentDirectoryURL.appendingPathComponent("docs")

let docsContents = try fileManager.contentsOfDirectory(at: docsURL, includingPropertiesForKeys: nil)
let htmlFiles = docsContents.filter{ $0.pathExtension == "html" }

// Remove all HTML files in /docs.
for htmlFile in htmlFiles {
    try fileManager.removeItem(at: htmlFile)
}

// Read in the entire template
let templateURL = currentDirectoryURL.appendingPathComponent("templates/base.html")
var template = try String(contentsOf: templateURL, encoding: .utf8)

let contentURL = currentDirectoryURL.appendingPathComponent("content")
let contentContents = try fileManager.contentsOfDirectory(at: contentURL, includingPropertiesForKeys: nil)

// Build 'pages' dictionary
var pages = [[String:String]]()

for contentFile in contentContents {
    let inputFilePath = "content/" + contentFile.lastPathComponent
    let outputFilePath = "docs/" + contentFile.lastPathComponent
    let inputURL = currentDirectoryURL.appendingPathComponent(inputFilePath)
    let input = try String(contentsOf: inputURL, encoding: .utf8)
    let lines = input.components(separatedBy: "\n")
    var page = ["inputFilePath": inputFilePath, "outputFilePath": outputFilePath]
    
    for line in lines {
        if line.hasPrefix("***") {
            let line = line.replacingOccurrences(of: "***", with: "")
            let lineArray = line.components(separatedBy: ":")
            let key = lineArray[0]
            let value = lineArray[1]
            page[key] = value
        }
    }
    pages.append(page)
}

//Extract HTML from input files
func extractHTML(fileContent: String) -> String {
    var extracted = ""
    let lines = fileContent.components(separatedBy: "\n")
    for line in lines {
        if !line.hasPrefix("***") {
            extracted = extracted + line
        }
    }
    return extracted
}

//Build the pages
for contentFile in contentContents {
    let inputFilePath = "content/" + contentFile.lastPathComponent
    let inputURL = currentDirectoryURL.appendingPathComponent(inputFilePath)
    let input = try String(contentsOf: inputURL, encoding: .utf8)
    
    let htmlContent = extractHTML(fileContent: input)
    let finishedPage = template.replacingOccurrences(of: "{{content}}", with: htmlContent)
    
    let outputFilePath = "docs/" + contentFile.lastPathComponent
    let outputURL = currentDirectoryURL.appendingPathComponent(outputFilePath)
    try finishedPage.write(to: outputURL, atomically: false, encoding: .utf8)
}

//Open file in default browser
func openFile(fileURL: URL) {
    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = [fileURL.path]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
}

//Open pages in browser if "sendOutputToBrowser" is true
if sendOutputToBrowser {
    for page in pages {
        if let pageOutputFilePath = page["outputFilePath"] {
            let pageURL = currentDirectoryURL.appendingPathComponent(pageOutputFilePath)
            
            openFile(fileURL: pageURL)
        }
    }
}
