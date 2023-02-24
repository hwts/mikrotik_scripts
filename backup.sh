#!/bin/bash

#vars
USER="user"
HOSTS=(
	"192.168.10.128"
	"192.168.10.122"
)
SSH_KEY="./id_rsa"
BACKUP_DIR="$HOME/backups/mikrotik"
DEBUG_MODE=0

### Ключи и аргументы
while getopts ":u:s:b:vh" arg; do
  case $arg in
    u)
      USER=$OPTARG
      ;;
    s)
      SSH_KEY=$OPTARG
      ;;
    b)
      BACKUP_DIR=$OPTARG
      ;;
    v)
      DEBUG_MODE=1
      ;;
    h)
      echo "Usage: backup.sh [-u user] [-b backup_dir] [-v enable_debug] [-h help]"
      exit 0
      ;;
    \?)
      echo "Неверный формат -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Опция -$OPTARG требует аргумента." >&2
       exit 1
      ;;
  esac
done

# Создаем директорию для хранения бекапов
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
fi

for i in "${HOSTS[@]}";
do

DEV_NAME="$(ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system identity print" | grep "name" | cut -d ":" -f2 | tr -d ' ' | tr -d '\r' )";
DATE_NOW="$(date "+%Y_%m_%d_%H_%M")";
BACKUP_NAME="${DEV_NAME}-${DATE_NOW}";
ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/export file=$BACKUP_NAME"

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system/backup/save name=$BACKUP_NAME"

scp -o StrictHostKeyChecking=no -i $SSH_KEY $USER@$i:/$BACKUP_NAME.rsc $BACKUP_DIR 

scp -o StrictHostKeyChecking=no -i $SSH_KEY $USER@$i:/$BACKUP_NAME.backup $BACKUP_DIR

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system/backup/save name=$BACKUP_NAME"

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY '/file/remove [/file find name~".backup"]'

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY '/file/remove [/file find name~".rsc"]'
done | which parallel -j 20 
