
library(dplyr)
# ������ ����� ������ �ҷ�����
raw_moon <- readLines("speech_moon.txt", encoding = "UTF-8")
moon <- raw_moon %>%
  as_tibble() %>%
  mutate(president = "moon")
# �ڱ��� ����� ������ �ҷ�����
raw_park <- readLines("speech_park.txt", encoding = "UTF-8")
park <- raw_park %>%
  as_tibble() %>%
  mutate(president = "park")

# �� ������ ��ġ���
bind_speeches <- bind_rows(moon, park) %>%
  select(president, value)


bind_speeches %>% count(president)

head(bind_speeches)
tail(bind_speeches)

# �⺻���� ��ó��
library(stringr)
speeches <- bind_speeches %>%
  mutate(value = str_replace_all(value, "[^��-�R]", " "),
         value = str_squish(value))
speeches


# ��ūȭ
library(tidytext)
library(KoNLP)
speeches <- speeches %>%
  unnest_tokens(input = value,
                output = word,
                token = extractNoun)
speeches

frequency <- speeches %>%
  count(president, word) %>% # ������ �� �ܾ ��
  filter(str_count(word) > 1) # �� ���� �̻� ����
head(frequency)
tail(frequency)

# dplyr::slice_max() : ���� ū ���� n���� ���� ������ �������� ����
top10 <- frequency %>%
  group_by(president) %>% # president���� �и�
  arrange(desc(n)) %>% # ���� 10�� ����
  head(10) %>% filter(president == "park")
top10

top10 <- frequency %>%
  group_by(president) %>% # president���� �и�
  slice_max(n, n= 10)
top10

top10 <- frequency %>%
  group_by(president) %>%
  slice_max(n, n = 10, with_ties = F)
top10

library(ggplot2)
ggplot(top10, aes(x = reorder(word, n),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president)

# y���� �������� �ʰ� ���� 10����

ggplot(top10, aes(x = reorder(word, n),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president, scales = "free_y")

# �� ������
ggplot(top10, aes(x = reorder_within(word, n, president),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president, scales = "free_y")

#tidytext::scale_x_reordered() : �� �ܾ� ���� ���� �׸� ����

ggplot(top10, aes(x = reorder_within(word, n, president),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president, scales = "free_y") +
  scale_x_reordered() +
  labs(x = NULL) + # x�� ����
  theme(text = element_text(family = "nanumgothic")) # ��Ʈ

# 11-1 ODDS Ratio


df_long <- frequency %>%
  group_by(president) %>%
  slice_max(n, n = 10) %>%
  filter(word %in% c("����", "�츮", "��ġ", "�ູ"))

df_long

# pivoting

install.packages("tidyr")
library(tidyr)
df_wide <- df_long %>%
  pivot_wider(names_from = president,
              values_from = n)
df_wide


df_long

#  NA�� 0���� 
df_wide <- df_long %>%
  pivot_wider(names_from = president,
              values_from = n,
              values_fill = list(n = 0))
df_wide


frequency_wide <- frequency %>%
  pivot_wider(names_from = president,
              values_from = n,
              values_fill = list(n = 0))
frequency_wide

#Odds ratio ���
frequency_wide <- frequency_wide %>%
  mutate(ratio_moon = ((moon)/(sum(moon))), # moon ���� �ܾ��� ����
         ratio_park = ((park)/(sum(park)))) # park ���� �ܾ��� ����
frequency_wide

# �ܾ� ���� �񱳸� ���ؼ� �� �࿡ 1�� ����

frequency_wide <- frequency_wide %>%
  mutate(ratio_moon = ((moon + 1)/(sum(moon + 1))), # moon���� �ܾ��� ����
         ratio_park = ((park + 1)/(sum(park + 1)))) # park���� �ܾ��� ����
frequency_wide


frequency_wide <- frequency_wide %>%
  mutate(odds_ratio = ratio_moon/ratio_park)
frequency_wide

#"moon"���� ������� ���� Ŭ���� 1���� ū ��
#"park"���� ������� ���� Ŭ���� 1���� ���� ��

frequency_wide %>%
  arrange(-odds_ratio)


frequency_wide %>%
  arrange(odds_ratio)


# ��������� �߿��� �ܾ� �����ϱ�
top10 <- frequency_wide %>%
  filter(rank(odds_ratio) <= 10 | rank(-odds_ratio) <= 10)
top10



top10 <- top10 %>%
  mutate(president = ifelse(odds_ratio > 1, "moon", "park"),
         n = ifelse(odds_ratio > 1, moon, park))
top10

top10 <- top10 %>%
  group_by(president) %>% 
  slice_max(n, n= 10, with_ties = F)
top10


ggplot(top10, aes(x = reorder_within(word, n, president),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president, scales = "free_y") +
  scale_x_reordered()


# �׷��� ���� �� ���� ����
ggplot(top10, aes(x = reorder_within(word, n, president),
                  y = n,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  facet_wrap(~ president, scales = "free") +
  scale_x_reordered() +
  labs(x = NULL) + # x�� ����
  theme(text = element_text(family = "nanumgothic")) # ��Ʈ

# �α� �����
frequency_wide <- frequency_wide %>%
  mutate(log_odds_ratio = log(odds_ratio))
frequency_wide


frequency_wide %>%
  arrange(-log_odds_ratio)


frequency_wide %>%
  arrange(log_odds_ratio)


top10 <- frequency_wide %>%
  group_by(president = ifelse(log_odds_ratio > 0, "moon", "park")) %>%
  slice_max(abs(log_odds_ratio), n = 10, with_ties = F)
top10


top10 %>%
  arrange(-log_odds_ratio) %>%
  select(word, log_odds_ratio, president)

# ���� �ٸ� �������� ���� �׷��� �׸���
ggplot(top10, aes(x = reorder(word, log_odds_ratio),
                  y = log_odds_ratio,
                  fill = president)) +
  geom_col() +
  coord_flip() +
  labs(x = NULL) +
  theme(text = element_text(family = "nanumgothic"))