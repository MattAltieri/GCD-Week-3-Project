## Summary

This project used data files from the _Human Activity Recognition Using Smartphones Data Set_ available at the [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones).

The raw data is available [here](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip ).

The goal of this project is to read in both the test and training datasets, tidy them up for analysis, and output a dataset containing the average values of all _mean()_ and _std()_ measurements for each subject and activity (_meanFreq()_ and _angle(...Mean)_ are both ignored here). Either the long form or the wide form can be presented, as long as the data is tidy.

In this solution, I've opted for the long form, though I've taken time to add variables which break down the original measurement names in their component parts (see CodeBook.md for more info on this). The variable names in the raw data contain a lot of information about the nature of the devices and movements being measured, and it's not clear from the request exactly what the requester is planning to measure. This allows for a great degree of freedom to perform a number of analyses.

## Code Walkthrough

##### Packages used
- `dplyr`
- `tidyr`
- `Hmisc`

##### Project Requirement #1
> [Create a script that] ... merges the training and the test sets to create one data set.

1. _features.txt_ is read into `features` so that it can provide us with the basic headers of the _X_[test|train].txt_ files.
2. Load the **test** data:
	1. _subject_test.txt_ is read into `testSubjects` to be combined w/ the numeric observations in _X_test.txt_.
	2. _y_test.txt_ is read into `testActivityIDs` to be combined w/ the numeric observations in _X_test.txt_.
	3. Finally, _X_test.txt_ is read into `testData`.
	4. The rightmost column of `features` is applied to the `names` attribute of `testData` to provide the **test** observations with basic (untidy) variable names. 
	5. `cbind` is used to combine `testSubjects`, `testActivityIDs`, and `testData`. This is done before anything else to ensure they stay in the same order.
3. Load the **train** data:
	1. _subject_train.txt_ is read into `trainSubjects` to be combined w/ the numeric observations in _X_train.txt_.
	2. _y_train.txt_ is read into `trainActivityIDs` to be combined w/ the numeric observations in _X_train.txt_.
	3. Finally, _X_train.txt_ is read into `trainData`.
	4. The rightmost column of `features` is applied to the `names` attribute of `trainData` to provide the **training** observations with basic (untidy) variable names.
	5. `cbind()` is used to combine `trainSubjects`, `trainActivityIDs`, and `trainData`. This is done before anything else to ensure they stay in the same order.
4.  As a final step, `dplyr:bind_rows()` is used to quickly union together the **test** and **training** datasets.
  
The resulting dataset is `HAR_Data_req1`.

##### Project Requirement #2
> [Create a script that]... Extracts only the measurements on the mean and standard deviation for each measurement.

1. The variables `subject`, `activityId`, and any features with either "sum()" or "std()" in their name are selected, and all other features are excluded.   

The resulting dataset is `HAR_Data_req2`.

##### Project Requirement #3
> [Create a script that] ... Uses descriptive activity names to name the activities in the data set.

**Note:** _activity_labels.txt_ has the definitions for the activity IDs from _y_test.txt_ and _y_train.txt_, but not in an easily machine-readable format. Instead I've interpreted their contents into a hard-coded data frame in the script itself.

1. An `activities` data frame is created to mimic the contents of _activity_labels.txt_ in tabular form. The text descriptions are loaded in 1:6 order from a character vector, then `dplyr::mutate()` and `dplyr::row_number()` are used to assign the IDs, since they're already in the correct order.
2. `dplyr::inner_join()` is used to merge `activities` to `HAR_Data_req2` on the _activityId_ field.
3. Finally, the variable _activityId_ is excluded from the results. We won't need it now that we have the activity names.

The resulting dataset is `HAR_Data_req3`.

##### Project Requirement #4
> [Create a script that] ... Appropriately labels the data set with descriptive variable names.

**Note:** This step probably could have been much shorter, but the variable names are so unclear (and the contents of _features_info.txt_ so out of sync with the actual feature names) that I decided it would make for much cleaner data to pull out the meaning of the variable names and capture them as discrete variables that could be filtered, grouped or pivoted on as needed.

The full definitions of these extracted variables can be found in CodeBook.md.
- domain
- device
- signalSource
- direction
- calculation

The original variable names are maintained in a variable called _originalFeatureName_ so that the relationship between the original feature names and the tidied-up variables is apparent.

1. HAR_Data_req3 is unpivoted (with `dplyr::gather()`) so that all feature names are now in the variable _originalFeatureName_, and the values are in the variable _measurement_.
2. The _calculation_ and _direction_ variables are pulled out of _originalFeatureName_ with the default behavior of `tidyr::separate()` and some minor adjustments via `dplyr::mutate()`.
3. The measurement domain (time or frequency) are pulled out of the first character of _messyVar_, again with a combination of `tidyr::separate()` and `dplyr::mutate()`.
4. The _signalSource_ is pulled out of _messyVar_ next using a chain of `dplyr:mutate()` function calls. `ifelse()` and `grepl()` do the heavy lifting here.
5. The same basic approach is able to capture the _device_ variable.
6. `dplyr::select()` is used to grab only the variables we want, and put them in a sensible order.
7. `dplyr::mutate()` is then used to cast the character variables into factors.

The resulting dataset is `HAR_unpivot`.

##### Project Requirement #5
> [Create a script that] ... From the data set in step 4, creates a second,  independent tidy data set with the average of each variable for each activity and each subject.

1. `HAR_unpivot` is grouped by all variables except _measurement_.
2. Then the mean of _measurement_ is calculated across the grouped variables.

The resulting dataset is `HAR_tidy`.

##### Project Output

The following function call is used to write `HAR_tidy` to a text file:
``` r
write.table(HAR_tidy, "./HAR_tidy.txt", row.names=F)
```

It can be read back in with:
``` r
HAR_tidy <- read.table("./HAR_tidy.txt", header=T)
```