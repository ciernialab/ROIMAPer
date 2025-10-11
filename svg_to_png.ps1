$Files = Get-ChildItem -Recurse -Include *.svg
Foreach ($file in $Files) {
    inkscape --export-type="png" --export-png-antialias=0 --export-width=1000 $file
    }