/*
 *
 * GO 20091112: indexes added
 *
 * PhG 20010-01-06:
 *   LMF_LASER_COLORS_DEF -> LMF_LASER_COLOR_DEF + column changes.
 *   Err. on norm. factor
 * 
 * GO 20010109: new indexes added - removed SEQ_ID from 
 *   LMF_PRIM_DATASET_DAT - partitioned tables
 *
 * GO 20100323: sequences redefined with NOCACHE
 *	
 * GO 20100910: removed contraints against RUN_IOV (cannot constraint on a
 *   different account): substituted by triggers
 *
 * GO 20100927: SYNONYMs created (may need grant on CMS_ECAL_COND)
 * GO 20101011: modified table structure for XXX_CLS_XXX tables
 * GO 20101020: LMF_CLS_XXX tables modified to move the REF field after
 *              LOGIC_ID (needed to use only one class in C++) 
 * GO 20101124: modified Corr coeff table
 */

PROMPT "Starting creating laser tables: "
PROMPT "   please GRANT SELECT ON RUN_IOV from CMS_ECAL_COND account"

CREATE SEQUENCE lmf_run_tag_sq INCREMENT BY 1 START WITH 1 NOCACHE;

CREATE SEQUENCE lmf_run_iov_sq INCREMENT BY 1 START WITH 1 NOCACHE;

CREATE SEQUENCE LMF_LMR_SUB_IOV_ID_SQ INCREMENT BY 1 START WITH 1 NOCACHE;

CREATE SEQUENCE lmf_iov_sq INCREMENT BY 1 START WITH 1 NOCACHE;

CREATE SEQUENCE SEQ_ID_SQ INCREMENT BY 1 START WITH 1 NOCACHE;
CREATE SEQUENCE CORR_COEF_ID_SQ INCREMENT BY 1 START WITH 1 NOCACHE;

/*  LMF_RUN_TAG: done  */
CREATE TABLE LMF_RUN_TAG
(
  GEN_TAG VARCHAR2(100),
  VERSION NUMBER,
  TAG_ID  NUMBER NOT NULL
)
/

INSERT INTO LMF_RUN_TAG VALUES ('gen', 1, lmf_run_tag_sq.nextVal);

ALTER TABLE LMF_RUN_TAG
  ADD CONSTRAINT LMF_RUN_TAG_PK PRIMARY KEY (TAG_ID)
/

/* LMF_COLOR_DEF: done */
CREATE TABLE LMF_COLOR_DEF
(
  COLOR_ID    NUMBER NOT NULL,
  COLOR_INDEX NUMBER    NOT NULL,
  SNAME       VARCHAR2(10) NOT NULL,
  LNAME       VARCHAR2(100) NOT NULL
)
/

ALTER TABLE LMF_COLOR_DEF
  ADD CONSTRAINT LM_COLOR_DEF_PK PRIMARY KEY (COLOR_ID)
/

INSERT INTO LMF_COLOR_DEF VALUES (1, 0, 'blue', 
	'blue laser (440 nm) or blue led');
INSERT INTO LMF_COLOR_DEF VALUES (2, 1, 'green', 'green (495 nm)');
INSERT INTO LMF_COLOR_DEF VALUES (3, 2, 
	'red/orange', 'red laser (706 nm) or orange led');
INSERT INTO LMF_COLOR_DEF VALUES (4, 3, 'IR', 'infrared (796 nm)');

/* LMF_TRIG_TYPE_DEF */
CREATE TABLE LMF_TRIG_TYPE_DEF
(
  TRIG_TYPE NUMBER,
  SNAME VARCHAR2(5),
  LNAME VARCHAR2(50),
  CONSTRAINT LMF_TRIG_TYPE_DEF PRIMARY KEY(TRIG_TYPE)
)
/

INSERT INTO LMF_TRIG_TYPE_DEF VALUES (1, 'las', 'laser');
INSERT INTO LMF_TRIG_TYPE_DEF VALUES (2, 'led', 'led');
INSERT INTO LMF_TRIG_TYPE_DEF VALUES (3, 'tp', 'test pulse');
INSERT INTO LMF_TRIG_TYPE_DEF VALUES (4, 'ped', 'pedestal');

/* LMF_SEQ_VERS */
CREATE TABLE LMF_SEQ_VERS
(
  VERS NUMBER(3),
  DB_TIMESTAMP TIMESTAMP DEFAULT sys_extract_utc(SYSTIMESTAMP) NOT NULL,
  DESCR VARCHAR2(100),
  CONSTRAINTS LMF_SEQ_VERS_PK PRIMARY KEY(VERS)
)
/

