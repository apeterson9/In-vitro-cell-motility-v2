
## LOAD PACKAGES ####
library(dplyr)
library(purrr)
library(knitr)
library(tidyverse)

## READ IN DATA
DATA <- read_csv("C:/Users/anpet/cell_tracking-selected/variables - 2d/2D_formatted4R.csv")

#data_results <- list.files(path = "data", full.names = T) 
#DATA <- read.csv(data_results)
#rm(data_results)

# View a portion of DATA 
head(DATA)


# create new data structure with na values excluded
# ANP edit: the column names must've been changed at some point, so I renamed them to match the CSV file
wksp <- DATA[!is.na(DATA$mean_speed), ]
wksp <- wksp[!is.na(wksp$DI), ]
wksp <- wksp[!is.na(wksp$cumulative_distance), ]
wksp <- wksp[!is.na(wksp$CI), ]
wksp <- wksp[!is.na(wksp$accuracy), ]
wksp <- wksp[!is.na(wksp$MI), ]
wksp <- wksp[!is.na(wksp$CR), ]
#wksp <- wksp[!is.na(wksp$mean_dc), ]

# factor by day
# ANP-keep the naming convention that f.day means the day column factored by day
wksp$f.day <- as.factor(wksp$day)

# Creating additional value, J and then aggregating data by summing over speed and J. Later, we will use the
# value of summed J to divide for calculating mean speed
wksp$J <- 1



## CLEAN DATA ####
# Fix and update columns for results data, combine with other data
# Rename the columns first
# ANP-renamed some of the original columns, again to match the matlab output
# ANP-removed references to diffusion coefficient for now since it's not in the csv.
# removed reference to net gain because it wasn't in the csv file
# give more intelligible names
# format: rename(new_name = old_name)
data_clean = wksp %>%
  #rename(cline = cell_line)  %>%
  rename(cell_speed = mean_speed) %>% 
  rename(directionality_index = DI)%>%
  rename(distance = cumulative_distance) %>%
  rename(chemotactic_index = CI) %>%
  rename(confinement_radius = CR) %>%
  rename(motility_index = MI)
  #rename(f.stim = stimulus) %>%
  #rename(diff_coeff = mean_dc) %>%
select(data_clean, cell_line, stimulus, f.day, slide, id, J, cell_speed, chemotactic_index, directionality_index, distance, accuracy, motility_index, confinement_radius, num_pauses, pause_duration)
  

DATA <- subset(DATA, DATA$stimulus != "PBS")
# factor data by stimulus
DATA$f.stim <- factor(DATA$stimulus, levels=c("PBS","fMLF_1uM","Low_3uM_C5a","High_30uM_C5a"),labels=c("PBS","fMLF 1uM","C5a 3uM","C5a 30uM"))

# factor data by cell line
(a <- unique(DATA$cell_line))
DATA$cell_line <- factor(DATA$cell_line, levels=a, labels=c("Control", "Arpc1b")) 
rm(a)

# Remove tracks of cells that didn't move. This should be already removed from Imaris settings
wksp <- wksp[!is.na(wksp$num_pauses), ]
#wksp <- wksp[!is.na(wksp$free_vel), ]

# ANP-removed reference to vFree since it wasn't used or listed in the matlab output file
motility_clean = wksp %>%
  #rename(cell_line = cline)  %>%
  #rename(stimulus = f.stim) %>%
  #rename(vFree = free_vel) %>%
  select(cell_line, stimulus, f.day, slide, id, J, num_pauses)


wksp <- wksp[!is.na(wksp$pause_duration), ]


tPause_clean = wksp %>%
  #rename(cell_line = cline)  %>%
  #rename(stimulus = f.stim) %>%
  #rename(tPause = durPause) %>%
  select(cell_line, stimulus, f.day, slide, id, J, pause_duration)
  


## FILTER DATA ####
# Next, I'm going to gather some summary statistics and use that to filter out outliers. Here, I will not be filtering 
# out anything from the low end - as these may be immotile cells. I will filter out anything with physiologically 
# irrelevant speed and distance measures as these are typically due to tracking errors. I will not filter anything that 
# is already mathematically confined (ex. CI between -1 and 1)

# Get speed outlier information
data_speed_sum = data_clean %>%
  group_by(cell_line, f.day, stimulus) %>%
  summarise(speed_mean = mean(cell_speed),
            speed_sd = sd(cell_speed)) %>%
  ungroup() %>%
  mutate(speed_high = speed_mean + (2 * speed_sd)) 

# Remove any data points with excessively high speeds on the assumption that they are due to tracking errors
data_clean = data_clean %>%
  inner_join(data_speed_sum) %>%
  filter(cell_speed < speed_high) 

rm(data_speed_sum)


## CREATE AGGREGATE DATA
# Aggregate takes all elements on the left side of the ~ and uses the given function on those values, while they are grouped by the values of the right side.
# ANP-removed a reference to net_gain and diff_coeff in the aggregate function 
agg <- data_clean
agg <- aggregate( cbind(cell_speed, directionality_index, distance, accuracy, confinement_radius, J) ~ f.day + slide + cell_line + stimulus, data=agg, FUN=sum)

agg <- cbind(agg[,1:4],agg[,5:9]/agg[,10])


agg$trt <- apply(agg[,c("stimulus","cell_line")], 1, paste, sep="", collapse=":")
agg$trt <- as.factor(agg$trt)


m_agg <- motility_clean

#ANP-removed a reference to vFree because it didn't seem to be real numbers
#m_agg <- aggregate( cbind(num_pauses, vFree, J) ~f.day + slide + cell_line + stimulus, data = m_agg, FUN=sum)
m_agg <- aggregate( cbind(num_pauses, J) ~f.day + slide + cell_line + stimulus, data = m_agg, FUN=sum)
m_agg <- cbind(m_agg[1:4],m_agg[,5]/m_agg[,6])
m_agg$trt <- apply(m_agg[,c("stimulus","cell_line")], 1, paste, sep="", collapse=":")
m_agg$trt <- as.factor(m_agg$trt)

tPause_agg <- tPause_clean
tPause_agg <- aggregate( cbind(pause_duration, J) ~f.day + slide + cell_line + stimulus, data = tPause_agg, FUN=sum)
tPause_agg <- cbind(tPause_agg[1:4],tPause_agg[,5]/tPause_agg[,6])
tPause_agg$trt <- apply(tPause_agg[,c("stimulus","cell_line")], 1, paste, sep="", collapse=":")
tPause_agg$trt <- as.factor(tPause_agg$trt)


