#setwd

# Read CSV
df <- read.csv("dat/age_gender_priming2026.csv", stringsAsFactors = FALSE)

# Remove duplicate rows
df <- unique(df)

# Count gender values (F and M) and show in console
print(table(df$gender))

# Create age column from year of birth
df$age <- 2026 - as.numeric(df$year_birth)
