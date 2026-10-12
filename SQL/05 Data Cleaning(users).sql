---Replace NULL values with 'Unknown' to preserve the records without assuming a specific device type.---
UPDATE pathwise.users
SET device_type = 'Unknown'
WHERE device_type IS NULL;
--verify--
SELECT device_type, COUNT(*) AS user_count
FROM pathwise.users
GROUP BY device_type
ORDER BY user_count DESC;

---Replace NULL values with 'Unknown' to preserve the records without assuming a subscription plan.---
UPDATE pathwise.users
SET subscription_type = 'Unknown'
WHERE subscription_type IS NULL;
--verify--
SELECT subscription_type, COUNT(*) AS user_count
FROM pathwise.users
GROUP BY subscription_type
ORDER BY user_count DESC;


