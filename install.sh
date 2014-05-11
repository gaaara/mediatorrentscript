#!/bin/bash
# Bash Menu

echo "Mediastorrent installation Script"

PS3='entrez votre chois: '
options=("Installation avec lvm" "Installation sans lvm" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Installation avec lvm")
            bash install_sans_lvm.sh
            break
            ;;
        "Installation sans lvm")
             echo "non disponible dsl"
             break
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
