library(dplyr)
library(ggplot2)
options(scipen=999) #TURN OFF SCIENTIFIC NOTATION

#---------------------------------------------------------------------------#
#DATA IMPORTATION, EXPLORATION, AND CLEANING
#---------------------------------------------------------------------------#

#I READ IN THE SPACE DELIMITED TEXT FILE TO A DATA FRAME THEN SUMMARIZE THE DATA.
data = read.table("secom.data")

print(paste0("Number of features : ", ncol(data)))
print(paste0("Number of observations : ", nrow(data)))
print(summary(data))

#SO I KNOW THAT I HAVE A LOT OF FEATURES (590), NOT SO MANY OBSERVATIONS (1567), AND LOTS OF MISSING VALUES (NA'S).
#THE FEATURES ARE UNLABLED SO I DO NOT KNOW THEIR UNITS OR MEANING.
#I AM GOING TO DO SOME FEATURE ANALYSIS TO SEE WHAT I CAN LEARN ABOUT THEM.

#FOR EACH FEATURE I CALCULATE THE MEAN, MEDIAN, STANDARD DEVIATION, AND IQR.
f_mean = sapply(data, mean, na.rm=TRUE)
f_median = sapply(data, median, na.rm=TRUE)
f_sd = sapply(data, sd, na.rm=TRUE)
f_iqr = sapply(data, IQR, na.rm=TRUE)

#NOW I PLOT HISTOGRAMS OF THE FEATURE MEANS, MEDIANS, SD'S, AND IQR'S THAT I JUST CALCULATED.
#MEAN HISTOGRAM
hist(f_mean, main="Histogram of Means Across Features", xlab="Mean Value")
#MEDIAN HISTOGRAM
hist(f_median, main="Histogram of Medians Across Features", xlab="Median Value")
#SD HISTOGRAM
hist(f_sd, main="Histogram of SDs Across Features", xlab="Standard Deviation")
#IQR HISTOGRAM
hist(f_iqr, main="Histogram of IQR Across Features", xlab="Inter Quartile Range")
#I WANT TO ZOOM IN ON THE LOW END OF THE IQR RANGE.
hist(f_iqr, breaks=1000000, xlim=c(0,.1), main="Histogram of Low IQR Features", xlab="IQR")

#I BELIEVE I THERE ARE SOME FEATURES WITH 0 IQR, MEANING THEY ARE MOST LIKELY CONSTANT AND USELESS TO ME.
#I AM GOING TO REMOVE THEM.
data = data[, which(f_iqr > 0)]
print(paste0("Number of features after removing those with IQR=0 : ", ncol(data)))

#NOW I AM DOWN TO 464 FEATURES.
#NEXT I'LL CHECK FOR DUPLICATE OBSERVATION AND REMOVE THEM. (THERE WERE NONE.)
data = unique(data)
print(paste0("Number of observations after removing duplicates : ", nrow(data)))

#FROM MY HISTOGRAM ANALYSIS ABOVE IT IS CLEAR THAT THE FEATURES HAVE A HUGE RANGE IN MAGNITUDE, CENTRAL TENDANCEY, AND VARIANCE. 
#I AM GOING TO NORMALIZE ALL FEATURES BY CONVERTING THEM TO Z-SCORE.
data_z = as.data.frame(scale(data))

#NOW I WANT TO PLOT SOME OF THE HISTOGRAMS AGAIN.
f_median_z = sapply(data_z, median, na.rm=TRUE)
hist(f_median_z, main="Histogram of Medians Across Scaled Features", xlab="Scaled Median Value")
f_iqr_z = sapply(data_z, IQR, na.rm=TRUE)
hist(f_iqr_z, main="Histogram of IQR Across Scaled Features", xlab="Scaled Inter Quartile Range")

#SO IT LOOKS LIKE MOST OF THE FEATURES ARE RIGHT-SKEWED AND THERE IS STILL SIGNIFICANT VARIATION IN IQR ACROSS FEATURES.

#NOW I WANT TO LOOK INTO HOW MUCH DATA EACH FEATURES IS MISSING.
na_percent = (colMeans(is.na(data_z)))*100
ncol(data_z)
hist(na_percent, breaks=50, main="Histogram of Missing Data %", xlab="% of entries which are NA")

