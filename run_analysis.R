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
testData <- cbind(testSubjects, testActivityIDs, testData)

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
trainData <- cbind(trainSubjects, trainActivityIDs, trainData)

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

# PROJECT REQUIREMENT #4
# "[Create a script that] ... Appropriately labels the data set with descriptive variable names."

HAR_unpivot <- HAR_Data_req3 %>%
    # Step 1: There are many values in the variable names, so we'll gather them into messyVar.
    mutate(observationNbr=row_number()) %>%
    gather(messyVar, value, -observationNbr, -subject, -activity) %>% 
    # Step 2: We can separate messyVar w/ the default behavior to capture calculation perfectly, and also
    #         the X, Y, and Z directions. "magnitude" is missing from direction, so use mutate to fill in the
    #         blanks.
    separate(messyVar, c("messyVar", "calculation", "direction")) %>% 
    mutate(direction=ifelse(direction == "", "Magnitude", direction)) %>%
    # Step 3: The first character of messyVar signifies the domain, so we'll separate it out and then mutate
    #         it into a tidy form.
    separate(messyVar, c("domain", "messyVar"), sep=c(1)) %>%
    mutate(domain=ifelse(domain == "t", "time", "ttf")) %>%
    # Step 4: Everything else is a total mess in messyVar. grepl and ifelse via mutate is our best friend
    #         here. We'll capture the signalsource values of "gravity", "body jerk", and "body" first.
    mutate(signalsource="") %>%
    mutate(signalsource=ifelse(grepl("Gravity", messyVar), "Gravity", signalsource)) %>%
    mutate(signalsource=ifelse(grepl("Jerk", messyVar), "Body Jerk", signalsource)) %>%
    mutate(signalsource=ifelse(signalsource == "", "Body", signalsource)) %>%
    # Step 5: The device is a little easier.
    mutate(device=ifelse(grepl("Gyro", messyVar), "Gyro", "Accel")) %>%
    # Step 6: Let's put them in a nice order and drop messyVar for good
    #select(subject, activity, domain, device, signalsource, direction, calculation, value) %>%
    # Step 6: Now we can pivot out the actual calculations via spread.
    spread(calculation, value) %>%
    # Step 7: Put the fields in a tidy order
    select(subject, activity, domain, device, signalsource, direction, mean, std) %>%
    # Step 8: Finally, convert character variables into factors where appropriate
    mutate(domain=factor(domain),
           device=factor(device),
           signalsource=factor(signalsource),
           direction=factor(direction))

# PROJECT REQUIREMENT #5
# "[Create a script that] ... From the data set in step 4, creates a second, independent tidy data set with
# the average of each variable for each activity and each subject."

HAR_tidy <- HAR_unpivot %>%
    group_by(subject, activity, domain, device, signalsource, direction) %>%
    summarize(meanOfObservedMeans=mean(mean), meanOfObservedStd=mean(std))