INSERT INTO LMF_SEQ_VERS VALUES (0, DEFAULT, 'none');
INSERT INTO LMF_SEQ_VERS VALUES (1, DEFAULT, 'default');

/* LMF_SEQ_DAT 
-- In the table the list of calibration sequences, that is a scan
-- of the whole ECAL with the different event type. 1 row = 1 sequence.
*/
CREATE TABLE LMF_SEQ_DAT
(
  SEQ_ID        NUMBER,
  RUN_IOV_ID    NUMBER,
  SEQ_NUM       NUMBER,
  SEQ_START     DATE NOT NULL,
  SEQ_STOP      DATE NOT NULL,
  VMIN          NUMBER,
  VMAX          NUMBER,
  CONSTRAINTS LMF_SEQ_DAT_PK PRIMARY KEY(SEQ_ID),
  CONSTRAINTS LMF_SEQ_DAT_FK2 FOREIGN KEY(VMIN) REFERENCES LMF_SEQ_VERS(VERS),
  CONSTRAINTS LMF_SEQ_DAT_FK3 FOREIGN KEY(VMAX) REFERENCES LMF_SEQ_VERS(VERS)
)
PARTITION BY RANGE ("SEQ_ID")
(PARTITION "LMF_SEQ_DAT_10" VALUES LESS THAN (MAXVALUE))
/

/*  LMF_RUN_IOV  */
-- This table holds the list of monitoring subruns, that a batch
-- of consecutive events on the same region and of the same type.
CREATE TABLE LMF_RUN_IOV
(
  LMF_IOV_ID     NUMBER NOT NULL,
  TAG_ID         NUMBER NOT NULL,
  SEQ_ID         NUMBER NOT NULL,
  LMR            NUMBER NOT NULL,
  COLOR_ID       NUMBER NOT NULL,
  TRIG_TYPE      NUMBER NOT NULL,
  SUBRUN_START   DATE NOT NULL,
  SUBRUN_END     DATE NOT NULL,
  SUBRUN_TYPE    VARCHAR2(20) NOT NULL,
  DB_TIMESTAMP   TIMESTAMP DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_RUN_IOV_10" VALUES LESS THAN (MAXVALUE));

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_PK PRIMARY KEY (LMF_IOV_ID)
/

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_UK UNIQUE (SEQ_ID, LMR, COLOR_ID, TRIG_TYPE)
/

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_FK1 FOREIGN KEY (TAG_ID)
  REFERENCES LMF_RUN_TAG(TAG_ID)
/

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_FK2 FOREIGN KEY (SEQ_ID)
  REFERENCES LMF_SEQ_DAT(SEQ_ID)
/

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_FK3 FOREIGN KEY (COLOR_ID)
  REFERENCES LMF_COLOR_DEF(COLOR_ID)
/

ALTER TABLE LMF_RUN_IOV
  ADD CONSTRAINT LMF_RUN_IOV_FK4 FOREIGN KEY (TRIG_TYPE)
  REFERENCES LMF_TRIG_TYPE_DEF
/

/*  LMF_LASER_CONFIG_DAT  */
CREATE TABLE LMF_LASER_CONFIG_DAT
(
  LMF_IOV_ID     NUMBER NOT NULL,
  LOGIC_ID       NUMBER NOT NULL,
  WAVELENGTH     NUMBER,
  VFE_GAIN       NUMBER,
  PN_GAIN        NUMBER,
  LSR_POWER      NUMBER,
  LSR_ATTENUATOR NUMBER,
  LSR_CURRENT    NUMBER,
  LSR_DELAY_1    NUMBER,
  LSR_DELAY_2    NUMBER
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_CONFIG_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_CONFIG_DAT
  ADD CONSTRAINT LMF_LASER_CONFIG_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID)
/

ALTER TABLE LMF_LASER_CONFIG_DAT
  ADD CONSTRAINT LMF_LASER_CONFIG_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

/*  LMF_RUN_DAT  */
CREATE TABLE LMF_RUN_DAT
(
  LMF_IOV_ID   NUMBER NOT NULL,
  LOGIC_ID     NUMBER NOT NULL,
  NEVENTS      NUMBER,
  QUALITY_FLAG NUMBER
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_RUN_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_RUN_DAT
  ADD CONSTRAINT LMF_RUN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID)
/

ALTER TABLE LMF_RUN_DAT
  ADD CONSTRAINT LMF_RUN_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/


/*  LMF_TEST_PULSE_CONFIG_DAT  */
CREATE TABLE LMF_TEST_PULSE_CONFIG_DAT
(
  LMF_IOV_ID NUMBER NOT NULL,
  LOGIC_ID   NUMBER NOT NULL,
  VFE_GAIN   NUMBER,
  DAC_MGPA   NUMBER,
  PN_GAIN    NUMBER,
  PN_VINJ    NUMBER
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_TEST_PULSE_CONFIG_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_TEST_PULSE_CONFIG_DAT
  ADD CONSTRAINT LMF_TEST_PULSE_CONFIG_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID)
/

ALTER TABLE LMF_TEST_PULSE_CONFIG_DAT
  ADD CONSTRAINT LMF_TEST_PULSE_CONFIG_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/


/* LMF_PRIM_VERS */
CREATE TABLE LMF_PRIM_VERS
(
  VERS         NUMBER,
  DB_TIMESTAMP TIMESTAMP DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL,
  DESCR        VARCHAR2(100),
  CONSTRAINTS LMF_PRIM_VERS_PK  PRIMARY KEY(VERS)
)
/

INSERT INTO LMF_PRIM_VERS VALUES (0, DEFAULT, 'none');
INSERT INTO LMF_PRIM_VERS VALUES (1, DEFAULT, 'default');

/*  LMF_CLS_XXX_DAT  */
CREATE TABLE LMF_CLS_BLUE_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  LMF_IOV_ID_REF    NUMBER,
  MEAN              NUMBER, 
  NORM              NUMBER, 
  RMS               NUMBER, 
  NEVT		    NUMBER,
  ENORM             NUMBER,
  FLAG              NUMBER,
  FLAGNORM          NUMBER,
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_CLS_BLUE_DAT_FK1 FOREIGN KEY(VMIN)
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_CLS_BLUE_DAT_FK2 FOREIGN KEY(VMAX)
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_CLS_BLUE_DAT_FK3 FOREIGN KEY(LMF_IOV_ID)
    REFERENCES LMF_RUN_IOV(LMF_IOV_ID),
  CONSTRAINTS LMF_CLS_BLUE_DAT_FK4 FOREIGN KEY(LMF_IOV_ID_REF)
    REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_CLS_BLUE_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_CLS_BLUE_DAT
  ADD CONSTRAINT LMF_CLS_BLUE_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
        VMIN)
