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

echo "Running migrations..."
cd /code
python /code/manage.py makemigrations auth
python /code/manage.py migrate auth
python /code/manage.py makemigrations scoring
python /code/manage.py migrate scoring
python /code/manage.py  makemigrations
python /code/manage.py  migrate     # Apply database migrations - weird order is due to https://stackoverflow.com/questions/31417470/django-db-utils-programmingerror-relation-app-user-does-not-exist-during-ma
echo "Running loader..."
python loader.py
echo "Running collectstatic..."
python manage.py collectstatic --clear --noinput -v 0 # clearstatic files
python manage.py collectstatic --noinput -v 0 # collect static files

echo "Creating superuser..."

# Automatically create the superuser...
script="
from django.contrib.auth.models import User;

username = '$WEB_DJANGO_SUPERUSER_NAME';
password = '$WEB_DJANGO_SUPERUSER_PASSWORD';
email = '$WEB_DJANGO_SUPERUSER_EMAIL';

if User.objects.filter(username=username).count()==0:
    User.objects.create_superuser(username, email, password);
    print('Superuser created.');
else:
    print('Superuser creation skipped.');
"
printf "$script" | python manage.py shell

# Prepare log files and start outputting logs to stdout
touch /srv/logs/gunicorn.log
touch /srv/logs/access.log
tail -n 0 -f /srv/logs/*.log &
# Start the NPM build
echo "Starting..."
cd /code/frontend && npm run dev &
# Start Gunicorn processes
echo "Starting Gunicorn...."
gunicorn fragalysis.wsgi:application \
    --daemon \
    --name fragalysis \
    --bind unix:django_app.sock \
    --workers 3 \
    --log-level=debug \
    --log-file=/srv/logs/gunicorn.log \
    --access-logfile=/srv/logs/access.log

echo "Testing nginx config..."
nginx -t
echo "Running nginx..."
nginx
