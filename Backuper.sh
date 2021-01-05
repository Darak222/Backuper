#!/bin/sh

helpFunc()
{
    echo "Prototypowy skrypt pozwalający na wykonanie kopii zapasowej wybranego fragmentu systemu plików."
    echo "Skrypt zapisuje wszystkie akcje które wykonał (również te zakończone niepowodzniem) w pliku tekstowym log.txt"
    echo "Wszystkie kopie zapasowe zapisywane są w folderze backup a logi z ich zapisu są zapisywane w folderze archiwa.txt (wraz ze ścieżką oraz datą zapisu)"
    echo "Skrypt pozwala również na przywrócenie kopii zapasowej w wybranym przez użytkownika miejscu oraz porównywanie czy kopia zapasowa różni się od aktualnego stanu plików w systemie"
    echo "Parametry skryptu: "
    echo "-h -- Wyświetla pomoc"
    echo "-b -- Tworzy kopię zapasową wskazanej części systemu plików i zapisuje ją w folderze backup, log operacji zostaje zapisany w archiwa.txt"
    echo "-r -- Przywraca wybraną kopię zapasową w wybranym miejscu systemu"
    echo "-d -- Sprawdza czy istnieją różnicę między wskazaną kopią zapasową i plikami w systemie"
}

createBackup()
{
    if [ ! -d "backup" ]; then
        mkdir backup
    fi
    echo "Podaj nazwę pod jaką chcesz zapisać kopię zapasową"
    read NAZWA_KOPII

    echo "Wskaż fragment systemu plików (ścieżka) przeznaczony do kopii zapasowej"
    read SCIEZKA

    TIME_START=$(date +%s)

    if [ -d "$SCIEZKA" ]; then
        echo "Ścieżka jest prawidlowa, przystępuję do wykonania kopii zapasowej..."
        tar -cf "$NAZWA_KOPII".tar "$SCIEZKA"
        mv "$NAZWA_KOPII".tar backup
        echo "$NAZWA_KOPII.tar" >> archiwa.txt
        echo "$SCIEZKA" >> archiwa.txt
        CURRENT_DATE=`date`
        echo "$CURRENT_DATE" >> archiwa.txt
        echo "Utworzenie kopii zapasowej $CURRENT_DATE" >> log.txt
    else
        echo "Podana ścieżka nie istnieje, kończę proces..."
        echo "Próba utworzenia kopii zapasowej zakończona niepowodzeniem $CURRENT_DATE" >> log.txt
        exit
    fi
    TIME_STOP=$(date +%s)
    echo "Czas wykonania w sekundach: $(($TIME_STOP - $TIME_START))"
}

restoreBackup()
{
    echo "Wybierz archiwum które chcesz przywrócić (numer)"
    i=0
    j=1
    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$i" == "0" ]; then
            echo "$j $p"
            ((j = j + 1))
        fi
        if [ "$i" == "2" ]; then
            ((i = -1))
        fi
        ((i = i + 1))
    done < archiwa.txt
    read NUMER
    ((i = 0))
    ((j = 1))
    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$i" == "0" ]; then
            if [ "$j" == "$NUMER" ]; then
                CHOSEN_ARCHIVE="$p" 
                break
            fi
            ((j = j + 1))
        fi
        if [ "$i" == "2" ]; then
            ((i = -1))
        fi
        ((i = i + 1))
    done < archiwa.txt
    if [ "$CHOSEN_ARCHIVE" == "" ]; then
        echo "Nie wybrano archiwum, nastąpi teraz wyjście ze skryptu..."
        echo "Wybór archiwum zakończone niepowodzeniem `date`" >> log.txt
        exit
    fi
    echo "Wybrano archiwum $CHOSEN_ARCHIVE"
    unpackArchive "$CHOSEN_ARCHIVE"

}

unpackArchive()
{
    ARCHIWUM=$1
    echo "Podaj ścieżkę do której chcesz wypakować archiwum"
    read SCIEZKA
    if [ -d "$SCIEZKA" ]; then
        echo "Podana ścieżka jest prawidłowa, przystępuję do wypakowywania archiwum..."
        CURRENT_DATE=`date`
        echo "Wypakowanie archiwum $CURRENT_DATE" >> log.txt
        tar -xvf backup/"$ARCHIWUM".tar -C "$SCIEZKA"
        echo "Wypakowanie archiwum zakończone powodzeniem $CURRENT_DATE" >> log.txt

    else
        echo "Podana ścieżka jest nieprawidłowa"
        CURRENT_DATE=`date`
        echo "Błędna ścieżka wypakowania archiwum $CURRENT_DATE" >> log.txt
        unpackArchive "$ARCHIWUM"
    fi
}

compareBackups()
{
    ls >> temp.txt
    BAC_TEST=0

    while IFS="" read -r h || [ -n "$h" ]
    do
        if [ "$h" == "backup" ]; then
            ((BAC_TEST = 1))
            break
        fi
    done < temp.txt

    rm -r temp.txt

    if [ "$BAC_TEST" == "0" ]; then
        echo "Proszę przejść do katalogu w którym znajduje się folder z archiwami (backup)"
        echo "Niepowodzenie w sprawdzaniu różnic w archiwach i systemie plikowym `date`"
        exit
    fi

    echo "Wybierz archiwum które chcesz porównać z aktualnym stanem w systemie plikowym (numer)"
    i=0
    j=1
    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$i" == "0" ]; then
            echo "$j $p"
            ((j = j + 1))
        fi
        if [ "$i" == "2" ]; then
            ((i = -1))
        fi
        ((i = i + 1))
    done < archiwa.txt
    read NUMER
    ((i = 0))
    ((j = 1))

    while IFS="" read -r p || [ -n "$p" ]
    do
        if [ "$i" == "0" ]; then
            if [ "$j" == "$NUMER" ]; then
                CHOSEN_ARCHIVE="$p" 
                break
            fi
            ((j = j + 1))
        fi
        if [ "$i" == "2" ]; then
            ((i = -1))
        fi
        ((i = i + 1))
    done < archiwa.txt  

    LOKALIZACJA=`pwd`"/backup/$CHOSEN_ARCHIVE"
    POWROT=`pwd`
    echo "Odczytywanie statusu..."
    cd /
    echo "$LOKALIZACJA"
    tar --diff -vf "$LOKALIZACJA"
    cd "$POWROT"
    echo "Sprawdzenie różnic w systemie plikowym i archiwum `date` "
}



while getopts ":hbrd" option; do
    case $option in
        h) 
            echo "Wybrano opcję pomocy"
            helpFunc
            exit;;
        b)
            echo "Wybrano utworzenie kopii zapasowej"
            createBackup
            exit;;
        r)
            echo "Wybrano odtworzenie kopii zapasowej"
            restoreBackup
            exit;;
        d)
            echo "Wybrano sprawdzanie różnic między kopią zapasową a aktualnym stanem plików w systemie"
            compareBackups
            exit;;
        \?)
            echo "Błędny kod"
            exit;;
    esac
done

echo "Nie wybrano żadnej z opcji"