#I AM GOING TO REMOVE ANY FEATURES MISSING MORE THAN 5% OF DATA POINTS.
data_z = data_z[, which( (colMeans(is.na(data_z)))*100 <= 5 )]
print(paste0("Number of features after removing those with > 5% NA : ", ncol(data_z)))

#SO NOW I'M DOWN TO 412 FEATURES FROM 590.



#---------------------------------------------------------------------------#
#LABELS IMPORTATION AND TEMPORAL ANALYSIS
#---------------------------------------------------------------------------#

#I READ IN LABELS AND SUMMARIZE
labels = read.table("secom_labels.data")
colnames(labels) = c('LABEL', 'DATE')
summary(labels)

#I HAVE 1567 LABELS WITH +1 REPRESENTING A FAIL AND -1 REPRESENTING A PASS.

#I'LL MAKE A BAR PLOT OF THE LABEL DISTRIBUTION.
barplot(table(labels$LABEL), main="Label Distribution")

#SO THERE ARE A LOT MORE EXAMPLES OF PASS THAN FAIL (1463 VS 104)(~7% FAIL).

#THERE IS ALSO A TIMESTAMP FOR EACH LABEL.
#I WANT TO SEE IF THERE IS ANY TEMPORAL TREND.
labels$DATE = strptime(labels$DATE, format = "%d/%m/%Y %H:%M:%S")
labels$DATE = as.POSIXct(labels$DATE)
timeplot <- ggplot(labels, aes(x = DATE, y = LABEL)) +
	geom_point()

print(timeplot + ggtitle("Pass/Fail vs Time"))

#I DON'T SEE ANY CLEAR TRENDS SUCH AS INCREASING/DECREASING FAILURE RATE OVER TIME OR RECURRING PATTERNS.
#I'M GOING TO DISREGARD THE TIMESTAMP AS A USEFUL FEATURE.

#NOW I'LL JOIN THE LABELS TO THE DATA.
df = data.frame(data_z, labels$LABEL)
var_names = colnames(df)

#I'LL USE THIS CLEANED DATA FOR MY CLASSIFICATION MODEL.
#FIRST I'LL REMOVE ANY INCOMPLETE OBSERVATIONS.
nrow(df)
ML_df = df[ which( rowSums(is.na(df)) == 0 ) ,]
print(paste0("Number of complete observations : ", nrow(ML_df)))

#THEN I'LL OUTPUT THIS DATA FRAME AS A CSV FILE.
colnames(ML_df)[ncol(ML_df)] = "LABEL"
write.csv(ML_df, "C:\\Users\\kmccr\\OneDrive\\Projects\\CS Club Datathon 2023-2024\\CleanedData.csv", row.names=FALSE)



#---------------------------------------------------------------------------#
#FEATURE RANKING
#---------------------------------------------------------------------------#

#NOW I WANT TO INVESTIGATE WHICH FEATURES ARE THE MOST SEPERABLE BETWEEN THE + AND - CASES.
#FIRST I WILL DIVIDE THE DATA INTO PASS AND FAIL DATASETS.
fail_df = filter(df, df$labels.LABEL == 1)
pass_df = filter(df, df$labels.LABEL == -1)
nrow(fail_df)
nrow(pass_df)

#I WOULD NORMALLY USE A SIDE BY SIDE BOX PLOT TO COMPARE THE DISTRIBUTION OF EACH FEATURE FOR THE FAIL AND PASS CASES.
#THERE ARE TOO MANY FEATURES FOR THAT TO BE A VIABLE METHOD HERE.
#I WILL INSTEAD MAKE A SIMILAR COMPARISON NUMERICALLY.
#I WILL LOOK FOR ANY FEATURES WHERE Q1, MEDIAN, AND Q3 ARE ALL OFFSET IN THE SAME DIRECTION FOR THE PASS AND FAIL CASES.

