# RCEU-makepdf
Script specifically designed for www.retro-commodore.eu to process ScanTailor output into a PDF file.

Will produce a lossless PDF (relative to formats of input files) using different optimal compressions for different image types (bicolor->JBIG2 lossless for example), add OCR text overlay, a trailing page and updates the metadata .txt file.

## Prerequisites:
- Docker, e.g. https://hub.docker.com/editions/community/docker-ce-desktop-windows
- Local folder with tif/jpg/png files (ScanTailor output folder)

## How to build Docker image from this repository:
`docker build -t martinosoerensen/rceu-makepdf https://github.com/martinosoerensen/RCEU-makepdf.git`
## Alternatively, get the image from dockerhub:
`docker pull martinosoerensen/rceu-makepdf:latest`

To use the docker image, use run.cmd from a Windows command prompt and follow the guide.
