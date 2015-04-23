require(data.table)
require(dplyr)
require(tidyr)

# PROJECT REQUIREMENT #1
# "[Create a script that] ... merges the training and the test sets to create one data set"

# Get the list of features. These will be the basic headers for both datasets
features <- data.frame(read.table("./UCI HAR Dataset/features.txt"))

# Load the test data
testPath <- "./UCI HAR Dataset/test/"
testSubjects <- data.frame(read.table(paste0(testPath, "subject_test.txt"),
                                      col.names="subject"))
testActivityIDs <- data.frame(read.table(paste0(testPath, "y_test.txt"),
                                         col.names="activityId"))
testData <- data.frame(read.table(paste0(testPath, "X_test.txt")))

# Apply the list of features to the raw test data
names(testData) <- features[, "V2"]

# Add the test subjects and activity IDs as two columns at the beginning of the
# data frame
testData <- bind_cols(testSubjects, testActivityIDs, testData)

# Load the training data
trainPath <- "./UCI HAR Dataset/train/"
trainSubjects <- data.frame(read.table(paste0(trainPath, "subject_train.txt"),
                                       col.names="subject"))
trainActivityIDs <- data.frame(read.table(paste0(trainPath, "y_train.txt"),
                                          col.names="activityId"))
trainData <- data.frame(read.table(paste0(trainPath, "X_train.txt")))

# Apply the list of features to the raw training data
names(trainData) <- features[, "V2"]

# Add the training subjects and activity IDs as two columns at the beginning of
# the data frame
trainData <- bind_cols(trainSubjects, trainActivityIDs, trainData)

HAR_Data_req1 <- bind_rows(testData, trainData)



# PROJECT REQUIREMENT #2
# "[Create a script that]... Extracts only the measurements on the mean and
# standard deviation for each measurement. "

# Capture the mean and std feature names from features so that we can select
# them from HAR_Data
selections <- as.character(subset(features, grepl("mean\\(\\)", tolower(V2)) | 
                                      grepl("std\\(\\)", tolower(V2)))$V2)

# Select the required fields
HAR_Data_req2 <- select(HAR_Data_req1, one_of(c("subject", "activityId", selections)))


# PROJECT REQUIREMENT #3
# "[Create a script that] ... Uses descriptive activity names to name the activities in the data set."

# Create a data frame of activities
activities <- data.frame(activity=c("Walking", "Walking Upstairs", "Walking Downstairs",
                                    "Sitting", "Standing", "Laying Down"))
activities <- activities %>%
    mutate(activityId=row_number()) %>%
    select(activityId, activity)

# Inner join the HAR Data with activities and swap activityId with activity in the HAR Data

HAR_Data_req3 <- HAR_Data_req2 %>%
    inner_join(activities, by="activityId") %>%
    select(-activityId)