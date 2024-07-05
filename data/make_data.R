# Data from Wagenmakers, Ratcliff, Gomez, & McKoon (2008, Experiment 1)
# See ?rtdists::speed_acc for details
# Excluding all trials also excluded from the papers using it namely uninterpretable response, too fast response (<180 ms), too slow response (>3 sec)

library(tidyverse)


df <- rtdists::speed_acc |>
  filter(censor == "FALSE") |>
  filter(rt < 2) |>
  mutate(Participant=id,
         Condition=condition,
         RT=rt,
         Error=as.character(response) != as.character(stim_cat),
         Frequency = str_remove_all(frequency, "nw_"),
         Frequency = str_replace(Frequency, "very_low", "Very Low"),
         Frequency = str_replace(Frequency, "low", "Low"),
         Frequency = str_replace(Frequency, "high", "High"),
         Condition = str_replace(Condition, "speed", "Speed"),
         Condition = str_replace(Condition, "accuracy", "Accuracy"),
         .keep = "none") |>
  filter(Participant %in% c(1:6))

write.csv(df, "wagenmakers2008.csv", row.names = FALSE)

# summary(df)
