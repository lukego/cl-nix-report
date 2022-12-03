library(dplyr)
library(ggplot2)
library(readr)

data <- read_csv("report.csv")
ggplot(filter(data, !is.na(reason)), aes(x=variant, fill=variant)) +
  geom_bar() +
  facet_wrap(~reason) +
  scale_x_discrete(guide = guide_axis(angle = 90)) +
  theme(strip.text = element_text(size = 3))

#(data %>% group_by(package) %>% summarize(answ=sum(status=="ok")/n())) %>%
#  ggplot(data, x=as.factor(anws)) + geom_bar()
