#!/bin/bash

docker compose exec db psql -U postgres -d toolmarket -f /pre-seed/init_schema.sql --single-transaction