#!/usr/bin/env bash
set -u
set -e

# Configurable items
PGBOUNCER_HOSTS="pgb1" # you can add any pgbouncer host here
PGBOUNCER_DATABASE_INI="/etc/pgbouncer/pgbouncer.database.ini"
PGBOUNCER_DATABASE="test_db"
PGBOUNCER_PORT=6432

REPMGR_DB="repmgr"
REPMGR_USER="repmgr"
REPMGR_SCHEMA="repmgr_cluster1"

# manager user password
export PGPASSWORD=manager_password

# 1. Pause running pgbouncer instances
for HOST in $PGBOUNCER_HOSTS
do
    psql -t -c "pause" -h $HOST -p $PGBOUNCER_PORT -U manager pgbouncer
done

# 2. Promote this node from standby to master

repmgr standby promote -f /etc/repmgr.conf --log-to-file

# 3. Reconfigure pgbouncer instances

PGBOUNCER_DATABASE_INI_NEW="/tmp/pgbouncer.database.ini"

for HOST in $PGBOUNCER_HOSTS
do
    # Recreate the pgbouncer config file
    echo -e "[databases]\n" > $PGBOUNCER_DATABASE_INI_NEW

    psql -d $REPMGR_DB -U $REPMGR_USER -t -A \
      -c "SELECT '${PGBOUNCER_DATABASE}= host=' || name || ' dbname=${PGBOUNCER_DATABASE}' \
          FROM ${REPMGR_SCHEMA}.repl_nodes \
          WHERE active = TRUE AND type='master'" >> $PGBOUNCER_DATABASE_INI_NEW

    rsync $PGBOUNCER_DATABASE_INI_NEW $HOST:$PGBOUNCER_DATABASE_INI --inplace || EXIT_CODE=$? && true
    
    echo $EXIT_CODE

    psql -tc "reload" -h $HOST -p $PGBOUNCER_PORT -U manager pgbouncer
    psql -tc "resume" -h $HOST -p $PGBOUNCER_PORT -U manager pgbouncer

done

# Clean up generated file
rm $PGBOUNCER_DATABASE_INI_NEW

echo "Reconfiguration of pgbouncer complete"
