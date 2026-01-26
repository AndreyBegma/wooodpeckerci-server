#!/bin/bash

set -e

SERVER=""
REMOTE_PATH="/var/app/apps/woodpecker"

echo "Deploying Woodpecker CI to $SERVER..."

rsync --progress -vrz --filter='merge deploy.filter' ./ $SERVER:$REMOTE_PATH/

# ssh $SERVER "cd $REMOTE_PATH && docker compose --profile server pull && docker compose --profile server up -d"

echo "Files synced!"
