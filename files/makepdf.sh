#!/bin/bash
# makepdf script written by Martin Sørensen for use with retro-commodore.eu
# converts a folder containing tif/jpg/png files into a single pdf file using optimal lossless formats,
# adds OCR, a scaled trailing banner page, creates a thumbnail jpg and updates the metadata txt file
#
# Before running the script, change the project folder name to the correct name

CONFIGFILE="data/settings.conf"

# Defaults used if config file does not exist:
export PDFINFO="Processed by demolition @ retro-commodore.eu"
export OCRLANGUAGES="eng" # separate with '+', e.g. "eng+dan" (choices: dan,eng,deu,nld,nor,swe,fin,fra,ita etc.)
BOOKLET_REPAGINATION="0" # set to "1" if the original was a disassembled booklet with two pages on each paper side
FRONTPAGE_FIRST="0" # Normally "0" - used if BOOKLET_REPAGINATION=="1"
OCR_ENABLE="1"

[ -f "$CONFIGFILE" ] && source "$CONFIGFILE"

# These should usually be left as is:
export TOOLSFOLDER=`dirname "$(readlink -f "$0")"` # Helper files are assumed to be in same folder as this script
export BANNERPDF="$TOOLSFOLDER/brought_to_you_by.pdf" # will be scaled to match width of page 1
export NUM_CORES="100%" # "100%" = uses all available CPU threads
export TMPFOLDER="/tmp/makepdf"

export PATH="$PATH:$TOOLSFOLDER"

# The script was tested with these versions:
# tesseract 5.0.0-alpha
# leptonica-1.79.0
#  libjpeg 8d (libjpeg-turbo 1.4.2) : libpng 1.6.20 : libtiff 4.0.6 : zlib 1.2.8
# ocrmypdf 7.4.0
# jbig2enc 0.28
# pdftk 2.02
# Python 2.7.12
# pdfinfo version 0.41.0
# convert: ImageMagick 6.8.9-9 Q16 x86_64
# identify: ImageMagick 6.8.9-9 Q16 x86_64
# GNU parallel 20161222
# perl 5, version 22, subversion 1
# gs 9.26
# bc 1.06.95
# PHP 7.0.33-0ubuntu0.16.04.9

# get additional languages from here:
# https://github.com/tesseract-ocr/tessdata_fast/
# or get package tesseract-ocr-xxx

checkexistexecutable () {
 type $1 &>/dev/null || { echo "missing '$1'" ; exit 1 ; }
}

checkexistexecutable parallel
checkexistexecutable pdftk
checkexistexecutable pdfinfo
checkexistexecutable convert
checkexistexecutable identify
checkexistexecutable jbig2
checkexistexecutable python
checkexistexecutable tesseract
checkexistexecutable ocrmypdf
checkexistexecutable perl
checkexistexecutable gs
checkexistexecutable bc
checkexistexecutable php
checkexistexecutable md5sum
checkexistexecutable sha1sum
[ -f "$TOOLSFOLDER/pdfsimp.py" ] ||  { echo "missing '$TOOLSFOLDER/pdfsimp.py'" ; exit 1 ; }

if [ "$1" = "" ]; then
  echo "missing argument"
  exit 1
fi
if [ "$2" = "" ]; then
  echo "missing argument"
  exit 1
fi
# [ -f "$1" ] || { echo "cannot find file '$1'" ; exit 1 ; }

