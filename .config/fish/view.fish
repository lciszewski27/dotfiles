function view_file
    set filepath $argv[1]
    set mimetype (file --mime-type -b $filepath | string trim)

    if string match -q 'text/*' $mimetype
        echo "Tekstowy plik: $filepath"
        bat $filepath
    else if string match -q 'image/*' $mimetype
        echo "Graficzny plik: $filepath"
        kitten icat $filepath
    else
        echo "Nieobsługiwany typ pliku: $filepath ($mimetype)"
    end
end

function view
    set path $argv[1]

    if test -f $path
        echo "$path jest plikiem."
        view_file $path
    else if test -d $path
        echo "$path jest katalogiem."
        for file in (find $path -maxdepth 1 -type f)
            view_file $file
        end
    else
        echo "$path nie jest ani plikiem, ani katalogiem."
    end
end
