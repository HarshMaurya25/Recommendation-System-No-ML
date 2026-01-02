WITH ordered_interactions AS (
    SELECT
        ui.user_id,
        ui.content_content_id,
        ui.interact_at,
        CASE
            WHEN ui.is_liked     THEN  2.0
            WHEN ui.is_commented THEN  4.0
            WHEN ui.is_disliked  THEN -5.0
            ELSE 0
        END AS action_weight,
        ROW_NUMBER() OVER (
            PARTITION BY ui.user_id
            ORDER BY ui.interact_at DESC
        ) - 1 AS interaction_index
    FROM users_interaction ui
    WHERE ui.user_id = '1b3d1f03-eab5-433f-82bd-a89946b41a16'
),
interaction_scores AS (
    SELECT
        oi.content_content_id,
        oi.action_weight
        * EXP(-LN(2) * oi.interaction_index / 20.0)  
        * EXP(-LN(2) * EXTRACT(DAY FROM (NOW() - oi.interact_at)) / 45.0) 
        AS score
    FROM ordered_interactions oi
),
tag_stats AS (
    SELECT
        tg.tag,
        SUM(iscore.score) / SQRT(COUNT(*)) AS raw_tag_score,
        COUNT(*) AS interaction_count
    FROM interaction_scores iscore
    JOIN content_tags tg
      ON tg.content_id = iscore.content_content_id
    GROUP BY tg.tag
),
tag_affinity AS (
    SELECT
        tag,
        raw_tag_score,
        EXP(raw_tag_score) / SUM(EXP(raw_tag_score)) OVER () AS tag_weight
    FROM tag_stats
)
SELECT ta.tag, ta.raw_tag_score, ta.tag_weight
FROM tag_affinity ta
ORDER BY ta.tag_weight DESC;
