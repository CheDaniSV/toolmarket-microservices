#!/bin/bash

createdb -U postgres toolmarket

cat populatedb.sql | psql -U postgres -d toolmarket --single-transaction -f-

