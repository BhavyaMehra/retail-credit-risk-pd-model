WITH stacked AS (
    SELECT
        'Model A' AS model_name,
        default_flag,
        predicted_pd_a AS predicted_pd
    FROM public.scored_test

    UNION ALL

    SELECT
        'Model B' AS model_name,
        default_flag,
        predicted_pd_b AS predicted_pd
    FROM public.scored_test
),

ranked AS (
    SELECT
        model_name,
        default_flag,
        predicted_pd,
        NTILE(10) OVER (
            PARTITION BY model_name
            ORDER BY predicted_pd DESC
        ) AS decile
    FROM stacked
),

top_decile AS (
    SELECT
        model_name,
        SUM(default_flag) FILTER (WHERE decile = 1) * 1.0
        / SUM(default_flag) AS top_decile_capture
    FROM ranked
    GROUP BY model_name
),

cutoffs AS (
    SELECT
        model_name,
        PERCENTILE_CONT(0.7)
        WITHIN GROUP (ORDER BY predicted_pd) AS pd_cutoff
    FROM stacked
    GROUP BY model_name
),

total_bads AS (
    SELECT
        model_name,
        SUM(default_flag) AS total_bads
    FROM stacked
    GROUP BY model_name
),

rejected_bads AS (
    SELECT
        s.model_name,
        SUM(s.default_flag) AS rejected_bads
    FROM stacked s
    JOIN cutoffs c
        ON s.model_name = c.model_name
    WHERE s.predicted_pd > c.pd_cutoff
    GROUP BY s.model_name
)

SELECT
    td.model_name,
    ROUND(td.top_decile_capture::numeric,4) AS top_decile_capture,
    ROUND(
        (rb.rejected_bads * 1.0 / tb.total_bads)::numeric,
    4) AS reject_30_capture
FROM top_decile td
JOIN rejected_bads rb
    ON td.model_name = rb.model_name
JOIN total_bads tb
    ON td.model_name = tb.model_name
ORDER BY td.model_name;