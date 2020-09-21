# makepdf
#
FROM ubuntu:19.10 as base

FROM base as builder

ENV LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential autoconf automake libtool \
  libleptonica-dev \
  zlib1g-dev \
  python3 \
  python3-distutils \
  ca-certificates \
  curl \
  git \
  imagemagick-6.q16 \
  patch

# Get the latest pip (Ubuntu version doesn't support manylinux2010)
RUN git clone https://github.com/jbarlow83/OCRmyPDF.git /app && \
  curl https://bootstrap.pypa.io/get-pip.py | python3

# Compile and install jbig2
# Needs libleptonica-dev, zlib1g-dev
RUN \
  mkdir jbig2 \
  && curl -L https://github.com/agl/jbig2enc/archive/0.29.tar.gz | \
  tar xz -C jbig2 --strip-components=1 \
  && cd jbig2 \
  && ./autogen.sh && ./configure && make && make install \
  && cd .. \
  && rm -rf jbig2

WORKDIR /app

COPY files/* /app/

RUN pip3 install --no-cache-dir \
  -r requirements/main.txt \
  . && \
  patch /etc/ImageMagick-6/policy.xml < policy.xml.diff

FROM base

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN ln -fs /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime && \
  apt-get update && apt-get install -y --no-install-recommends \
  ghostscript \
  img2pdf \
  liblept5 \
  libsm6 libxext6 libxrender-dev \
  zlib1g \
  pngquant \
  python3 \
  qpdf \
  tesseract-ocr \
  tesseract-ocr-deu \
  tesseract-ocr-eng \
  tesseract-ocr-fra \
  tesseract-ocr-dan \
  tesseract-ocr-nld \
  tesseract-ocr-swe \
  tesseract-ocr-nor \
  tesseract-ocr-ita \
  tesseract-ocr-fin \
  tesseract-ocr-ara \
  parallel \
  php \
  imagemagick-6.q16 \
  pdftk \
  poppler-utils \
  python \
  bc \
  dos2unix
#unpaper \

WORKDIR /app

COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6
COPY --from=builder /app/makepdf.sh /app/pdfsimp.py /app/brought_to_you_by.pdf /app/repaginate_booklet_scan.php /app/

RUN dos2unix makepdf.sh pdfsimp.py repaginate_booklet_scan.php && chmod +x makepdf.sh

ENTRYPOINT ["./makepdf.sh"]
#ENTRYPOINT /bin/bash