/

CREATE TABLE LMF_CLS_IR_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  LMF_IOV_ID_REF    NUMBER,
  MEAN              NUMBER, 
  NORM              NUMBER, 
  RMS               NUMBER, 
  NEVT		    NUMBER,
  ENORM             NUMBER,
  FLAG              NUMBER,
  FLAGNORM          NUMBER,
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_CLS_IR_DAT_FK1 FOREIGN KEY(VMIN)
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_CLS_IR_DAT_FK2 FOREIGN KEY(VMAX)
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_CLS_IR_DAT_FK3 FOREIGN KEY(LMF_IOV_ID)
    REFERENCES LMF_RUN_IOV(LMF_IOV_ID),
  CONSTRAINTS LMF_CLS_IR_DAT_FK4 FOREIGN KEY(LMF_IOV_ID_REF)
    REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_CLS_IR_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_CLS_IR_DAT
  ADD CONSTRAINT LMF_CLS_IR_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
        VMIN)
/

/* LMF_CORR_VERS */
CREATE TABLE LMF_CORR_VERS
(
  VERS NUMBER,
  DB_TIMESTAMP TIMESTAMP DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL,
  DESCR VARCHAR2(100),
  CONSTRAINTS LMF_CORR_VERS_PK PRIMARY KEY(VERS)
)
/

INSERT INTO LMF_CORR_VERS VALUES (0, DEFAULT, 'none');
INSERT INTO LMF_CORR_VERS VALUES (1, DEFAULT, 'default');

