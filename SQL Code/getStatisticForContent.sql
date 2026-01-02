SELECT
    COUNT(*) AS total_content,
    COUNT(*) FILTER (WHERE time_of_creation >= NOW() - INTERVAL '30 days') AS content_last_30_days,
    AVG(EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS avg_days_ago,
    STDDEV(EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS stddev_days_ago,
    VARIANCE(EXTRACT(DAY FROM (NOW() - time_of_creation)))::numeric AS variance_days_ago,
    MIN(EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS min_days_ago,
    MAX(EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS max_days_ago,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS median_days_ago,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS q1_days_ago,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY EXTRACT(DAY FROM (NOW() - time_of_creation)))::int AS q3_days_ago
FROM content;
