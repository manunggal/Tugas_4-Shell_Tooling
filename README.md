# Shell Tooling - 4th Task
## Student ID
Username: manunggal-BvkE

Name: Manunggal Sukendro

## Purpose
Using `csvkit` and Bash to clean data. In this case two ecommerce sample data need to be combined and filtered. The goal is filtering `event_type` "purchase", creating new columns to contain "product name" and "product category".

## Process
### Getting the Input Files
using `read` command in bash, input files are held as variables to be used in the upcoming functions.
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

The second step verifies whether the resulting filtered data contains the keyword. If it does not, it will result in an empty rows table. in order to do that, first `csvcut` is used to select the target column, afterwards `csvgrep` + keyword will filter the rows and pipes the result as `.txt` file. This file's content is 'Row count: XXX' strings. Secondly, the numbers part of this file will be used in `ifelse` sequence to verify the rows numbers. For this purpose variable `awk` function is used to remove the 'Row count: ' strings from the txt file.

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

### Filtering 'product_category' and 'product_name' from 'category_code' Column
The `category_code` column contains strings which are combination of product category and product name, they are separated by '.', for example: `apparel.shoes.keds`, this strings means:
- Product category: 'apparel'
- Product name: 'keds'
The first sequence of characters prior to the first dot is product category, whereas the last sequence of strings after the last dot is the product name.

To separate these strings, `csvsql` function is used. If it is applied to database, the syntax will follow which database being used, however if it is applied to csv file, this function use `SQLite` syntax.
The typical syntax of this function is
```
csvsql --query "_required_query FROM [csv_file-without '.csv']" [csv_file.csv] > [saved_csv_file.csv]
```
This function will return the query result as csv file.

#### Separating Product Category
The query for this process is:
``` SQLite
SELECT 
    *, 
    substr(
        category_code, 
        instr(category_code, '.'), 
        -LENGTH(category_code)
    ) AS category 
from filtered_data
```
The `substr(x,y,z)` takes three arguments:
- x: column name, in this case it is `category_code`
- y: first character position, in this case the first '.' from the left. `instr()` is used to locate the first '.' within the strings.
- z: the lenght of the resulting characters to be read, in this case it is negative lenght of `category_code` since it is read from left where the first dot is, to the right direction of the strings in order to capture the product category.

#### Separating Product Name
Similiarly for this step, `csvsql` is used. For this purpose, the last dot in the strings or the first dot from the right needs to be identified, in order to select the last sequence of strings from the dot. The syntax in `SQLite` for this purpose is not as straight forward as in, let's say, 'MySQL'. Since, to the best of my knowldge, there is no function to locate a character from the right. Hence, IMO, the query for this step is not simple:
```
1       SELECT 
2           *, 
3           replace(
4               category_code, 
5               rtrim(
6                   category_code, 
7                   replace(
8                       category_code, '.', '')
9               ), 
10              ''
11          ) AS product_name 
12      from new_cl_category
```

- Firstly the `replace` function in 7th line removes '.' from the strings, as a result if the content of `category_code` column is 'electronics.audio.headphone', the result of this function will be 'electronicsaudioheadphone'. 
- Secondly, the `rtrim` function in line number 5 will use the newly created strings from `replace` function above will remove all the resulting charaters from previous function from the right until the first '.'. With the same example above, its result will be 'electronics.audio.'  
- Finally, The final `replace` function  at line number 3 will remove the sequence of strings in `category_code` that match with the result of `rtrim` function above, this way we will have the `product_name`. Using the example above, `product_name` column content will be 'headphone'.

### Selecting relevant columns
The last step is selecting the relevant columns for the report, they are:

<table>
<tr><th>Original Columns </th><th> New Columns </th></tr>
<tr><td>

|Column Numbers| Column Names|
|--| --|
 1 | empty 
  2| event_time
  3| event_type
  4| product_id
  5| category_id
  6| category_code
  7| brand
  8| price
  9| user_id
 10| user_session

</td><td>

|Column Numbers| Column Names|
|--| --|
  1| event_time
  2| event_type
  3| product_id
  4| category_id
  5| brand
  6| price
  7| category
  8| product_name
 NA|
 NA| 
</td></tr> </table>

For this purpose, `csvcut` function is used where the selected column numbers are in correspondence with the original columns illustrated above. The code for this selection is:
```
# select relevant columns
csvcut new_cl_productname.csv -c 2,3,4,5,7,8,11,12 > final_data.csv
# check if select columns success
test_exit=$?
error_status "$selecting_success" "$selecting_error"
```
This code will result in new columns shown in the right side of the table above.

### Result Verification
To verify the result use `verify_result.sh`

## Last Words
`csvkit` is useful for quick exploration of csv data. However, if one needs more advance data wrangling with big csv data, it is recommended to do it in SQL directly or using a proper programming language like python or R. For example the required function to locate a character from the right side of a strings above is relatively complicated due to the limitation of `SQLite`. For this reason I would not use `csvkit` in a similiar wrangling cases for my day to day tasks.   















