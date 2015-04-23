require(data.table)
require(dplyr)

# Get the list of features. These will be the basic headers for both datasets
features <- data.frame(read.table("./UCI HAR Dataset/features.txt"))

# Load the test data
testPath <- "./UCI HAR Dataset/test/"
testSubjects <- data.frame(read.table(paste0(testPath, "subject_test.txt"),
                                      col.names="Subject.Nbr"))
testActivityIDs <- data.frame(read.table(paste0(testPath, "y_test.txt"),
                                         col.names="Activity.Id"))
testData <- data.frame(read.table(paste0(testPath, "X_test.txt")))

# Apply the list of features to the raw test data
names(testData) <- features[, "V2"]

# Add the test subjects and activity IDs as two columns at the beginning of the
# data frame
testData <- cbind(testSubjects, testActivityIDs, testData)

# Load the training data
trainPath <- "./UCI HAR Dataset/train/"
trainSubjects <- data.frame(read.table(paste0(trainPath, "subject_train.txt"),
                                       col.names="Subject.Nbr"))
trainActivityIDs <- data.frame(read.table(paste0(trainPath, "y_train.txt"),
                                          col.names="Activity.Id"))
trainData <- data.frame(read.table(paste0(trainPath, "X_train.txt")))

# Apply the list of features to the raw training data
names(trainData) <- features[, "V2"]

# Add the training subjects and activity IDs as two columns at the beginning of
# the data frame
trainData <- cbind(trainSubjects, trainActivityIDs, trainData)

# PROJECT REQUIREMENT #1
# "[Create a script that] ... merges the training and the test sets to create
# one data set"
HAR_Data <- rbind(testData, trainData)

### Note to self, was using this to try and find the right features to select
subset(features, grepl("mean", tolower(V2)) | grepl("std", tolower(V2)))