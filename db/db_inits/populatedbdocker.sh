#!/bin/bash

docker compose exec -T -i db psql -U postgres -d toolmarket  < ./populatedb.sql