MANUALPATH=${1//\\/"/"}
SOURCEPATH=${2//\\/"/"}

#OUTPUTFOLDER=`dirname "$(readlink -f "$1")"`
regex='^.*/([^/]+)$'
[[ $MANUALPATH =~ $regex ]] || { echo "error isolating project name from path" ; exit 1 ; }
export PROJECTNAME=${BASH_REMATCH[1]}
[[ $PROJECTNAME == "" ]] && { echo "error isolating project name from path" ; exit 1 ; }
#SOURCEFOLDER="${2%/}/" # strip trailing slash, if any

#MANUALPATH=${MANUALPATH//(/"\("}
#MANUALPATH=${MANUALPATH//)/"\)"}
#MANUALPATH=${MANUALPATH// /"\ "}
#SOURCEPATH=${SOURCEPATH//(/"\("}
#SOURCEPATH=${SOURCEPATH//)/"\)"}
#SOURCEPATH=${SOURCEPATH// /"\ "}

#PROJECTNAME="$1"
export SOURCEFOLDER="/app/mnt$SOURCEPATH"
export OUTPUTFOLDER="/app/mnt$MANUALPATH"

#echo "SOURCEFOLDER=$SOURCEFOLDER"
#echo "OUTPUTFOLDER=$OUTPUTFOLDER"
#echo "PROJECTNAME=$PROJECTNAME"
#/bin/bash
#exit

mkdir "$TMPFOLDER" 2>/dev/null
rm -R "$TMPFOLDER"/* 2>/dev/null
touch "$TMPFOLDER/jobs1"
touch "$TMPFOLDER/jobs2"
rm -f "$OUTPUTFOLDER/"*.ocr.txt 2>/dev/null
rm -f "$OUTPUTFOLDER/"*.md5 2>/dev/null
rm -f "$OUTPUTFOLDER/"*.sha1 2>/dev/null
[ `ls 2>/dev/null -Ub1 -- "$OUTPUTFOLDER/"*.txt | wc -l` -gt "1" ] && { echo "Error: more than one txt file found in output dir" ; exit 1; }
[ `ls 2>/dev/null -Ub1 -- "$OUTPUTFOLDER/"*.txt | wc -l` -eq "1" ] && TXTNAME=`ls 2>/dev/null -U1 -- "$OUTPUTFOLDER/"*.txt` || TXTNAME="$OUTPUTFOLDER/$PROJECTNAME.txt"
touch "$TXTNAME"
#echo "TXTNAME=$TXTNAME" 

parselanguages () {
 OCRLANGUAGES=`echo "$OCRLANGUAGES" | tr -d -c [a-z+]`
 LANGUAGES=${OCRLANGUAGES//+/", "}
 LANGUAGES=${LANGUAGES//dan/"Danish"}
 LANGUAGES=${LANGUAGES//eng/"English"}
 LANGUAGES=${LANGUAGES//ita/"Italian"}
 LANGUAGES=${LANGUAGES//deu/"German"}
 LANGUAGES=${LANGUAGES//nld/"Dutch"}
 LANGUAGES=${LANGUAGES//fra/"French"}
 LANGUAGES=${LANGUAGES//nor/"Norwegian"}
 LANGUAGES=${LANGUAGES//fin/"Finnish"}
 LANGUAGES=${LANGUAGES//swe/"Swedish"}
 LANGUAGES=${LANGUAGES//ara/"Arabic"}
}

updateconfig () {
 echo "PDFINFO=\"$PDFINFO\"" >"$CONFIGFILE"
 echo "OCRLANGUAGES=\"$OCRLANGUAGES\"" >>"$CONFIGFILE"
 echo "BOOKLET_REPAGINATION=\"$BOOKLET_REPAGINATION\"" >>"$CONFIGFILE"
 echo "FRONTPAGE_FIRST=\"$FRONTPAGE_FIRST\"" >>"$CONFIGFILE"
 echo "OCR_ENABLE=\"$OCR_ENABLE\"" >>"$CONFIGFILE"
 OUTPUTPDF="$PROJECTNAME.pdf"
 OUTPUTOCRTEXTFILE="$PROJECTNAME.ocr.txt"
 THUMBNAIL="$PROJECTNAME.jpg"
}

echo
echo -n "Current settings:"
SHOWMENU="1"
while [ $SHOWMENU = "1" ] ; do
 parselanguages
 updateconfig
 echo
 echo "-----------------------------------"
 echo
 echo "1: Project name: $PROJECTNAME"
 echo "2: PDF info string: $PDFINFO"
 echo "3: Languages: $LANGUAGES"
 echo -n "4: Booklet repagination: " ; [ "$BOOKLET_REPAGINATION" = "1" ] && echo "yes" ||  echo "no"; 
 echo -n "5: Front page first: " ; [ "$FRONTPAGE_FIRST" = "1" ] && echo "yes" ||  echo "no"; 
 echo -n "6: OCR: " ; [ "$OCR_ENABLE" = "1" ] && echo "yes" ||  echo "no"; 
 read -p "Option: (1-6 or 'y' to start, 'n' to exit)? " -n 1 -r ; echo
 echo "$REPLY" >/tmp/tst
 [[ $REPLY =~ ^[Yy]$ ]] && SHOWMENU="0"
 [[ $REPLY =~ ^[Nn]$ ]] && exit 1
 [ $REPLY = "1" ] && { read -p "Project name: " -ei "$PROJECTNAME" PROJECTNAME; }
 [ $REPLY = "2" ] && { read -p "PDF info string: " -ei "$PDFINFO" PDFINFO; }
 [ $REPLY = "3" ] && { tesseract --list-langs ; read -p "Languages (e.g. 'eng+dan')': " -ei "$OCRLANGUAGES" OCRLANGUAGES; }
 [ $REPLY = "4" ] && { [ "$BOOKLET_REPAGINATION" = "1" ] && BOOKLET_REPAGINATION="0" || BOOKLET_REPAGINATION="1" ; }
 [ $REPLY = "5" ] && { [ "$FRONTPAGE_FIRST" = "1" ] && FRONTPAGE_FIRST="0" || FRONTPAGE_FIRST="1" ; }
 [ $REPLY = "6" ] && { [ "$OCR_ENABLE" = "1" ] && OCR_ENABLE="0" || OCR_ENABLE="1" ; }
 [ $REPLY = $'\x1b' ] && /bin/bash
done

# download OCR language files, if missing
#for LANGUAGE in `echo "$OCRLANGUAGES" | grep -o -e "[^+]*"`; do
# [ -f "$TOOLSFOLDER/$LANGUAGE.traineddata" ] || { \
#  echo "$TOOLSFOLDER/$LANGUAGE.traineddata missing" ; \
#  wget "https://github.com/tesseract-ocr/tessdata_fast/blob/master/$LANGUAGE.traineddata" -P "$TOOLSFOLDER" || exit 1 ; }
#done

process_file() {
  PAGE=`cat "$TMPFOLDER/PAGE"`
  DPI=`cat "$TMPFOLDER/DPI"`
  FILESFOUND=`cat "$TMPFOLDER/FILESFOUND"`
  #[ "$PAGE" = "" ] && PAGE="0"
  #[ "$DPI" = "" ] && DPI="0"
  [ -e "$1" ] || continue
  BASE="${1##*/}"
  FILETYPE=${BASE##*.}
  if [[ "${FILETYPE,,}" =~ ^(tiff|tif|jpg|jpeg|png)$ ]]; then
    PAGE=$[PAGE+1]
    FILESFOUND="1"
    [ "$PAGE" = "1" ] && DPI=`identify -format "%x" "$1"`
    if identify -quiet "$1" | grep -i -q "bilevel"; then
      echo "Page $PAGE: $BASE -> JBIG2 lossless"
      echo "jbig2 -p -v \"$1\" > \"$TMPFOLDER/${BASE%.*}.jb2\" 2>/dev/null" >>"$TMPFOLDER/jobs1"
      echo "python $TOOLSFOLDER/pdfsimp.py \"$TMPFOLDER/${BASE%.*}.jb2\" > \"$TMPFOLDER/${BASE%.*}.pdf\"" >>"$TMPFOLDER/jobs2"
    else
      if [[ "${FILETYPE,,}" =~ ^(tiff|tif)$ ]]; then
        echo "Page $PAGE: $BASE -> LZW TIFF"
        echo "convert -quiet \"$1\" -compress lzw \"$TMPFOLDER/${BASE%.*}.pdf\"" >>"$TMPFOLDER/jobs1"
      else
        echo "Page $PAGE: $BASE -> direct copy"
        echo "convert -quiet \"$1\" \"$TMPFOLDER/${BASE%.*}.pdf\"" >>"$TMPFOLDER/jobs1"
      fi
    fi
  else
    echo "Skipping $1"
  fi
  echo "$DPI" >"$TMPFOLDER/DPI"
  echo "$PAGE" >"$TMPFOLDER/PAGE"
  echo "$FILESFOUND" >"$TMPFOLDER/FILESFOUND"
}
export -f process_file; 

echo "0" >"$TMPFOLDER/PAGE"
echo "0" >"$TMPFOLDER/DPI"
echo "0" >"$TMPFOLDER/FILESFOUND"
find "$SOURCEFOLDER" -maxdepth 1 -type f -name '*' -exec bash -c 'process_file "$0"' {} \;
PAGE=`cat "$TMPFOLDER/PAGE"`
DPI=`cat "$TMPFOLDER/DPI"`
FILESFOUND=`cat "$TMPFOLDER/FILESFOUND"`
[ "$FILESFOUND" = "1" ] || { echo "No files found in $SOURCEFOLDER" ; exit 1; }

echo "Converting files"
parallel -j $NUM_CORES < "$TMPFOLDER/jobs1" || exit 1
parallel -j $NUM_CORES < "$TMPFOLDER/jobs2" || exit 1

echo "Done with conversions, assembling pdf"
[ "$BOOKLET_REPAGINATION" = "1" ] && { \
 mkdir "$TMPFOLDER/unsorted/" ; \
 mv "$TMPFOLDER/"*.pdf "$TMPFOLDER/unsorted/" ; \
 php "$TOOLSFOLDER/repaginate_booklet_scan.php" "$TMPFOLDER/unsorted/" "$TMPFOLDER/" "$FRONTPAGE_FIRST" ; \
}
pdftk "$TMPFOLDER/"*.pdf cat output "$TMPFOLDER/manual.pdf" || exit 1
pdftk "$TMPFOLDER/manual.pdf" cat 1 output "$TMPFOLDER/frontpage.pdf" || exit 1
convert "$TMPFOLDER/frontpage.pdf" -resize 240x310\! -quality 80% "$OUTPUTFOLDER/$THUMBNAIL"

[ "$OCR_ENABLE" = "1" ] && { \
 echo "Running OCR with languages $OCRLANGUAGES" ; \
 ocrmypdf -l "$OCRLANGUAGES" --sidecar "$OUTPUTFOLDER/$OUTPUTOCRTEXTFILE" --output-type pdf --optimize 1 "$TMPFOLDER/manual.pdf" "$TMPFOLDER/manual1.pdf" || { tesseract --list-langs ; exit 1 ; } \
} || { OUTPUTOCRTEXTFILE="" ; cp "$TMPFOLDER/manual.pdf" "$TMPFOLDER/manual1.pdf" ; }

echo "Adding banner page and meta data"
# Scale banner page to match width of front page
PAGEWIDTH=`pdfinfo "$TMPFOLDER/frontpage.pdf" | perl -n -e'/Page size: *([0-9]+).+/i && print $1'`
PAGEHEIGHT=`echo "841*$PAGEWIDTH/595" | bc`
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dNOPAUSE -dQUIET -dBATCH -dFIXEDMEDIA -dPDFFitPage -dDEVICEHEIGHTPOINTS=$PAGEHEIGHT -dDEVICEWIDTHPOINTS=$PAGEWIDTH -dAutoRotatePages=/None -sOutputFile="$TMPFOLDER/banner.pdf" "$BANNERPDF" || exit 1
pdftk "$TMPFOLDER/manual1.pdf" "$TMPFOLDER/banner.pdf" cat output "$TMPFOLDER/manual2.pdf" || exit 1
printf "InfoBegin\nInfoKey: Author\nInfoValue: $PDFINFO" >"$TMPFOLDER/metadata.txt"
pdftk "$TMPFOLDER/manual2.pdf" update_info "$TMPFOLDER/metadata.txt" output "$OUTPUTFOLDER/$OUTPUTPDF" || exit 1

# rewrite text file with correct pagecount and languages
rm -f "$TMPFOLDER/meta.txt" 2>/dev/null
echo ""
echo "Updating fields in text file:"
DATESET="0"
COMPANYSET="0"
TEXTSET="0"
URLSET="0"
RESOLUTIONSET="0"
LANGSET="0"
PAGECOUNTSET="0"
TITLESET="0"
item_re="^([^: ]*) *: *(.*)$"
while read -r; do
 if [[ $REPLY =~ $item_re ]]; then
  if [[ ${BASH_REMATCH[1],,} == "pagecount" ]]; then
   echo "${BASH_REMATCH[1]}: $PAGE" >>"$TMPFOLDER/meta.txt"
   PAGECOUNTSET="1"
  elif [[ ${BASH_REMATCH[1],,} == "lang" ]]; then
   echo "${BASH_REMATCH[1]}: $LANGUAGES" >>"$TMPFOLDER/meta.txt"
   LANGSET="1"
  elif [[ ${BASH_REMATCH[1],,} == "resolution" ]]; then
   echo "${BASH_REMATCH[1]}: $DPI" >>"$TMPFOLDER/meta.txt"
   RESOLUTIONSET="1"
  elif [[ ${BASH_REMATCH[1],,} == "url" ]]; then
   echo "${BASH_REMATCH[1]}: $OUTPUTPDF" >>"$TMPFOLDER/meta.txt"
   URLSET="1"
  elif [[ ${BASH_REMATCH[1],,} == "text" ]]; then
   echo "${BASH_REMATCH[1]}: $OUTPUTOCRTEXTFILE" >>"$TMPFOLDER/meta.txt" ;
   TEXTSET="1"
  elif [[ ${BASH_REMATCH[1],,} == "date" ]]; then
   [[ ${BASH_REMATCH[2]} == "" ]] || { DATESET="1" ; echo "${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}" >>"$TMPFOLDER/meta.txt" ; }
  elif [[ ${BASH_REMATCH[1],,} == "company" ]]; then
   [[ ${BASH_REMATCH[2]} == "" ]] || { COMPANYSET="1" ; echo "${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}" >>"$TMPFOLDER/meta.txt" ; }
  elif [[ ${BASH_REMATCH[1],,} == "title" ]]; then
   [[ ${BASH_REMATCH[2]} == "" ]] || { TITLESET="1" ; echo "${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}" >>"$TMPFOLDER/meta.txt" ; }
  else
   echo "${BASH_REMATCH[1]}: ${BASH_REMATCH[2]}" >>"$TMPFOLDER/meta.txt"
  fi
 else
  echo "$REPLY" >>"$TMPFOLDER/meta.txt"
 fi
done < "$TXTNAME"
echo "url: $OUTPUTPDF"
echo "lang: $LANGUAGES"
echo "text: $OUTPUTOCRTEXTFILE"
echo "pagecount: $PAGE"
echo "resolution: $DPI"
[ "$URLSET" = "0" ] && echo "url: $OUTPUTPDF" >>"$TMPFOLDER/meta.txt"
[ "$COMPANYSET" = "0" ] && { echo "Warning: 'company' field undefined" ; echo "company: " >>"$TMPFOLDER/meta.txt" ; }
[ "$LANGSET" = "0" ] && echo "lang: $LANGUAGES" >>"$TMPFOLDER/meta.txt"
[ "$TEXTSET" = "0" ] && echo "text: $OUTPUTOCRTEXTFILE" >>"$TMPFOLDER/meta.txt"
[ "$PAGECOUNTSET" = "0" ] && echo "pagecount: $PAGE" >>"$TMPFOLDER/meta.txt"
[ "$RESOLUTIONSET" = "0" ] && echo "resolution: $DPI" >>"$TMPFOLDER/meta.txt"
[ "$DATESET" = "0" ] && { echo "Warning: 'date' field undefined" ; echo "date: " >>"$TMPFOLDER/meta.txt" ; }
[ "$TITLESET" = "0" ] && { echo "Warning: 'title' field undefined" ; echo "title: " >>"$TMPFOLDER/meta.txt" ; }
rm -f "$TXTNAME"
mv "$TMPFOLDER/meta.txt" "$OUTPUTFOLDER/$PROJECTNAME.txt"

ORGPATH=`pwd`
cd "$OUTPUTFOLDER"
rm -f *.md5
rm -f *.sha1
md5sum -b "$OUTPUTPDF" >"$OUTPUTPDF.md5"
sha1sum -b "$OUTPUTPDF" >"$OUTPUTPDF.sha1"
[ "$OCR_ENABLE" = "1" ] && { \
 md5sum -b "$OUTPUTOCRTEXTFILE" >"$OUTPUTOCRTEXTFILE.md5" ; \
 sha1sum -b "$OUTPUTOCRTEXTFILE" >"$OUTPUTOCRTEXTFILE.sha1" ; \
}
for f in *.zip; do
  [ -e "$f" ] || continue
  md5sum -b "$f" >"$f.md5"
  sha1sum -b "$f" >"$f.sha1"
done
cd "$ORGPATH"

rm -R "$TMPFOLDER" 2>/dev/null
echo ""
echo "Finished: $OUTPUTFOLDER/$OUTPUTPDF"
