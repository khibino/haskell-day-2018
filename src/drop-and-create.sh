#!/bin/sh

db=haskell-day

set -x

psql $db < haskell-day.drop.sql
psql $db < haskell-day.sql