#STEP 1 IS TO CALCULATE Q1, MEDIAN, AND Q3 FOR ALL FEATURES IN BOTH PASS AND FAIL DATASETS.
fail_q1 = sapply(fail_df, quantile, .25, na.rm=TRUE)
pass_q1 = sapply(pass_df, quantile, .25, na.rm=TRUE)
fail_median = sapply(fail_df, median, na.rm=TRUE)
pass_median = sapply(pass_df, median, na.rm=TRUE)
fail_q3 = sapply(fail_df, quantile, .75, na.rm=TRUE)
pass_q3 = sapply(pass_df, quantile, .75, na.rm=TRUE)

#STEP 2 IS TO CALCULATE THE DELTA BETWEEN THE Q1, MEDIAN, Q3.
delta_q1 = fail_q1 - pass_q1
delta_median = fail_median - pass_median
delta_q3 = fail_q3 - pass_q3

#STEP 3 COMBINE INTO ONE DATA FRAME
deltas = data.frame(delta_q1, delta_median, delta_q3)
rownames(deltas) = var_names

#STEP 4 FILTER TO ONLY FEATURES WHERE Q1, MEAN, Q3 DELTAS HAVE SAME SIGN.
deltas = filter(deltas,  deltas$delta_q1>0 & deltas$delta_median>0 & deltas$delta_q3>0  |  deltas$delta_q1<0 & deltas$delta_median<0 & deltas$delta_q3<0)
print(paste0("Number of features after performing pseudo bar plot analysis : ", nrow(deltas)))

#I AM DOWN TO 206 FEATURES THAT MEET THE CRITERIA OF THE PSEUDO BOX PLOT ANALYSIS.
#NOW I WILL SUM Q1, MEDIAN, Q3 AND TAKE THE ABSOLUTE VALUE SO I CAN RANK THE FEATURES.
deltas = mutate(deltas, delta_sum = abs(delta_q1 + delta_median + delta_q3))
deltas = deltas[order(deltas$delta_sum, decreasing=TRUE), ]
head(deltas,50)

#I'LL OUTPUT THIS RANKING TO A CSV FILE.
write.csv(deltas[2:nrow(deltas),], "FeatureRankingCentralTendencyBased.csv", row.names=TRUE)

#I'LL CREATE SIDE-BY-SIDE BOX PLOTS FOR THE TOP 5 FEATURES.
boxplot(fail_df$V60, pass_df$V60, fail_df$V104, pass_df$V104, fail_df$V29, pass_df$V29, fail_df$V349, pass_df$V349, fail_df$V511, pass_df$V511, main="Side-By-Side Box Plot of Features 60, 104, 29, 349, and 511", names = c("V60 Fail", "V60 Pass", "V104 Fail", "V104 Pass", "V29 Fail", "V29 Pass", "V349 Fail", "V349 Pass", "V511 Fail", "V511 Pass"))

#NOW FOR THE SECOND VARIATION OF THIS PSEUDO BOXPLOT ANALYSIS - THIS TIME FOCUSING ON CHANGE IN IQR BETWEEN PASS AND FAIL CASES
fail_iqr = sapply(fail_df, IQR, na.rm=TRUE)
pass_iqr = sapply(pass_df, IQR, na.rm=TRUE)
delta_iqr = fail_iqr - pass_iqr
d_iqr = data.frame(delta_iqr)
d_iqr
d_iqr = d_iqr[order(d_iqr$delta_iqr, decreasing=TRUE), ,drop=FALSE]
head(d_iqr,50)
d_iqr <- cbind(Feature = rownames(d_iqr), d_iqr)
rownames(d_iqr) <- 1:nrow(d_iqr)
boxplot(fail_df$V96, pass_df$V96, fail_df$V81, pass_df$V81, fail_df$V60, pass_df$V60, fail_df$V65, pass_df$V65, fail_df$V66, pass_df$V66, main="Side-By-Side Box Plot of Features 96, 81, 60, 65, and 66", names = c("V96 Fail", "V96 Pass", "V81 Fail", "V81 Pass", "V60 Fail", "V60 Pass", "V65 Fail", "V65 Pass", "V66 Fail", "V66 Pass"))

#I'LL OUTPUT THIS RANKING TO A CSV FILE.
write.csv(d_iqr[2:nrow(d_iqr),], "FeatureRankingVarianceBased.csv", row.names=FALSE)
