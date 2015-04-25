require(dplyr)
require(tidyr)
require(Hmisc)

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

# Capture the mean and std feature names from features so that we can select them from HAR_Data_req1
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
    # Step 1: There are many values in the variable names, so we'll gather them into "originalFeatureName"
    #         and their values "measurement".
    gather(originalFeatureName, measurement, -subject, -activity) %>% 
    # Step 2: We can separate originalFeatureName w/ the default behavior to capture the type of calculation
    #         used exactly (with some capitalization added). The direction of motion is mostly captured as
    #         well (X, Y, Z), but Magnitude requires a mutation to get it in the variable.
    #         The first, very messy, part of the variable names goes into "messyVar" for further processing.
    separate(originalFeatureName, c("messyVar", "calculation", "direction"), remove=F) %>% 
    mutate(calculation=capitalize(calculation)) %>%
    mutate(direction=ifelse(direction == "", "Magnitude", direction)) %>%
    # Step 3: The first character of messyVar signifies the domain, so we'll separate it out and then mutate
    #         it into a tidy form.
    separate(messyVar, c("domain", "messyVar"), sep=c(1)) %>%
    mutate(domain=ifelse(domain == "t", "Time Domain Signal", "Frequency Domain Signal (TTF)")) %>%
    # Step 4: Everything else is a total mess in messyVar. grepl and ifelse via mutate are our best friends
    #         here. We'll capture the signalSource values of "gravity", "body jerk", and "body" first.
    mutate(signalSource="") %>%
    mutate(signalSource=ifelse(grepl("Gravity", messyVar), "Gravity", signalSource)) %>%
    mutate(signalSource=ifelse(grepl("Jerk", messyVar), "Body Jerk", signalSource)) %>%
    mutate(signalSource=ifelse(signalSource == "", "Body", signalSource)) %>%
    # Step 5: The device is a little easier.
    mutate(device=ifelse(grepl("Gyro", messyVar), "Gyro", "Accel")) %>%
    # Step 6: Put the fields in a tidy order
    select(subject, activity, originalFeatureName, domain, device, signalSource, direction, calculation, measurement) %>%
    # Step 7: Finally, convert character variables into factors where appropriate
    mutate(originalFeatureName=factor(originalFeatureName),
           domain=factor(domain),
           device=factor(device),
           signalSource=factor(signalSource),
           direction=factor(direction),
           calculation=factor(calculation))



# PROJECT REQUIREMENT #5
# "[Create a script that] ... From the data set in step 4, creates a second, independent tidy data set with
# the average of each variable for each activity and each subject."

HAR_tidy <- HAR_unpivot %>%
    group_by(subject, activity, originalFeatureName, domain, device, signalSource, direction,
             calculation) %>%
    dplyr::summarize(meanOfMeasurement=mean(measurement)) # Hmisc also has a "summarize", namespace needed.


# Export dataset to txt file
write.table(HAR_tidy, "./HAR_tidy.txt", row.names=F)