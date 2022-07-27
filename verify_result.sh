#!/bin/bash

echo "csv file to be verified:"
read file_csv

cat $file_csv | wc

cat $file_csv | grep electronics | grep smartphone| awk -F ',' '{print $5}'| sort | uniq -c | sort -nr
