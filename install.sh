#!/bin/bash
# Bash Menu

echo "Mediastorrent installation Script"

PS3='entrez votre chois: '
options=("Installation sans lvm" "Installation avec lvm" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Installation sans lvm")
            bash install_sans_lvm.sh
            break
            ;;
        "Installation avec lvm")
             echo "non disponible dsl"
             break
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done