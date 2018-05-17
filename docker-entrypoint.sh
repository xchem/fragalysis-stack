#!/bin/bash
# Wait for media
date
echo "Waiting for media..."
until [ -f /code/media/loaded ]
do
    sleep 2
done
date
echo "Media is ready."
/code/launch-stack.sh