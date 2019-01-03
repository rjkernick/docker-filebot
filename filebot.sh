#!/bin/bash

# This script by default uses "Automated Media Center" (AMC). See the final filebot call below. For more docs on AMC,
# visit: http://www.filebot.net/forums/viewtopic.php?t=215

#-----------------------------------------------------------------------------------------------------------------------

# Specify the URLs of any scripts that you need. They will be downloaded into /config/scripts
SCRIPTS_TO_DOWNLOAD=(
# Example:
# https://raw.githubusercontent.com/filebot/scripts/devel/cleaner.groovy
)

#-----------------------------------------------------------------------------------------------------------------------

QUOTE_FIXER='replaceAll(/[\`\u00b4\u2018\u2019\u02bb]/, "'"'"'").replaceAll(/[\u201c\u201d]/, '"'"'""'"'"')'

# Customize the renaming format here. For info on formatting: https://www.filebot.net/naming.html

# Music/Eric Clapton/From the Cradle/05 - It Hurts Me Too.mp3
MUSIC_FORMAT="Music/{n.$QUOTE_FIXER}/{album.$QUOTE_FIXER}/{media.TrackPosition.pad(2)} - {t.$QUOTE_FIXER}"

# Movies/Fight Club (year).mkv
MOVIE_FORMAT="Movies/{n.$QUOTE_FIXER} ({y}) {' CD'+pi}"

# TV Shows/Game of Thrones/Season 05/Game of Thrones - S05E08 - Hardhome.mp4
# TV Shows/Game of Thrones/Special/Game of Thrones - S00E11 - A Day in the Life.mp4
SERIES_FORMAT="TV Shows/{n}/{episode.special ? 'Special' : 'Season '+s.pad(2)}/{n} - {episode.special ? 'S00E'+special.pad(2) : s00e00} - {t.${QUOTE_FIXER}.replaceAll(/[!?.]+$/).replacePart(', Part $1')}{'.'+lang}"

. /files/FileBot.conf

if [ "$SUBTITLE_LANG" == "" ];then
  SUBTITLE_OPTION=""
else
  SUBTITLE_OPTION="subtitles=$SUBTITLE_LANG"
fi

#-----------------------------------------------------------------------------------------------------------------------

# Used to detect old versions of this script
VERSION=5

# Download scripts and such.
. /files/pre-run.sh

# See http://www.filebot.net/forums/viewtopic.php?t=215 for details on amc
filebot -script fn:amc -no-xattr --output "$OUTPUT_DIR" --log-file /files/amc.log --action copy --conflict auto \
  -non-strict --def ut_dir="$INPUT_DIR" ut_kind=multi music=y deleteAfterExtract=y clean=y \
  excludeList=/config/amc-exclude-list.txt $SUBTITLE_OPTION \
  movieFormat="$MOVIE_FORMAT" musicFormat="$MUSIC_FORMAT" seriesFormat="$SERIES_FORMAT"

if [ "$ALLOW_REPROCESSING" = "yes" ]; then
  tempfile=$(mktemp)
  # FileBot only puts files that it can process into the amc-exclude-list.txt file. e.g. jpg files are not in there. So
  # take the intersection of the existing files and the ones in the list.
  comm -12 <(sort /config/amc-exclude-list.txt) <(find /input | sort) > $tempfile
  mv -f $tempfile /config/amc-exclude-list.txt
fi
