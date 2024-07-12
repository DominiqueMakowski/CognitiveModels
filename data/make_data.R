# Data from Wagenmakers, Ratcliff, Gomez, & McKoon (2008, Experiment 1)
# See ?rtdists::speed_acc for details
# Excluding all trials also excluded from the papers using it namely uninterpretable response, too fast response (<180 ms), too slow response (>3 sec)

library(tidyverse)


# RT ----------------------------------------------------------------------


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



# Personality -------------------------------------------------------------


df <- psych::bfi
df$Agreeableness <- rowMeans(select(df, starts_with("A", ignore.case = FALSE)))
df$Conscientiousness <- rowMeans(select(df, starts_with("C", ignore.case = FALSE)))
df$Extraversion <- rowMeans(select(df, starts_with("E", ignore.case = FALSE)))
df$Neuroticism <- rowMeans(select(df, starts_with("N", ignore.case = FALSE)))
df$Openness <- rowMeans(select(df, starts_with("O", ignore.case = FALSE)))

df <- df |>
  select(Gender=gender, Age=age, Agreeableness, Conscientiousness, Extraversion, Neuroticism, Openness) |>
  filter(Age > 18) |>
  mutate(Gender = ifelse(Gender == 1, "Male", "Female"))

df <- df[complete.cases(df),]


write.csv(df, "harman1967.csv", row.names = FALSE)



# Patho Personality -------------------------------------------------------------


df <- read.csv("https://raw.githubusercontent.com/RealityBending/IllusionGameValidation/main/data/study3.csv") |>
  select(starts_with("IPIP6_"), starts_with("PID5_"), -PID5_SD, -IPIP6_SD) |>
  mutate(across(starts_with("IPIP6_"), \(x) datawizard::rescale(x, range=c(0, 100), to=c(1, 7))),
         across(starts_with("PID5_"), \(x) datawizard::rescale(x, range=c(0, 100), to=c(0, 3))) )

df <- df[complete.cases(df),]

ggplot(df, aes(x=PID5_Disinhibition)) +
  geom_histogram(bins = 60)

write.csv(df, "makowski2023.csv", row.names = FALSE)



