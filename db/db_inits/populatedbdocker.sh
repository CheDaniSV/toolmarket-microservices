#!/bin/bash

docker compose exec db psql -U toolmarket -d toolmarket -f /pre-seed/init_schema.sql --single-transaction