# SQL Recommendation Engine

A sophisticated content recommendation system built with SQL/PostgreSQL that uses advanced mathematical models to personalize content recommendations based on user interactions, preferences, and content velocity.

## Project Overview

This project implements a recommendation engine that analyzes user interactions (likes, comments, dislikes) to generate personalized content recommendations. The system considers multiple factors including:

- **User affinity** for categories, genres, and tags
- **Temporal decay** of interactions and content freshness
- **Content velocity** (trending content detection)
- **Content quality** based on engagement metrics
- **Personalization** using exponential softmax weighting

## Files Description

### 1. `RecommendationEngineVelocity.sql`

The main recommendation engine that combines all scoring mechanisms with velocity-based trending detection.

### 2. `getCategoryScoreForUser.sql`

Calculates user affinity scores for content categories based on interaction history.

### 3. `getGenreScoreForUser.sql`

Computes user preference weights for different content genres.

### 4. `getTagScoreFromUser.sql`

Determines user affinity for specific content tags.

### 5. `getStatisticForContent.sql`

Generates statistical analysis of content age distribution including mean, median, variance, and quartiles.

### 6. `getUserInteractionCount.sql`

Simple aggregation query to count user interactions.

---

## Mathematical Formulas Used

### 1. **Exponential Decay Function**

Used for temporal weighting of interactions and content freshness.

$$\text{decay} = e^{-\ln(2) \cdot \frac{t}{t_{1/2}}}$$

Where:

- $t$ = time elapsed (interaction index or days)
- $t_{1/2}$ = half-life parameter
- $\ln(2)$ = natural logarithm of 2 (≈ 0.693)

**Applications:**

- **Interaction Index Decay**: $t_{1/2} = 20$ (older interactions in history)
- **Interaction Time Decay**: $t_{1/2} = 45$ days (time since interaction)
- **Content Time Decay**: $t_{1/2} = 30$ days (content freshness)

### 2. **Interaction Score Formula**

Combines action weights with temporal decay factors.

$$\text{score} = w_{\text{action}} \cdot e^{-\ln(2) \cdot \frac{i}{20}} \cdot e^{-\ln(2) \cdot \frac{d}{45}}$$

Where:

