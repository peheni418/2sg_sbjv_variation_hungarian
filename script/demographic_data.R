#setwd

# Read CSV
df <- read.csv("dat/age_gender_priming2026.csv", stringsAsFactors = FALSE)

# Remove duplicate rows
df <- unique(df)

# Create age column from year of birth
df$age <- 2026 - as.numeric(df$year_birth)

# Gender counts (F and M) in console
print(table(df$gender))

# Age summary (min, median, max) in console
print(min(df$age, na.rm = TRUE))
print(median(df$age, na.rm = TRUE))
print(max(df$age, na.rm = TRUE))
