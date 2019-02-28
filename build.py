# Importing dependencies
import os
import webbrowser
import readline
import glob

#Optional. True opens in Firefox after building site.
send_output_to_browser = True 

def directoryStatus(folder, fileNames):
	print('The current state of the', folder, 'directory is:')
	if len(fileNames) > 1:
		print(fileNames)
	else:
		print('The', folder, 'directory is empty! :)')

def deleteFileList(files):
	for file in files:
		os.remove(file)

def buildMetaData(files, inputDir, outputDir):
	pages = []
	for file in files:
		# print('24', file)
		outputFile = file.replace(inputDir + '/',outputDir + '/')
		# print('26', outputFile)
		content = open(file).read()
		lines = content.splitlines()
		count = 1
		page = {'file': file, 'outputFile': outputFile,}
		for line in lines:
			if line.startswith('***'):
				line = line.strip('*')
				key = line.split(":", maxsplit=1)[0]
				value = line.split(": ", maxsplit=1)[1]
				page[key] = value
		pages.append(page)
		count += 1
	if len(pages) > 1:
		return pages
	return 'There is no content!'

	# Extract HTML from input files
def extractHTML(file):
	# print(file)
	extracted = ''
	lines = file.splitlines()
	for line in lines:
		if not line.startswith('***'):
			extracted = extracted + line
	return extracted

# Build the pages
def buildPages(contentMetaData, templates):
	template = open(templates[0]).read()
	for item in contentMetaData:
		file_content = open(item['file']).read()
		html_content = extractHTML(file_content)
		finished_page = template.replace("{{content}}", html_content)
		open(item['outputFile'], 'w+').write(finished_page)

# Optionally open output in web browser
def open_firefox(contentMetaData):
	if send_output_to_browser == True:
		docs_path = "file://" + os.path.abspath('') + "/"
		print(docs_path)
		for item in contentMetaData:
			webbrowser.open(docs_path + item['outputFile'])

def main():
####################################################
### Cleansing the output directory ###
####################################################
	outputDir = 'docs'
	outputFiles = glob.glob(outputDir+'/'+'*.html')
	print('41',outputFiles)

	# Print current status of /docs directory.
	directoryStatus(outputDir, outputFiles)

	# Remove all HTML files in /docs directory.
	deleteFileList(outputFiles)
####################################################
### Building the Content MetaData ###
####################################################
	templateDir = 'templates'
	templates = glob.glob(templateDir+'/'+'*.template')

	inputDir = 'content'
	inputFiles = glob.glob(inputDir+'/'+'*.*')

	# print('43', inputFiles)
	# print('44', templates)

	contentMetaData = buildMetaData(inputFiles, inputDir, outputDir)
	#print(contentMetaData)
####################################################
### Generating the Output ###
####################################################
	buildPages(contentMetaData, templates)
####################################################
### Opening output with Firefox ###
####################################################
	open_firefox(contentMetaData)

if __name__ == "__main__":
	main()