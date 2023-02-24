#!/bin/bash

#vars
USER="user"
HOSTS=(
	"192.168.10.128"
	"192.168.10.122"
)
SSH_KEY="./id_rsa"

for i in "${HOSTS[@]}";
do

DEV_NAME="$(ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system identity print" | grep "name" | cut -d ":" -f2 | tr -d ' ' | tr -d '\r' )";
DATE_NOW="$(date "+%Y_%m_%d_%H_%M")";
BACKUP_NAME="${DEV_NAME}-${DATE_NOW}";
ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/export file=$BACKUP_NAME"

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system/backup/save name=$BACKUP_NAME"

scp -o StrictHostKeyChecking=no -i $SSH_KEY $USER@$i:/$BACKUP_NAME.rsc ./ 

scp -o StrictHostKeyChecking=no -i $SSH_KEY $USER@$i:/$BACKUP_NAME.backup ./ 

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY "/system/backup/save name=$BACKUP_NAME"

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY '/file/remove [/file find name~".backup"]'

ssh -o StrictHostKeyChecking=no $USER@$i -i $SSH_KEY '/file/remove [/file find name~".rsc"]'
done | which parallel -j 3 
