up-project: docker-up up-migrations

up-migrations: install-structure load-data

down-db:
	docker-compose exec ch_server bash -c "cat /var/lib/migrations/down.sql | clickhouse-client -mn -u ch_user --password 123456"

docker-up:
	docker-compose up -d

install-structure:
	docker-compose exec ch_server bash -c "cat /var/lib/migrations/structure.sql | clickhouse-client -mn -u ch_user --password 123456"

load-data:
	docker-compose exec ch_server bash -c 'cat /var/lib/migrations/first_clicks.csv | clickhouse-client -u ch_user --password 123456 --query="INSERT INTO ch_test_db.first_clicks FORMAT CSV";cat /var/lib/migrations/correct_clicks.csv | clickhouse-client -u ch_user --password 123456 --query="INSERT INTO ch_test_db.correct_clicks FORMAT CSV"'