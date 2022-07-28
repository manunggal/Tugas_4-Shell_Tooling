# Shell Tooling - 4th Task
## Student ID
Username: manunggal-BvkE

Name: Manunggal Sukendro

## Purpose
Using `csvkit` and Bash to clean data. In this case two ecommerce sample data need to be combined and filtered. The goal is filtering `event_type` "purchase", creating new columns to contain "product name" and "product category".

## Process
### Getting the Input Files
using `read` command in bash, input files are hold as variables to be used in the following functions.
```
#take first file
echo "insert first file name:"
read file_pertama


#take second file
echo "insert second file name:"
read file_kedua
```

### Error Handling Function
In order to catch any error during the processing steps, a simple error handling function is created.
``` 
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
```
This function will take input of strings variables as `$1` and `$2` in accordance with the steps being processed.
the variable `$test_exit` will hold the status of bash operation. if the status  is zero, it indicates operation is successful. Hence, the error handling only catch if the operation fails (`$?` != 0).  

### Stacking Files
Using `csvstack`, two csv files can be stacked onto one file, given both files have the same column numbers.
```
# stack first file and second file, saved as csv file
csvstack $file_pertama $file_kedua > stacked_files.csv
# check if stacking success
test_exit=$?
error_status "$stacking_success" "$stacking_error"
```

### Filtering 'purchase' in `view_type`
There are two steps in filtering 'purchase' in `view_type`.
The first step uses `csvgrep` to filter the rows that contains 'purchase' in `view_type` column.
This function below use `csvgrep` and pipes the result to csv file.
```
# Filtering keyword
# define filtering keyword
filter_keyword="purchase"

# filter column event_type (3) with filterkeyword, save result as csv file
csvgrep stacked_files.csv -c 3 -m $filter_keyword > filtered_data.csv
# check if filtering success
test_exit=$?
error_status "$filtering_elements_success" "$filtering_elements_error"

```

The second step verifies whether the resulting filtered data contains the keyword. If it does not, it will result in an empty rows table. The following steps do just that.

```
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
```










