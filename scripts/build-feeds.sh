#!/usr/bin/env bash

#####################################################
# Used by git hub actions to create the public feeds
# DO NOT MOVE OR RENAME
#####################################################

set -euo pipefail

echo "======================================="
echo " Validating feeds"
echo "======================================="

if [ ! -d "feeds" ]; then
    echo "ERROR: feeds/ directory not found"
    exit 1
fi

if [ -z "$(ls -A feeds 2>/dev/null)" ]; then
    echo "ERROR: feeds/ directory is empty"
    exit 1
fi

echo "Feeds OK"
echo "======================================="
echo "Creating latest feed package"
echo "======================================="

function create_latest_feed_package() {
	local feed="${1}"
    local newest_vespera_ipk="$(find feeds/"${feed}"/vespera -type f -name 'vespera*.ipk' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"

    if [ -n "$newest_vespera_ipk" ]; then
            latest_copy_path="$(dirname "$newest_vespera_ipk")/vespera-latest.ipk"
            cp -f "$newest_vespera_ipk" "$latest_copy_path"
			echo "Created latest package copy: feeds/${feed}/$latest_copy_path"
	else
			echo "No vespera*.ipk package found under feeds/${feed}"
	fi
}

create_latest_feed_package "release"
create_latest_feed_package "develop"

echo "======================================="
echo " Generating feed HTML indexes"
echo "======================================="

# We will generate HTML directly inside feeds first
# (temporary stage before Jekyll copy)

html_head='
<html>
<head>
<meta charset="utf-8">
<title>Index</title>
<style>
body { font-family: monospace; }
ul { list-style: none; padding: 0; }
li { padding: 4px 0; }
.name { display:inline-block; width:60ch; }
.mtime { display:inline-block; width:20ch; }
.size { display:inline-block; width:10ch; text-align:right; }
</style>
</head>
<body>
'

# Generate index pages inside feeds
find feeds -type d | while read -r dir; do
{
    echo "$html_head"
    echo "<h1>${dir#feeds/}</h1>"
    echo "<ul>"

    parent=$(dirname "$dir")
    if [ -f "$parent/index.html" ]; then
        echo "<li><a href=\"../\">.. Parent Directory</a></li>"
    fi

    for f in "$dir"/*; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        [ "$name" = "index.html" ] && continue

        if [ -f "$f" ]; then
            size=$(stat -c %s "$f")
            size=$(numfmt --to=iec --suffix=B "$size")
            folder=""
        else
            size="-"
            folder="/"
        fi

        mtime=$(stat -c %y "$f" | cut -d'.' -f1)

        echo "<li><span class=\"name\"><a href=\"$name\">$name$folder</a></span> \
<span class=\"mtime\">$mtime</span> \
<span class=\"size\">$size</span></li>"
    done

    echo "</ul></body></html>"
} > "$dir/index.html"

done

echo "======================================="
echo " Feed validation and feed index page generation complete "
echo "======================================="