/* LMF_IOV */
CREATE TABLE LMF_IOV
(
  IOV_ID    NUMBER,
  IOV_START DATE,
  IOV_STOP  DATE,
  VMIN      NUMBER,
  VMAX      NUMBER,
  CONSTRAINTS LMF_IOV_PK PRIMARY KEY(IOV_ID),
  CONSTRAINTS LMF_IOV_FK1 FOREIGN KEY(VMIN) REFERENCES LMF_CORR_VERS(VERS),
  CONSTRAINTS LMF_IOV_FK2 FOREIGN KEY(VMAX) REFERENCES LMF_CORR_VERS(VERS)
)
PARTITION BY RANGE ("IOV_ID")
(PARTITION "LMF_IOV_10" VALUES LESS THAN (MAXVALUE))
/

/* LMF_LMR_SUB_IOV */
CREATE TABLE LMF_LMR_SUB_IOV
(
  LMR_SUB_IOV_ID     NUMBER,
  IOV_ID             NUMBER,
  T1                 DATE,
  T2                 DATE,
  T3                 DATE,
  CONSTRAINTS LMF_LMR_SUB_IOV_PK PRIMARY KEY(LMR_SUB_IOV_ID),
  CONSTRAINTS LMF_LMR_SUB_IOV_FK FOREIGN KEY(IOV_ID) REFERENCES LMF_IOV
)
PARTITION BY RANGE ("LMR_SUB_IOV_ID")
(PARTITION "LMF_LMR_SUB_IOV_10" VALUES LESS THAN (MAXVALUE))
/

