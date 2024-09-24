-- CREATE EVN_average_customer_waiting_time_every_1_hour

-- CREATE TABLE
CREATE TABLE `customer_service_kpi` (
`customer_service_KPI_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
`customer_service_KPI_average_waiting_time_minutes` INT NOT NULL,
PRIMARY KEY (`customer_service_KPI_timestamp`));

-- CREATE EVENT
DELIMITER $$

CREATE EVENT EVN_average_customer_waiting_time_every_1_hour
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    DECLARE avg_wait_time FLOAT;

    -- Calculate the average waiting time for tickets raised in the past hour
    SELECT AVG(TIMESTAMPDIFF(SECOND, customer_service_ticket_raise_time, NOW()))
    INTO avg_wait_time
    FROM customer_service_ticket
    WHERE customer_service_ticket_raise_time >= NOW() - INTERVAL 1 HOUR;

    -- Insert the computed average(converted into minutes) into the customer_service_kpi table
    INSERT INTO customer_service_kpi (customer_service_KPI_average_waiting_time_minutes, customer_service_KPI_timestamp)
    VALUES (COALESCE(avg_wait_time / 60) 0), NOW()); 

END $$

DELIMITER ;

-- OTHER COMMANDS EXECUTED ACCORDING TO THE LAB MANUAL STEPS
SHOW PROCESSLIST;

SET GLOBAL event_scheduler = OFF;
SHOW PROCESSLIST;

SHOW GRANTS FOR 'student' @'%';


SET GLOBAL event_scheduler = ON;
SHOW PROCESSLIST;

CREATE TABLE `customer_service_ticket` (
`customer_service_ticket_ID` int UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identifies the ticket number',
`customer_service_ticket_resolved` TINYINT DEFAULT NULL COMMENT 'Indicates whether the issue raised via the ticket has been
resolved (1 if resolved and 0 if not resolved)',
`customer_service_ticket_raise_time` timestamp NULL DEFAULT NULL COMMENT 'Records the time when the ticket was raised by the
client. Required to know when to start the timer.',
`customer_service_total_wait_time_minutes` int DEFAULT NULL COMMENT 'Records the total amount of time elapsed since the
customer raised the ticket.',
`customer_service_ticket_last_update` text COMMENT 'Records a message that specifies when the last update was made by firing
the event',
`customerNumber` int DEFAULT NULL COMMENT 'Identifies the customer who has raised the ticket',
PRIMARY KEY (`customer_service_ticket_ID`),
KEY `FK_1_customers_TO_M_customer_service_ticket` (`customerNumber`),
CONSTRAINT `FK_1_customers_TO_M_customer_service_ticket` FOREIGN KEY (`customerNumber`) REFERENCES `customers`
(`customerNumber`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Used to keep track of how long an issue raised via a IT ticketing
system has remained unresolved.';

INSERT INTO `customer_service_ticket`
(`customer_service_ticket_raise_time`, `customer_service_ticket_resolved`, `customerNumber`)
VALUES (CURRENT_TIMESTAMP, 0, 145);

INSERT INTO `customer_service_ticket`
(`customer_service_ticket_raise_time`, `customer_service_ticket_resolved`, `customerNumber`)
VALUES (CURRENT_TIMESTAMP, 0, 496);

INSERT INTO `customer_service_ticket`
(`customer_service_ticket_raise_time`, `customer_service_ticket_resolved`, `customerNumber`)
VALUES (CURRENT_TIMESTAMP, 0, 168);

SELECT * FROM `customer_service_ticket`;

CREATE EVENT EVN_record_customer_waiting_time_every_1_minute_for_1_hour
ON
SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP + INTERVAL 3 MINUTE
ENDS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
ON
COMPLETION PRESERVE
COMMENT 'This event computes the total time a customer has waited since they raised a ticket'
DO
UPDATE
`customer_service_ticket`
SET
`customer_service_total_wait_time_minutes` = TIMESTAMPDIFF(MINUTE,
`customer_service_ticket_raise_time`,
CURRENT_TIMESTAMP),
`customer_service_ticket_last_update` = CONCAT('The last 1-minute recurring update was made at ', CURRENT_TIMESTAMP)
WHERE
`customer_service_ticket_resolved` = 0;

SHOW EVENTS;

SELECT * FROM `customer_service_ticket`;

ALTER EVENT EVN_record_customer_waiting_time_every_1_minute_for_1_hour
DISABLE;

SHOW EVENTS FROM `classicmodels`;

SELECT * FROM `customer_service_ticket`;

UPDATE
`customer_service_ticket`
SET
`customer_service_ticket_resolved` = '1'
WHERE
(`customer_service_ticket_ID` = '2');

ALTER EVENT EVN_record_customer_waiting_time_every_1_minute_for_1_hour
ENABLE;

SELECT * FROM `customer_service_ticket`;

ALTER EVENT EVN_record_customer_waiting_time_every_1_minute_for_1_hour
RENAME TO EVN_record_customer_waiting_time_every_2_minutes_for_1_hour;

ALTER EVENT EVN_record_customer_waiting_time_every_2_minutes_for_1_hour
ON
SCHEDULE EVERY 2 MINUTE
STARTS CURRENT_TIMESTAMP + INTERVAL 3 MINUTE
ENDS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
ON
COMPLETION PRESERVE
DO
UPDATE
`customer_service_ticket`
SET
`customer_service_total_wait_time_minutes` = TIMESTAMPDIFF(MINUTE,
`customer_service_ticket_raise_time`,
CURRENT_TIMESTAMP),
`customer_service_ticket_last_update` = CONCAT('The last 2-minute recurring update was made at ', CURRENT_TIMESTAMP)
WHERE
`customer_service_ticket_resolved` = 0;

SELECT * FROM `customer_service_ticket`;