--create table of raw advertisement exposures
CREATE TABLE Exposures (
    PELID int,
    TRANSACTIONDATE date,
    FIRSTNAME varchar(255),
    LASTNAME varchar(255),
    PUBLISHER varchar(255),
    PLACEMENT_GROUP varchar(255),
    PUBLISHER_TYPE varchar(255)
);

--insert data from raw exposures table into new table just created
INSERT INTO Exposures
SELECT PELID, TRANSACTIONDATE, FNAME, LNAME, PUBLISHER, PLACEMENT_GROUP, PUBTYPE
FROM RawData;


------------------
----CLEAN DATA----
------------------

--check count of exposures
SELECT COUNT(distinct PELID) FROM Exposures;

--check count of exposures by publisher, ordered by biggest publisher
SELECT PUBLISHER,COUNT(distinct PELID) FROM Exposures GROUP BY PUBLISHER ORDER BY COUNT(distinct PELID) DESC;

--check if any counts are greater than 10,000 b/c will need to split up
SELECT PUBLISHER,COUNT(distinct PELID) FROM Exposures GROUP BY PUBLISHER HAVING COUNT(distinct PELID) >= 10000;

--check biggest publisher
SELECT PUBLISHER,COUNT(distinct PELID) FROM Exposures GROUP BY PUBLISHER ORDER BY COUNT(distinct PELID) DESC LIMIT 1;

--check second biggest publisher
SELECT PUBLISHER,COUNT(distinct PELID) FROM Exposures 
WHERE PELID NOT IN (SELECT PUBLISHER,COUNT(distinct PELID) FROM Exposures GROUP BY PUBLISHER ORDER BY COUNT(distinct PELID) DESC LIMIT 1) 
GROUP BY PUBLISHER ORDER BY COUNT(distinct PELID) DESC LIMIT 1;

--check exposure date range
SELECT MIN(TRANSACTIONDATE), MAX(TRANSACTIONDATE) FROM Exposures;

--cut data off past 05/31/2018 the campaign end date
DELETE FROM Exposures WHERE TRANSACTIONDATE <= '20180601';

--check count again to see how many were past 05/31
SELECT COUNT(distinct PELID) FROM Exposures;

--dedupe exposures based on first touch
CREATE TABLE Exp_dd AS SELECT a.* FROM Exposures a WHERE a.TRANSACTIONDATE||random = (SELECT MIN(b.TRANSACTIONDATE||random) 
FROM Exposures b WHERE a.PEL_ID=b.PEL_ID);


----------------
---AGGREGATE----
----------------

--join deduped exposures table to demographics table
CREATE TABLE Exp_Demo AS SELECT a.* FROM Exp_dd a LEFT JOIN Demographics b ON a.PELID=b.PELID;

--flag publisher as Endemic or Nonendemic type
ALTER TABLE Exp_Demo ADD ENDEMIC_PUB int;
UPDATE Exp_Demo SET ENDEMIC_PUB = (CASE WHEN PUBLISHER_TYPE='Endemic' THEN 1 ELSE 0 END);