/* LMF_CORR_COEF_DAT */
CREATE TABLE LMF_CORR_COEF_DAT
(
  LMR_SUB_IOV_ID NUMBER NOT NULL,
  LOGIC_ID       NUMBER NOT NULL,
  P1             NUMBER, -- OR BINARY_FLOAT
  P2             NUMBER, -- OR BINARY_FLOAT
  P3             NUMBER, -- OR BINARY_FLOAT
  P1_ERR         NUMBER, -- OR BINARY_FLOAT
  P2_ERR         NUMBER, -- OR BINARY_FLOAT
  P3_ERR         NUMBER, -- OR BINARY_FLOAT
  FLAG           NUMBER,
  SEQ_ID	 NUMBER,
  DB_TIMESTAMP   TIMESTAMP DEFAULT SYS_EXTRACT_UTC(SYSTIMESTAMP) NOT NULL
)
PARTITION BY RANGE ("LMR_SUB_IOV_ID")
(PARTITION "LMF_CORR_COEF_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_CORR_COEF_DAT
  ADD CONSTRAINT LMF_CORR_COEF_DAT_PK PRIMARY KEY (LOGIC_ID, LMR_SUB_IOV_ID)
/

ALTER TABLE LMF_CORR_COEF_DAT
  ADD CONSTRAINT LMF_CORR_COEF_DAT_FK1 FOREIGN KEY (LMR_SUB_IOV_ID)
  REFERENCES LMF_LMR_SUB_IOV
/

ALTER TABLE LMF_CORR_COEF_DAT
 ADD CONSTRAINT LMF_CORR_COEF_DAT_FK2 FOREIGN KEY (SEQ_ID)
 REFERENCES LMF_SEQ_DAT
/

/*  RUN_LASERRUN_CONFIG_DAT  */
CREATE TABLE RUN_LASERRUN_CONFIG_DAT
(
  IOV_ID              NUMBER NOT NULL,
  LOGIC_ID            NUMBER NOT NULL,
  LASER_SEQUENCE_TYPE VARCHAR2(20),
  LASER_SEQUENCE_COND VARCHAR2(20)
)
PARTITION BY RANGE ("IOV_ID")
(PARTITION "RUN_LASERRUN_CONFIG_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE RUN_LASERRUN_CONFIG_DAT
  ADD CONSTRAINT RUN_LASERRUN_CONFIG_DAT_PK UNIQUE (IOV_ID,LOGIC_ID)
/

-- BLUE LASER PRIMITIVE TABLES

/*  LMF_LASER_BLUE_PN_PRIM_DAT  */
CREATE TABLE LMF_LASER_BLUE_PN_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  SHAPE_COR_PN      NUMBER, 
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_MEAN NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_RMS  NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_M3   NUMBER, -- or BINARY_FLOAT
  FLAG              NUMBER,
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LASER_BLUE_PN_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_BLUE_PN_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_BLUE_PN_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_BLUE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_BLUE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PN_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_LASER_BLUE_PULSE_DAT  */
CREATE TABLE LMF_LASER_BLUE_PULSE_DAT
(
  LMF_IOV_ID  NUMBER NOT NULL,
  LOGIC_ID    NUMBER NOT NULL,
  FIT_METHOD  NUMBER,
  MTQ_AMPL    NUMBER, -- OR BINARY_FLOAT
  MTQ_TIME    NUMBER, -- OR BINARY_FLOAT
  MTQ_RISE    NUMBER, -- OR BINARY_FLOAT
  MTQ_FWHM    NUMBER, -- OR BINARY_FLOAT
  MTQ_FW20    NUMBER, -- OR BINARY_FLOAT
  MTQ_FW80    NUMBER, -- OR BINARY_FLOAT
  MTQ_SLIDING NUMBER,  -- OR BINARY_FLOAT
  VMIN        NUMBER,
  VMAX        NUMBER,
  CONSTRAINTS LMF_LASER_BLUE_PULSE_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_BLUE_PULSE_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_BLUE_PULSE_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_BLUE_PULSE_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PULSE_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_BLUE_PULSE_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PULSE_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

/*  LMF_TESTPULSE_PN_PRIM_DAT */
CREATE TABLE LMF_TESTPULSE_PN_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  FLAG              NUMBER,
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_TESTPULSE_PN_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_TESTPULSE_PN_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_TESTPULSE_PN_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_TESTPULSE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_TESTPULSE_PN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_TESTPULSE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_TESTPULSE_PN_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_TESTPULSE_PRIM_DAT */
CREATE TABLE LMF_TESTPULSE_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  FLAG              NUMBER,
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_TESTPULSE_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_TESTPULSE_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_TESTPULSE_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_TESTPULSE_PRIM_DAT
  ADD CONSTRAINT LMF_TESTPULSE_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_TESTPULSE_PRIM_DAT
  ADD CONSTRAINT LMF_TESTPULSE_DAT_FK1 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_LASER_BLUE_PRIM_DAT: done  */
CREATE TABLE LMF_LASER_BLUE_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- OR BINARY_FLOAT
  RMS               NUMBER, -- OR BINARY_FLOAT
  M3                NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_MEAN  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_RMS   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_M3    NUMBER, -- OR BINARY_FLOAT
  ALPHA             NUMBER, -- OR BINARY_FLOAT
  BETA              NUMBER, -- OR BINARY_FLOAT
  SHAPE_COR         NUMBER, -- OR BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LASER_BLUE_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_BLUE_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_BLUE_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_BLUE_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PRIM_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_BLUE_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_BLUE_PRIM_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

-- IR LASER PRIMITIVE TABLES

/*  LMF_LASER_IR_PN_PRIM_DAT  */
CREATE TABLE LMF_LASER_IR_PN_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  SHAPE_COR_PN      NUMBER, 
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_MEAN NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_RMS  NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_M3   NUMBER, -- or BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LASER_IR_PN_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_IR_PN_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_IR_PN_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_IR_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_IR_PN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_IR_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_IR_PN_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_LASER_IR_PULSE_DAT  */
CREATE TABLE LMF_LASER_IR_PULSE_DAT
(
  LMF_IOV_ID  NUMBER NOT NULL,
  LOGIC_ID    NUMBER NOT NULL,
  FIT_METHOD  NUMBER,
  MTQ_AMPL    NUMBER, -- OR BINARY_FLOAT
  MTQ_TIME    NUMBER, -- OR BINARY_FLOAT
  MTQ_RISE    NUMBER, -- OR BINARY_FLOAT
  MTQ_FWHM    NUMBER, -- OR BINARY_FLOAT
  MTQ_FW20    NUMBER, -- OR BINARY_FLOAT
  MTQ_FW80    NUMBER, -- OR BINARY_FLOAT
  MTQ_SLIDING NUMBER, -- OR BINARY_FLOAT
  VMIN        NUMBER,
  VMAX        NUMBER,
  CONSTRAINTS LMF_LASER_IR_PULSE_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_IR_PULSE_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_IR_PULSE_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_IR_PULSE_DAT
  ADD CONSTRAINT LMF_LASER_IR_PULSE_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_IR_PULSE_DAT
  ADD CONSTRAINT LMF_LASER_IR_PULSE_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

/*  LMF_LASER_IR_PRIM_DAT  */
CREATE TABLE LMF_LASER_IR_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- OR BINARY_FLOAT
  RMS               NUMBER, -- OR BINARY_FLOAT
  M3                NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_MEAN  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_RMS   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_M3    NUMBER, -- OR BINARY_FLOAT
  ALPHA             NUMBER, -- OR BINARY_FLOAT
  BETA              NUMBER, -- OR BINARY_FLOAT
  SHAPE_COR         NUMBER, -- OR BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LASER_IR_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LASER_IR_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LASER_IR_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LASER_IR_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_IR_PRIM_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LASER_IR_PRIM_DAT
  ADD CONSTRAINT LMF_LASER_IR_PRIM_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

-- BLUE LED PRIMITIVE TABLES

/*  LMF_LED_BLUE_PN_PRIM_DAT  */
CREATE TABLE LMF_LED_BLUE_PN_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_MEAN NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_RMS  NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_M3   NUMBER, -- or BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LED_BLUE_PN_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LED_BLUE_PN_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LED_BLUE_PN_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LED_BLUE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LED_BLUE_PN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LED_BLUE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LED_BLUE_PN_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_LED_BLUE_PRIM_DAT  */
CREATE TABLE LMF_LED_BLUE_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- OR BINARY_FLOAT
  RMS               NUMBER, -- OR BINARY_FLOAT
  M3                NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_MEAN  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_RMS   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_M3    NUMBER, -- OR BINARY_FLOAT
  ALPHA             NUMBER, -- OR BINARY_FLOAT
  BETA              NUMBER, -- OR BINARY_FLOAT
  SHAPE_COR         NUMBER, -- OR BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LED_BLUE_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LED_BLUE_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LED_BLUE_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LED_BLUE_PRIM_DAT
  ADD CONSTRAINT LMF_LED_BLUE_PRIM_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LED_BLUE_PRIM_DAT
  ADD CONSTRAINT LMF_LED_BLUE_PRIM_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

-- ORANGE LED PRIMITIVE TABLES

/*  LMF_LED_ORANGE_PN_PRIM_DAT  */
CREATE TABLE LMF_LED_ORANGE_PN_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- or BINARY_FLOAT
  RMS               NUMBER, -- or BINARY_FLOAT
  M3                NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_MEAN NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_RMS  NUMBER, -- or BINARY_FLOAT
  PNA_OVER_PNB_M3   NUMBER, -- or BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LED_ORANGE_PN_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LED_ORANGE_PN_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LED_ORANGE_PN_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LED_ORANGE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LED_ORANGE_PN_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LED_ORANGE_PN_PRIM_DAT
  ADD CONSTRAINT LMF_LED_ORANGE_PN_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV
/

/*  LMF_LED_ORANGE_PRIM_DAT  */
CREATE TABLE LMF_LED_ORANGE_PRIM_DAT
(
  LMF_IOV_ID        NUMBER NOT NULL,
  LOGIC_ID          NUMBER NOT NULL,
  FLAG              NUMBER,
  MEAN              NUMBER, -- OR BINARY_FLOAT
  RMS               NUMBER, -- OR BINARY_FLOAT
  M3                NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNA_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_MEAN NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_RMS  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PNB_M3   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_MEAN  NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_RMS   NUMBER, -- OR BINARY_FLOAT
  APD_OVER_PN_M3    NUMBER, -- OR BINARY_FLOAT
  ALPHA             NUMBER, -- OR BINARY_FLOAT
  BETA              NUMBER, -- OR BINARY_FLOAT
  SHAPE_COR         NUMBER, -- OR BINARY_FLOAT
  VMIN              NUMBER,
  VMAX              NUMBER,
  CONSTRAINTS LMF_LED_ORANGE_PRIM_DAT_FK1 FOREIGN KEY(VMIN) 
    REFERENCES LMF_PRIM_VERS(VERS),
  CONSTRAINTS LMF_LED_ORANGE_PRIM_DAT_FK2 FOREIGN KEY(VMAX) 
    REFERENCES LMF_PRIM_VERS(VERS)
)
PARTITION BY RANGE ("LMF_IOV_ID")
(PARTITION "LMF_LED_ORANGE_PRIM_DAT_10" VALUES LESS THAN (MAXVALUE))
/

ALTER TABLE LMF_LED_ORANGE_PRIM_DAT
  ADD CONSTRAINT LMF_LED_ORANGE_PRIM_DAT_PK PRIMARY KEY (LMF_IOV_ID,LOGIC_ID,
	VMIN)
/

ALTER TABLE LMF_LED_ORANGE_PRIM_DAT
  ADD CONSTRAINT LMF_LED_ORANGE_PRIM_DAT_FK3 FOREIGN KEY (LMF_IOV_ID)
  REFERENCES LMF_RUN_IOV(LMF_IOV_ID)
/

CREATE INDEX LMF_RUN_STRT_IX ON LMF_RUN_IOV(SUBRUN_START)
/
CREATE INDEX LMF_RUN_END_IX ON LMF_RUN_IOV(SUBRUN_END)
/

CREATE INDEX LMF_SEQ_DAT_IX ON LMF_SEQ_DAT(RUN_IOV_ID)
/

CREATE INDEX LMF_LASER_CONFIG_DAT_IX ON LMF_LASER_CONFIG_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_RUN_DAT_IX ON LMF_RUN_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_TEST_PULSE_CONFIG_DAT_IX ON LMF_TEST_PULSE_CONFIG_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_IOV_START_IX ON LMF_IOV(IOV_START)
/
CREATE INDEX LMF_IOV_STOP_IX ON LMF_IOV(IOV_STOP)
/

CREATE INDEX RUN_LASRRUN_CONFIG_DAT_IX ON RUN_LASERRUN_CONFIG_DAT(IOV_ID)
/

CREATE INDEX LMF_LASER_BLUE_PN_PRIM_DAT_IX ON LMF_LASER_BLUE_PN_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LASER_BLUE_PULSE_DAT_IX ON LMF_LASER_BLUE_PULSE_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LASER_BLUE_PRIM_DAT_IX ON LMF_LASER_BLUE_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LASER_IR_PN_PRIM_DAT_IX ON LMF_LASER_IR_PN_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LASER_IR_PULSE_DAT_IX ON LMF_LASER_IR_PULSE_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LASER_IR_PRIM_DAT_IX ON LMF_LASER_IR_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LED_BLUE_PN_PRIM_DAT_IX ON LMF_LED_BLUE_PN_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LED_BLUE_PRIM_DAT_IX ON LMF_LED_BLUE_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LED_ORANGE_PN_PRIM_DAT_IX ON LMF_LED_ORANGE_PN_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LED_ORANGE_PRIM_DAT_IX ON LMF_LED_ORANGE_PRIM_DAT(LMF_IOV_ID)
/

CREATE INDEX LMF_LMR_SUB_IOV_IX ON LMF_LMR_SUB_IOV(T1)
/

CREATE INDEX LMF_CORR_COEF_DAT_IX ON LMF_CORR_COEF_DAT(LMR_SUB_IOV_ID)
/

CREATE OR REPLACE TRIGGER LMF_CHECK_SEQ_DAT_TG
  BEFORE INSERT	ON LMF_SEQ_DAT
  REFERENCING NEW AS new_seq_dat
  FOR EACH ROW
  DECLARE
  result NUMBER;
  BEGIN
    SELECT COUNT(IOV_ID) INTO result FROM CMS_ECAL_COND.RUN_IOV
        WHERE IOV_ID = :new_seq_dat.RUN_IOV_ID;
    IF result =	0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'RUN.IOV_ID = ' ||
         :new_seq_dat.RUN_IOV_ID || ' does not exists!');
    END IF;
  END;
/

CREATE OR REPLACE TRIGGER LMF_CHECK_LASERCONF_TG
  BEFORE INSERT	ON RUN_LASERRUN_CONFIG_DAT
  REFERENCING NEW AS new_config_dat
  FOR EACH ROW
  DECLARE
  result NUMBER;
  BEGIN
    SELECT COUNT(IOV_ID) INTO result FROM CMS_ECAL_COND.RUN_IOV
        WHERE IOV_ID = :new_config_dat.IOV_ID;
    IF result =	0 THEN
       RAISE_APPLICATION_ERROR(-20000, 'RUN.IOV_ID = ' ||
         :new_config_dat.IOV_ID || ' does not exists!');
    END IF;
  END;
/

/*
CREATE SYNONYM RUN_TYPE_DEF FOR CMS_ECAL_COND.RUN_TYPE_DEF;
CREATE SYNONYM RUN_IOV FOR CMS_ECAL_COND.RUN_IOV;
CREATE SYNONYM VIEWDESCRIPTION FOR CMS_ECAL_COND.VIEWDESCRIPTION;
CREATE SYNONYM CHANNELVIEW FOR CMS_ECAL_COND.CHANNELVIEW;
CREATE SYNONYM LOCATION_DEF FOR CMS_ECAL_COND.LOCATION_DEF;
*/