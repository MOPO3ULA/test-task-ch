CREATE DATABASE IF NOT EXISTS ch_test_db;

CREATE TABLE IF NOT EXISTS ch_test_db.first_clicks
(
    id                UUID,
    campaign_id       UUID,
    offer_id          UUID,
    landing_page_id   UUID,
    offer_type        String,
    geo_id            UUID,
    user_agent_id     UUID,
    proxy_id          UUID,
    language_id       UUID,
    referer_domain_id UUID,
    ip_v4             String,
    cost              UInt32,
    click_datetime    DateTime64 default now()
) ENGINE = MergeTree()
      PARTITION BY toYYYYMMDD(click_datetime)
      ORDER BY (id, click_datetime);

CREATE TABLE IF NOT EXISTS ch_test_db.correct_clicks
(
    id                UUID,
    payout            UInt32,
    event_1           String,
    event_2           String,
    token_1           String,
    token_2           String,
    conversion_status String,
    click_datetime    DateTime64 default now()
) ENGINE = ReplacingMergeTree()
      PARTITION BY toYYYYMMDD(click_datetime)
      ORDER BY id;

CREATE VIEW IF NOT EXISTS ch_test_db.campaign_view
AS
SELECT campaign_id,
       count(fc.id)            as click_count,
       sum(cost)               as costs,
       sum(payout)             as revenue,
       sum(payout) - sum(cost) as profit
FROM ch_test_db.first_clicks fc
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
WHERE fc.click_datetime > toDateTime64(toStartOfMonth(now() - INTERVAL 4 MONTH), 3)
GROUP BY (campaign_id)
HAVING count(id) > 10;

CREATE VIEW IF NOT EXISTS ch_test_db.campaign_view_total
AS
SELECT cv.campaign_id,
       sum(fc.cost)   as sum_costs,
       sum(cc.payout) as sum_payouts
FROM ch_test_db.campaign_view cv
         LEFT JOIN ch_test_db.first_clicks fc ON cv.campaign_id = fc.campaign_id
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
GROUP BY cv.campaign_id;

CREATE VIEW IF NOT EXISTS ch_test_db.offer_view
AS
SELECT offer_id,
       count(id)                                          as unique_click_count,
       countIf(offer_id, notEquals(offer_type, 'direct')) as offer_count,
       sum(payout)                                        as revenue
FROM ch_test_db.first_clicks fc
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
WHERE (fc.click_datetime BETWEEN toDateTime64('2021-01-01 12:00:00', 3) AND toDateTime64('2021-02-10 16:00:00', 3))
GROUP BY (offer_id);

CREATE VIEW IF NOT EXISTS ch_test_db.offer_view_total
AS
SELECT ov.offer_id,
       sum(fc.cost)   as sum_costs,
       sum(cc.payout) as sum_payouts
FROM ch_test_db.offer_view ov
         LEFT JOIN ch_test_db.first_clicks fc on ov.offer_id = fc.offer_id
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
GROUP BY ov.offer_id;

CREATE VIEW IF NOT EXISTS ch_test_db.landing_view
AS
SELECT landing_page_id,
       count(id)   as unique_click_count,
       sum(payout) as revenue
FROM ch_test_db.first_clicks fc
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
GROUP BY (landing_page_id)
LIMIT 500;

CREATE VIEW IF NOT EXISTS ch_test_db.landing_view_total
AS
SELECT lv.landing_page_id,
       sum(fc.cost)   as sum_costs,
       sum(cc.payout) as sum_payouts
FROM ch_test_db.landing_view lv
         LEFT JOIN ch_test_db.first_clicks fc on lv.landing_page_id = fc.landing_page_id
         LEFT JOIN ch_test_db.correct_clicks cc ON fc.id = cc.id
GROUP BY lv.landing_page_id;