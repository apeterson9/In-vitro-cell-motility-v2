## LOAD PACKAGES ####
library(dplyr)
library(purrr)
library(knitr)
library(tidyverse)

## READ IN DATA
DATA <- read_csv("C:/Users/anpet/Desktop/2D_exp_full_data/movies/C5a movies/Arpc1b lines/2D/Variables/2D LUT_formatted4R.csv")
#DATA <- read.csv("C:/Users/axp701/In-vitro-cell-motility-v2/2D LUT_formatted4R.csv")

#data_results <- list.files(path = "data", full.names = T) 
#DATA <- read.csv(data_results)
#rm(data_results)

# View a portion of DATA-keep this DATA clean, for posterity 
head(DATA)
wksp <- DATA

# factor by cell line
(a <- unique(wksp$cell_line)) # cline = cell line
wksp$f.cell_line <- factor(wksp$cell_line, levels=a, labels=c("Control", "Arpc1b")) 
rm(a)


wksp <- subset(wksp, wksp$stimulus != "PBS")
# factor data by stimulus
wksp$f.stim <- factor(wksp$stimulus, levels=c("PBS","fMLF_1uM","Low_3uM_C5a","High_30uM_C5a"),labels=c("PBS","fMLF 1uM","C5a 3uM","C5a 30uM"))

# ANP-keep the naming convention that f.day means the day column factored by day
wksp$f.day <- as.factor(wksp$day)

# create new data structure with na values excluded
wksp <- wksp[!is.na(wksp$track_length), ]
wksp <- wksp[!is.na(wksp$cumul_distance), ]
wksp <- wksp[!is.na(wksp$net_displacement), ]
wksp <- wksp[!is.na(wksp$tortuosity), ]
wksp <- wksp[!is.na(wksp$mean_velocity), ]
wksp <- wksp[!is.na(wksp$mean_theta), ]
wksp <- wksp[!is.na(wksp$mean_CI), ]
wksp <- wksp[!is.na(wksp$num_pauses), ]
wksp <- wksp[!is.na(wksp$pause_duration), ]



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


#data_clean = wksp %>%
  #rename(cell_line = cline)  %>%
  #rename(cell_speed = m.speed) %>% # give more intelligible names
  #rename(directionality_index = m.di) %>%
  #rename(cumulative_distance = distance) %>%
  #rename(confinement_radius = mean_cr) %>%
  #rename(stimulus = f.stim) %>%
  #rename(diff_coeff = mean_dc) %>%
  #select(cell_line, stimulus, f.day, slide, id, J, mean_velocity, net_displacement, 
         #cumul_distance, mean_CI, tortuosity, confinement_radius, track_length)
#select(wksp, cell_line, stimulus, f.day, slide, id, J, track_length, cumul_distance, net_displacement,tortuosity,mean_velocity,mean_theta, mean_CI, num_pauses,pause_duration, confinement_radius, confined_vel, free_vel,super_vel)

# Remove tracks of cells that didn't move. This should be already removed from Imaris settings
wksp <- wksp[!is.na(wksp$num_pauses), ]
wksp <- wksp[!is.na(wksp$free_vel), ]

# ANP-I don't think this is needed anymore
motility_clean = wksp %>%
  #rename(stimulus = f.stim) %>%
  #rename(vFree = free_vel) %>%
  select(cell_line, stimulus, f.day, slide, id, J, num_pauses, free_vel)

wksp <- wksp[!is.na(wksp$pause_duration), ]

# ANP-I don't think this is needed anymore
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

data_clean <- wksp

# Get speed outlier information
data_speed_sum = data_clean %>%
  group_by(cell_line, f.day, stimulus) %>%
  summarise(speed_mean = mean(mean_velocity),
            speed_sd = sd(mean_velocity)) %>%
  ungroup() %>%
  mutate(speed_high = speed_mean + (2 * speed_sd)) 

# Remove any data points with excessively high speeds on the assumption that they are due to tracking errors
data_clean = data_clean %>%
  inner_join(data_speed_sum) %>%
  filter(mean_velocity < speed_high) 
rm(data_speed_sum)

agg <- data_clean

agg <- aggregate( cbind(track_length,cumul_distance,net_displacement,tortuosity, mean_velocity, mean_theta, mean_CI, num_pauses, pause_duration, confinement_radius, confined_vel, free_vel, super_vel, J) ~ f.day + slide + cell_line + stimulus, data=agg, FUN=sum)

agg$trt <- apply(agg[,c("stimulus","cell_line")], 1, paste, sep="", collapse=":")
agg$trt <- as.factor(agg$trt)
