# RCEU-makepdf
Script specifically designed for www.retro-commodore.eu to process ScanTailor output into a PDF file.

Will produce a lossless PDF (relative to formats of input files) using different compressions for different image types (bicolor->JBIG2 lossless for example), add OCR text using specified languages, a trailing page and a .txt file with metadata as used by the backend.

## Prerequisites:
- Docker, e.g. https://hub.docker.com/editions/community/docker-ce-desktop-windows
- Local folder with tif/jpg/png files (ScanTailor output folder)
- Docker configured to allow access to local drive with source folder

## Get image from DockerHub:
`docker pull martinosoerensen/rceu-makepdf:latest`

## How to manually build and run:
- build.cmd - Builds the Docker image using Docker for Windows
- run.cmd - Starts the Docker image
