WITH lgd AS (
    SELECT 0.5927::numeric AS avg_lgd
),

stacked AS (
    SELECT
        'Model A' AS model_name,
        loan_amnt,
        predicted_pd_a AS predicted_pd
    FROM public.scored_test

    UNION ALL

    SELECT
        'Model B' AS model_name,
        loan_amnt,
        predicted_pd_b AS predicted_pd
    FROM public.scored_test
),

cutoffs AS (
    SELECT
        model_name,
        PERCENTILE_CONT(0.7)
        WITHIN GROUP (ORDER BY predicted_pd) AS pd_cutoff
    FROM stacked
    GROUP BY model_name
),

baseline AS (
    SELECT
        s.model_name,
        SUM(s.loan_amnt * s.predicted_pd * l.avg_lgd) AS baseline_el
    FROM stacked s, lgd l
    GROUP BY s.model_name
),

policy AS (
    SELECT
        s.model_name,
        SUM(s.loan_amnt * s.predicted_pd * l.avg_lgd) AS policy_el
    FROM stacked s
    JOIN cutoffs c
        ON s.model_name = c.model_name
    CROSS JOIN lgd l
    WHERE s.predicted_pd <= c.pd_cutoff
    GROUP BY s.model_name
)

SELECT
    b.model_name,
    ROUND(b.baseline_el::numeric,2) AS baseline_el,
    ROUND(p.policy_el::numeric,2) AS policy_el,
    ROUND((b.baseline_el - p.policy_el)::numeric,2) AS el_reduction_absolute,
    ROUND(
        ((b.baseline_el - p.policy_el)
        / b.baseline_el)::numeric,
    4) AS el_reduction_pct
FROM baseline b
JOIN policy p
    ON b.model_name = p.model_name
ORDER BY b.model_name;