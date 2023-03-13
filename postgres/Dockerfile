FROM postgres:14.5

COPY postgresql.conf /etc/postgresql/postgresql.conf

CMD docker-entrypoint.sh -c 'config_file=/etc/postgresql/postgresql.conf'