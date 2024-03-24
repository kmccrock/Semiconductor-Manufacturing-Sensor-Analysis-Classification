# Semiconductor-Manufacturing-Sensor-Analysis-Classification

IUPUI DATATHON 2023-2024

SEMICONDUCTOR MANUFACTURING SENSOR ANALYSIS & CLASSIFICATION

Team: Kyle McCrocklin (kmccrock@iu.edu)
___

PROJECT DESCRIPTION

Prior to joining the Computational Data Science master’s program at IUPUI, I worked for 5 years in the manufacturing industry and I believe there is huge potential for applying data science methodologies to manufacturing problems. For this Datathon I will be working with the UCI SECOM dataset which came from a semiconductor manufacturing process. 

I am approaching this project as if I were hired by SECOM to provide insights to the engineers working on this semiconductor line. I will analyze the data in a clearly explainable way, then attempt to build a classification algorithm to predict if a produced unit will pass or fail quality control.
___

METHODS

-Parts 1 & 2: R

Parts 1 and 2 of this analysis were performed using R. The methods used are straightforward and make use of the R base package along with the “dplyr” and “ggplot2” libraries.


-Part 3: Python

The classification portion of this analysis was done in Python. The cleaned data from Part 1 was imported and split into test/train datasets. The classes were very imbalanced with 1294 examples passing QC and only 99 examples failing QC. Initially a logistic regression model, a decision tree, a random forest and XGBoost were trained on the data.

All four models had great accuracy - 88%, 90%, 93%, and 93% respectively - but they were essentially only predicting the pass case which makes up 93% of the test data. This means they had terrible recall for the fail case - 11%, 25%, 4%, and 0%. 

To combat the class imbalance, the pass case was randomly undersampled to contain only 99 passing examples, equal to the number of failing examples. Logistic regression, a decision tree, and XGBoost were applied to the undersampled data.

Accuracy is a fine metric for these models on undersampled data and it hovered around 50% with XGBoost performing slightly better than random classification at 60%. Though undersampling to balance the classes did resolve the single class prediction problem, it did not yield usable models.

Another method for dealing with imbalanced data is to use a weighted/balanced classification algorithm. These algorithms take the class imbalance into account by adjusting the weights of the loss function during training. This allows the full dataset to be used instead of throwing away valuable training examples. Weighted XGBoost, balanced random forest, RUSBoost, and local outlier factor models were trained on the full dataset. 

Weighted XGBoost did not perform any better than the normal XGBoost. Artificially high loss for misclassified fails was required to move it away from predicting pass almost every time. RUSBoost had the best performance of any algorithm with a recall of 81% for passing examples, 57% for failing examples, and overall accuracy of 79%. 
___

CONCLUSION

The SECOM dataset turned out to be mostly noise. The feature ranking and classification modeling showed that there is little separability between the pass and fail cases. Still, I was able to uncover some insights into which areas of the manufacturing process appear to have the most correlation with whether the produced unit passes or fails QC. This is information that a client could take action. They may benefit from focusing their engineering efforts on these areas of the process. They may also have more success with a classification algorithm if better data is collected from these areas.

While it would have been nice to come up with more flashy insights, and there are many Kaggle submissions which claim >80% classification accuracy/recall or massive feature reduction on this dataset, it is better to honestly conclude that the dataset contains mostly noise, than to mistakenly claim impossible results.

Additionally, this project was good practice for future, real world situations where I may be tasked with making the most of poor quality data.
___

CITATIONS

McCann,Michael and Johnston,Adrian. (2008). SECOM. UCI Machine Learning Repository. https://doi.org/10.24432/C54305.
