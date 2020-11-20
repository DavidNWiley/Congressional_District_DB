
##############################################
# CREATING TABLES
##############################################

# CONGRESS TABLE
CREATE TABLE G24_OLTP.Congress (
	cong_id INT NOT NULL AUTO_INCREMENT,
    cong_name VARCHAR(100),
    PRIMARY KEY (cong_id));
##############################################   
   
# AREA TABLE
CREATE TABLE G24_OLTP.Area (
    fips INT NOT NULL,
    area_name VARCHAR(100),
    PRIMARY KEY (fips));
##############################################

# CONGRESSIONAL DISTRICT TABLE
CREATE TABLE G24_OLTP.Congressional_District (
	cd_id INT NOT NULL AUTO_INCREMENT,
    cong_id INT,
    fips INT,
    dist_num INT,
    PRIMARY KEY (cd_id),
    FOREIGN KEY (cong_id) REFERENCES G24_OLTP.Congress(cong_id),
    FOREIGN KEY (fips) REFERENCES G24_OLTP.Area(fips));
##############################################

# INDUSTRY TABLE
CREATE TABLE G24_OLTP.Industry (
	ind_id INT NOT NULL AUTO_INCREMENT,
	naics CHAR(6),
	ind_desc VARCHAR(255),
	PRIMARY KEY (ind_id),
	UNIQUE (naics));
##############################################

# FLAG TABLE
CREATE TABLE G24_OLTP.Flag (
	code CHAR(1) NOT NULL PRIMARY KEY,
    flag_desc VARCHAR(255));
##############################################

# DISTRICT INDUSTRY TABLE
CREATE TABLE G24_OLTP.District_Industry (
	cd_id INT,
    ind_id INT,
    year INT,
    num_est INT,
    num_empl INT,
    empl_flag_id CHAR(1),
    q1_pr FLOAT,
    q1_pr_flag_id CHAR(1),
    yr_pr FLOAT,
    yr_pr_flag_id CHAR(1),
    PRIMARY KEY (cd_id, ind_id, year),
    FOREIGN KEY (empl_flag_id) REFERENCES G24_OLTP.Flag(code),
    FOREIGN KEY (q1_pr_flag_id) REFERENCES G24_OLTP.Flag(code),
    FOREIGN KEY (yr_pr_flag_id) REFERENCES G24_OLTP.Flag(code),
    FOREIGN KEY (cd_id) REFERENCES G24_OLTP.Congressional_District(cd_id),
    FOREIGN KEY (ind_id) REFERENCES G24_OLTP.Industry(ind_id));


##############################################
# INSERTING DATA INTO THE TABLES
##############################################

# CONGRESS 

INSERT INTO G24_OLTP.Congress (cong_name)
SELECT DISTINCT(CONGRESS)
FROM FCP_CBP.full_dataset;
##############################################

# AREA

INSERT INTO G24_OLTP.Area (fips, area_name)
SELECT DISTINCT(STATE_FIPS), LTRIM(RTRIM(STATE))
FROM FCP_CBP.full_dataset;
##############################################

# CONGRESSIONAL DISTRICT

INSERT INTO G24_OLTP.Congressional_District (cong_id, fips, dist_num)
SELECT DISTINCT cong_id, STATE_FIPS, DISTRICT
FROM FCP_CBP.full_dataset AS fd
	LEFT JOIN G24_OLTP.Congress AS con 
		ON con.cong_name = fd.CONGRESS;
##############################################

# INDUSTRY
    
INSERT INTO G24_OLTP.Industry (naics, ind_desc)
SELECT DISTINCT NAICS, NAICS_DESC
FROM FCP_CBP.full_dataset
# we took out the "total for all sectors" because they 
# could be aggregated and calculated when querying later
WHERE NAICS_DESC <> "Total for all sectors";
##############################################

# FLAG

INSERT INTO G24_OLTP.Flag (code, flag_desc)
VALUES ("D", "Withheld to avoid disclosing data for individual companies; data are included in higher level totals"),
		("S", "Withheld because estimate did not meet publication standards"),
        ("G", "Low noise infusion"),
        ("H", "Medium noise infusion"),
        ("J", "High noise infusion");
##############################################

# DISTRICT INDUSTRY

INSERT INTO G24_OLTP.District_Industry
SELECT cd.cd_id, ind.ind_id, YR, NUM_EST, NUM_EMPL, EMPL_F, Q1_PR, Q1_PR_F, YR_PR, YR_PR_F
FROM FCP_CBP.full_dataset as fd
	LEFT JOIN (SELECT *
				FROM G24_OLTP.Congressional_District
					LEFT JOIN G24_OLTP.Congress USING (cong_id)) AS cd
						ON cd.cong_name = fd.CONGRESS AND cd.fips = fd.STATE_FIPS AND cd.dist_num=fd.DISTRICT
	LEFT JOIN G24_OLTP.Industry as ind
		ON ind.naics = fd.NAICS
	LEFT JOIN G24_OLTP.Flag as flg1
		ON flg1.code = fd.EMPL_F
	LEFT JOIN G24_OLTP.Flag as flg2
		ON flg2.code = fd.Q1_PR_F
	LEFT JOIN G24_OLTP.Flag as flg3
		ON flg3.code = fd.YR_PR_F
WHERE NAICS_DESC <> "Total for all sectors";
##############################################
