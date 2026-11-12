-- Load the source files into the raw tables
-- Run with psql from the project folder (\copy is a psql command)

\copy raw.district        FROM 'data/district.asc' WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.account         FROM 'data/account.asc'  WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.client          FROM 'data/client.asc'   WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.disp            FROM 'data/disp.asc'     WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.card            FROM 'data/card.asc'     WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.loan            FROM 'data/loan.asc'     WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.permanent_order FROM 'data/order.asc'    WITH (FORMAT csv, HEADER true, DELIMITER ';')
\copy raw.trans           FROM 'data/trans.asc'    WITH (FORMAT csv, HEADER true, DELIMITER ';')