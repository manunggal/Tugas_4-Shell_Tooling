#!/bin/bash

echo "This program will stack two ecommerce data in csv format, \
select event_type of purchase, create two columns of product category and product name \
from category_code"

# success message strings
stacking_success='Files successfully stacked'
filtering_columns_success='New Columns successfully created'
filtering_elements_success='Elements/keywords successfully filtered'
seleting_success='Columns succesfully selected'

# error message strings
stacking_error='Error: Failed to stack the files'
filtering_columns_error='Error: Failed to create new columns'
filtering_elements_error='Error: Failed to separate the contents/keywords'
selecting_error='Error: Failed to select columns'

# provide error info for failed step
error_status() {
	if [ $test_exit -eq 0 ]
	then
		echo $1
	else
		echo $2
		echo 'exiting..'
		exit
	fi
}


#take first file
echo "insert first file name:"
read file_pertama


#take second file
echo "insert second file name:"
read file_kedua

# stack first file and second file, saved as csv file
csvstack $file_pertama $file_kedua > stacked_files.csv
# check if stacking success
test_exit=$?
error_status "$stacking_success" "$stacking_error"


# Filtering keyword
# define filtering keyword
filter_keyword="purchase"

# filter column event_type (3) with filterkeyword, save result as csv file
csvgrep stacked_files.csv -c 3 -m $filter_keyword > filtered_data.csv
# check if filtering success
test_exit=$?
error_status "$filtering_elements_success" "$filtering_elements_error"

# Check filtered data, search if filter keyword exists in result, save result as txt file (result 0, no matching result) 
csvcut -c event_type filtered_data.csv |csvgrep -c event_type -m $filter_keyword|csvstat|tail -n 1 > filtered_result.txt

# take the row count numbers
row_numbers=$(cat filtered_result.txt | awk '{ print substr( $0, 12 ) }')

# if row count = 0, no matching keyword found in the filtered column (return of filter = 0 row)
if [ "$row_numbers" -gt 0 ]
then
	echo -n "Numbers of rows with matched keyword, "
	cat filtered_result.txt
else
	echo -n "No matching strings found, "
	cat filtered_result.txt
	echo 'exiting due to no matching filtered keyword'
	exit
fi


# create new column category_name where values first strings before first dot in category_code
csvsql --query "SELECT *, substr(category_code, instr(category_code, '.'), -LENGTH(category_code)) AS category from filtered_data" filtered_data.csv > new_cl_category.csv
# check if new column creation success
test_exit=$?
error_status "$filtering_columns_success" "$filtering_columns_error"


# create new column product_name where value from last strings before last dot in category_code
csvsql --query "SELECT *, replace(category_code, rtrim(category_code, replace(category_code, '.', '')), '') AS product_name from new_cl_category" new_cl_category.csv > new_cl_productname.csv
# check if new column creation success
test_exit=$?
error_status "$filtering_columns_success" "$filtering_columns_error"

# select relevant columns
csvcut new_cl_productname.csv -c 2,3,4,5,7,8,11,12 > final_data.csv
# check if select columns success
test_exit=$?
error_status "$selecting_success" "$selecting_error"

# remove unused files
rm stacked_files.csv filtered_data.csv new_cl_category.csv new_cl_productname.csv filtered_result.txt


# display head result
head final_data.csv | csvlook
# display list of columns
csvcut -n final_data.csv

echo "Done!"


