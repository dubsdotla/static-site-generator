#!/bin/swift

import Foundation

let sendOutputToBrowser = true

func directoryStatus(folder:URL, files:[URL] ) {
    print("The current state of the \(folder.lastPathComponent) directory is:")
    
    if files.count > 1 {
        for file in files {
            print("\(file.lastPathComponent)")
        }
    }
    else {
        print("The \(folder.lastPathComponent) directory is empty! :)")
    }
}


func deleteFileList(files:[URL]) {
    for file in files {
        try! FileManager.default.removeItem(at: file)
    }
}

func buildMetaData(files:[URL], inputDir:String, outputDir:String) -> [[String:String]]  {
    var pages = [[String:String]]()
    
    for file in files {
        let filePath = file.path
        let outputFilePath = file.path.replacingOccurrences(of: "\(inputDir)/", with: "\(outputDir)/")
        
        let content = try! String(contentsOf: file, encoding: .utf8)
        
        let lines = content.components(separatedBy: "\n")
        var count = 1
        var page = ["file": filePath, "outputFile": outputFilePath]
        
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
        count += 1
    }
    
    if pages.count == 0 {
        print("There is no content!")
    }
    
    return pages
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
func buildPages(contentMetaData:[[String:String]], templates:[URL]) {
    let template = try! String(contentsOf: templates[0], encoding: .utf8)
    for item in contentMetaData {
        if let filePath = item["file"] {
            let file = URL(fileURLWithPath: filePath)
            let fileContent = try! String(contentsOf: file, encoding: .utf8)
            let htmlContent = extractHTML(fileContent: fileContent)
            let finishedPage = template.replacingOccurrences(of: "{{content}}", with: htmlContent)
            if let outputFilePath = item["outputFile"] {
                let outputFile = URL(fileURLWithPath: outputFilePath)
                try! finishedPage.write(to: outputFile, atomically: false, encoding: .utf8)
            }
        }
    }
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
func openBrowser(contentMetaData:[[String:String]]) {
    if sendOutputToBrowser {
        for item in contentMetaData {
            if let outputFilePath = item["outputFile"] {
                let pageURL = URL(fileURLWithPath: outputFilePath)
                openFile(fileURL: pageURL)
            }
        }
    }
}


//Cleansing the output directory
let currentDirectoryPath = FileManager.default.currentDirectoryPath
let currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)

let outputDir = currentDirectoryURL.appendingPathComponent("docs")
let outputDirContents = try FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: nil)
let outputFiles = outputDirContents.filter{ $0.pathExtension == "html" }

//Print current status of /docs directory.
directoryStatus(folder: outputDir, files: outputFiles)

//Remove all HTML files in /docs directory.
deleteFileList(files: outputFiles)

///Building the Content MetaData
let templateDir = currentDirectoryURL.appendingPathComponent("templates")
let templateDirContents = try FileManager.default.contentsOfDirectory(at: templateDir, includingPropertiesForKeys: nil)
let templateFiles = templateDirContents.filter{ $0.pathExtension == "template" }

let inputDir = currentDirectoryURL.appendingPathComponent("content")
let inputFiles = try FileManager.default.contentsOfDirectory(at: inputDir, includingPropertiesForKeys: nil)

let contentMetaData = buildMetaData(files: inputFiles, inputDir: inputDir.lastPathComponent, outputDir: outputDir.lastPathComponent)

//Generating the Output
buildPages(contentMetaData: contentMetaData, templates: templateFiles)

//Opening output with default web browser
openBrowser(contentMetaData: contentMetaData)
