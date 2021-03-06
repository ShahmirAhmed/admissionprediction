#Cross validation for DNN model (Github)
library(readr)
library(dplyr)
library(reshape2)
library(parallel)
library(caret)
library(xgboost)
library(doMC)
library(pROC)
library(keras)

#1) load the data and the indeces for splits (these files are created from the build_boost.R script)

load('./Results/5v_indeces_list.RData')
load('./Results/5v_sparseMatrix.RData')

#2) 
source('./Scripts/R/26_splitandimpute.R')

results <- matrix(NA, length(indeces_list), 2)
colnames(results) <- c('train', 'dev')

x <- as.matrix(dataset$x) #convert sparse matrix into normal matrix
y <- dataset$y
rm(dataset)

for (i in 1:length(indeces_list)) {
        indeces <- indeces_list[[i]]
        splitandimpute(indeces, x, y) #creates global variables x_train, y_train, etc.
        #fit model using keras
        model <-keras_model_sequential()
        model %>%
                #model architecture is changed here manually
                layer_dense(units = 30, activation = 'relu', input_shape = ncol(x)) %>%
                layer_dense(units = 30, activation = 'relu') %>%
                layer_dense(units = 30, activation = 'relu') %>%
                layer_dense(units = 1, activation = 'sigmoid') %>%
                compile(
                        loss = 'binary_crossentropy',
                        optimizer = optimizer_rmsprop(lr = 0.001),
                        metrics = c('accuracy')
                )
        history <- model %>% fit(x_train, y_train, epochs = 5, batch_size = 128)
        acc_train <- history$metrics$acc[length(history$metrics$acc)]
        
        #predict on dev
        acc_dev <- evaluate(model, x_dev, y_dev)$acc
        
        results[i,] <- c(acc_train, acc_dev)
        if (i == length(indeces_list)) {
                print(summary(model))
        }
}
results
colMeans(results)