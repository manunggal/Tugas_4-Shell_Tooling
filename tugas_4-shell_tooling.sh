#!/bin/bash

echo "This program will stack two ecommerce data in csv format, \
select event_type of purchase, create two columns of product category and product name \
from category_code"

#take first file
echo "insert first file name:"
read file_pertama

#take second file
echo "insert second file name:"
read file_kedua

# stack first file and second file, saved as csv file
csvstack $file_pertama $file_kedua > stacked_files.csv

# Filter event_type = purchase
csvgrep stacked_files.csv -c 3 -m "purchase" > filtered_purchase.csv

# create new column category_name where values first strings before first dot in category_code
csvsql --query "SELECT *, substr(category_code, instr(category_code, '.'), -LENGTH(category_code)) AS category from filtered_purchase" filtered_purchase.csv > new_cl_category_name.csv

# create new column product_name where value from last strings before last dot in category_code
csvsql --query "SELECT *, replace(category_code, rtrim(category_code, replace(category_code, '.', '')), '') AS product_name from new_cl_category_name" new_cl_category_name.csv > new_product_name.csv

# select relevant columns
csvcut new_product_name.csv -c 2,3,4,5,7,8,11,12 > final_data.csv

# remove unused files
rm stacked_files.csv filtered_purchase.csv new_cl_category_name.csv

# display head result
head final_data.csv | csvlook
csvcut -n final_data.csv