- $w_{\text{action}}$ = action weight (like: 2, comment: 4, dislike: -5)
- $i$ = interaction index (position in user's history)
- $d$ = days since interaction

### 3. **Raw Affinity Score (Categories/Genres/Tags)**

Normalized by square root of sample size to reduce variance.

$$\text{raw\_score} = \frac{\sum \text{scores}}{\sqrt{n}}$$

Where:

- $n$ = count of interactions with that category/genre/tag
- Square root normalization reduces impact of categories with many but low-quality interactions

### 4. **Softmax (Exponential Normalization)**

Converts raw scores to probability distributions for affinity weights.

$$w_i = \frac{e^{s_i / T}}{\sum_j e^{s_j / T}}$$

Where:

- $s_i$ = raw score for item $i$
- $T$ = temperature parameter (controls distribution sharpness)
- Higher temperature → more uniform distribution
- Lower temperature → more concentrated on top items

**Simplified version** (used in category/genre/tag scoring):

$$w_i = \frac{e^{s_i}}{\sum_j e^{s_j}}$$

**With temperature** (used in RecommendationEngineVelocity.sql):

$$w_i = \frac{e^{\max(s_i, -1.5) / 1.5}}{\sum_j e^{\max(s_j, -1.5) / 1.5}}$$

### 5. **Mean Score (Content Quality)**

Weighted engagement metric based on positive vs total interactions.

$$\text{mean\_score} = w_{\text{mean}} \cdot \frac{n_{\text{like}} + n_{\text{comment}}}{n_{\text{like}} + n_{\text{dislike}} + n_{\text{comment}}}$$

Where:

- $w_{\text{mean}}$ = mean score weight factor (0.4)
- Ratio represents proportion of positive engagement

### 6. **Exponential Saturation for Personalization**

Prevents over-weighting when user has strong preferences.

$$\text{saturation} = 1 - e^{-x}$$

Where:

- $x$ = sum of affinity weights
- Creates diminishing returns for additional matching preferences
- Asymptotically approaches 1.0

### 7. **Weighted Preference Score**

Combines base quality with personalized affinity using saturation.

$$\text{weighted\_score} = \min\left((\text{mean\_score} + 1) \cdot \left(1 + \sum f_k \cdot (1 - e^{-w_k})\right), \text{max\_score}\right)$$

Where:

- $f_k$ = factor for feature type (category: 0.5, genre: 1.0, tag: 0.8)
- $w_k$ = sum of affinity weights for feature type $k$
- Capped at maximum weighted score (6.0)

### 8. **Hyperbolic Tangent (Velocity Boost)**

Measures rate of change in engagement, bounded between -1 and 1.

$$\text{velocity\_boost} = \tanh\left(\frac{s_{\text{recent}} - \frac{s_{\text{baseline}}}{4}}{|s_{\text{baseline}}| + 1}\right)$$

Where:

- $s_{\text{recent}}$ = engagement score in last 7 days
- $s_{\text{baseline}}$ = engagement score in last 30 days
- $\tanh$ = hyperbolic tangent function: $\tanh(x) = \frac{e^x - e^{-x}}{e^x + e^{-x}}$
- Compares recent activity to baseline, normalized by baseline magnitude
- Positive when content is accelerating in popularity

### 9. **Final Recommendation Score**

Combines quality, temporal decay, and velocity.

$$\text{final\_score} = \text{weighted\_score} \cdot e^{-\ln(2) \cdot \frac{d_{\text{age}}}{30}} \cdot (1 + s_v \cdot \text{velocity\_boost})$$

Where:

- $d_{\text{age}}$ = days since content creation
- $s_v$ = velocity strength factor (0.5)
- Balances content quality, freshness, and trending momentum

### 10. **Statistical Measures**

Used in content analysis:

- **Mean (Average)**: $\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i$

- **Variance**: $\sigma^2 = \frac{1}{n}\sum_{i=1}^{n} (x_i - \bar{x})^2$

- **Standard Deviation**: $\sigma = \sqrt{\sigma^2}$

- **Median (50th Percentile)**: Middle value when sorted

- **Quartiles**:
  - Q1 (25th percentile): 25% of data below this value
  - Q3 (75th percentile): 75% of data below this value

---

## Key Constants and Parameters

| Parameter                     | Value   | Description                                  |
| ----------------------------- | ------- | -------------------------------------------- |
| `liked_power`                 | 2       | Weight for like actions                      |
| `comment_power`               | 4       | Weight for comment actions                   |
| `dislike_power`               | -5      | Weight for dislike actions                   |
| `category_factor`             | 0.5     | Importance of category matching              |
| `genre_factor`                | 1.0     | Importance of genre matching                 |
| `tag_factor`                  | 0.8     | Importance of tag matching                   |
| `interaction_index_half_life` | 20      | Half-life for interaction recency in history |
| `interaction_time_half_life`  | 45 days | Half-life for interaction age                |
| `content_time_half_life`      | 30 days | Half-life for content age                    |
| `mean_score_weight`           | 0.4     | Weight for content quality metric            |
| `affinity_temperature`        | 1.5     | Temperature for softmax distribution         |
| `max_weighted_score`          | 6.0     | Maximum cap for weighted scores              |
| `velocity_strength`           | 0.5     | Strength of velocity boost effect            |

---

## Database Schema Requirements

The queries expect the following tables:

- **`users_interaction`**: User interactions with content (user_id, content_content_id, interact_at, is_liked, is_commented, is_disliked)
- **`content`**: Content metadata (content_id, content_title, time_of_creation, like_count, comment_count, dislike_count)
- **`content_categories`**: Content category mappings (content_id, category)
- **`content_genres`**: Content genre mappings (content_id, genre)
- **`content_tags`**: Content tag mappings (content_id, tag)

---

## Algorithm Flow

1. **Collect User Interactions**: Order by recency, assign weights based on action type
2. **Calculate Interaction Scores**: Apply double exponential decay (index + time)
3. **Compute Affinity Weights**: Aggregate scores by category/genre/tag with softmax normalization
4. **Calculate Content Quality**: Mean score from engagement metrics
5. **Apply Personalization**: Weight content by user affinities with saturation
6. **Calculate Velocity**: Detect trending content using hyperbolic tangent
7. **Generate Final Scores**: Combine quality × freshness × velocity
8. **Rank and Return**: Sort by final score descending

---

## Mathematical Concepts

### Exponential Decay

Models natural processes where quantity decreases at a rate proportional to its current value. Used here to model:

- Forgetting/recency bias in user preferences
- Content becoming stale over time
- Older interactions having less predictive power

### Softmax Function

Converts arbitrary real values to a probability distribution. Properties:

- Output values sum to 1
- Maintains relative ordering
- Differentiable (useful for optimization)
- Temperature parameter controls concentration

### Hyperbolic Tangent (tanh)

S-shaped curve that:

- Bounds output to [-1, 1]
- Smooth and differentiable
- Symmetric around origin
- Models saturation effects

### Exponential Saturation

Function $1 - e^{-x}$ that:

- Starts at 0 when x=0
- Asymptotically approaches 1 as x→∞
- Models diminishing returns
- Prevents over-fitting to strong preferences

---

## Usage Example

To get personalized recommendations for a specific user:

```sql
-- Update the user_id in the WHERE clauses throughout the query
-- Then execute to get ranked recommendations
```

Results include:

- Content ID and title
- Mean quality score
- Weighted personalization score
- Content age in days
- Final recommendation score (higher = better match)

---

## Performance Considerations

- **CTEs (Common Table Expressions)**: Organized as building blocks for clarity
- **Window Functions**: Efficient for ranking and partitioning operations
- **Indexes Recommended**:
  - `users_interaction(user_id, interact_at DESC)`
  - `content(content_id)`
  - `content_categories(content_id, category)`
  - `content_genres(content_id, genre)`
  - `content_tags(content_id, tag)`

---

## Future Enhancements

- Collaborative filtering integration
- A/B testing framework for parameter tuning
- Real-time update mechanisms
- Multi-armed bandit for exploration vs exploitation
- Neural embedding for content similarity

---

## License

This project is provided as-is for educational and commercial use.

## Author

Created as part of SQL mini-projects collection.
