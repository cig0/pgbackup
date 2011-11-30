#!/bin/bash
#
# Author: Pablo Gutiérrez del Castillo
# E-Mail: pablogutierrezdelc@gmail.com
#

DBUSER="postgres"
DBNAME="db3g"
HOST="localhost"
BKPDIR="/var/backups/dbs"
BKPLOG="$BKPDIR/backup.log"

PGDUMP=$(which pg_dump)
IONICE=$(which ionice)
DATE=$(date +%F-%H%M)

function help {
  echo "Uso: $0 [--binary] [--copy=user@host:/path]" && exit
}

[ $# -eq 0 ] && help && exit

# Analiza los argumentos
for arg in $@; do
  case $arg in
    --binary)
      binary="yes"
      ;;
    --copy*)
      copy="yes"
      copy_host=$(echo $arg | awk -F '=' '{ print $2 }')
      ;;
    *)
      help
      ;;
  esac
done

# Crea el directorio para los backups
if [ ! -d $BKPDIR ]; then
  echo "Making the backup directory: $BKPDIR"
  mkdir -p $BKPDIR
fi

# Limpiamos el directorio de backups
echo "Deleting old backups..."
rm -f $BKPDIR/*

# Realiza los backups
if [ "$binary" == "yes" ]; then
  echo "Full Binary Dump..."
  $IONICE -c2 -n7 $PGDUMP -h $HOST -U $DBUSER -Fc -b -v -f $BKPDIR/$DBNAME-full-$DATE.pgdump $DBNAME > $BKPLOG 2>&1
  [ $? -ne 0 ] && echo "[Failed]" && echo "Error while doing the full binary dump." | tee $BKPLOG && exit
  echo "$(date +%c): Successfully dumped $DBNAME database data to $DBNAME-full-$DATE.pgdump" >> $BKPLOG
else
  echo "Full Text Dump..."
  $IONICE -c2 -n7 $PGDUMP -h $HOST -U $DBUSER -c -v -f $BKPDIR/$DBNAME-full-$DATE.sql $DBNAME > $BKPLOG 2>&1
  [ $? -ne 0 ] && echo "[Failed]" && echo "Error while doing the full text dump." | tee $BKPLOG && exit
  echo "$(date +%c): Successfully dumped $DBNAME database data to $DBNAME-full-$DATE.sql" >> $BKPLOG
fi

# Copia el backup a un host remoto
if [ "$copy" == "yes" ]; then
  echo "Copying backup..."
  $IONICE -c2 -n7 scp $BKPDIR/*$DATE* $copy_host
  [ $? -ne 0 ] && echo "[Failed]" && echo "Error while copying the backup to $copy_host." | tee $BKPLOG && exit
  echo "$(date +%c): Successfully copied the backup to $copy_host." >> $BKPLOG
fi
