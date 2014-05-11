#!/bin/bash
# Bash Menu

clear

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
             bash install_avec_lvm.sh
             break
            ;;
         "Logiciel optionnelle")
             echo "pas disponible"
             break
            ;;
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
