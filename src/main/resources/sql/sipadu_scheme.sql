--
-- PostgreSQL database dump
--

-- Dumped from database version 9.0.18
-- Dumped by pg_dump version 9.0.18
-- Started on 2015-02-13 15:20:23

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- TOC entry 846 (class 2612 OID 11574)
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: -
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpgsql;


SET search_path = public, pg_catalog;

--
-- TOC entry 227 (class 1255 OID 17068)
-- Dependencies: 5 846
-- Name: delete_hwilda(character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_hwilda(kdprop character varying, kdkab character varying, kdkec character varying, kdpropdel character varying, kdkabdel character varying, kdkecdel character varying, nodel character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	noactive character varying;
	kd_lama	character varying;
	lowern integer;
	highern integer;
	jmllowern integer;
	jmlhighern integer;
	nomin character varying;
	bln character varying;
	thn character varying;
BEGIN

	--create temp table history
	SELECT no_urut INTO noactive
	FROM t_history_wilda
	WHERE kd_prop=kdProp AND kd_kab=kdKab AND kd_kec=kdKec AND is_active ='1';

		IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'temp') THEN DROP TABLE temp;
		END IF;
		CREATE TABLE temp(
			  no_urut char(4),
			  kd_prop varchar(2),
			  kd_kab varchar(2),
			  kd_kec varchar(3),
			  kd_prop_lama varchar(2),
			  kd_kab_lama varchar(2),
			  kd_kec_lama varchar(3),
			  no_urut_lama char(4),
			  nm_wilda varchar(100),
			  nm_wilda_lama varchar(100),
			  bulan char(2),
			  tahun char(4)
			  );

		INSERT INTO temp(no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun)
		SELECT no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun
		FROM t_history_wilda
		WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND is_active='1';

		SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
		FROM temp
		WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND no_urut = noactive;

		SELECT min(no_urut) INTO nomin FROM temp;
		
		WHILE kd_lama IS NOT NULL loop
		
			INSERT INTO temp(no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun)
			SELECT no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun
			FROM t_history_wilda
			WHERE kd_prop||kd_kab||kd_kec||no_urut IN 
				(SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama FROM temp WHERE no_urut = nomin);

			SELECT min(no_urut) INTO nomin FROM temp;

			SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
			FROM temp
			WHERE no_urut = nomin;

		END loop;

-- mark wilda which will be deleted

	UPDATE temp SET no_urut = '0' WHERE no_urut = nodel AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	SELECT bulan INTO bln FROM t_history_wilda WHERE no_urut = nodel AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	SELECT tahun INTO thn FROM t_history_wilda WHERE no_urut = nodel AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	
-- renumbering
	
	SELECT MIN(CAST(no_urut AS integer)) INTO highern FROM temp
	WHERE (CAST(bulan AS integer) > CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) > CAST(thn AS integer);

	SELECT COUNT(*) INTO jmlhighern FROM temp
	WHERE (CAST(bulan AS integer) > CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) > CAST(thn AS integer);

	IF jmlhighern>0 THEN
		SELECT COUNT(*) INTO jmllowern FROM temp
		WHERE (CAST(bulan AS integer) < CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) < CAST(thn AS integer);

		IF jmllowern>0 THEN
	
			SELECT MAX(CAST(no_urut AS integer)) INTO lowern FROM temp
			WHERE (CAST(bulan AS integer) < CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) < CAST(thn AS integer);
		
			UPDATE t_history_wilda SET
				kd_prop_lama = a.kd_prop_lama, 
				kd_kab_lama = a.kd_kab_lama, 
				kd_kec_lama = a.kd_kec_lama, 
				no_urut_lama = a.no_urut_lama,
				nm_wilda_lama = a.nm_wilda_lama
			FROM (SELECT kd_prop_lama, kd_kab_lama, kd_kec_lama, nm_wilda_lama, no_urut_lama FROM temp WHERE no_urut = '0') AS a
			WHERE t_history_wilda.no_urut||t_history_wilda.kd_prop||t_history_wilda.kd_kab||t_history_wilda.kd_kec IN
				(SELECT no_urut||kd_prop||kd_kab||kd_kec FROM temp WHERE no_urut = CAST(highern AS character varying));
		ELSE 
			UPDATE t_history_wilda SET
				kd_prop_lama = null, 
				kd_kab_lama = null, 
				kd_kec_lama = null, 
				no_urut_lama = null,
				nm_wilda_lama = null
			WHERE t_history_wilda.no_urut||t_history_wilda.kd_prop||t_history_wilda.kd_kab||t_history_wilda.kd_kec IN
				(SELECT no_urut||kd_prop||kd_kab||kd_kec FROM temp WHERE no_urut = CAST(highern AS character varying));
		END IF;
			
	END IF;

	DELETE FROM t_history_wilda WHERE no_urut = nodel AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	DELETE FROM m_produsen WHERE kd_produsen = kdpropdel||kdkabdel||kdkecdel||nodel;

	RETURN 1;	
END;
$$;


--
-- TOC entry 228 (class 1255 OID 17069)
-- Dependencies: 5 846
-- Name: delete_hwilda(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION delete_hwilda(kdprop character varying, kdkab character varying, kdkec character varying, kdpropdel character varying, kdkabdel character varying, kdkecdel character varying, nodel integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jml integer;
	i integer;
	x integer;
	y integer;
BEGIN

	--create temp table history
	SELECT no_urut INTO jml
	FROM t_history_wilda
	WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'temp') THEN DROP TABLE temp;
	END IF;
	CREATE TABLE temp(
		  no_urut int,
		  kd_prop varchar(2),
		  kd_kab varchar(2),
		  kd_kec varchar(3),
		  kd_prop_lama varchar(2),
		  kd_kab_lama varchar(2),
		  kd_kec_lama varchar(3),
		  nm_wilda varchar(100),
		  bulan char(2),
		  tahun char(4)
		  );

	INSERT INTO temp(no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, nm_wilda, bulan, tahun)
	SELECT no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, nm_wilda, bulan, tahun
	FROM t_history_wilda
	WHERE kd_prop=kdProp AND kd_kab=kdKab AND kd_kec=kdKec AND is_active='1';

	WHILE jml >= 1 loop
		INSERT INTO temp(no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, nm_wilda, bulan, tahun)
		SELECT no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, nm_wilda, bulan, tahun
		FROM t_history_wilda
		WHERE no_urut = jml-1 AND kd_prop||kd_kab||kd_kec IN 
			(SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama FROM temp WHERE no_urut = jml);
	jml := jml - 1;
	END loop;

-- mark wilda which will be deleted

	UPDATE t_history_wilda SET no_urut = 0 WHERE no_urut = nodel AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	 
-- renumbering
	SELECT MAX(no_urut) INTO y FROM temp WHERE no_urut > nodel;
	x := nodel + 1;

	IF nodel > 1 THEN

		WHILE x <= y loop
		
			UPDATE t_history_wilda SET
				kd_prop_lama = a.kd_prop, 
				kd_kab_lama = a.kd_kab, 
				kd_kec_lama = a.kd_kec, 
				no_urut = x-1
			FROM (SELECT kd_prop, kd_kab, kd_kec, x - 1 FROM temp WHERE no_urut = x-2) AS a
			WHERE t_history_wilda.no_urut||t_history_wilda.kd_prop||t_history_wilda.kd_kab||t_history_wilda.kd_kec IN
				(SELECT no_urut||kd_prop||kd_kab||kd_kec FROM temp WHERE no_urut = x);

			UPDATE temp SET no_urut = x-1
			WHERE no_urut = x;

			x := x + 1;
		END loop;
			
	ELSE
		WHILE x <= y loop
			UPDATE t_history_wilda SET no_urut = x - 1
			WHERE no_urut||kd_prop||kd_kab||kd_kec IN
				(SELECT no_urut||kd_prop||kd_kab||kd_kec FROM temp WHERE no_urut = x);
			x := x + 1;

			UPDATE temp SET no_urut = x-1
			WHERE no_urut = x;

		END loop;

		UPDATE t_history wilda SET kd_prop_lama = null, kd_kab_lama = null, kd_kec_lama = null
		WHERE no_urut||kd_prop||kd_kab||kd_kec IN
			(SELECT no_urut||kd_prop||kd_kab||kd_kec FROM temp WHERE no_urut = 1);

	END IF;

	DELETE FROM t_history_wilda WHERE no_urut = 0 AND kd_prop = kdpropdel AND kd_kab = kdkabdel AND kd_kec = kdkecdel;
	
	RETURN 1;	
END;
$$;


--
-- TOC entry 229 (class 1255 OID 17070)
-- Dependencies: 5 846
-- Name: insert_bukuinduk(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_bukuinduk() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlpub integer;
	i integer;
	j integer;
	id_pub character varying[] = '{}';

BEGIN
-- jumlah
	SELECT array_agg(id_publikasi) INTO id_pub FROM t_publikasi WHERE kd_bahan_pustaka = '111';
	SELECT COUNT(id_publikasi) INTO jmlpub FROM t_publikasi WHERE kd_bahan_pustaka = '111';
	i := 1;
	WHILE i<= jmlpub loop
		SELECT jml_eks INTO jumlah FROM migtemp WHERE id_publikasi = id_pub[i];
		j := 1;
		WHILE j<= jumlah loop
			INSERT INTO t_buku_induk(
			    id, id_publikasi, jumlah_eks, 
			    tgl_terima, tgl_entri, flag_entri, nip, 
			    jenis_publikasi)
			(SELECT j, id_publikasi, jml_eks, 
				    to_date('01-'||substring(id_publikasi,5,2)||'-'||substring(id_publikasi,7,2),'DD-MM-YY'), tgl_entri, '0', nip, 
				    jenis_publikasi
			  FROM migtemp WHERE id_publikasi =id_pub[i]);

			j := j+1;
		end loop;
		i := i+1;
	end loop;


	RETURN;

END;
$$;


--
-- TOC entry 230 (class 1255 OID 17071)
-- Dependencies: 846 5
-- Name: insert_bukuinduk_123(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_bukuinduk_123() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlpub integer;
	i integer;
	j integer;
	id_pub character varying[] = '{}';

BEGIN
-- jumlah
	SELECT array_agg(id_publikasi) INTO id_pub FROM t_publikasi WHERE kd_bahan_pusataka = '121';
	SELECT COUNT(id_publikasi) INTO jmlpub FROM t_publikasi WHERE kd_bahan_pusataka = '121';
	i := 1;
	WHILE i<= jmlpub loop
		SELECT jml_eks INTO jumlah FROM migtemp123 WHERE id_publikasi = id_pub[i];
		j := 1;
		WHILE j<= jumlah loop
			INSERT INTO t_buku_induk(
			    id, id_publikasi, jumlah_eks, 
			    tgl_terima, tgl_entri, flag_entri, nip, 
			    jenis_publikasi)
			(SELECT j, id_publikasi, jml_eks, 
				    to_date('01-'||substring(id_publikasi,5,2)||'-'||substring(id_publikasi,7,2),'DD-MM-YY'), tgl_entri, '0', nip, 
				    jenis_publikasi
			  FROM migtemp123 WHERE id_publikasi =id_pub[i]);

			j := j+1;
		end loop;
		i := i+1;
	end loop;


	RETURN;

END;
$$;


--
-- TOC entry 231 (class 1255 OID 17072)
-- Dependencies: 5 846
-- Name: insert_bukuinduk_dda(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_bukuinduk_dda() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlpub integer;
	i integer;
	j integer;
	id_pub character varying[] = '{}';

BEGIN
-- jumlah
	SELECT array_agg(id_publikasi) INTO id_pub FROM t_publikasi WHERE kd_bahan_pusataka = '121';
	SELECT COUNT(id_publikasi) INTO jmlpub FROM t_publikasi WHERE kd_bahan_pusataka = '121';
	i := 1;
	WHILE i<= jmlpub loop
		SELECT jml_eks INTO jumlah FROM migtempdda WHERE id_publikasi = id_pub[i];
		j := 1;
		WHILE j<= jumlah loop
			INSERT INTO t_buku_induk(
			    id, id_publikasi, jumlah_eks, 
			    tgl_terima, tgl_entri, flag_entri, nip, 
			    jenis_publikasi)
			(SELECT j, id_publikasi, jml_eks, 
				    to_date('01-'||substring(id_publikasi,5,2)||'-'||substring(id_publikasi,7,2),'DD-MM-YY'), tgl_entri, '0', nip, 
				    jenis_publikasi
			  FROM migtempdda WHERE id_publikasi =id_pub[i]);

			j := j+1;
		end loop;
		i := i+1;
	end loop;


	RETURN;

END;
$$;


--
-- TOC entry 232 (class 1255 OID 17073)
-- Dependencies: 846 5
-- Name: insert_hunit(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_hunit(kdunitkerja character varying, kdunitkerjabaru character varying, unitkerja character varying, bln character varying, thn character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jml integer;
	i integer;
	lowern integer;
	no integer;
	highern integer;
	blnactive character varying;
	thnactive character varying;
BEGIN

--check insert is enable
	SELECT bulan INTO blnactive
	FROM t_history_unit_kerja
	WHERE kd_unit_kerja = kdunitkerja AND is_active='1';

	SELECT tahun INTO thnactive
	FROM t_history_unit_kerja
	WHERE kd_unit_kerja = kdunitkerja AND is_active='1';

	IF (CAST(thnactive AS integer)=CAST(thn AS integer) AND CAST(blnactive AS integer)<CAST(bln AS integer)) OR CAST(thnactive AS integer)<CAST(thn AS integer) THEN
	RETURN 0;

	ELSE
--create temp table history
		SELECT no_urut INTO jml
		FROM t_history_unit_kerja
		WHERE kd_unit_kerja=kdunitkerja;

		IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'temp_history_unit_kerja') THEN DROP TABLE temp_history_unit_kerja;
		END IF;
		CREATE TABLE temp_history_unit_kerja(
			  no_urut int,
			  kd_unit_kerja varchar(255),
			  kd_unit_lama varchar(255),
			  unit_kerja varchar(255),
			  bulan char(2),
			  tahun char(4)
			  );

		INSERT INTO temp_history_unit_kerja(no_urut, kd_unit_kerja, kd_unit_lama, unit_kerja, bulan, tahun)
		SELECT no_urut, kd_unit_kerja, kd_unit_lama, unit_kerja, bulan, tahun
		FROM t_history_unit_kerja
		WHERE kd_unit_kerja=kdunitkerja AND is_active='1';

		WHILE jml >= 1 loop
			INSERT INTO temp_history_unit_kerja(no_urut, kd_unit_kerja, kd_unit_lama, unit_kerja, bulan, tahun)
			SELECT no_urut, kd_unit_kerja, kd_unit_lama, unit_kerja, bulan, tahun
			FROM t_history_unit_kerja
			WHERE no_urut = jml-1 AND kd_unit_kerja IN 
				(SELECT kd_unit_lama FROM temp_history_unit_kerja WHERE no_urut = jml);
		jml := jml - 1;
		END loop;

	-- compare bulan & tahun wilda
		SELECT MAX(no_urut) INTO lowern FROM temp
		WHERE (CAST(bulan AS integer) < CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) < CAST(thn AS integer);

		IF lowern is not null THEN
			no := lowern + 1;
		ELSE 
			no := 1;
		END IF;

		SELECT MAX(no_urut) INTO highern FROM temp
		WHERE no_urut >= no;
		
		WHILE highern >= no loop
			UPDATE t_history_unit_kerja SET no_urut = no_urut+1
			WHERE no_urut = highern AND no_urut||kd_unit_kerja IN
				(SELECT no_urut||kd_unit_kerja FROM temp_history_unit_kerja WHERE no_urut = highern);
			highern := highern -1;
		END loop;

		IF no > 1 THEN
			INSERT INTO t_history_unit_kerja(kd_unit_kerja, no_urut, unit_kerja, kd_unit_lama, unit_lama, bulan, tahun, is_active)
			SELECT kdunitkerjabaru, no, UPPER(unitkerja), kd_unit_kerja, unit_kerja, bln, thn, '0'
			FROM temp_history_unit_kerja
			WHERE no_urut = no-1;
		ELSE
			INSERT INTO t_history_unit_kerja(kd_unit_kerja, no_urut, unit_kerja, bulan, tahun, is_active)
			VALUES(kdunitkerjabaru, no, UPPER(unitkerja), bln, thn, '0');
		END IF;

		UPDATE t_history_unit_kerja SET kd_unit_lama = kdunitkerjabaru, unit_lama = UPPER(unitkerja)
			WHERE no_urut = no + 1 AND no_urut||kd_unit_kerja IN
				(SELECT (no_urut + 1)||kd_unit_kerja FROM temp_history_unit_kerja WHERE no_urut = no);

		RETURN 1;
	END IF;
	
END;
$$;


--
-- TOC entry 233 (class 1255 OID 17074)
-- Dependencies: 846 5
-- Name: insert_hwilda(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_hwilda(kdprop character varying, kdkab character varying, kdkec character varying, kdpropbaru character varying, kdkabbaru character varying, kdkecbaru character varying, nmwilda character varying, bln character varying, thn character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	lowern integer;
	highern integer;
	blnactive character varying;
	thnactive character varying;
	selisihthn integer;
	selisihbln integer;
	nobaruthn integer;
	charbaruthn character varying;
	noactive character varying;
	kd_lama	character varying;
	blnsebelum character varying;
	thnsebelum character varying;
	jml integer;
	eksis integer;
	nomin character varying;
BEGIN

--check insert is enable
	SELECT bulan INTO blnactive
	FROM t_history_wilda
	WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND is_active='1';

	SELECT tahun INTO thnactive
	FROM t_history_wilda
	WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND is_active='1';

	IF (CAST(thnactive AS integer)=CAST(thn AS integer) AND CAST(blnactive AS integer)<=CAST(bln AS integer)) OR CAST(thnactive AS integer)<CAST(thn AS integer) THEN
	RETURN 0;

	ELSE
--create temp table history
		
		SELECT no_urut INTO noactive
		FROM t_history_wilda
		WHERE kd_prop=kdProp AND kd_kab=kdKab AND kd_kec=kdKec AND is_active ='1';

		IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'temp') THEN DROP TABLE temp;
		END IF;
		CREATE TABLE temp(
			  no_urut char(4),
			  kd_prop varchar(2),
			  kd_kab varchar(2),
			  kd_kec varchar(3),
			  kd_prop_lama varchar(2),
			  kd_kab_lama varchar(2),
			  kd_kec_lama varchar(3),
			  no_urut_lama char(4),
			  nm_wilda varchar(100),
			  bulan char(2),
			  tahun char(4)
			  );

		INSERT INTO temp(no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun)
		SELECT no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun
		FROM t_history_wilda
		WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND is_active='1';

		SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
		FROM temp
		WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND no_urut = noactive;

		SELECT min(no_urut) INTO nomin FROM temp;
		
		WHILE kd_lama IS NOT NULL loop
		
			INSERT INTO temp(no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun)
			SELECT no_urut,kd_prop,kd_kab,kd_kec,kd_prop_lama,kd_kab_lama,kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun
			FROM t_history_wilda
			WHERE kd_prop||kd_kab||kd_kec||no_urut IN 
				(SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama FROM temp WHERE no_urut = nomin);

			SELECT min(no_urut) INTO nomin FROM temp;

			SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
			FROM temp
			WHERE no_urut = nomin;

		END loop;

	-- compare bulan & tahun wilda
		selisihthn := CAST(thnactive AS integer) - CAST(thn AS integer);
		nobaruthn := CAST(SUBSTRING(noactive,1,2) AS integer)-selisihthn;
		charbaruthn := CAST(nobaruthn AS character varying);

		SELECT MIN(CAST(no_urut AS integer)) INTO highern FROM temp
		WHERE (CAST(bulan AS integer) > CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) > CAST(thn AS integer);

	-- update kode lama & insert history
			
		SELECT COUNT(*) INTO jml FROM temp
		WHERE (CAST(bulan AS integer) < CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) < CAST(thn AS integer);

		IF jml>0 THEN
			SELECT MAX(CAST(no_urut AS integer)) INTO lowern FROM temp
			WHERE (CAST(bulan AS integer) < CAST(bln AS integer) AND CAST(tahun AS integer) = CAST(thn AS integer)) OR CAST(tahun AS integer) < CAST(thn AS integer);

			UPDATE t_history_wilda 
			SET kd_prop_lama=kdpropbaru, kd_kab_lama=kdkabbaru, kd_kec_lama=kdkecbaru, no_urut_lama=charbaruthn||bln, nm_wilda_lama=UPPER(nmwilda)
			WHERE kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama IN (
				SELECT kd_prop||kd_kab||kd_kec||no_urut FROM temp
				WHERE no_urut = CAST(lowern AS character varying));

			INSERT INTO t_history_wilda(kd_prop, kd_kab, kd_kec, no_urut, nm_wilda, kd_prop_lama, kd_kab_lama, 
				kd_kec_lama, no_urut_lama, nm_wilda_lama, bulan, tahun, is_active)
				SELECT kdpropbaru, kdkabbaru, kdkecbaru, charbaruthn||bln, UPPER(nmwilda), kd_prop, kd_kab, kd_kec, no_urut, nm_wilda, bln, thn, '0'
				FROM temp
				WHERE no_urut = CAST(lowern AS character varying);

			--insert m_produsen
			INSERT INTO m_produsen(kd_produsen, kd_table) 
				SELECT kdpropbaru||kdkabbaru||kdkecbaru||charbaruthn||bln, '1'
				FROM temp
				WHERE no_urut = CAST(lowern AS character varying);

		ELSE
			UPDATE t_history_wilda 
			SET kd_prop_lama=kdpropbaru, kd_kab_lama=kdkabbaru, kd_kec_lama=kdkecbaru, no_urut_lama=charbaruthn||bln, nm_wilda_lama=UPPER(nmwilda)
			WHERE kd_prop||kd_kab||kd_kec||no_urut IN (
				SELECT kd_prop||kd_kab||kd_kec||no_urut FROM temp
				WHERE no_urut = CAST(highern AS character varying));

			INSERT INTO t_history_wilda(kd_prop, kd_kab, kd_kec, no_urut, nm_wilda, bulan, tahun, is_active)
			VALUES(kdpropbaru, kdkabbaru, kdkecbaru, charbaruthn||bln, UPPER(nmwilda), bln, thn, '0');


			--insert m_produsen
			INSERT INTO m_produsen(kd_produsen, kd_table) 
			VALUES(kdpropbaru||kdkabbaru||kdkecbaru||charbaruthn||bln, '1');
		END IF;
		RETURN 1;
	END IF;

END;
$$;


--
-- TOC entry 234 (class 1255 OID 17075)
-- Dependencies: 846 5
-- Name: insert_lokasi(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_lokasi() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jmleks integer;
	jumlah integer;
	jmlpub integer;
	i integer;
	j integer;
	k integer;
	selisih integer;
	nourut integer[] = '{}';
	id_pub character varying[] = '{}';

BEGIN
-- jumlah eksemplar
	SELECT array_agg(id_publikasi) INTO id_pub FROM t_publikasi WHERE kd_bahan_pustaka = '111';
	SELECT COUNT(id_publikasi) INTO jmlpub FROM t_publikasi WHERE kd_bahan_pustaka = '111';
	i := 1;
	WHILE i<= jmlpub loop
		SELECT count(nip) INTO jumlah from lokasi WHERE nip IN (SELECT nip_lama FROM t_publikasi WHERE id_publikasi = id_pub[i]);
		SELECT array_agg(sk) INTO nourut from lokasi WHERE nip IN (SELECT nip_lama FROM t_publikasi WHERE id_publikasi = id_pub[i]);
		-- SELECT jml_eks INTO jmleks FROM t_publikasi WHERE id_publikasi = id_pub[i];
		-- selisih := jmleks - jumlah;
		j := 1;
		k := 1;
		WHILE j<= jumlah loop
			SELECT CAST(eksemplar AS integer) INTO jmleks FROM lokasi WHERE nip IN (SELECT nip_lama FROM t_publikasi WHERE id_publikasi = id_pub[i]) AND sk = nourut[j];
			WHILE k <= jmleks loop
				INSERT INTO t_pub_lokasi(no_eks, id_publikasi, kd_ruang, rak, lorong, baris,  kondisi, flag_cetak_label, flag_hapus_eksemplar, flag_pinjam, flag_aktif)
					(select k, c.id_publikasi, CAST(trim(b.ruang) AS integer), trim(b.rak), trim(b.lorong), trim(b.baris), case when c.thn_terima >= '2000' then '1' else '2' end kondisi, '1', '0', '0','1'
					from t_publikasi c 
					left join lokasi b on c.nip_lama = b.nip
					where c.id_publikasi = id_pub[i] AND b.sk = nourut[j]);
				k := k+1;
			end loop;
			j := j+1;
		end loop;
		i := i+1;
	end loop;


	RETURN;

END;
$$;


--
-- TOC entry 235 (class 1255 OID 17076)
-- Dependencies: 5 846
-- Name: insert_mwilda(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_mwilda(kdpropbaru character varying, kdkabbaru character varying, kdkecbaru character varying, nmwilda character varying, kdprophis character varying, kdkabhis character varying, kdkechis character varying, bln character varying, thn character varying, kdibukota character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	i integer;
	x integer;
	y integer;
	z integer;
	thnnew integer;
	nonew character varying;
	nohis character varying;
	thnhis character varying;
BEGIN

	--insert into m_prop or m_kab or m_kec
	
	    IF kdkabbaru = '00' AND kdkecbaru = '000' THEN
		SELECT COUNT(*) INTO x FROM m_prop WHERE kd_prop = kdpropbaru AND upper(prop)=upper(nmwilda);
		IF x = 0 THEN 
			INSERT INTO m_prop(kd_prop, prop, is_ibukota)
			VALUES(kdpropbaru, upper(nmwilda), '0');
		END IF;
		UPDATE m_kab SET is_ibukota = '1' WHERE kd_prop = kdpropbaru AND kd_kab = kdibukota ;
            
            ELSEIF kdkabbaru != '00' AND kdkecbaru = '000' THEN
		SELECT COUNT(*) INTO y FROM m_kab WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND upper(kab)=upper(nmwilda);
		IF y = 0 THEN 
			INSERT INTO m_kab(kd_prop, kd_kab, kab, is_ibukota)
			VALUES(kdpropbaru, kdkabbaru, upper(nmwilda), '0');
		END IF;
		UPDATE m_kec SET is_ibukota = '1' WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdibukota;
            
            ELSEIF kdkabbaru != '00' AND kdkecbaru != '000' THEN
		SELECT COUNT(*) INTO z FROM m_kec WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND upper(kec)=upper(nmwilda);
		IF z = 0 THEN 
			INSERT INTO m_kec(kd_prop, kd_kab, kd_kec, kec, is_ibukota)
			VALUES(kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), '0');
		END IF;
            END IF;

            --insert into t_history_wilda
		SELECT COUNT(*) INTO i FROM t_history_wilda WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND upper(nm_wilda)=upper(nmwilda);
		IF i = 1 THEN 
			IF kdprophis != '' OR kdkabhis !='' OR kdkechis !='' THEN
				SELECT no_urut INTO nohis FROM t_history_wilda 
				WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

				SELECT tahun INTO thnhis FROM t_history_wilda 
				WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

				thnnew := CAST(thn AS integer) - CAST(thnhis AS integer) + CAST(SUBSTRING(nohis,1,2) AS integer);
				nonew := CAST(thnnew AS character varying)||bln;
				
				
				UPDATE t_history_wilda b SET no_urut_lama = a.no_urut, 
						kd_prop_lama = a.kd_prop, 
						kd_kab_lama = a.kd_kab, 
						kd_kec_lama = a.kd_kec, 
						nm_wilda_lama = upper(a.nm_wilda), 
						bulan = bln, 
						tahun = thn, 
						is_active='1'
						FROM (SELECT no_urut, kd_prop, kd_kab, kd_kec, nm_wilda, bln, thn, '1' 
							FROM t_history_wilda WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis AND is_active='1') AS a
						WHERE b.kd_prop = kdpropbaru AND b.kd_kab = kdkabbaru AND b.kd_kec = kdkecbaru AND upper(b.nm_wilda)=upper(nmwilda);

			ELSE
				thnnew := CAST(thn AS integer)-1945+1;
				nonew := CAST(thnnew AS character varying)||bln;

				UPDATE t_history_wilda SET no_urut = nonew, bulan = bln, tahun = thn, is_active = '1'
				WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND upper(nm_wilda)=upper(nmwilda);

			END IF;
		ELSE
			IF kdprophis != '' OR kdkabhis !='' OR kdkechis !='' THEN
			SELECT no_urut INTO nohis FROM t_history_wilda 
			WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

			SELECT tahun INTO thnhis FROM t_history_wilda 
			WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

			thnnew := CAST(thn AS integer) - CAST(thnhis AS integer) + CAST(SUBSTRING(nohis,1,2) AS integer);
			nonew := CAST(thnnew AS character varying)||bln;
			
				INSERT INTO  t_history_wilda(kd_prop, kd_kab, kd_kec, nm_wilda, no_urut, no_urut_lama, kd_prop_lama, kd_kab_lama, kd_kec_lama, nm_wilda_lama, bulan, tahun, is_active)
				SELECT kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), nonew, no_urut, kd_prop, kd_kab, kd_kec, nm_wilda, bln, thn, '1'
				FROM t_history_wilda WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis AND is_active='1';
				-- UPDATE t_history_wilda SET is_active='0' WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis;

			ELSE
			thnnew := CAST(thn AS integer)-1945+1;
			nonew := CAST(thnnew AS character varying)||bln;

				INSERT INTO  t_history_wilda(kd_prop, kd_kab, kd_kec, nm_wilda, no_urut, bulan, tahun, is_active)
				VALUES(kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), nonew, bln, thn, '1');
			END IF;
                INSERT INTO m_produsen(kd_produsen, kd_table) 
                SELECT kd_prop||kd_kab||kd_kec||no_urut, kd_table
                FROM t_history_wilda, m_table_prod
                WHERE kd_prop||kd_kab||kd_kec =kdpropbaru||kdkabbaru||kdkecbaru AND is_active = '1' AND jns_produsen='t_history_wilda';

	    END IF;
	    
	    

	RETURN i; 
END;
$$;


--
-- TOC entry 236 (class 1255 OID 17077)
-- Dependencies: 5 846
-- Name: insert_mwilda(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_mwilda(kdpropbaru character varying, kdkabbaru character varying, kdkecbaru character varying, nmwilda character varying, kdprophis character varying, kdkabhis character varying, kdkechis character varying, bln character varying, thn character varying, kdibukota character varying, nmwildalama character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	i integer;
	x integer;
	y integer;
	z integer;
	thnnew integer;
	nonew character varying;
	nohis character varying;
	thnhis character varying;
BEGIN

	--insert into m_prop or m_kab or m_kec
	
	    IF kdkabbaru = '00' AND kdkecbaru = '000' THEN
		SELECT COUNT(*) INTO x FROM m_prop WHERE kd_prop = kdpropbaru AND upper(prop)=upper(nmwilda);
		IF x = 0 THEN 
			INSERT INTO m_prop(kd_prop, prop, is_ibukota)
			VALUES(kdpropbaru, upper(nmwilda), '0');
		END IF;
		UPDATE m_kab SET is_ibukota = '1' WHERE kd_prop = kdpropbaru AND kd_kab = kdibukota ;
            
            ELSEIF kdkabbaru != '00' AND kdkecbaru = '000' THEN
		SELECT COUNT(*) INTO y FROM m_kab WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND upper(kab)=upper(nmwilda);
		IF y = 0 THEN 
			INSERT INTO m_kab(kd_prop, kd_kab, kab, is_ibukota)
			VALUES(kdpropbaru, kdkabbaru, upper(nmwilda), '0');
		END IF;
		UPDATE m_kec SET is_ibukota = '1' WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdibukota;
            
            ELSEIF kdkabbaru != '00' AND kdkecbaru != '000' THEN
		SELECT COUNT(*) INTO z FROM m_kec WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND upper(kec)=upper(nmwilda);
		IF z = 0 THEN 
			INSERT INTO m_kec(kd_prop, kd_kab, kd_kec, kec, is_ibukota)
			VALUES(kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), '0');
		END IF;
            END IF;

            --insert into t_history_wilda
		thnnew := CAST(thn AS integer)-1945+1;
		nonew := CAST(thnnew AS character varying)||bln;

		SELECT COUNT(*) INTO i FROM t_history_wilda WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND no_urut = nonew;
		IF i = 1 THEN 
			IF kdprophis != '' OR kdkabhis !='' OR kdkechis !='' THEN
				SELECT no_urut INTO nohis FROM t_history_wilda 
				WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

				SELECT tahun INTO thnhis FROM t_history_wilda 
				WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

				-- thnnew := CAST(thn AS integer) - CAST(thnhis AS integer) + CAST(SUBSTRING(nohis,1,2) AS integer);
				-- nonew := CAST(thnnew AS character varying)||bln;
				
				
				UPDATE t_history_wilda b SET no_urut_lama = a.no_urut, 
						kd_prop_lama = a.kd_prop, 
						kd_kab_lama = a.kd_kab, 
						kd_kec_lama = a.kd_kec, 
						nm_wilda_lama = upper(a.nm_wilda), 
						nm_wilda = upper(nmwilda),
						bulan = bln, 
						tahun = thn, 
						is_active='1'
						FROM (SELECT no_urut, kd_prop, kd_kab, kd_kec, nm_wilda, bln, thn, '1' 
							FROM t_history_wilda WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis AND is_active='1') AS a
						WHERE b.kd_prop = kdpropbaru AND b.kd_kab = kdkabbaru AND b.kd_kec = kdkecbaru AND upper(b.nm_wilda)=upper(nmwildalama);

			ELSE

				UPDATE t_history_wilda SET no_urut = nonew, nm_wilda = upper(nmwilda), bulan = bln, tahun = thn, is_active = '1'
				WHERE kd_prop = kdpropbaru AND kd_kab = kdkabbaru AND kd_kec = kdkecbaru AND no_urut = nonew;

			END IF;
		ELSE
			IF kdprophis != '' OR kdkabhis !='' OR kdkechis !='' THEN
			SELECT no_urut INTO nohis FROM t_history_wilda 
			WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

			SELECT tahun INTO thnhis FROM t_history_wilda 
			WHERE kd_prop=kdprophis AND kd_kab=kdkabhis AND kd_kec=kdkechis AND is_active='1';

			thnnew := CAST(thn AS integer) - CAST(thnhis AS integer) + CAST(SUBSTRING(nohis,1,2) AS integer);
			nonew := CAST(thnnew AS character varying)||bln;
			
				INSERT INTO  t_history_wilda(kd_prop, kd_kab, kd_kec, nm_wilda, no_urut, no_urut_lama, kd_prop_lama, kd_kab_lama, kd_kec_lama, nm_wilda_lama, bulan, tahun, is_active)
				SELECT kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), nonew, no_urut, kd_prop, kd_kab, kd_kec, nm_wilda, bln, thn, '1'
				FROM t_history_wilda WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis AND is_active='1';
				-- UPDATE t_history_wilda SET is_active='0' WHERE kd_prop = kdprophis AND kd_kab = kdkabhis AND kd_kec = kdkechis;

			ELSE
			thnnew := CAST(thn AS integer)-1945+1;
			nonew := CAST(thnnew AS character varying)||bln;

				INSERT INTO  t_history_wilda(kd_prop, kd_kab, kd_kec, nm_wilda, no_urut, bulan, tahun, is_active)
				VALUES(kdpropbaru, kdkabbaru, kdkecbaru, upper(nmwilda), nonew, bln, thn, '1');
			END IF;
                INSERT INTO m_produsen(kd_produsen, kd_table) 
                SELECT kd_prop||kd_kab||kd_kec||no_urut, kd_table
                FROM t_history_wilda, m_table_prod
                WHERE kd_prop||kd_kab||kd_kec =kdpropbaru||kdkabbaru||kdkecbaru AND is_active = '1' AND jns_produsen='t_history_wilda';

	    END IF;
	    
	    

	RETURN i; 
END;
$$;


--
-- TOC entry 237 (class 1255 OID 17078)
-- Dependencies: 5 846
-- Name: insert_profile(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_profile(idcard character varying, idtype character varying, nama character varying, almt character varying, jk character varying, umur character varying, pend character varying, pkrj character varying, wn character varying, layanan character varying, dt_nas character varying, dt_reg character varying, dl character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	intmax integer;
	chrid character varying;
	intid integer;
	chrnow character varying;
	x integer;
	y integer;
	i integer;
	chrbtid character varying;
	intbtid integer;
	intbtmax integer;
BEGIN

	--select max id profile
	SELECT CAST(MAX(SUBSTRING(profile_id,9,3)) AS integer) INTO intmax FROM profile
	WHERE SUBSTRING(profile_id,1,8)= replace(CAST(current_date AS character varying),'-','');

	IF intmax > 0 THEN
		intid := intmax + 1;
		SELECT CAST(intid AS character varying) INTO chrid;
		IF length(chrid) = 1 THEN 
			chrid := '00'||chrid;
		ELSEIF length(chrid) = 2 
			THEN chrid := '0'||chrid;
		END IF;
	ELSE
		chrid := '001';
	END IF;

	SELECT replace(CAST(current_date AS character varying),'-','') INTO chrnow;
	
	--insert into profile

	INSERT INTO profile(
            profile_id, profile_idcard, profile_idtype, profile_nama, profile_almt, 
            profile_jk, profile_umur, profile_pend, profile_pkrj, profile_wn)
        VALUES (chrnow||chrid, idcard, idtype, nama, almt, 
            jk, umur, pend, pkrj, wn);

--bukutamu
	--select max id bukutamu
	SELECT CAST(MAX(bukutamu_id) AS integer) INTO intbtmax FROM bukutamu
	WHERE bukutamu_tgl = current_date;

	IF intbtmax > 0 THEN
		intbtid := intbtmax + 1;
		SELECT CAST(intbtid AS character varying) INTO chrbtid;
		IF length(chrbtid) = 1 THEN 
			chrbtid := '00'||chrbtid;
		ELSEIF length(chrbtid) = 2 
			THEN chrbtid := '0'||chrbtid;
		END IF;
	ELSE
		chrbtid := '001';
	END IF;

	--insert into bukutamu
	INSERT INTO bukutamu(
            bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
            bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl)
        VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, chrnow||chrid,
            current_date, layanan, dt_nas, dt_reg, dl);
	
	SELECT COUNT(*) INTO x FROM profile WHERE profile_id = chrnow||chrid;   
	SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = chrnow||chrid;   
	i:=x+y;
	
	RETURN i; 
END;
$$;


--
-- TOC entry 238 (class 1255 OID 17079)
-- Dependencies: 5 846
-- Name: insert_profile(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_profile(idcard character varying, idtype character varying, nama character varying, almt character varying, jk character varying, umur character varying, pend character varying, pkrj character varying, wn character varying, layanan character varying, dt_nas character varying, dt_reg character varying, dl character varying, telp character varying, email character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	intmax integer;
	chrid character varying;
	intid integer;
	chrnow character varying;
	x integer;
	y integer;
	i integer;
	chrbtid character varying;
	intbtid integer;
	intbtmax integer;
	jml integer;
	profileid character varying;
BEGIN

	--bukutamu
	--select max id bukutamu
	SELECT CAST(MAX(bukutamu_id) AS integer) INTO intbtmax FROM bukutamu
	WHERE bukutamu_tgl = current_date;

	IF intbtmax > 0 THEN
		intbtid := intbtmax + 1;
		SELECT CAST(intbtid AS character varying) INTO chrbtid;
		IF length(chrbtid) = 1 THEN 
			chrbtid := '00'||chrbtid;
		ELSEIF length(chrbtid) = 2 
			THEN chrbtid := '0'||chrbtid;
		END IF;
	ELSE
		chrbtid := '001';
	END IF;

	-- cek if id exist
	SELECT count(*) INTO jml FROM profile 		
	WHERE profile_idcard = idcard AND profile_idtype = idtype;

	IF jml = 0 THEN

		--select max id profile
		SELECT CAST(MAX(SUBSTRING(profile_id,9,3)) AS integer) INTO intmax FROM profile
		WHERE SUBSTRING(profile_id,1,8)= replace(CAST(current_date AS character varying),'-','');

		IF intmax > 0 THEN
			intid := intmax + 1;
			SELECT CAST(intid AS character varying) INTO chrid;
			IF length(chrid) = 1 THEN 
				chrid := '00'||chrid;
			ELSEIF length(chrid) = 2 
				THEN chrid := '0'||chrid;
			END IF;
		ELSE
			chrid := '001';
		END IF;

		SELECT replace(CAST(current_date AS character varying),'-','') INTO chrnow;
		
		--insert into profile

		INSERT INTO profile(
		    profile_id, profile_idcard, profile_idtype, profile_nama, profile_almt, 
		    profile_jk, profile_umur, profile_pend, profile_pkrj, profile_wn, profile_telp, profile_email)
		VALUES (chrnow||chrid, idcard, idtype, nama, almt, 
		    jk, umur, pend, pkrj, wn, telp, email);


		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, chrnow||chrid,
		    current_date, layanan, dt_nas, dt_reg, dl);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = chrnow||chrid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = chrnow||chrid; 

	ELSE
		SELECT replace(CAST(current_date AS character varying),'-','') INTO chrnow;

		SELECT profile_id INTO profileid FROM profile 		
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

  		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, profileid,
		    current_date, layanan, dt_nas, dt_reg, dl);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = profileid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = profileid;  

	END IF; 

	i:=x+y;
	
	RETURN i; 
END;
$$;


--
-- TOC entry 239 (class 1255 OID 17080)
-- Dependencies: 5 846
-- Name: insert_profile(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_profile(idcard character varying, idtype character varying, nama character varying, almt character varying, jk character varying, umur character varying, pend character varying, pkrj character varying, wn character varying, layanan character varying, dt_nas character varying, dt_reg character varying, dl character varying, telp character varying, email character varying, groupid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	intmax integer;
	chrid character varying;
	intid integer;
	chrnow character varying;
	x integer;
	y integer;
	i integer;
	chrbtid character varying;
	intbtid integer;
	intbtmax integer;
	jml integer;
	profileid character varying;
	tanggalkunjungan date;
BEGIN
	SELECT tgl_kunjungan INTO tanggalkunjungan FROM profile_group WHERE group_id = groupid;
	--bukutamu
		--select max id bukutamu
		SELECT CAST(MAX(bukutamu_id) AS integer) INTO intbtmax FROM bukutamu
		WHERE bukutamu_tgl IN (SELECT tgl_kunjungan FROM profile_group WHERE group_id = groupid);

		IF intbtmax > 0 THEN
			intbtid := intbtmax + 1;
			SELECT CAST(intbtid AS character varying) INTO chrbtid;
			IF length(chrbtid) = 1 THEN 
				chrbtid := '00'||chrbtid;
			ELSEIF length(chrbtid) = 2 
				THEN chrbtid := '0'||chrbtid;
			END IF;
		ELSE
			chrbtid := '001';
		END IF;

	-- cek if id exist
	SELECT count(*) INTO jml FROM profile 		
	WHERE profile_idcard = idcard AND profile_idtype = idtype;

	IF jml = 0 THEN

		SELECT replace(CAST(tgl_kunjungan AS character varying),'-','')  INTO chrnow FROM profile_group WHERE group_id = groupid;

		--select max id profile
		SELECT CAST(MAX(SUBSTRING(profile_id,9,3)) AS integer) INTO intmax FROM profile
		WHERE SUBSTRING(profile_id,1,8)= chrnow;

		IF intmax > 0 THEN
			intid := intmax + 1;
			SELECT CAST(intid AS character varying) INTO chrid;
			IF length(chrid) = 1 THEN 
				chrid := '00'||chrid;
			ELSEIF length(chrid) = 2 
				THEN chrid := '0'||chrid;
			END IF;
		ELSE
			chrid := '001';
		END IF;

		
		--insert into profile

		INSERT INTO profile(
		    profile_id, profile_idcard, profile_idtype, profile_nama, profile_almt, 
		    profile_jk, profile_umur, profile_pend, profile_pkrj, profile_wn, profile_telp, profile_email)
		VALUES (chrnow||chrid, idcard, idtype, nama, almt, 
		    jk, umur, pend, pkrj, wn, telp, email);


		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_group)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, chrnow||chrid,
		    tanggalkunjungan, layanan, dt_nas, dt_reg, dl, groupid);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = chrnow||chrid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = chrnow||chrid;  

	ELSE
		SELECT replace(CAST(tgl_kunjungan AS character varying),'-','')  INTO chrnow FROM profile_group WHERE group_id = groupid;

		SELECT profile_id INTO profileid FROM profile 		
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

		-- update profile
		UPDATE profile SET group_id = groupid 
		WHERE profile_idcard = idcard AND profile_idtype = idtype;
		
		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_group)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, profileid,
		    tanggalkunjungan, layanan, dt_nas, dt_reg, dl, groupid);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = profileid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = profileid;  

	END IF; 
	i:=x+y;
	
	RETURN i; 
END;
$$;


--
-- TOC entry 240 (class 1255 OID 17081)
-- Dependencies: 846 5
-- Name: insert_profile_group(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_profile_group(idcard character varying, idtype character varying, nama character varying, almt character varying, jk character varying, umur character varying, pend character varying, pkrj character varying, wn character varying, layanan character varying, dt_nas character varying, dt_reg character varying, dl character varying, telp character varying, email character varying, groupid integer, pc character varying, los character varying, wktb character varying, o character varying, locker integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	intmax integer;
	chrid character varying;
	intid integer;
	chrnow character varying;
	x integer;
	y integer;
	i integer;
	chrbtid character varying;
	intbtid integer;
	intbtmax integer;
	jml integer;
	profileid character varying;
	tanggalkunjungan date;
	n integer;
	bid integer;
	nc character varying;
	--nolocker character varying[] = '{}';
	no_lock character varying;

	a record;
	
BEGIN
	SELECT tgl_kunjungan INTO tanggalkunjungan FROM profile_group WHERE group_id = groupid;
	
	IF locker > 0 THEN	
		n := 1;
		no_lock := '0';	
		--for(n = 1;n <= 59; n++)
		LOOP
			SELECT CAST(n AS character varying) INTO nc;
			--bid := 0;
			SELECT COUNT(*) INTO bid FROM bukutamu WHERE (bukutamu_nolock) = nc AND bukutamu_wktb = '00:00:00';
			IF bid = 0 THEN		 
				no_lock := nc;			
				n := 60;
			ELSE
				n := n+1;
			END IF;
			
			EXIT WHEN n >= locker;
		END LOOP;
	ELSE
		no_lock := '-';
	END IF;
	
	--select max id bukutamu
	SELECT CAST(MAX(bukutamu_id) AS integer) INTO intbtmax FROM bukutamu
	WHERE bukutamu_tgl IN (SELECT tgl_kunjungan FROM profile_group WHERE group_id = groupid);

	IF intbtmax > 0 THEN
		intbtid := intbtmax + 1;
		SELECT CAST(intbtid AS character varying) INTO chrbtid;
		IF length(chrbtid) = 1 THEN 
			chrbtid := '00'||chrbtid;
		ELSEIF length(chrbtid) = 2 
			THEN chrbtid := '0'||chrbtid;
		END IF;
	ELSE
		chrbtid := '001';
	END IF;

	-- cek if id exist
	SELECT count(*) INTO jml FROM profile 		
	WHERE profile_idcard = idcard AND profile_idtype = idtype;

	IF jml = 0 THEN

		SELECT replace(CAST(tgl_kunjungan AS character varying),'-','')  INTO chrnow FROM profile_group WHERE group_id = groupid;

		--select max id profile
		SELECT CAST(MAX(SUBSTRING(profile_id,9,3)) AS integer) INTO intmax FROM profile
		WHERE SUBSTRING(profile_id,1,8)= chrnow;

		IF intmax > 0 THEN
			intid := intmax + 1;
			SELECT CAST(intid AS character varying) INTO chrid;
			IF length(chrid) = 1 THEN 
				chrid := '00'||chrid;
			ELSEIF length(chrid) = 2 
				THEN chrid := '0'||chrid;
			END IF;
		ELSE
			chrid := '001';
		END IF;

		
		--insert into profile

		INSERT INTO profile(
		    profile_id, profile_idcard, profile_idtype, profile_nama, profile_almt, 
		    profile_jk, profile_umur, profile_pend, profile_pkrj, profile_wn, profile_telp, profile_email)
		VALUES (chrnow||chrid, idcard, idtype, nama, almt, 
		    jk, umur, pend, pkrj, wn, telp, email);


		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_group, bukutamu_pc, bukutamu_los, bukutamu_wkta, bukutamu_wktb, bukutamu_nolock, bukutamu_o)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, chrnow||chrid,
		    tanggalkunjungan, layanan, dt_nas, dt_reg, dl, groupid, pc, los, CAST(current_time AS TIME WITHOUT TIME ZONE), CAST(wktb AS TIME WITHOUT TIME ZONE), no_lock, o);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = chrnow||chrid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = chrnow||chrid;  

	ELSE
		SELECT replace(CAST(tgl_kunjungan AS character varying),'-','')  INTO chrnow FROM profile_group WHERE group_id = groupid;

		SELECT profile_id INTO profileid FROM profile 		
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

		-- update profile
		UPDATE profile SET group_id = groupid 
		WHERE profile_idcard = idcard AND profile_idtype = idtype;
		
		--update profile
		UPDATE profile SET 
		    profile_nama = nama, profile_almt = almt, profile_jk = jk, profile_umur = umur, 
		    profile_pend = pend, profile_pkrj = pkrj, profile_wn = wn, profile_telp = telp, profile_email = email
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_group, bukutamu_pc, bukutamu_los, bukutamu_wkta, bukutamu_wktb, bukutamu_nolock, bukutamu_o)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, profileid,
		    tanggalkunjungan, layanan, dt_nas, dt_reg, dl, groupid, pc, los, CAST(current_time AS TIME WITHOUT TIME ZONE), CAST(wktb AS TIME WITHOUT TIME ZONE), no_lock, o);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = profileid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = profileid;  

	END IF; 
	i:=x+y;
	
	RETURN i; 
END;
$$;


--
-- TOC entry 241 (class 1255 OID 17082)
-- Dependencies: 5 846
-- Name: insert_profile_personal(character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION insert_profile_personal(idcard character varying, idtype character varying, nama character varying, almt character varying, jk character varying, umur character varying, pend character varying, pkrj character varying, wn character varying, layanan character varying, dt_nas character varying, dt_reg character varying, dl character varying, telp character varying, email character varying, pc character varying, los character varying, wktb character varying, o character varying, locker integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	intmax integer;
	chrid character varying;
	intid integer;
	chrnow character varying;
	x integer;
	y integer;
	i integer;
	chrbtid character varying;
	intbtid integer;
	intbtmax integer;
	jml integer;
	profileid character varying;
	n integer;
	bid integer;
	nc character varying;
	--nolocker character varying[] = '{}';
	no_lock character varying;

	a record;
	
BEGIN

	IF locker > 0 THEN
	
		n := 1;
		no_lock := '0';	
		--for(n = 1;n <= 59; n++)
		LOOP
			SELECT CAST(n AS character varying) INTO nc;
			--bid := 0;
			SELECT COUNT(*) INTO bid FROM bukutamu WHERE (bukutamu_nolock) = nc AND bukutamu_wktb = '00:00:00';
			IF bid = 0 THEN		 
				no_lock := nc;			
				n := 60;
			ELSE
				n := n+1;
			END IF;
			
			EXIT WHEN n >= locker;
		END LOOP;
	ELSE
		no_lock := '-';
	END IF;
	
	--select max id bukutamu
	SELECT CAST(MAX(bukutamu_id) AS integer) INTO intbtmax FROM bukutamu
	WHERE bukutamu_tgl = current_date;

	IF intbtmax > 0 THEN
		intbtid := intbtmax + 1;
		SELECT CAST(intbtid AS character varying) INTO chrbtid;
		IF length(chrbtid) = 1 THEN 
			chrbtid := '00'||chrbtid;
		ELSEIF length(chrbtid) = 2 
			THEN chrbtid := '0'||chrbtid;
		END IF;
	ELSE
		chrbtid := '001';
	END IF;

	-- cek if id exist
	SELECT count(*) INTO jml FROM profile 		
	WHERE profile_idcard = idcard AND profile_idtype = idtype;

	IF jml = 0 THEN

		--select max id profile
		SELECT CAST(MAX(SUBSTRING(profile_id,9,3)) AS integer) INTO intmax FROM profile
		WHERE SUBSTRING(profile_id,1,8)= replace(CAST(current_date AS character varying),'-','');

		IF intmax > 0 THEN
			intid := intmax + 1;
			SELECT CAST(intid AS character varying) INTO chrid;
			IF length(chrid) = 1 THEN 
				chrid := '00'||chrid;
			ELSEIF length(chrid) = 2 
				THEN chrid := '0'||chrid;
			END IF;
		ELSE
			chrid := '001';
		END IF;

		SELECT replace(CAST(current_date AS character varying),'-','') INTO chrnow;
		
		--insert into profile

		INSERT INTO profile(
		    profile_id, profile_idcard, profile_idtype, profile_nama, profile_almt, 
		    profile_jk, profile_umur, profile_pend, profile_pkrj, profile_wn, profile_telp, profile_email)
		VALUES (chrnow||chrid, idcard, idtype, nama, almt, 
		    jk, umur, pend, pkrj, wn, telp, email);


		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_pc, bukutamu_los, bukutamu_wkta, bukutamu_wktb, bukutamu_nolock, bukutamu_o)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, chrnow||chrid,
		    current_date, layanan, dt_nas, dt_reg, dl, pc, los, CAST(current_time(0) AS TIME WITHOUT TIME ZONE), CAST(wktb AS TIME WITHOUT TIME ZONE), no_lock, o);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = chrnow||chrid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = chrnow||chrid; 

	ELSE
		SELECT replace(CAST(current_date AS character varying),'-','') INTO chrnow;

		SELECT profile_id INTO profileid FROM profile 		
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

		--update profile
		UPDATE profile SET 
		    profile_nama = nama, profile_almt = almt, profile_jk = jk, profile_umur = umur, 
		    profile_pend = pend, profile_pkrj = pkrj, profile_wn = wn, profile_telp = telp, profile_email = email
		WHERE profile_idcard = idcard AND profile_idtype = idtype;

  		--insert into bukutamu
		INSERT INTO bukutamu(
		    bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id, bukutamu_profile, 
		    bukutamu_tgl, bukutamu_layanan, bukutamu_dt_nas, bukutamu_dt_reg, bukutamu_dl, bukutamu_pc, bukutamu_los, bukutamu_wkta, bukutamu_wktb, bukutamu_nolock, bukutamu_o)
		VALUES(substring(chrnow,1,4), substring(chrnow,5,2), substring(chrnow,7,2), chrbtid, profileid,
		    current_date, layanan, dt_nas, dt_reg, dl, pc, los, CAST(current_time(0) AS TIME WITHOUT TIME ZONE), CAST(wktb AS TIME WITHOUT TIME ZONE), no_lock, o);
		
		SELECT COUNT(*) INTO x FROM profile WHERE profile_id = profileid;   
		SELECT COUNT(*) INTO y FROM bukutamu WHERE bukutamu_profile = profileid;  

	END IF; 

	i:=x+y;
	
	RETURN i; 
END;
$$;


--
-- TOC entry 242 (class 1255 OID 17083)
-- Dependencies: 846 5
-- Name: laporan_daerah_kab(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_kab(awilda character varying, atahun1 character varying, atahun2 character varying, atahun3 character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = awilda and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;

	
	INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 243 (class 1255 OID 17084)
-- Dependencies: 5 846
-- Name: laporan_daerah_kab(character varying, character varying, character varying, character varying, character varying, character varying, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_kab(awilda character varying, atahun1 character varying, atahun2 character varying, atahun3 character varying, kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = awilda and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;

	
	INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 244 (class 1255 OID 17085)
-- Dependencies: 846 5
-- Name: laporan_daerah_kec(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_kec(awilda character varying, atahun1 character varying, atahun2 character varying, atahun3 character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop||kd_kab = awilda and kd_kec != '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;

	INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 245 (class 1255 OID 17086)
-- Dependencies: 5 846
-- Name: laporan_daerah_kec(character varying, character varying, character varying, character varying, character varying, character varying, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_kec(awilda character varying, atahun1 character varying, atahun2 character varying, atahun3 character varying, kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop||kd_kab = awilda and kd_kec != '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;

	INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 246 (class 1255 OID 17087)
-- Dependencies: 846 5
-- Name: laporan_daerah_nas(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_nas(atahun1 character varying, atahun2 character varying, atahun3 character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen= aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 247 (class 1255 OID 17088)
-- Dependencies: 5 846
-- Name: laporan_daerah_nas(character varying, character varying, character varying, character varying, character varying, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_daerah_nas(atahun1 character varying, atahun2 character varying, atahun3 character varying, kode_wilda character varying, wilayah character varying, dda1 integer, nondda1 integer, dda2 integer, nondda2 integer, dda3 integer, nondda3 integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda1 integer;
    jml_nondda1 integer;
    jml_dda2 integer;
    jml_nondda2 integer;
    jml_dda3 integer;
    jml_nondda3 integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda1 integer;
    sum_dda2 integer;
    sum_dda3 integer;
    sum_nondda1 integer;
    sum_nondda2 integer;
    sum_nondda3 integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda1 integer,
	anondda1 integer,
	adda2 integer,
	anondda2 integer,
	adda3 integer,
	anondda3 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda1 := 0;
	sum_dda2 := 0;
	sum_dda3 := 0;
	sum_nondda1 := 0;
	sum_nondda2 := 0;
	sum_nondda3 := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda1 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_nondda1 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun1;
		SELECT count(*) INTO jml_dda2 from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_nondda2 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun2;
		SELECT count(*) INTO jml_dda3 from t_publikasi where kd_produsen= aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun3;
		SELECT count(*) INTO jml_nondda3 from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and tahun_terbit = atahun3;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda1,jml_nondda1,jml_dda2,jml_nondda2,jml_dda3,jml_nondda3);
		sum_dda1 := sum_dda1 + jml_dda1;
		sum_dda2 := sum_dda2 + jml_dda2;
		sum_dda3 := sum_dda3 + jml_dda3;
		sum_nondda1 := sum_nondda1 + jml_nondda1;
		sum_nondda2 := sum_nondda2 + jml_nondda2;
		sum_nondda3 := sum_nondda3 + jml_nondda3;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda1,sum_nondda1,sum_dda2,sum_nondda2,sum_dda3,sum_nondda3);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 248 (class 1255 OID 17089)
-- Dependencies: 5 846
-- Name: laporan_dda_kab_hc(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_kab_hc(aprop character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_h = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_h = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 249 (class 1255 OID 17090)
-- Dependencies: 5 846
-- Name: laporan_dda_kab_hc(character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_kab_hc(aprop character varying, kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_h = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_h = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 250 (class 1255 OID 17091)
-- Dependencies: 5 846
-- Name: laporan_dda_kab_sc(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_kab_sc(aprop character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_s = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 251 (class 1255 OID 17092)
-- Dependencies: 5 846
-- Name: laporan_dda_kab_sc(character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_kab_sc(aprop character varying, kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab != '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_s = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 252 (class 1255 OID 17093)
-- Dependencies: 5 846
-- Name: laporan_dda_nas_hc(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_nas_hc() RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_h = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_h = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 253 (class 1255 OID 17094)
-- Dependencies: 5 846
-- Name: laporan_dda_nas_hc(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_nas_hc(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_h = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_h = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 254 (class 1255 OID 17095)
-- Dependencies: 5 846
-- Name: laporan_dda_nas_sc(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_nas_sc() RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_s = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 255 (class 1255 OID 17096)
-- Dependencies: 846 5
-- Name: laporan_dda_nas_sc(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_dda_nas_sc(kode_wilda character varying, wilayah character varying, dda integer, nondda integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_nondda integer;
    jml_total integer;   
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    sum_dda integer;
    sum_nondda integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	anondda integer,
	ajumlah integer
	
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop != '00' and kd_kab = '00' and kd_kec = '000' ;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	sum_dda := 0;
	sum_nondda := 0;
	jml_total := 0;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s = '1';
		SELECT count(*) INTO jml_nondda from t_publikasi where kd_produsen = aprod and substring(kd_bahan_pustaka,1,2) ='12' and kd_bahan_pustaka !='121' and flag_s = '1';
		jml_total := jml_dda + jml_nondda;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_nondda,jml_total);
		sum_dda := sum_dda + jml_dda;
		sum_nondda := sum_nondda + jml_nondda;
		sum_total := sum_dda + sum_nondda;
		i := i + 1;
	END LOOP;
		
		INSERT INTO lap values('Total','--',sum_dda,sum_nondda,sum_total);
	
	RETURN QUERY SELECT * from lap order by kode_wilda;
	DROP TABLE lap;
    
END 
$$;


--
-- TOC entry 256 (class 1255 OID 17097)
-- Dependencies: 5 846
-- Name: laporan_kab(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kab(aprop character varying, atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kec = '000' and kd_kab != '00';

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 257 (class 1255 OID 17098)
-- Dependencies: 5 846
-- Name: laporan_kab2(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kab2(aprop character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kec = '000' and kd_kab != '00';

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121';
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122';
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122';
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 258 (class 1255 OID 17099)
-- Dependencies: 5 846
-- Name: laporan_kabsc(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kabsc(aprop character varying, atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    prod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kec = '000' and kd_kab != '00';

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
				
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 259 (class 1255 OID 17100)
-- Dependencies: 5 846
-- Name: laporan_kabsc2(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kabsc2(aprop character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    prod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kec = '000' and kd_kab != '00';

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
				
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 260 (class 1255 OID 17101)
-- Dependencies: 5 846
-- Name: laporan_kec(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kec(aprop character varying, akab character varying, atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    kode varchar (255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab = akab and kd_kec != '000'  order by kd_prop, kd_kab, kd_kec;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		SELECT kd_prop||kd_kab||kd_kec INTO kode from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 261 (class 1255 OID 17102)
-- Dependencies: 5 846
-- Name: laporan_kec2(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kec2(aprop character varying, akab character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    kode varchar (255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab = akab and kd_kec != '000'  order by kd_prop, kd_kab, kd_kec;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		SELECT kd_prop||kd_kab||kd_kec INTO kode from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121';
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122';
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122';
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 262 (class 1255 OID 17103)
-- Dependencies: 5 846
-- Name: laporan_kecsc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kecsc(aprop character varying, akab character varying, atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    kode varchar (255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab = akab and kd_kec != '000'  order by kd_prop, kd_kab, kd_kec;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		SELECT kd_prop||kd_kab||kd_kec INTO kode from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 263 (class 1255 OID 17104)
-- Dependencies: 5 846
-- Name: laporan_kecsc2(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_kecsc2(aprop character varying, akab character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
    kode varchar (255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1' and kd_prop = aprop and kd_kab = akab and kd_kec != '000'  order by kd_prop, kd_kab, kd_kec;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		SELECT kd_prop||kd_kab||kd_kec INTO kode from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121'  and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 264 (class 1255 OID 17105)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_bulan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_bulan(atahun character varying) RETURNS TABLE(bulan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_bulan varchar(255);
    jml_bulan integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    abln varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_bulan') THEN DROP TABLE lap_bulan;
	END IF;
	
	CREATE TABLE lap_bulan (
	abulan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_bulan') THEN DROP TABLE m_bulan;
	END IF;
	
	CREATE TABLE m_bulan (
	id serial,
	kode varchar(255),
	nm_bulan varchar(255)
	);

	INSERT into m_bulan(kode,nm_bulan) VALUES ('01','Januari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('02','Februari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('03','Maret');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('04','April');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('05','Mei');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('06','Juni');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('07','Juli');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('08','Agustus');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('09','September');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('10','Oktober');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('11','November');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('12','Desember');

	SELECT count(*) INTO jml_bulan from m_bulan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_bulan)
	LOOP
		SELECT nm_bulan INTO abln FROM m_bulan where id = i;
		SELECT kode INTO kode_bulan from m_bulan where id = i;
		
		IF (kode_bulan = '01')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_bulan = '02')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_bulan = '03')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_bulan = '04')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '05')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '06')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '07')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
		ELSE IF (kode_bulan = '08')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

		ELSE IF (kode_bulan = '09')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '10')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '11')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
		ELSE IF (kode_bulan = '12')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
		END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_bulan values (abln,jml_laki,jml_perempuan,jml_total);

		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_bulan values('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_bulan ;
	DROP TABLE lap_bulan;DROP TABLE m_bulan;
	
    
END 
$$;


--
-- TOC entry 265 (class 1255 OID 17106)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_bulan(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_bulan(atahun character varying, bulan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_bulan varchar(255);
    jml_bulan integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    abln varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_bulan') THEN DROP TABLE lap_bulan;
	END IF;
	
	CREATE TABLE lap_bulan (
	abulan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_bulan') THEN DROP TABLE m_bulan;
	END IF;
	
	CREATE TABLE m_bulan (
	id serial,
	kode varchar(255),
	nm_bulan varchar(255)
	);

	INSERT into m_bulan(kode,nm_bulan) VALUES ('01','Januari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('02','Februari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('03','Maret');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('04','April');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('05','Mei');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('06','Juni');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('07','Juli');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('08','Agustus');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('09','September');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('10','Oktober');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('11','November');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('12','Desember');

	SELECT count(*) INTO jml_bulan from m_bulan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_bulan)
	LOOP
		SELECT nm_bulan INTO abln FROM m_bulan where id = i;
		SELECT kode INTO kode_bulan from m_bulan where id = i;
		
		IF (kode_bulan = '01')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_bulan = '02')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_bulan = '03')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_bulan = '04')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '05')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '06')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '07')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
		ELSE IF (kode_bulan = '08')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

		ELSE IF (kode_bulan = '09')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '10')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_bulan = '11')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
		ELSE IF (kode_bulan = '12')
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and b.bukutamu_bl = kode_bulan and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
		END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_bulan values (abln,jml_laki,jml_perempuan,jml_total);

		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_bulan values('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_bulan ;
	DROP TABLE lap_bulan;DROP TABLE m_bulan;
	
    
END 
$$;


--
-- TOC entry 266 (class 1255 OID 17107)
-- Dependencies: 846 5
-- Name: laporan_pengunjung_ganda(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_ganda(atahun character varying) RETURNS TABLE(bulan character varying, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_bulan varchar(255);
    jml_bulan integer;
    jml_total integer;
    abln varchar(255);
    ajan integer;
    afeb integer;
    amar integer;
    aapr integer;
    amei integer;
    ajun integer;
    ajul integer;
    aagu integer;
    asep integer;
    aokt integer;
    anov integer;
    ades integer; 
    abanyak integer;
    anilai integer;  
    i integer;
    k integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_ganda') THEN DROP TABLE lap_ganda;
	END IF;
	
	CREATE TABLE lap_ganda (
	abulan varchar(255),
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_bulan') THEN DROP TABLE m_bulan;
	END IF;
	
	CREATE TABLE m_bulan (
	id serial,
	kode varchar(255),
	nm_bulan varchar(255)
	);

	INSERT into m_bulan(kode,nm_bulan) VALUES ('01','Januari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('02','Februari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('03','Maret');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('04','April');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('05','Mei');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('06','Juni');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('07','Juli');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('08','Agustus');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('09','September');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('10','Oktober');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('11','November');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('12','Desember');

	SELECT count(*) INTO jml_bulan from m_bulan;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_ganda') THEN DROP TABLE m_ganda;
	END IF;
	
	CREATE TABLE m_ganda (
	id serial,
	kode varchar(255),
	ganda integer
	);


	i := 1;
	sum_total := 0;
	while(i <= jml_bulan)
	LOOP
		SELECT nm_bulan INTO abln FROM m_bulan where id = i;
		SELECT kode INTO kode_bulan from m_bulan where id = i;
		
		IF (kode_bulan = '01')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '01'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajan FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajan);
			jml_total := ajan;
	        
	        ELSE IF (kode_bulan = '02')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '02'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO afeb FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,afeb);
			jml_total := afeb;

	        ELSE IF (kode_bulan = '03')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '03'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO amar FROM m_ganda WHERE ganda > 1;
	                INSERT INTO lap_ganda values (abln,amar);
	                jml_total := amar;

	        ELSE IF (kode_bulan = '04')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '04'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aapr FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aapr);
			jml_total := aapr;
			
	        ELSE IF (kode_bulan = '05')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '05'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO amei FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,amei);
			jml_total := amei;

	        ELSE IF (kode_bulan = '06')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '06'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajun FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajun);
			jml_total := ajun;

	        ELSE IF (kode_bulan = '07')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '07'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajul FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajul);
			jml_total := ajul;
	        
		ELSE IF (kode_bulan = '08')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '08'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aagu FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aagu);
			jml_total := aagu;

		ELSE IF (kode_bulan = '09')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '09'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO asep FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,asep);
			jml_total := asep;

	        ELSE IF (kode_bulan = '10')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '10'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aokt FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aokt);
			jml_total := aokt;
		
	        ELSE IF (kode_bulan = '11')
	        THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '11'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO anov FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,anov);
			jml_total := anov;
	        
		ELSE IF (kode_bulan = '12')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '12'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ades FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ades);
			jml_total := ades;
	        
	        END IF;
		END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_ganda values('Total',sum_total);

	
	RETURN QUERY SELECT * from lap_ganda ;
	DROP TABLE lap_ganda;DROP TABLE m_bulan;DROP TABLE m_ganda;
	
    
END 
$$;


--
-- TOC entry 267 (class 1255 OID 17108)
-- Dependencies: 846 5
-- Name: laporan_pengunjung_ganda(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_ganda(atahun character varying, bulan character varying, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_bulan varchar(255);
    jml_bulan integer;
    jml_total integer;
    abln varchar(255);
    ajan integer;
    afeb integer;
    amar integer;
    aapr integer;
    amei integer;
    ajun integer;
    ajul integer;
    aagu integer;
    asep integer;
    aokt integer;
    anov integer;
    ades integer; 
    abanyak integer;
    anilai integer;  
    i integer;
    k integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_ganda') THEN DROP TABLE lap_ganda;
	END IF;
	
	CREATE TABLE lap_ganda (
	abulan varchar(255),
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_bulan') THEN DROP TABLE m_bulan;
	END IF;
	
	CREATE TABLE m_bulan (
	id serial,
	kode varchar(255),
	nm_bulan varchar(255)
	);

	INSERT into m_bulan(kode,nm_bulan) VALUES ('01','Januari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('02','Februari');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('03','Maret');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('04','April');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('05','Mei');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('06','Juni');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('07','Juli');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('08','Agustus');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('09','September');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('10','Oktober');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('11','November');
	INSERT into m_bulan(kode,nm_bulan) VALUES ('12','Desember');

	SELECT count(*) INTO jml_bulan from m_bulan;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_ganda') THEN DROP TABLE m_ganda;
	END IF;
	
	CREATE TABLE m_ganda (
	id serial,
	kode varchar(255),
	ganda integer
	);


	i := 1;
	sum_total := 0;
	while(i <= jml_bulan)
	LOOP
		SELECT nm_bulan INTO abln FROM m_bulan where id = i;
		SELECT kode INTO kode_bulan from m_bulan where id = i;
		
		IF (kode_bulan = '01')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '01'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajan FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajan);
			jml_total := ajan;
	        
	        ELSE IF (kode_bulan = '02')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '02'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO afeb FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,afeb);
			jml_total := afeb;

	        ELSE IF (kode_bulan = '03')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '03'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO amar FROM m_ganda WHERE ganda > 1;
	                INSERT INTO lap_ganda values (abln,amar);
	                jml_total := amar;

	        ELSE IF (kode_bulan = '04')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '04'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aapr FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aapr);
			jml_total := aapr;
			
	        ELSE IF (kode_bulan = '05')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '05'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO amei FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,amei);
			jml_total := amei;

	        ELSE IF (kode_bulan = '06')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '06'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajun FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajun);
			jml_total := ajun;

	        ELSE IF (kode_bulan = '07')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '07'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ajul FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ajul);
			jml_total := ajul;
	        
		ELSE IF (kode_bulan = '08')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '08'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aagu FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aagu);
			jml_total := aagu;

		ELSE IF (kode_bulan = '09')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '09'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO asep FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,asep);
			jml_total := asep;

	        ELSE IF (kode_bulan = '10')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '10'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO aokt FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,aokt);
			jml_total := aokt;
		
	        ELSE IF (kode_bulan = '11')
	        THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '11'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO anov FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,anov);
			jml_total := anov;
	        
		ELSE IF (kode_bulan = '12')
		THEN
		DELETE FROM m_ganda;
		INSERT INTO m_ganda(kode) SELECT profile_id FROM profile WHERE substring(profile_id,5,2) = '12'; 
		SELECT COUNT(*) INTO abanyak FROM m_ganda;
		k := 1;
		WHILE(k <= abanyak)
			LOOP
			SELECT COUNT(*) INTO anilai FROM bukutamu,m_ganda WHERE bukutamu.bukutamu_profile = m_ganda.kode and k = id;
			UPDATE m_ganda SET ganda = anilai WHERE k = id;
			k := k + 1;
			END LOOP;
			SELECT COUNT(*) INTO ades FROM m_ganda WHERE ganda > 1;
			INSERT INTO lap_ganda values (abln,ades);
			jml_total := ades;
	        
	        END IF;
		END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_ganda values('Total',sum_total);

	
	RETURN QUERY SELECT * from lap_ganda ;
	DROP TABLE lap_ganda;DROP TABLE m_bulan;DROP TABLE m_ganda;
	
    
END 
$$;


--
-- TOC entry 268 (class 1255 OID 17109)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_kewarganegaraan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_kewarganegaraan(atahun character varying) RETURNS TABLE(kewarganegaraan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_wn integer;
    jml_wn integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    awn varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_kewarganegaraan') THEN DROP TABLE lap_kewarganegaraan;
	END IF;
	
	CREATE TABLE lap_kewarganegaraan (
	akewarganegaraan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_kewarganegaraan') THEN DROP TABLE m_kewarganegaraan;
	END IF;
	
	CREATE TABLE m_kewarganegaraan (
	id serial,
	kode integer,
	nm_kewarganegaraan varchar(255)
	);

	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (1,'Indonesia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (2,'Jepang');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (3,'Amerika');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (4,'Malaysia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (5,'Australia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (6,'Cina');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (7,'India');
    INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (8,'Lainnya');

	SELECT count(*) INTO jml_wn from m_kewarganegaraan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_wn)
	LOOP
		SELECT nm_kewarganegaraan INTO awn FROM m_kewarganegaraan where id = i;
		SELECT kode INTO kode_wn from m_kewarganegaraan where id = i;
		
		IF (kode_wn = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_wn = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_wn = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_wn = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_wn = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_wn = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 7)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '7' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '7' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
            ELSE IF (kode_wn = 8)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '8' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '8' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        END IF;
            END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_kewarganegaraan values (awn,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_kewarganegaraan values('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_kewarganegaraan ;
	DROP TABLE lap_kewarganegaraan;
	DROP TABLE m_kewarganegaraan;
END 
$$;


--
-- TOC entry 269 (class 1255 OID 17110)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_kewarganegaraan(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_kewarganegaraan(atahun character varying, kewarganegaraan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_wn integer;
    jml_wn integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    awn varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_kewarganegaraan') THEN DROP TABLE lap_kewarganegaraan;
	END IF;
	
	CREATE TABLE lap_kewarganegaraan (
	akewarganegaraan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_kewarganegaraan') THEN DROP TABLE m_kewarganegaraan;
	END IF;
	
	CREATE TABLE m_kewarganegaraan (
	id serial,
	kode integer,
	nm_kewarganegaraan varchar(255)
	);

	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (1,'Indonesia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (2,'Jepang');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (3,'Amerika');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (4,'Malaysia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (5,'Australia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (6,'Cina');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (7,'India');
    INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (8,'Lainnya');

	SELECT count(*) INTO jml_wn from m_kewarganegaraan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_wn)
	LOOP
		SELECT nm_kewarganegaraan INTO awn FROM m_kewarganegaraan where id = i;
		SELECT kode INTO kode_wn from m_kewarganegaraan where id = i;
		
		IF (kode_wn = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_wn = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_wn = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_wn = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_wn = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_wn = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 7)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th  = atahun and a.profile_wn = '7' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '7' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
            ELSE IF (kode_wn = 8)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_wn = '8' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th  = atahun and a.profile_wn = '8' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        END IF;
            END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_kewarganegaraan values (awn,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
	INSERT INTO lap_kewarganegaraan values('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_kewarganegaraan ;
	DROP TABLE lap_kewarganegaraan;
	DROP TABLE m_kewarganegaraan;
END 
$$;


--
-- TOC entry 270 (class 1255 OID 17111)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_kewarganegaraan_bulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_kewarganegaraan_bulan(atahun character varying, abulan character varying) RETURNS TABLE(kewarganegaraan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_wn integer;
    jml_wn integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    awn varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_kewarganegaraan') THEN DROP TABLE lap_kewarganegaraan;
	END IF;
	
	CREATE TABLE lap_kewarganegaraan (
	akewarganegaraan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_kewarganegaraan') THEN DROP TABLE m_kewarganegaraan;
	END IF;
	
	CREATE TABLE m_kewarganegaraan (
	id serial,
	kode integer,
	nm_kewarganegaraan varchar(255)
	);

	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (1,'Indonesia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (2,'Jepang');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (3,'Amerika');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (4,'Malaysia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (5,'Australia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (6,'Cina');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (7,'India');
    INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (8,'Lainnya');

	SELECT count(*) INTO jml_wn from m_kewarganegaraan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_wn)
	LOOP
		SELECT nm_kewarganegaraan INTO awn FROM m_kewarganegaraan where id = i;
		SELECT kode INTO kode_wn from m_kewarganegaraan where id = i;
		
		IF (kode_wn = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_wn = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_wn = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_wn = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '5'and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 7)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '7' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '7' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
            ELSE IF (kode_wn = 8)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '8' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and substring(profile_id,1,4) = atahun  and substring(profile_id,5,2) = abulan and profile_wn = '8' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        END IF;
            END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_kewarganegaraan values (awn,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
		INSERT INTO lap_kewarganegaraan values ('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_kewarganegaraan ;
	DROP TABLE lap_kewarganegaraan;
	DROP TABLE m_kewarganegaraan;
    
END 
$$;


--
-- TOC entry 271 (class 1255 OID 17112)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_kewarganegaraan_bulan(character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_kewarganegaraan_bulan(atahun character varying, abulan character varying, kewarganegaraan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_wn integer;
    jml_wn integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    awn varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_kewarganegaraan') THEN DROP TABLE lap_kewarganegaraan;
	END IF;
	
	CREATE TABLE lap_kewarganegaraan (
	akewarganegaraan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_kewarganegaraan') THEN DROP TABLE m_kewarganegaraan;
	END IF;
	
	CREATE TABLE m_kewarganegaraan (
	id serial,
	kode integer,
	nm_kewarganegaraan varchar(255)
	);

	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (1,'Indonesia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (2,'Jepang');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (3,'Amerika');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (4,'Malaysia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (5,'Australia');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (6,'Cina');
	INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (7,'India');
    INSERT into m_kewarganegaraan(kode,nm_kewarganegaraan) VALUES (8,'Lainnya');

	SELECT count(*) INTO jml_wn from m_kewarganegaraan;

	i := 1;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	while(i <= jml_wn)
	LOOP
		SELECT nm_kewarganegaraan INTO awn FROM m_kewarganegaraan where id = i;
		SELECT kode INTO kode_wn from m_kewarganegaraan where id = i;
		
		IF (kode_wn = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_wn = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_wn = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_wn = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '5'and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	         ELSE IF (kode_wn = 7)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '7' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '7' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
            ELSE IF (kode_wn = 8)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and profile_wn = '8' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where profile_jk = '2' and substring(profile_id,1,4) = atahun  and substring(profile_id,5,2) = abulan and profile_wn = '8' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        END IF;
            END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_kewarganegaraan values (awn,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		i := i + 1;
	END LOOP;
		INSERT INTO lap_kewarganegaraan values ('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_kewarganegaraan ;
	DROP TABLE lap_kewarganegaraan;
	DROP TABLE m_kewarganegaraan;
    
END 
$$;


--
-- TOC entry 272 (class 1255 OID 17113)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pekerjaan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pekerjaan(atahun character varying) RETURNS TABLE(pekerjaan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apek varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pekerjaan') THEN DROP TABLE lap_pekerjaan;
	END IF;
	
	CREATE TABLE lap_pekerjaan (
	apekerjaan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pekerjaan') THEN DROP TABLE m_pekerjaan;
	END IF;
	
	CREATE TABLE m_pekerjaan (
	id serial,
	kode integer,
	nm_pekerjaan varchar(255)
	);

	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (1,'Mahasiswa');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (2,'Pegawai Swasta');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (3,'PNS/TNI?Polri');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (4,'Pegawai BPS');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (5,'Pelajar');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (6,'Lainnya');
	
	SELECT count(*) INTO jml_pek from m_pekerjaan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pekerjaan INTO apek FROM m_pekerjaan where id = i;
		SELECT kode INTO kode_pek from m_pekerjaan where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;


	        ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pekerjaan values (apek,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;
		INSERT INTO lap_pekerjaan values ('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_pekerjaan ;
	DROP TABLE lap_pekerjaan;
	DROP TABLE m_pekerjaan;
    
END 
$$;


--
-- TOC entry 273 (class 1255 OID 17114)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pekerjaan(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pekerjaan(atahun character varying, pekerjaan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apek varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pekerjaan') THEN DROP TABLE lap_pekerjaan;
	END IF;
	
	CREATE TABLE lap_pekerjaan (
	apekerjaan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pekerjaan') THEN DROP TABLE m_pekerjaan;
	END IF;
	
	CREATE TABLE m_pekerjaan (
	id serial,
	kode integer,
	nm_pekerjaan varchar(255)
	);

	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (1,'Mahasiswa');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (2,'Pegawai Swasta');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (3,'PNS/TNI/Polri');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (4,'Pegawai BPS');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (5,'Pelajar');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (6,'Lainnya');
	
	SELECT count(*) INTO jml_pek from m_pekerjaan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pekerjaan INTO apek FROM m_pekerjaan where id = i;
		SELECT kode INTO kode_pek from m_pekerjaan where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;


	        ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pekerjaan values (apek,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;
		INSERT INTO lap_pekerjaan values ('Total',sum_laki,sum_pr,sum_total);

	
	RETURN QUERY SELECT * from lap_pekerjaan ;
	DROP TABLE lap_pekerjaan;
	DROP TABLE m_pekerjaan;
    
END 
$$;


--
-- TOC entry 274 (class 1255 OID 17115)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pekerjaan_bulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pekerjaan_bulan(atahun character varying, abulan character varying) RETURNS TABLE(pekerjaan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apek varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pekerjaan') THEN DROP TABLE lap_pekerjaan;
	END IF;
	
	CREATE TABLE lap_pekerjaan (
	apekerjaan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pekerjaan') THEN DROP TABLE m_pekerjaan;
	END IF;
	
	CREATE TABLE m_pekerjaan (
	id serial,
	kode integer,
	nm_pekerjaan varchar(255)
	);

	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (1,'Mahasiswa');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (2,'Pegawai Swasta');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (3,'PNS/TNI?Polri');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (4,'Pegawai BPS');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (5,'Pelajar');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (6,'Lainnya');
	
	SELECT count(*) INTO jml_pek from m_pekerjaan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;

	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pekerjaan INTO apek FROM m_pekerjaan where id = i;
		SELECT kode INTO kode_pek from m_pekerjaan where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;


	        ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pekerjaan values (apek,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;
		INSERT INTO lap_pekerjaan values('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_pekerjaan ;
	DROP TABLE lap_pekerjaan;
	DROP TABLE m_pekerjaan;
    
END 
$$;


--
-- TOC entry 275 (class 1255 OID 17116)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pekerjaan_bulan(character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pekerjaan_bulan(atahun character varying, abulan character varying, pekerjaan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apek varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pekerjaan') THEN DROP TABLE lap_pekerjaan;
	END IF;
	
	CREATE TABLE lap_pekerjaan (
	apekerjaan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pekerjaan') THEN DROP TABLE m_pekerjaan;
	END IF;
	
	CREATE TABLE m_pekerjaan (
	id serial,
	kode integer,
	nm_pekerjaan varchar(255)
	);

	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (1,'Mahasiswa');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (2,'Pegawai Swasta');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (3,'PNS/TNI?Polri');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (4,'Pegawai BPS');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (5,'Pelajar');
	INSERT into m_pekerjaan(kode,nm_pekerjaan) VALUES (6,'Lainnya');
	
	SELECT count(*) INTO jml_pek from m_pekerjaan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;

	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pekerjaan INTO apek FROM m_pekerjaan where id = i;
		SELECT kode INTO kode_pek from m_pekerjaan where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;

	        ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;


	        ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_laki from profile a, bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a, bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pekerjaan values (apek,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;
		INSERT INTO lap_pekerjaan values('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_pekerjaan ;
	DROP TABLE lap_pekerjaan;
	DROP TABLE m_pekerjaan;
    
END 
$$;


--
-- TOC entry 276 (class 1255 OID 17117)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pendidikan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pendidikan(atahun character varying) RETURNS TABLE(pendidikan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apend varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pendidikan') THEN DROP TABLE lap_pendidikan;
	END IF;
	
	CREATE TABLE lap_pendidikan (
	apendidikan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO apend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pendidikan values (apend,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;

	INSERT INTO lap_pendidikan values('Total',sum_laki,sum_pr,sum_total);
	RETURN QUERY SELECT * from lap_pendidikan ;
	DROP TABLE lap_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 277 (class 1255 OID 17118)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pendidikan(character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pendidikan(atahun character varying, pendidikan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apend varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pendidikan') THEN DROP TABLE lap_pendidikan;
	END IF;
	
	CREATE TABLE lap_pendidikan (
	apendidikan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;
	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO apend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pendidikan values (apend,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;

		i := i + 1;
	END LOOP;

	INSERT INTO lap_pendidikan values('Total',sum_laki,sum_pr,sum_total);
	RETURN QUERY SELECT * from lap_pendidikan ;
	DROP TABLE lap_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 278 (class 1255 OID 17119)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pendidikan_bulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pendidikan_bulan(atahun character varying, abulan character varying) RETURNS TABLE(pendidikan character varying, laki_laki integer, perempuan integer, jumlah integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apend varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;

BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pendidikan') THEN DROP TABLE lap_pendidikan;
	END IF;
	
	CREATE TABLE lap_pendidikan (
	apendidikan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;

	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO apend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '1'and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pendidikan values (apend,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		
		i := i + 1;
	END LOOP;
		INSERT INTO lap_pendidikan values('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_pendidikan ;
	DROP TABLE lap_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 279 (class 1255 OID 17120)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_pendidikan_bulan(character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_pendidikan_bulan(atahun character varying, abulan character varying, pendidikan character varying, laki_laki integer, perempuan integer, jumlah integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_laki integer;
    jml_perempuan integer;
    jml_total integer;
    apend varchar(255);
    i integer;
    sum_laki integer;
    sum_pr integer;
    sum_total integer;

BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pendidikan') THEN DROP TABLE lap_pendidikan;
	END IF;
	
	CREATE TABLE lap_pendidikan (
	apendidikan varchar(255),
	alaki integer,
	aperempuan integer,
	ajumlah integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_laki := 0;
	sum_pr := 0;
	sum_total := 0;

	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO apend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '1'and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_laki from profile a,bukutamu b where a.profile_jk = '1' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
		SELECT count(*) INTO jml_perempuan from profile a,bukutamu b where a.profile_jk = '2' and b.bukutamu_th = atahun and b.bukutamu_bl = abulan and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id;
	        jml_total := jml_laki + jml_perempuan;
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO lap_pendidikan values (apend,jml_laki,jml_perempuan,jml_total);
		sum_laki := sum_laki + jml_laki;
		sum_pr := sum_pr + jml_perempuan;
		sum_total := sum_total + jml_total;
		
		i := i + 1;
	END LOOP;
		INSERT INTO lap_pendidikan values('Total',sum_laki,sum_pr,sum_total);
	
	RETURN QUERY SELECT * from lap_pendidikan ;
	DROP TABLE lap_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 280 (class 1255 OID 17121)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_rekap_jk(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_jk(atahun character varying) RETURNS TABLE(ajk character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_jk integer;
    jml_jk integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bjk varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_jk') THEN DROP TABLE rek_jk;
	END IF;
	
	CREATE TABLE rek_jk (
	ajen varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_jk') THEN DROP TABLE m_jk;
	END IF;
	
	CREATE TABLE m_jk (
	id serial,
	kode integer,
	nm_jk varchar(255)
	);

	INSERT into m_jk(kode,nm_jk) VALUES (1,'Laki-laki');
	INSERT into m_jk(kode,nm_jk) VALUES (2,'Perempuan');

	SELECT count(*) INTO jml_jk from m_jk;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_jk)
	LOOP
		SELECT nm_jk INTO bjk FROM m_jk where id = i;
		SELECT kode INTO kode_jk from m_jk where id = i;
		
		IF (kode_jk = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_jk = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

	        
	        END IF;
	        END IF;
		INSERT INTO rek_jk values (bjk,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_jk values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	
	RETURN QUERY SELECT * from rek_jk ;
	DROP TABLE rek_jk;
	DROP TABLE m_jk;
END 
$$;


--
-- TOC entry 282 (class 1255 OID 17122)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_rekap_jk(character varying, character varying, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_jk(atahun character varying, ajk character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_jk integer;
    jml_jk integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bjk varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_jk') THEN DROP TABLE rek_jk;
	END IF;
	
	CREATE TABLE rek_jk (
	ajen varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_jk') THEN DROP TABLE m_jk;
	END IF;
	
	CREATE TABLE m_jk (
	id serial,
	kode integer,
	nm_jk varchar(255)
	);

	INSERT into m_jk(kode,nm_jk) VALUES (1,'Laki-laki');
	INSERT into m_jk(kode,nm_jk) VALUES (2,'Perempuan');

	SELECT count(*) INTO jml_jk from m_jk;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_jk)
	LOOP
		SELECT nm_jk INTO bjk FROM m_jk where id = i;
		SELECT kode INTO kode_jk from m_jk where id = i;
		
		IF (kode_jk = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_jk = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_jk = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

	        
	        END IF;
	        END IF;
		INSERT INTO rek_jk values (bjk,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_jk values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	
	RETURN QUERY SELECT * from rek_jk ;
	DROP TABLE rek_jk;
	DROP TABLE m_jk;
END 
$$;


--
-- TOC entry 283 (class 1255 OID 17123)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_rekap_pek(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_pek(atahun character varying) RETURNS TABLE(apek character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bpek varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_pek') THEN DROP TABLE rek_pek;
	END IF;
	
	CREATE TABLE rek_pek (
	apkrj varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pek') THEN DROP TABLE m_pek;
	END IF;
	
	CREATE TABLE m_pek (
	id serial,
	kode integer,
	nm_pek varchar(255)
	);

	INSERT into m_pek(kode,nm_pek) VALUES (1,'Mahasiswa');
	INSERT into m_pek(kode,nm_pek) VALUES (2,'Pegawai Swasta');
	INSERT into m_pek(kode,nm_pek) VALUES (3,'PNS/TNI/Polri');
	INSERT into m_pek(kode,nm_pek) VALUES (4,'Pegawai BPS');
	INSERT into m_pek(kode,nm_pek) VALUES (5,'Pelajar');
	INSERT into m_pek(kode,nm_pek) VALUES (6,'Lainnya');

	SELECT count(*) INTO jml_pek from m_pek;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pek INTO bpek FROM m_pek where id = i;
		SELECT kode INTO kode_pek from m_pek where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';

		ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

		ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';


		ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';


		ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        
		INSERT INTO rek_pek values (bpek,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_pek values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	
	RETURN QUERY SELECT * from rek_pek ;
	DROP TABLE rek_pek;
	DROP TABLE m_pek;
END 
$$;


--
-- TOC entry 284 (class 1255 OID 17125)
-- Dependencies: 5 846
-- Name: laporan_pengunjung_rekap_pek(character varying, character varying, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_pek(atahun character varying, apek character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pek integer;
    jml_pek integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bpek varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_pek') THEN DROP TABLE rek_pek;
	END IF;
	
	CREATE TABLE rek_pek (
	apkrj varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pek') THEN DROP TABLE m_pek;
	END IF;
	
	CREATE TABLE m_pek (
	id serial,
	kode integer,
	nm_pek varchar(255)
	);

	INSERT into m_pek(kode,nm_pek) VALUES (1,'Mahasiswa');
	INSERT into m_pek(kode,nm_pek) VALUES (2,'Pegawai BPS');
	INSERT into m_pek(kode,nm_pek) VALUES (3,'Pegawai Swasta');
	INSERT into m_pek(kode,nm_pek) VALUES (4,'Pelajar');
	INSERT into m_pek(kode,nm_pek) VALUES (5,'PNS/TNI/Polri');
	INSERT into m_pek(kode,nm_pek) VALUES (6,'Lainnya');

	SELECT count(*) INTO jml_pek from m_pek;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_pek)
	LOOP
		SELECT nm_pek INTO bpek FROM m_pek where id = i;
		SELECT kode INTO kode_pek from m_pek where id = i;
		
		IF (kode_pek = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_pek = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';

		ELSE IF (kode_pek = 3)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

		ELSE IF (kode_pek = 4)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';


		ELSE IF (kode_pek = 5)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '5' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';


		ELSE IF (kode_pek = 6)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pkrj = '6' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        END IF;
	        
		INSERT INTO rek_pek values (bpek,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_pek values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	
	RETURN QUERY SELECT * from rek_pek ;
	DROP TABLE rek_pek;
	DROP TABLE m_pek;
END 
$$;


--
-- TOC entry 285 (class 1255 OID 17127)
-- Dependencies: 846 5
-- Name: laporan_pengunjung_rekap_pend(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_pend(atahun character varying) RETURNS TABLE(apend character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bpend varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_pendidikan') THEN DROP TABLE rek_pendidikan;
	END IF;
	
	CREATE TABLE rek_pendidikan (
	apendidikan varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO bpend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO rek_pendidikan values (bpend,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_pendidikan values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	RETURN QUERY SELECT * from rek_pendidikan ;
	DROP TABLE rek_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 286 (class 1255 OID 17128)
-- Dependencies: 846 5
-- Name: laporan_pengunjung_rekap_pend(character varying, character varying, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pengunjung_rekap_pend(atahun character varying, apend character varying, ajan integer, afeb integer, amar integer, aapr integer, amei integer, ajun integer, ajul integer, aagu integer, asep integer, aokt integer, anov integer, ades integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    kode_pend integer;
    jml_pend integer;
    jml_jan integer;
    jml_feb integer;
    jml_mar integer;
    jml_apr integer;
    jml_mei integer;
    jml_jun integer;
    jml_jul integer;
    jml_agu integer;
    jml_sep integer;
    jml_okt integer;
    jml_nov integer;
    jml_des integer;
    jml_total integer;
    bpend varchar(255);
    i integer;
    sum_jan integer;
    sum_feb integer;
    sum_mar integer;
    sum_apr integer;
    sum_mei integer;
    sum_jun integer;
    
    sum_jul integer;
    sum_agu integer;
    sum_sep integer;
    sum_okt integer;
    sum_nov integer;
    sum_des integer;
    sum_total integer;
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'rek_pendidikan') THEN DROP TABLE rek_pendidikan;
	END IF;
	
	CREATE TABLE rek_pendidikan (
	apendidikan varchar(255),
	bulan1 integer,
	bulan2 integer,
	bulan3 integer,
	bulan4 integer,
	bulan5 integer,
	bulan6 integer,
	bulan7 integer,
	bulan8 integer,
	bulan9 integer,
	bulan10 integer,
	bulan11 integer,
	bulan12 integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_pendidikan') THEN DROP TABLE m_pendidikan;
	END IF;
	
	CREATE TABLE m_pendidikan (
	id serial,
	kode integer,
	nm_pendidikan varchar(255)
	);

	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (1,'<= SMA');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (2,'D1/D2/D3');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (3,'S1/D4');
	INSERT into m_pendidikan(kode,nm_pendidikan) VALUES (4,'S2/S3');

	SELECT count(*) INTO jml_pend from m_pendidikan;
	sum_jan := 0;
	sum_feb := 0;
	sum_mar := 0;
	sum_apr := 0;
	sum_mei := 0;
	sum_jun := 0;
	sum_jan := 0;
	sum_jul := 0;
	sum_agu := 0;
	sum_sep := 0;
	sum_okt := 0;
	sum_nov := 0;
	sum_des := 0;
	sum_total := 0;

	jml_jan := 0;
	jml_feb := 0;
	jml_mar := 0;
	jml_apr := 0;
	jml_mei := 0;
	jml_jun := 0;
	jml_jul := 0;
	jml_agu := 0;
	jml_sep := 0;
	jml_okt := 0;
	jml_nov := 0;
	jml_des := 0;

	
	i := 1;
	while(i <= jml_pend)
	LOOP
		SELECT nm_pendidikan INTO bpend FROM m_pendidikan where id = i;
		SELECT kode INTO kode_pend from m_pendidikan where id = i;
		
		IF (kode_pend = 1)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '1' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
		
	       
	        
	        ELSE IF (kode_pend = 2)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '2' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	       

	        ELSE IF (kode_pend = 3)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '3' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	        

	        ELSE IF (kode_pend = 4)
		THEN
		SELECT count(*) INTO jml_jan from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '01';
		SELECT count(*) INTO jml_feb from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '02';
		SELECT count(*) INTO jml_mar from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '03';
		SELECT count(*) INTO jml_apr from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '04';
		SELECT count(*) INTO jml_mei from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '05';
		SELECT count(*) INTO jml_jun from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '06';
		SELECT count(*) INTO jml_jul from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '07';
		SELECT count(*) INTO jml_agu from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '08';
		SELECT count(*) INTO jml_sep from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '09';
		SELECT count(*) INTO jml_okt from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '10';
		SELECT count(*) INTO jml_nov from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '11';
		SELECT count(*) INTO jml_des from profile a,bukutamu b where b.bukutamu_th = atahun and a.profile_pend = '4' and b.bukutamu_profile = a.profile_id and b.bukutamu_bl = '12';
	        
	        END IF;
	        END IF;
	        END IF;
	        END IF;
		INSERT INTO rek_pendidikan values (bpend,jml_jan,jml_feb,jml_mar,jml_apr,jml_mei,jml_jun,jml_jul,jml_agu,jml_sep,jml_okt,jml_nov,jml_des);
		sum_jan := sum_jan + jml_jan;
		sum_feb := sum_feb + jml_feb;
		sum_mar := sum_mar + jml_mar;
		sum_apr := sum_apr + jml_apr;
		sum_mei := sum_mei + jml_mei;
		sum_jun := sum_jun + jml_jun;
		sum_jul := sum_jul + jml_jul;
		sum_agu := sum_agu + jml_agu;
		sum_sep := sum_sep + jml_sep;
		sum_okt := sum_okt + jml_okt;
		sum_nov := sum_nov + jml_nov;
		sum_des := sum_des + jml_des;

		i := i + 1;
	END LOOP;

	INSERT INTO rek_pendidikan values('Total',sum_jan,sum_feb,sum_mar,sum_apr,sum_mei,sum_jun,sum_jul,sum_agu,sum_sep,sum_okt,sum_nov,sum_des);
	RETURN QUERY SELECT * from rek_pendidikan ;
	DROP TABLE rek_pendidikan;
	DROP TABLE m_pendidikan;
END 
$$;


--
-- TOC entry 287 (class 1255 OID 17129)
-- Dependencies: 5 846
-- Name: laporan_petugas(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_petugas(atahun character varying) RETURNS TABLE(petugas character varying, pusat integer, daerah integer, luar_negeri integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_petugas integer;
    jml_pusat integer;
    jml_daerah integer;
    jml_luar integer;
    jml_lainnya integer;
    bpetugas varchar(255);
    anip varchar(255);
    i integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_petugas') THEN DROP TABLE lap_petugas;
	END IF;
	
	CREATE TABLE lap_petugas (
	apetugas varchar(255),
	apusat integer,
	adaerah integer,
	aluar_negeri integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_petugas') THEN DROP TABLE m_petugas;
	END IF;
	
	CREATE TABLE m_petugas (
	id serial,
	nip varchar(255),
	nm_petugas varchar(255)
	);

	INSERT into m_petugas(nip,nm_petugas) SELECT nip,nama from m_user WHERE nip != '99' AND level_user = '2' order by nama;

	SELECT count(*) INTO jml_petugas from m_petugas;

	i := 1;
	while(i <= jml_petugas)
	LOOP
		
		SELECT nip INTO anip from m_petugas WHERE id = i;
		
		SELECT Count(*) INTO jml_pusat from t_publikasi where substring(kd_bahan_pustaka,1,2) = '11' and nip = anip and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT Count(*) INTO jml_daerah from t_publikasi where substring(kd_bahan_pustaka,1,2) = '12' and nip = anip and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT Count(*) INTO jml_luar from t_publikasi where substring(kd_bahan_pustaka,1,2) = '22' and nip = anip and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT Count(*) INTO jml_lainnya from t_publikasi where substring(kd_bahan_pustaka,1,2) != '11' and substring(kd_bahan_pustaka,1,2) != '12' and substring(kd_bahan_pustaka,1,2) != '22' and nip = anip and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT nm_petugas INTO bpetugas FROM m_petugas WHERE id = i;
		
		INSERT INTO lap_petugas values (bpetugas,jml_pusat,jml_daerah,jml_luar,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap_petugas ;
    
END 
$$;


--
-- TOC entry 281 (class 1255 OID 17130)
-- Dependencies: 846 5
-- Name: laporan_petugas_bulan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_petugas_bulan(atahun character varying) RETURNS TABLE(bulan character varying, pusat integer, daerah integer, luar_negeri integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_bulan integer;
    jml_pusat integer;
    jml_daerah integer;
    jml_luar integer;
    jml_lainnya integer;
    bbulan varchar(255);
    nmbulan varchar(255);
    i integer;
 
BEGIN

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_petugas') THEN DROP TABLE lap_petugas;
	END IF;
	
	CREATE TABLE lap_petugas (
	cbulan varchar(255),
	apusat integer,
	adaerah integer,
	aluar_negeri integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'm_bulan') THEN DROP TABLE m_bulan;
	END IF;
	
	CREATE TABLE m_bulan (
	id serial,
	kd_bulan varchar,
	nm_bulan varchar(255)
	);

	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('1','Januari');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('2','Februari');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('3','Maret');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('4','April');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('5','Mei');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('6','Juni');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('7','Juli');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('8','Agustus');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('9','September');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('10','Oktober');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('11','November');
	INSERT into m_bulan(kd_bulan,nm_bulan) VALUES('12','Desember');

	SELECT count(*) INTO jml_bulan from m_bulan;

	i := 1;
	while(i <= jml_bulan)
	LOOP
		
		SELECT kd_bulan INTO bbulan from m_bulan WHERE id = i;
		
		SELECT count(*) INTO jml_pusat from t_publikasi where substring(kd_bahan_pustaka,1,2) = '11' and CAST(date_part('Month',tgl_entri)as VARCHAR)= bbulan and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT count(*) INTO jml_daerah from t_publikasi where substring(kd_bahan_pustaka,1,2) = '12' and CAST(date_part('Month',tgl_entri)as VARCHAR)= bbulan and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT count(*) INTO jml_luar from t_publikasi where substring(kd_bahan_pustaka,1,2) = '22' and CAST(date_part('Month',tgl_entri)as VARCHAR)= bbulan and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT count(*) INTO jml_lainnya from t_publikasi where substring(kd_bahan_pustaka,1,2) != '11' and CAST(date_part('Month',tgl_entri)as VARCHAR)= bbulan and substring(kd_bahan_pustaka,1,2) != '12' and substring(kd_bahan_pustaka,1,2) != '22' and CAST(extract(year from tgl_entri) as VARCHAR) = atahun;
		SELECT nm_bulan INTO nmbulan FROM m_bulan WHERE id = i;
		
		INSERT INTO lap_petugas values (nmbulan,jml_pusat,jml_daerah,jml_luar,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap_petugas ;
    
END 
$$;


--
-- TOC entry 288 (class 1255 OID 17131)
-- Dependencies: 5 846
-- Name: laporan_prop(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_prop(atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1'  and kd_kab = '00' and kd_kec = '000' and kd_prop != '00' order by kd_prop;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 289 (class 1255 OID 17132)
-- Dependencies: 5 846
-- Name: laporan_prop2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_prop2() RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1'  and kd_kab = '00' and kd_kec = '000' and kd_prop != '00' order by kd_prop;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121';
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122';
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122';
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 290 (class 1255 OID 17133)
-- Dependencies: 846 5
-- Name: laporan_propsc(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_propsc(atahun character varying) RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1'  and kd_kab = '00' and kd_kec = '000' and kd_prop != '00' order by kd_prop;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and tahun_terbit = atahun and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 291 (class 1255 OID 17134)
-- Dependencies: 5 846
-- Name: laporan_propsc2(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_propsc2() RETURNS TABLE(kode_wilda character varying, wilayah character varying, dda integer, statda integer, lainnya integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml_wilda integer;
    jml_dda integer;
    jml_statda integer;
    jml_lainnya integer;
    nm_wilayah varchar(255);
    i integer;
    aprod varchar(255);
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap') THEN DROP TABLE lap;
	END IF;
	
	CREATE TABLE lap (
	akode_wilda varchar(255),
	awilayah varchar(255),
	adda integer,
	astatda integer,
	alainnya integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'wilda') THEN DROP TABLE wilda;
	END IF;
	
	CREATE TABLE wilda (
	id serial,
	kd_prop varchar(255),
	kd_kab varchar(255),
	kd_kec varchar(255),
	no_urut varchar(255),
	nm_wilda varchar(255)
	);

	INSERT into wilda(kd_prop,kd_kab,kd_kec,no_urut,nm_wilda) SELECT kd_prop,kd_kab,kd_kec,no_urut,nm_wilda from t_history_wilda where is_active = '1'  and kd_kab = '00' and kd_kec = '000' and kd_prop != '00' order by kd_prop;

	SELECT count(*) INTO jml_wilda from wilda;

	i := 1;
	while(i <= jml_wilda)
	LOOP
		
		SELECT kd_prop||kd_kab||kd_kec||no_urut INTO aprod from wilda WHERE id = i;
		
		SELECT count(*) INTO jml_dda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='121' and flag_s is not null;
		SELECT count(*) INTO jml_statda from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka ='122' and flag_s is not null;
		SELECT count(*) INTO jml_lainnya from t_publikasi where kd_produsen = aprod and kd_bahan_pustaka !='121' and kd_bahan_pustaka !='122' and flag_s is not null;
		SELECT nm_wilda INTO nm_wilayah from wilda WHERE id = i;
		
		INSERT INTO lap values (substring(aprod,1,7),nm_wilayah,jml_dda,jml_statda,jml_lainnya);
		i := i + 1;
	END LOOP;

	
	RETURN QUERY SELECT * from lap ;
    
END 
$$;


--
-- TOC entry 292 (class 1255 OID 17135)
-- Dependencies: 846 5
-- Name: laporan_pusat_dephc(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc(abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
		
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 293 (class 1255 OID 17136)
-- Dependencies: 5 846
-- Name: laporan_pusat_dephc(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc(abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
		
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 294 (class 1255 OID 17137)
-- Dependencies: 846 5
-- Name: laporan_pusat_dephc_nonbulan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc_nonbulan(atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;

		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 295 (class 1255 OID 17138)
-- Dependencies: 5 846
-- Name: laporan_pusat_dephc_nonbulan(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc_nonbulan(atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;

		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 296 (class 1255 OID 17139)
-- Dependencies: 846 5
-- Name: laporan_pusat_dephc_nontahun(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc_nontahun() RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;

	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 297 (class 1255 OID 17140)
-- Dependencies: 5 846
-- Name: laporan_pusat_dephc_nontahun(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dephc_nontahun(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;

	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 298 (class 1255 OID 17141)
-- Dependencies: 846 5
-- Name: laporan_pusat_depsc(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc(abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 299 (class 1255 OID 17142)
-- Dependencies: 5 846
-- Name: laporan_pusat_depsc(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc(abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 300 (class 1255 OID 17143)
-- Dependencies: 846 5
-- Name: laporan_pusat_depsc_nonbulan(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc_nonbulan(atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 301 (class 1255 OID 17144)
-- Dependencies: 846 5
-- Name: laporan_pusat_depsc_nonbulan(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc_nonbulan(atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 302 (class 1255 OID 17145)
-- Dependencies: 5 846
-- Name: laporan_pusat_depsc_nontahun(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc_nontahun() RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 303 (class 1255 OID 17146)
-- Dependencies: 5 846
-- Name: laporan_pusat_depsc_nontahun(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_depsc_nontahun(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) ='000' and kd_unit_kerja != '00000' order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 304 (class 1255 OID 17147)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirhc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
    
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 305 (class 1255 OID 17148)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirhc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
    
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 306 (class 1255 OID 17149)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirhc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;

		SELECT sum(jml) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 307 (class 1255 OID 17150)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirhc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;

		SELECT sum(jml) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 308 (class 1255 OID 17151)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirhc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 309 (class 1255 OID 17152)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirhc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirhc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 310 (class 1255 OID 17153)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirsc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 311 (class 1255 OID 17154)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirsc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 312 (class 1255 OID 17155)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirsc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 313 (class 1255 OID 17156)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirsc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 314 (class 1255 OID 17157)
-- Dependencies: 5 846
-- Name: laporan_pusat_dirsc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
    
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 315 (class 1255 OID 17158)
-- Dependencies: 846 5
-- Name: laporan_pusat_dirsc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_dirsc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
    
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1' and substring(kd_unit_kerja,3,3) !='000' and substring(kd_unit_kerja,4,2) ='00' and substring(kd_unit_kerja,1,2) = substring(akode,1,2) order by kd_unit_kerja;

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from t_publikasi where kd_produsen = aprod;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat ;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 316 (class 1255 OID 17159)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksihc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 317 (class 1255 OID 17160)
-- Dependencies: 5 846
-- Name: laporan_pusat_seksihc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 318 (class 1255 OID 17161)
-- Dependencies: 5 846
-- Name: laporan_pusat_seksihc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 319 (class 1255 OID 17162)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksihc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 320 (class 1255 OID 17163)
-- Dependencies: 5 846
-- Name: laporan_pusat_seksihc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 321 (class 1255 OID 17164)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksihc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksihc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 322 (class 1255 OID 17165)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksisc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 323 (class 1255 OID 17166)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksisc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 324 (class 1255 OID 17167)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksisc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;	
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 325 (class 1255 OID 17168)
-- Dependencies: 5 846
-- Name: laporan_pusat_seksisc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;	
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 326 (class 1255 OID 17169)
-- Dependencies: 5 846
-- Name: laporan_pusat_seksisc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 327 (class 1255 OID 17170)
-- Dependencies: 846 5
-- Name: laporan_pusat_seksisc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_seksisc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) !='0' and substring(kd_unit_kerja,1,4) = substring(akode,1,4) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 328 (class 1255 OID 17171)
-- Dependencies: 846 5
-- Name: laporan_pusat_subdirhc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 329 (class 1255 OID 17172)
-- Dependencies: 846 5
-- Name: laporan_pusat_subdirhc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 330 (class 1255 OID 17173)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirhc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 331 (class 1255 OID 17174)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirhc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
END 
$$;


--
-- TOC entry 332 (class 1255 OID 17175)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirhc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 333 (class 1255 OID 17176)
-- Dependencies: 846 5
-- Name: laporan_pusat_subdirhc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirhc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	sum_total := 0;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_h = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_h = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		sum_total := sum_total + jml;
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		INSERT INTO lap_pusat values('Total','--','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP table lap_pusat ;
    
END 
$$;


--
-- TOC entry 334 (class 1255 OID 17177)
-- Dependencies: 846 5
-- Name: laporan_pusat_subdirsc(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc(akode character varying, abulan character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 335 (class 1255 OID 17178)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirsc(character varying, character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc(akode character varying, abulan character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and bulan_terbit = abulan and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 336 (class 1255 OID 17179)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirsc_nonbulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc_nonbulan(akode character varying, atahun character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 337 (class 1255 OID 17180)
-- Dependencies: 846 5
-- Name: laporan_pusat_subdirsc_nonbulan(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc_nonbulan(akode character varying, atahun character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and tahun_terbit = atahun and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and tahun_terbit = atahun and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
END 
$$;


--
-- TOC entry 338 (class 1255 OID 17181)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirsc_nontahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc_nontahun(akode character varying) RETURNS TABLE(bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 339 (class 1255 OID 17182)
-- Dependencies: 5 846
-- Name: laporan_pusat_subdirsc_nontahun(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_pusat_subdirsc_nontahun(akode character varying, bkd_unit_kerja character varying, bunit_kerja character varying, bkd_subyek character varying, bjml integer) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$

DECLARE
    jml integer;
    nm_unit varchar(255);
    i integer;
    jmlunit integer;
    aprod varchar(255);
    katalog varchar(255);
    katalog_k varchar(255);
    j integer;
    k integer;
    sum_total integer;
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_pusat') THEN DROP TABLE lap_pusat;
	END IF;
	
	CREATE TABLE lap_pusat (
	akode_unit_kerja varchar(255),
	aunit_kerja varchar(255),
	akatalog varchar(255),
	ajml integer
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'unit_kerja') THEN DROP TABLE unit_kerja;
	END IF;
	
	CREATE TABLE unit_kerja (
	id serial,
	kd_unit_kerja varchar(255),
	nm_unit_kerja varchar(255)
	);

	INSERT into unit_kerja(kd_unit_kerja,nm_unit_kerja) SELECT kd_unit_kerja||no_urut,unit_kerja from t_history_unit_kerja where is_active = '1'  and substring(kd_unit_kerja,5,1) ='0' and substring(kd_unit_kerja,4,2) !='00' and substring(kd_unit_kerja,1,3) = substring(akode,1,3) order by kd_unit_kerja;

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'subyek') THEN DROP TABLE subyek;
	END IF;
	CREATE TABLE subyek (
	id serial,
	kd_subyek varchar(255)
	);

	SELECT count(*) INTO jmlunit from unit_kerja;

	i := 1;
	k := 1;
	while(i <= jmlunit)
	LOOP
		SELECT kd_unit_kerja INTO aprod from unit_kerja WHERE id = i;
		SELECT nm_unit_kerja INTO nm_unit from unit_kerja WHERE id = i;
		INSERT INTO subyek(kd_subyek) SELECT kd_subyek FROM t_publikasi WHERE kd_produsen = aprod and flag_s = '1';
		SELECT count(*) INTO j FROM subyek;
		while(k <= j)
		LOOP
		SELECT kd_subyek INTO katalog_k  from subyek where id = k;
		SELECT jml_eks INTO jml from t_publikasi where kd_produsen = aprod and kd_subyek = katalog_k and flag_s = '1';
		INSERT INTO lap_pusat values (aprod,nm_unit,katalog_k,jml);
		k := k + 1;
		END LOOP;
		i := i + 1;
		
	END LOOP;
		SELECT count(*) INTO sum_total from lap_pusat;
		
		INSERT INTO lap_pusat values('Total','--',sum_total);
	
	RETURN QUERY SELECT * from lap_pusat;
	DROP TABLE lap_pusat;
    
END 
$$;


--
-- TOC entry 340 (class 1255 OID 17183)
-- Dependencies: 5 846
-- Name: laporan_simak_bulan(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_simak_bulan(atahun character varying, abulan character varying) RETURNS TABLE(bjudul character varying, beks integer, bkondisi character varying, bhal integer, bharga numeric, bpengirim character varying, bbukti character varying, bnilai numeric)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jmlbuku integer;
    cjudul varchar(255);
	ceks integer;
	ckondisi varchar(255);
	chal integer;
	charga numeric(8,2);
	cpengirim varchar(255);
	cbukti varchar(255);
	cnilai numeric(8,2);
	cid varchar(255);
	dkondisi varchar(255);
	i integer;
	j integer;
	jumlah integer;
	
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_simak') THEN DROP TABLE lap_simak;
	END IF;
	
	CREATE TABLE lap_simak (
	ajudul varchar(255),
	aeks integer,
	akondisi varchar(255),
	ahal integer,
	aharga numeric(8,2),
	apengirim varchar(255),
	abukti varchar(255),
	anilai numeric(8,2)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'eks_buku') THEN DROP TABLE eks_buku;
	END IF;
	
	CREATE TABLE eks_buku (
	id serial,
	id_publikasi varchar(255),
	jml_eks varchar(255)
	);

	INSERT into eks_buku(id_publikasi,jml_eks) SELECT id_publikasi,jml_eks from t_publikasi where  is_full_entry = '1' and thn_terima = atahun and bln_terima = abulan  order by id_publikasi;

	SELECT count(*) INTO jmlbuku from eks_buku;
	
	i := 1;
	while(i <= jmlbuku)
	LOOP
		
		SELECT id_publikasi INTO cid from eks_buku WHERE id = i;
		SELECT judul INTO cjudul from t_publikasi WHERE id_publikasi = cid;
		SELECT count(*) INTO ceks from t_pub_lokasi WHERE id_publikasi = cid;
		j := 1; dkondisi := '';
		while(j <= ceks)
			LOOP
			
			SELECT b.kondisi INTO ckondisi
			from t_pub_lokasi b,(select id_publikasi,no_eks,row_number() over (order by id_publikasi,no_eks) as no from t_pub_lokasi WHERE id_publikasi = cid) a 
			WHERE b.id_publikasi = cid and a.no = j and b.id_publikasi = a.id_publikasi and b.no_eks = a.no_eks
			order by b.id_publikasi,b.no_eks;
			IF (ckondisi = '1') THEN ckondisi := 'BAIK'; 
			ELSE IF (ckondisi = '2') THEN ckondisi := 'SEDANG';
			ELSE IF (ckondisi = '3') THEN ckondisi := 'BURUK';
			END IF;
			END IF;
			END IF;	
			--dkondisi := ckondisi || ',';
			dkondisi := dkondisi || ckondisi || ' ';
			j := j + 1;
			
		END LOOP;
		SELECT jml_hal INTO chal FROM t_publikasi WHERE id_publikasi = cid;
		SELECT jml_eks INTO jumlah FROM t_publikasi WHERE id_publikasi = cid;
		SELECT harga_perolehan INTO charga FROM t_publikasi WHERE id_publikasi = cid;
		SELECT pengirim INTO cpengirim FROM t_buku_induk WHERE id_publikasi = cid;
		
			 IF(cpengirim = '1') THEN cpengirim := 'Publikasi BPS Provinsi Sendiri';
			 ELSE IF(cpengirim = '2') THEN cpengirim := 'Publikasi BPS Kab/Kota Dalam Provinsi';
			 ELSE IF(cpengirim = '3') THEN cpengirim :=  'Publikasi BPS Provinsi Lain';
			 ELSE IF(cpengirim = '4') THEN cpengirim :=  'Publikasi BPS RI';
			 ELSE IF(cpengirim = '5') THEN cpengirim :=  'Publikasi Luar BPS';

			 END IF;
			 END IF;
			 END IF;
			 END IF;
			 END IF;
			
		SELECT bukti_terima INTO cbukti FROM t_buku_induk WHERE id_publikasi = cid;
		cnilai := charga * ceks;
		INSERT INTO lap_simak values (cjudul,jumlah,dkondisi,chal,charga,cpengirim,cbukti,cnilai);
		i := i + 1;
		
	END LOOP;

	
	RETURN QUERY SELECT * from lap_simak ;
    
END 
$$;


--
-- TOC entry 341 (class 1255 OID 17184)
-- Dependencies: 846 5
-- Name: laporan_simak_tahun(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION laporan_simak_tahun(atahun character varying) RETURNS TABLE(bjudul character varying, beks integer, bkondisi character varying, bhal integer, bharga numeric, bpengirim character varying, bbukti character varying, bnilai numeric)
    LANGUAGE plpgsql
    AS $$

DECLARE
    jmlbuku integer;
    cjudul varchar(255);
	ceks integer;
	ckondisi varchar(255);
	chal integer;
	charga numeric(8,2);
	cpengirim varchar(255);
	cbukti varchar(255);
	cnilai numeric(8,2);
	cid varchar(255);
	dkondisi varchar(255);
	i integer;
	j integer;
	jumlah integer;
	
   
BEGIN
	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'lap_simak') THEN DROP TABLE lap_simak;
	END IF;
	
	CREATE TABLE lap_simak (
	ajudul varchar(255),
	aeks integer,
	akondisi varchar(255),
	ahal integer,
	aharga numeric(8,2),
	apengirim varchar(255),
	abukti varchar(255),
	anilai numeric(8,2)
	);

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'eks_buku') THEN DROP TABLE eks_buku;
	END IF;
	
	CREATE TABLE eks_buku (
	id serial,
	id_publikasi varchar(255),
	jml_eks varchar(255)
	);

	INSERT into eks_buku(id_publikasi,jml_eks) SELECT id_publikasi,jml_eks from t_publikasi where is_full_entry = '1' and thn_terima = atahun  order by id_publikasi;

	SELECT count(*) INTO jmlbuku from eks_buku;
	
	i := 1;
	while(i <= jmlbuku)
	LOOP
		
		SELECT id_publikasi INTO cid from eks_buku WHERE id = i;
		SELECT judul INTO cjudul from t_publikasi WHERE id_publikasi = cid;
		SELECT count(*) INTO ceks from t_pub_lokasi WHERE id_publikasi = cid;
		j := 1; dkondisi := '';
		while(j <= ceks)
			LOOP
			
			SELECT b.kondisi INTO ckondisi
			from t_pub_lokasi b,(select id_publikasi,no_eks,row_number() over (order by id_publikasi,no_eks) as no from t_pub_lokasi WHERE id_publikasi = cid) a 
			WHERE b.id_publikasi = cid and a.no = j and b.id_publikasi = a.id_publikasi and b.no_eks = a.no_eks
			order by b.id_publikasi,b.no_eks;
			IF (ckondisi = '1') THEN ckondisi := 'BAIK'; 
			ELSE IF (ckondisi = '2') THEN ckondisi := 'SEDANG';
			ELSE IF (ckondisi = '3') THEN ckondisi := 'BURUK';
			END IF;
			END IF;
			END IF;	
			--dkondisi := ckondisi || ',';
			dkondisi := dkondisi || ckondisi || ' ';
			j := j + 1;
			
		END LOOP;
		SELECT jml_hal INTO chal FROM t_publikasi WHERE id_publikasi = cid;
		SELECT jml_eks INTO jumlah FROM t_publikasi WHERE id_publikasi = cid;
		SELECT harga_perolehan INTO charga FROM t_publikasi WHERE id_publikasi = cid;
		SELECT pengirim INTO cpengirim FROM t_buku_induk WHERE id_publikasi = cid;
		
			 IF(cpengirim = '1') THEN cpengirim := 'Publikasi BPS Provinsi Sendiri';
			 ELSE IF(cpengirim = '2') THEN cpengirim := 'Publikasi BPS Kab/Kota Dalam Provinsi';
			 ELSE IF(cpengirim = '3') THEN cpengirim :=  'Publikasi BPS Provinsi Lain';
			 ELSE IF(cpengirim = '4') THEN cpengirim :=  'Publikasi BPS RI';
			 ELSE IF(cpengirim = '5') THEN cpengirim :=  'Publikasi Luar BPS';

			 END IF;
			 END IF;
			 END IF;
			 END IF;
			 END IF;
			
		SELECT bukti_terima INTO cbukti FROM t_buku_induk WHERE id_publikasi = cid;
		cnilai := charga * ceks;
		INSERT INTO lap_simak values (cjudul,jumlah,dkondisi,chal,charga,cpengirim,cbukti,cnilai);
		i := i + 1;
		
	END LOOP;

	
	RETURN QUERY SELECT * from lap_simak ;
    
END 
$$;


--
-- TOC entry 342 (class 1255 OID 17185)
-- Dependencies: 5 846
-- Name: reorder(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION reorder() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlduplicate integer;
	maxno integer;
	i integer;
	j integer;
	nobaru integer;
	id_pub character varying[] = '{}';
	noduplicate integer[] = '{}';

BEGIN
-- jumlah publikasi yang harus direorder
	SELECT array_agg(distinct(id_publikasi)) INTO id_pub FROM migtemp 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtemp GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	SELECT count(distinct(id_publikasi)) INTO jumlah FROM migtemp 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtemp GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	i := 1;
	WHILE i<= jumlah loop
		SELECT count(*) INTO jmlduplicate
		FROM migtemp  WHERE id_publikasi = id_pub[i];
		SELECT array_agg(nomor) INTO noduplicate
		FROM migtemp  WHERE id_publikasi = id_pub[i];

		j := 2;
		WHILE j <= jmlduplicate loop
			SELECT max(cast(no_bi as integer)) INTO maxno FROM migtemp WHERE substring(id_publikasi,1,9) = substring(id_pub[i],1,9);
			nobaru := maxno+1;
			UPDATE migtemp SET no_bi = trim(to_char(nobaru,'0000')) WHERE nomor = noduplicate[j] ;
		j := j+1;
		END LOOP;
	i := i+1;
	END LOOP;

	UPDATE migtemp SET id_publikasi = substring(id_publikasi, 1,9)||no_bi 
		WHERE id_publikasi IN 
		(SELECT id_publikasi FROM migtemp GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	RETURN;

END;
$$;


--
-- TOC entry 343 (class 1255 OID 17186)
-- Dependencies: 5 846
-- Name: reorder123(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION reorder123() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlduplicate integer;
	maxno integer;
	i integer;
	j integer;
	nobaru integer;
	id_pub character varying[] = '{}';
	noduplicate integer[] = '{}';

BEGIN
-- jumlah publikasi yang harus direorder
	SELECT array_agg(distinct(id_publikasi)) INTO id_pub FROM migtemp123 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtemp123 GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	SELECT count(distinct(id_publikasi)) INTO jumlah FROM migtemp123 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtemp123 GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	i := 1;
	WHILE i<= jumlah loop
		SELECT count(*) INTO jmlduplicate
		FROM migtemp123  WHERE id_publikasi = id_pub[i];
		SELECT array_agg(nomor) INTO noduplicate
		FROM migtemp123  WHERE id_publikasi = id_pub[i];

		j := 2;
		WHILE j <= jmlduplicate loop
			SELECT max(cast(no_bi as integer)) INTO maxno FROM migtemp123 WHERE substring(id_publikasi,1,9) = substring(id_pub[i],1,9);
			nobaru := maxno+1;
			UPDATE migtemp123 SET no_bi = trim(to_char(nobaru,'0000')) WHERE nomor = noduplicate[j] ;
		j := j+1;
		END LOOP;
	i := i+1;
	END LOOP;

	UPDATE migtemp123 SET id_publikasi = substring(id_publikasi, 1,9)||no_bi 
		WHERE id_publikasi IN 
		(SELECT id_publikasi FROM migtemp123 GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	RETURN;

END;
$$;


--
-- TOC entry 344 (class 1255 OID 17187)
-- Dependencies: 5 846
-- Name: reorderdda(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION reorderdda() RETURNS void
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	jumlah integer;
	jmlduplicate integer;
	maxno integer;
	i integer;
	j integer;
	nobaru integer;
	id_pub character varying[] = '{}';
	noduplicate integer[] = '{}';

BEGIN
-- jumlah publikasi yang harus direorder
	SELECT array_agg(distinct(id_publikasi)) INTO id_pub FROM migtempdda 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtempdda GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	SELECT count(distinct(id_publikasi)) INTO jumlah FROM migtempdda 
	WHERE id_publikasi IN 
	(SELECT id_publikasi FROM migtempdda GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	i := 1;
	WHILE i<= jumlah loop
		SELECT count(*) INTO jmlduplicate
		FROM migtempdda  WHERE id_publikasi = id_pub[i];
		SELECT array_agg(nomor) INTO noduplicate
		FROM migtempdda  WHERE id_publikasi = id_pub[i];

		j := 2;
		WHILE j <= jmlduplicate loop
			SELECT max(cast(no_bi as integer)) INTO maxno FROM migtempdda WHERE substring(id_publikasi,1,9) = substring(id_pub[i],1,9);
			nobaru := maxno+1;
			UPDATE migtempdda SET no_bi = trim(to_char(nobaru,'0000')) WHERE nomor = noduplicate[j] ;
		j := j+1;
		END LOOP;
	i := i+1;
	END LOOP;

	UPDATE migtempdda SET id_publikasi = substring(id_publikasi, 1,9)||no_bi 
		WHERE id_publikasi IN 
		(SELECT id_publikasi FROM migtempdda GROUP BY id_publikasi HAVING Count(id_publikasi)>1 order by id_publikasi);

	RETURN;

END;
$$;


--
-- TOC entry 345 (class 1255 OID 17188)
-- Dependencies: 5 846
-- Name: tampil_wilda(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION tampil_wilda(kdprop character varying, kdkab character varying, kdkec character varying) RETURNS TABLE(no character, prop character varying, kab character varying, kec character varying, wilda character varying, bln character, thn character, stat character varying)
    LANGUAGE plpgsql
    AS $$ 

DECLARE 
	noactive character varying;
	nomin character varying;
	kd_lama character varying;
BEGIN
	SELECT no_urut INTO noactive
	FROM t_history_wilda
	WHERE kd_prop=kdProp AND kd_kab=kdKab AND kd_kec=kdKec AND is_active ='1';

	IF EXISTS (SELECT * FROM information_schema.tables where table_name = 'temp') THEN DROP TABLE temp;
	END IF;
	CREATE TABLE temp(
		  no_urut char(4),
		  kd_prop varchar(2),
		  kd_kab varchar(2),
		  kd_kec varchar(3),
		  kd_prop_lama varchar(2),
		  kd_kab_lama varchar(2),
		  kd_kec_lama varchar(3),
		  no_urut_lama char(4),
		  nm_wilda varchar(100),
		  bulan char(2),
		  tahun char(4),
		  is_active varchar(9)
		  );

	INSERT INTO temp(no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun, is_active)
	SELECT no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun,
	       CASE WHEN is_active = '1' THEN 'active'
		    ELSE 'inactive'
	       END
	FROM t_history_wilda
	WHERE kd_prop=kdProp AND kd_kab=kdKab AND kd_kec=kdKec AND is_active='1';

	SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
	FROM temp
	WHERE kd_prop=kdprop AND kd_kab=kdkab AND kd_kec=kdkec AND no_urut = noactive;

	SELECT min(no_urut) INTO nomin FROM temp;

	WHILE kd_lama IS NOT NULL loop
		INSERT INTO temp(no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun, is_active)
		SELECT no_urut, kd_prop, kd_kab, kd_kec, kd_prop_lama, kd_kab_lama, kd_kec_lama, no_urut_lama, nm_wilda, bulan, tahun,
		       CASE WHEN is_active = '1' THEN 'active'
			    ELSE 'inactive'
		       END
		FROM t_history_wilda
		WHERE kd_prop||kd_kab||kd_kec||no_urut IN 
			(SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama FROM temp WHERE no_urut = nomin);

		SELECT min(no_urut) INTO nomin FROM temp;

		SELECT kd_prop_lama||kd_kab_lama||kd_kec_lama||no_urut_lama INTO kd_lama
		FROM temp
		WHERE no_urut = nomin;

	END loop;

	RETURN QUERY(SELECT no_urut, kd_prop, kd_kab, kd_kec, nm_wilda, bulan, tahun, is_active FROM temp);
	
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 142 (class 1259 OID 17189)
-- Dependencies: 5
-- Name: t_application_settings; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_application_settings (
    id integer NOT NULL,
    server_name character varying(100),
    server_ip character varying(100),
    pdf_folder character varying(100),
    cover_folder character varying(100),
    map_foler character varying(100),
    ftp_server character varying,
    ftp_username character varying(50),
    ftp_password character varying(50)
);


--
-- TOC entry 143 (class 1259 OID 17195)
-- Dependencies: 142 5
-- Name: application_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE application_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2362 (class 0 OID 0)
-- Dependencies: 143
-- Name: application_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE application_settings_id_seq OWNED BY t_application_settings.id;


--
-- TOC entry 144 (class 1259 OID 17197)
-- Dependencies: 5
-- Name: bukutamu; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bukutamu (
    bukutamu_th character varying(4) NOT NULL,
    bukutamu_bl character varying(2) NOT NULL,
    bukutamu_tg character varying(2) NOT NULL,
    bukutamu_id character varying(3) NOT NULL,
    bukutamu_profile character varying(11),
    bukutamu_tgl date,
    bukutamu_wkta time without time zone,
    bukutamu_wktb time without time zone,
    bukutamu_layanan character varying(3),
    bukutamu_pc character varying(18),
    bukutamu_dt_nas character varying(20),
    bukutamu_dt_reg character varying(20),
    bukutamu_dl character varying(100),
    bukutamu_nolock character varying(3),
    bukutamu_los character varying(3),
    bukutamu_jum character varying(3),
    bukutamu_o character varying(10),
    bukutamu_group integer,
    bukutamu_petugas character varying(100)
);


--
-- TOC entry 145 (class 1259 OID 17200)
-- Dependencies: 5
-- Name: digilib; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE digilib (
    digilib_id character varying(3) NOT NULL,
    digilib_tgl date NOT NULL,
    digilib_log character varying(11),
    digilib_pc character varying(10),
    digilib_wkta time(6) without time zone,
    digilib_wktb time(6) without time zone,
    digilib_stat character varying(2),
    digilib_app character varying(20),
    digilib_remind character varying(5),
    digilib_durt character varying(5),
    digilib_mesg_s character varying(2),
    digilib_mesg character varying(200),
    digilib_o character varying(10)
);


--
-- TOC entry 146 (class 1259 OID 17203)
-- Dependencies: 5
-- Name: dutym; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dutym (
    dutym_id character varying(3) NOT NULL,
    dutym_tgl date NOT NULL,
    dutym_log character varying(11),
    dutym_wkta time(6) without time zone,
    dutym_wktb time(6) without time zone,
    dutym_app character varying(100),
    dutym_o character varying(10)
);


--
-- TOC entry 147 (class 1259 OID 17206)
-- Dependencies: 5
-- Name: faq; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq (
    faq_id character varying(5) NOT NULL,
    faq_idx character varying(50),
    faq_ans character varying(200)
);


--
-- TOC entry 148 (class 1259 OID 17209)
-- Dependencies: 5
-- Name: faq_a; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_a (
    a_q_id character varying(11) NOT NULL,
    a_nomor integer NOT NULL,
    a_answer text,
    a_username character varying(10),
    a_tgl date,
    a_tgl_edit date,
    a_state character(1)
);


--
-- TOC entry 149 (class 1259 OID 17215)
-- Dependencies: 2180 2181 2182 5
-- Name: faq_q; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE faq_q (
    q_id character varying(11) NOT NULL,
    q_tgl date NOT NULL,
    q_no character varying(3) NOT NULL,
    q_profile character varying(11) NOT NULL,
    q_question text NOT NULL,
    q_tipe integer DEFAULT 0 NOT NULL,
    q_state character(1) DEFAULT 0,
    q_subyek integer,
    is_aktif character(1) DEFAULT 0,
    q_username character varying(10)
);


--
-- TOC entry 150 (class 1259 OID 17224)
-- Dependencies: 5
-- Name: konsultasi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE konsultasi (
    konsultasi_id character varying(3) NOT NULL,
    konsultasi_dutym_id character varying(5),
    konsultasi_dutym_tgl date,
    konsultasi_1 character varying(200),
    konsultasi_2 character varying(200),
    konsultasi_3 character varying(200),
    konsultasi_4 character varying(200),
    konsultasi_5 character varying(200),
    konsultasi_o character varying(10)
);


--
-- TOC entry 151 (class 1259 OID 17230)
-- Dependencies: 5
-- Name: lap_petugas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE lap_petugas (
    cbulan character varying(255),
    apusat integer,
    adaerah integer,
    aluar_negeri integer,
    alainnya integer
);


--
-- TOC entry 152 (class 1259 OID 17233)
-- Dependencies: 5
-- Name: logincode; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logincode (
    logincode_id character varying(4) NOT NULL,
    logincode_tg character varying(10) NOT NULL,
    logincode_profile character varying(11),
    logincode_code character varying(4),
    logincode_max character varying(1),
    logincode_use character varying(1),
    logincode_o character varying(10)
);


--
-- TOC entry 153 (class 1259 OID 17236)
-- Dependencies: 5
-- Name: lokasi_sk_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE lokasi_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 154 (class 1259 OID 17238)
-- Dependencies: 5
-- Name: m_bahasa; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_bahasa (
    kd_bahasa integer NOT NULL,
    bahasa character varying(25) NOT NULL
);


--
-- TOC entry 155 (class 1259 OID 17241)
-- Dependencies: 5
-- Name: m_benua; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_benua (
    kd_benua character varying(2) NOT NULL,
    benua character varying(20) NOT NULL,
    kd_ddc character varying(6) NOT NULL
);


--
-- TOC entry 156 (class 1259 OID 17244)
-- Dependencies: 5
-- Name: m_buku; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_buku (
    nip character varying NOT NULL,
    wilda character varying,
    judul character varying,
    status character(1),
    eksemplar character(2),
    wilda_baru character varying,
    nip_baru character varying,
    judul_baru character varying,
    catatan character varying,
    kode_bahan_pustaka character(2),
    flag character(1),
    harga character varying(40),
    wilda_id character varying(2),
    kode_excel character varying(1),
    flag2 character(1),
    jenis_kertas character varying(2),
    halaman character varying(40),
    flag_final character(1),
    tahun character varying(10),
    flagscan character(1),
    flag_compare_migrasi character(1),
    flag_compare_djkom character(1)
);


--
-- TOC entry 157 (class 1259 OID 17250)
-- Dependencies: 5
-- Name: m_bulan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_bulan (
    id integer NOT NULL,
    kd_bulan character varying,
    nm_bulan character varying(255)
);


--
-- TOC entry 158 (class 1259 OID 17256)
-- Dependencies: 5
-- Name: m_bulan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_bulan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 159 (class 1259 OID 17258)
-- Dependencies: 5 157
-- Name: m_bulan_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_bulan_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2363 (class 0 OID 0)
-- Dependencies: 159
-- Name: m_bulan_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE m_bulan_id_seq1 OWNED BY m_bulan.id;


--
-- TOC entry 160 (class 1259 OID 17260)
-- Dependencies: 5
-- Name: m_ddc; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_ddc (
    kd_ddc character varying(25) NOT NULL,
    ddc character varying(100) NOT NULL
);


--
-- TOC entry 161 (class 1259 OID 17263)
-- Dependencies: 5
-- Name: m_identitas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_identitas (
    kd_prop character(2) NOT NULL,
    kd_kab character(2) NOT NULL,
    nm_daerah character varying(50) NOT NULL
);


--
-- TOC entry 162 (class 1259 OID 17266)
-- Dependencies: 5
-- Name: m_info; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_info (
    kd_info integer NOT NULL,
    tgl_entri date NOT NULL,
    judul_info character varying(255) NOT NULL,
    info text NOT NULL
);


--
-- TOC entry 163 (class 1259 OID 17272)
-- Dependencies: 5
-- Name: m_instansi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_instansi (
    kd_instansi character(3) NOT NULL,
    kd_negara character(3) NOT NULL,
    instansi character varying(75) NOT NULL
);


--
-- TOC entry 164 (class 1259 OID 17275)
-- Dependencies: 5
-- Name: m_jenis_bahan_pustaka; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_jenis_bahan_pustaka (
    kd_bahan_pustaka character(3) NOT NULL,
    jenis_bahan_pustaka character varying(50) NOT NULL,
    kd_label integer NOT NULL
);


--
-- TOC entry 165 (class 1259 OID 17278)
-- Dependencies: 2184 2185 5
-- Name: m_kab; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_kab (
    kd_kab character(2) NOT NULL,
    kd_prop character(2) NOT NULL,
    kab character varying(50) NOT NULL,
    is_ibukota character(1) DEFAULT 0 NOT NULL,
    is_independent character(1) DEFAULT 1 NOT NULL,
    kd_kab_induk character varying(4)
);


--
-- TOC entry 166 (class 1259 OID 17283)
-- Dependencies: 2186 2187 5
-- Name: m_kec; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_kec (
    kd_kec character(3) NOT NULL,
    kd_kab character(2) NOT NULL,
    kd_prop character(2) NOT NULL,
    kec character varying(50) NOT NULL,
    is_ibukota character(1) DEFAULT 0 NOT NULL,
    is_ksk character(1) DEFAULT 1 NOT NULL,
    ksk_pengganti character varying(7)
);


--
-- TOC entry 167 (class 1259 OID 17288)
-- Dependencies: 5
-- Name: m_kegiatan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_kegiatan (
    kd_kegiatan integer NOT NULL,
    kegiatan character varying(255),
    kd_unit_baru character varying(5) NOT NULL,
    no_unit_baru integer NOT NULL,
    kd_unit_lama character varying(5),
    no_unit_lama integer
);


--
-- TOC entry 168 (class 1259 OID 17291)
-- Dependencies: 5
-- Name: m_label; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_label (
    kd_label integer NOT NULL,
    label character varying(10) NOT NULL
);


--
-- TOC entry 169 (class 1259 OID 17294)
-- Dependencies: 5
-- Name: m_level; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_level (
    kd_level character varying(2) NOT NULL,
    level_user character varying(27)
);


--
-- TOC entry 170 (class 1259 OID 17297)
-- Dependencies: 2188 5
-- Name: m_lokasi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_lokasi (
    rak character varying(3) NOT NULL,
    lorong character varying(3) NOT NULL,
    baris character varying(7) NOT NULL,
    p_rak numeric(5,2) DEFAULT 0 NOT NULL,
    ket character varying(100),
    denah text,
    kd_ruang integer NOT NULL
);


--
-- TOC entry 171 (class 1259 OID 17304)
-- Dependencies: 5
-- Name: m_masa_pajang; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_masa_pajang (
    kd_masa_pajang integer NOT NULL,
    masa_pajang character varying(10) NOT NULL
);


--
-- TOC entry 172 (class 1259 OID 17307)
-- Dependencies: 5
-- Name: m_negara; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_negara (
    kd_negara character(3) NOT NULL,
    negara character varying(50) NOT NULL,
    alpha2 character(2),
    alpha3 character(3),
    negara_inggris character varying(50),
    benua character varying(2)
);


--
-- TOC entry 173 (class 1259 OID 17310)
-- Dependencies: 5
-- Name: m_pengadaan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_pengadaan (
    kd_pengadaan character varying(2) NOT NULL,
    pengadaan character varying(50) NOT NULL
);


--
-- TOC entry 174 (class 1259 OID 17313)
-- Dependencies: 5
-- Name: m_periode; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_periode (
    kd_periode character varying(3) NOT NULL,
    periode character varying(25)
);


--
-- TOC entry 175 (class 1259 OID 17316)
-- Dependencies: 5
-- Name: m_petugas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_petugas (
    id integer NOT NULL,
    nip character varying(255),
    nm_petugas character varying(255)
);


--
-- TOC entry 176 (class 1259 OID 17322)
-- Dependencies: 5
-- Name: m_petugas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_petugas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 177 (class 1259 OID 17324)
-- Dependencies: 5 175
-- Name: m_petugas_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_petugas_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2364 (class 0 OID 0)
-- Dependencies: 177
-- Name: m_petugas_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE m_petugas_id_seq1 OWNED BY m_petugas.id;


--
-- TOC entry 178 (class 1259 OID 17326)
-- Dependencies: 5
-- Name: m_produsen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_produsen (
    kd_produsen character varying(12) NOT NULL,
    kd_table character(1) NOT NULL
);


--
-- TOC entry 179 (class 1259 OID 17329)
-- Dependencies: 2190 5
-- Name: m_prop; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_prop (
    kd_prop character(2) NOT NULL,
    prop character varying(50) NOT NULL,
    is_ibukota character(1) DEFAULT 0 NOT NULL
);


--
-- TOC entry 180 (class 1259 OID 17333)
-- Dependencies: 5
-- Name: m_ruang_kd_ruang_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_ruang_kd_ruang_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 181 (class 1259 OID 17335)
-- Dependencies: 2191 5
-- Name: m_ruang; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_ruang (
    ruang character varying(25) NOT NULL,
    kd_ruang integer DEFAULT nextval('m_ruang_kd_ruang_seq'::regclass) NOT NULL
);


--
-- TOC entry 182 (class 1259 OID 17339)
-- Dependencies: 2192 2193 2194 2195 5
-- Name: m_subyek; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_subyek (
    kd_subyek character(7) NOT NULL,
    subyek character varying(300) NOT NULL,
    kd_ddc character varying(25) NOT NULL,
    kd_masa_pajang integer DEFAULT 1 NOT NULL,
    is_tampil character(1) DEFAULT 0 NOT NULL,
    is_wilda character(1) DEFAULT 0 NOT NULL,
    is_judul character(1) DEFAULT 0 NOT NULL,
    judul character varying(255),
    kd_produsen character varying(10),
    is_112 character(1)
);


--
-- TOC entry 183 (class 1259 OID 17349)
-- Dependencies: 5
-- Name: m_table_prod; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_table_prod (
    kd_table character(1) NOT NULL,
    jns_produsen character varying(50) NOT NULL
);


--
-- TOC entry 184 (class 1259 OID 17352)
-- Dependencies: 5
-- Name: m_unit_kerja; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_unit_kerja (
    kd_unit_kerja character varying(5) NOT NULL,
    unit_kerja character varying(100) NOT NULL
);


--
-- TOC entry 185 (class 1259 OID 17355)
-- Dependencies: 5
-- Name: m_user; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_user (
    nip character varying(18) NOT NULL,
    nama character varying(50) NOT NULL,
    user_name character varying(10) NOT NULL,
    pwd character varying(25) NOT NULL,
    level_user character varying(2) NOT NULL
);


--
-- TOC entry 186 (class 1259 OID 17358)
-- Dependencies: 5
-- Name: m_usertab_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE m_usertab_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 187 (class 1259 OID 17360)
-- Dependencies: 2196 5
-- Name: m_usertab; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE m_usertab (
    id integer DEFAULT nextval('m_usertab_id_seq'::regclass) NOT NULL,
    username character varying(20),
    password character varying(50),
    saltpassword character varying(50),
    email character varying(50),
    level integer
);


--
-- TOC entry 188 (class 1259 OID 17364)
-- Dependencies: 5
-- Name: penjualan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE penjualan (
    p_id character varying(11) NOT NULL,
    p_tgl date NOT NULL,
    p_nomor character varying(3),
    p_profile character varying(11),
    p_jam_datang time with time zone,
    p_jam_pulang time with time zone,
    p_petugas character varying(10),
    p_state character varying(1),
    p_no_kui character varying(20),
    p_atas_nama character varying(100),
    p_total_harga integer,
    p_jenis_pembelian character varying(1),
    p_jenis_kui character varying(1),
    p_no_urut_kui character varying(4),
    p_tahun_kui character varying(4)
);


--
-- TOC entry 189 (class 1259 OID 17367)
-- Dependencies: 5
-- Name: penjualan_tr; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE penjualan_tr (
    tr_p_id character varying(11) NOT NULL,
    tr_nomor character varying(3) NOT NULL,
    tr_id_publikasi character varying(13),
    tr_judul character varying(500),
    tr_jumlah integer,
    tr_harga double precision,
    tr_state character varying(1),
    tr_harga_total double precision
);


--
-- TOC entry 190 (class 1259 OID 17373)
-- Dependencies: 5
-- Name: profile; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profile (
    profile_id character(11) NOT NULL,
    profile_idcard character varying(20),
    profile_idtype character(1),
    profile_nama character varying(100),
    profile_almt text,
    profile_jk character varying(12),
    profile_umur character varying(2),
    profile_pend character varying(30),
    profile_pkrj character varying(2),
    profile_wn character varying(50),
    profile_o character varying(10),
    profile_telp character varying(20),
    profile_email character varying(50),
    kd_unit_kerja character varying(5),
    flag character(1),
    group_id integer
);


--
-- TOC entry 191 (class 1259 OID 17379)
-- Dependencies: 5
-- Name: profile_group_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE profile_group_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 192 (class 1259 OID 17381)
-- Dependencies: 2197 5
-- Name: profile_group; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE profile_group (
    group_id integer DEFAULT nextval('profile_group_seq'::regclass) NOT NULL,
    group_name character varying(50) NOT NULL,
    alamat character varying(500),
    jenis_group character(1),
    kd_negara character varying(3),
    tgl_kunjungan date NOT NULL,
    jml_pengunjung integer NOT NULL,
    flag character(1) NOT NULL,
    dt_nas character varying(20),
    dt_reg character varying(20),
    dt_lain character varying(100),
    layanan character varying(3)
);


--
-- TOC entry 193 (class 1259 OID 17388)
-- Dependencies: 5
-- Name: subyek_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subyek_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 194 (class 1259 OID 17390)
-- Dependencies: 2198 5
-- Name: t_buku_induk; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_buku_induk (
    id integer NOT NULL,
    id_publikasi character varying(13) NOT NULL,
    jumlah_eks integer,
    pengirim character varying(1),
    penerima character varying(50),
    bukti_terima character varying(100),
    tgl_terima date,
    tgl_entri date,
    flag_entri character(1) DEFAULT 1,
    nip character varying(18),
    nip_editor character varying(18),
    tgl_edit date,
    jenis_publikasi character varying(3) NOT NULL
);


--
-- TOC entry 195 (class 1259 OID 17394)
-- Dependencies: 5
-- Name: t_buku_table; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_buku_table (
    kd_buku_table integer NOT NULL,
    id_publikasi character varying(13) NOT NULL,
    nm_table text NOT NULL
);


--
-- TOC entry 196 (class 1259 OID 17400)
-- Dependencies: 2199 5
-- Name: t_history_unit_kerja; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_history_unit_kerja (
    kd_unit_kerja character varying(5) NOT NULL,
    no_urut integer NOT NULL,
    unit_kerja character varying(100) NOT NULL,
    kd_unit_lama character varying(5),
    unit_lama character varying(100),
    bulan character(2) NOT NULL,
    tahun character(4) NOT NULL,
    is_active character(1) DEFAULT 1 NOT NULL,
    no_urut_lama integer
);


--
-- TOC entry 197 (class 1259 OID 17404)
-- Dependencies: 2200 5
-- Name: t_history_wilda; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_history_wilda (
    kd_prop character(2) NOT NULL,
    kd_kab character(2) NOT NULL,
    kd_kec character(3) NOT NULL,
    nm_wilda character varying(100) NOT NULL,
    kd_prop_lama character(2),
    kd_kab_lama character(2),
    kd_kec_lama character(3),
    nm_wilda_lama character varying(100),
    bulan character(2) NOT NULL,
    tahun character(4) NOT NULL,
    is_active character(1) DEFAULT 1 NOT NULL,
    no_urut character(4) NOT NULL,
    no_urut_lama character(4)
);


--
-- TOC entry 198 (class 1259 OID 17408)
-- Dependencies: 5
-- Name: t_instrumen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_instrumen (
    id_publikasi character varying(13) NOT NULL,
    kd_kegiatan integer NOT NULL,
    kd_instrumen character varying(30),
    thn_kegiatan character varying(4) NOT NULL,
    is_internal boolean
);


--
-- TOC entry 199 (class 1259 OID 17411)
-- Dependencies: 5
-- Name: t_jurnal; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_jurnal (
    id_publikasi character varying(13) NOT NULL,
    no_jurnal character varying(3) NOT NULL,
    volume character varying(25) NOT NULL,
    issn character varying(13),
    isbn character varying(13),
    hal_awal character varying(3),
    hal_akhir character varying(3),
    kd_pengadaan character varying(2)
);


--
-- TOC entry 200 (class 1259 OID 17414)
-- Dependencies: 5
-- Name: t_option; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_option (
    id integer NOT NULL,
    page character varying(100),
    code character varying(20),
    child_code character varying(20),
    code_values character varying(1000),
    child_value character varying(1000),
    value_en character varying(1000),
    child_value_en character varying(1000)
);


--
-- TOC entry 201 (class 1259 OID 17420)
-- Dependencies: 200 5
-- Name: t_option_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE t_option_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2365 (class 0 OID 0)
-- Dependencies: 201
-- Name: t_option_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE t_option_id_seq OWNED BY t_option.id;


--
-- TOC entry 202 (class 1259 OID 17422)
-- Dependencies: 5
-- Name: t_paparan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_paparan (
    kd_paparan integer NOT NULL,
    kd_bahan_pustaka character(3) NOT NULL,
    judul text NOT NULL,
    penyaji character varying(100),
    kegiatan character varying(255),
    jml_hal integer,
    lokasi_penyajian character varying(200),
    abstraksi text,
    pdf_dir character varying(100),
    flag_h character(1),
    flag_s character(1),
    rak character(3) NOT NULL,
    lorong character varying(3) NOT NULL,
    baris character varying(7) NOT NULL,
    kd_bahasa integer NOT NULL,
    kd_pengadaan character(2) NOT NULL,
    harga_perolehan numeric(8,2),
    tgl_entri date NOT NULL,
    nip character varying(18) NOT NULL,
    kd_ruang integer NOT NULL
);


--
-- TOC entry 203 (class 1259 OID 17428)
-- Dependencies: 5
-- Name: t_pinjam_kd_pinjam_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE t_pinjam_kd_pinjam_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 204 (class 1259 OID 17430)
-- Dependencies: 2202 5
-- Name: t_pinjam; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_pinjam (
    kd_pinjam integer DEFAULT nextval('t_pinjam_kd_pinjam_seq'::regclass) NOT NULL,
    id_publikasi character varying(13) NOT NULL,
    no_eks integer NOT NULL,
    tgl_pinjam date NOT NULL,
    tgl_pengembalian date,
    jaminan character varying(255) NOT NULL,
    lama_pinjam integer NOT NULL,
    profile_id character varying(11),
    petugas character varying(18),
    flag_tampil character(1) NOT NULL
);


--
-- TOC entry 205 (class 1259 OID 17434)
-- Dependencies: 2203 5
-- Name: t_print; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_print (
    print_id character varying(3) NOT NULL,
    print_profile character varying(50) NOT NULL,
    print_tg character varying(10) NOT NULL,
    print_idpublikasi character varying(13) NOT NULL,
    print_halaman character varying(100),
    print_state character(1) DEFAULT 0,
    print_jmlhlm integer,
    print_nominal integer,
    print_operatorid character varying(13),
    print_rusak integer
);


--
-- TOC entry 2366 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE t_print; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE t_print IS 'table print';


--
-- TOC entry 206 (class 1259 OID 17438)
-- Dependencies: 2204 2205 5
-- Name: t_pub_bps; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_pub_bps (
    id_publikasi character varying(13) NOT NULL,
    no_publikasi character varying(15),
    isbn character varying(30),
    issn character varying(30),
    thn_data character varying(9),
    ket_tambahan character varying(100),
    abstraksi text,
    is_jual character(1) DEFAULT 0 NOT NULL,
    is_jual_cd character(1) DEFAULT 0 NOT NULL,
    kd_kegiatan integer NOT NULL,
    thn_judul character varying(9),
    wilda_subyek character varying(11),
    pengarang character varying(50),
    wilda_penerbit character varying(11)
);


--
-- TOC entry 207 (class 1259 OID 17446)
-- Dependencies: 5
-- Name: t_pub_lain; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_pub_lain (
    id_publikasi character varying(13) NOT NULL,
    isbn_uu character varying(20),
    issn_brs character varying(20),
    pengarang character varying(255),
    penerbit character varying(255),
    kd_pengadaan character varying(2),
    thn_judul character varying(9),
    kd_ddc character varying(9)
);


--
-- TOC entry 208 (class 1259 OID 17452)
-- Dependencies: 2206 2207 5
-- Name: t_pub_lokasi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_pub_lokasi (
    no_eks integer DEFAULT 1 NOT NULL,
    rak character varying(3) NOT NULL,
    lorong character varying(3) NOT NULL,
    baris character varying(7) NOT NULL,
    id_publikasi character varying(13) NOT NULL,
    kondisi character(1),
    flag_cetak_label character(1),
    flag_hapus_eksemplar character(1),
    kd_ruang integer NOT NULL,
    flag_pinjam character(1) NOT NULL,
    flag_aktif character(1) DEFAULT 1 NOT NULL,
    is_bmn boolean,
    is_hardcover boolean,
    is_berwarna boolean,
    is_laminating boolean,
    is_berjaket boolean,
    kode_bmn character varying(20),
    tgl_entri date,
    pengentri character varying(18),
    tgl_edit date,
    editor character varying(18)
);


--
-- TOC entry 209 (class 1259 OID 17457)
-- Dependencies: 2208 2209 2210 2211 2212 5
-- Name: t_publikasi; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_publikasi (
    id_publikasi character varying(13) NOT NULL,
    kd_bahan_pustaka character(3) NOT NULL,
    bln_terima character(2) NOT NULL,
    thn_terima character(4) NOT NULL,
    no_urut_bi character(4) NOT NULL,
    kd_subyek character(7) NOT NULL,
    judul text,
    judul_paralel text,
    kd_produsen character varying(11) NOT NULL,
    kd_table character(1) NOT NULL,
    kd_bahasa integer,
    jml_eks integer,
    jml_hal integer,
    p_buku numeric(4,1),
    l_buku numeric(4,1),
    is_table character(1) DEFAULT 0 NOT NULL,
    is_grafik character(1) DEFAULT 0 NOT NULL,
    is_peta character(1) DEFAULT 0 NOT NULL,
    flag_h character varying(2),
    flag_s character varying(2),
    pdf_dir character varying(255),
    cover_dir character varying(255),
    harga_perolehan numeric(9,2),
    nip_lama character varying(20),
    tgl_entri date,
    nip character varying(18),
    is_ilus character(1) DEFAULT 0 NOT NULL,
    jml_rom character varying(50),
    is_full_entry character(1) DEFAULT 0 NOT NULL,
    bulan_terbit character(2),
    tahun_terbit character(4),
    nip_editor character varying(18),
    tgl_edit date,
    kd_periode character varying(3) NOT NULL
);


--
-- TOC entry 210 (class 1259 OID 17468)
-- Dependencies: 5
-- Name: t_statistik_perpustakaan; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE t_statistik_perpustakaan (
    kd_prop character(2) NOT NULL,
    kd_kab character(2) NOT NULL,
    kd_kec character(3) NOT NULL,
    no_urut integer NOT NULL,
    jml_ruang integer,
    luas integer,
    jml_rak integer,
    is_pc_buku_tamu boolean,
    is_pc_digilib boolean,
    is_fotocopy boolean,
    is_website boolean,
    folder_pdf text,
    folder_cover text,
    folder_denah text,
    nama_web character varying(100),
    map bytea
);


--
-- TOC entry 211 (class 1259 OID 17474)
-- Dependencies: 5
-- Name: temp; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE temp (
    no_urut character(4),
    kd_prop character varying(2),
    kd_kab character varying(2),
    kd_kec character varying(3),
    kd_prop_lama character varying(2),
    kd_kab_lama character varying(2),
    kd_kec_lama character varying(3),
    no_urut_lama character(4),
    nm_wilda character varying(100),
    bulan character(2),
    tahun character(4),
    is_active character varying(9)
);


--
-- TOC entry 212 (class 1259 OID 17477)
-- Dependencies: 5
-- Name: unit_kerja_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE unit_kerja_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 213 (class 1259 OID 17479)
-- Dependencies: 5
-- Name: wilda; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE wilda (
    id integer NOT NULL,
    kd_prop character varying(255),
    kd_kab character varying(255),
    kd_kec character varying(255),
    no_urut character varying(255),
    nm_wilda character varying(255)
);


--
-- TOC entry 214 (class 1259 OID 17485)
-- Dependencies: 5
-- Name: wilda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wilda_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 215 (class 1259 OID 17487)
-- Dependencies: 213 5
-- Name: wilda_id_seq1; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wilda_id_seq1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 2367 (class 0 OID 0)
-- Dependencies: 215
-- Name: wilda_id_seq1; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wilda_id_seq1 OWNED BY wilda.id;


--
-- TOC entry 2183 (class 2604 OID 17489)
-- Dependencies: 159 157
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_bulan ALTER COLUMN id SET DEFAULT nextval('m_bulan_id_seq1'::regclass);


--
-- TOC entry 2189 (class 2604 OID 17490)
-- Dependencies: 177 175
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_petugas ALTER COLUMN id SET DEFAULT nextval('m_petugas_id_seq1'::regclass);


--
-- TOC entry 2201 (class 2604 OID 17491)
-- Dependencies: 201 200
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_option ALTER COLUMN id SET DEFAULT nextval('t_option_id_seq'::regclass);


--
-- TOC entry 2213 (class 2604 OID 17492)
-- Dependencies: 215 213
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wilda ALTER COLUMN id SET DEFAULT nextval('wilda_id_seq1'::regclass);


--
-- TOC entry 2215 (class 2606 OID 17494)
-- Dependencies: 142 142
-- Name: ap_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_application_settings
    ADD CONSTRAINT ap_pk PRIMARY KEY (id);


--
-- TOC entry 2217 (class 2606 OID 17496)
-- Dependencies: 144 144 144 144 144
-- Name: bukutamu_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bukutamu
    ADD CONSTRAINT bukutamu_pkey PRIMARY KEY (bukutamu_th, bukutamu_bl, bukutamu_tg, bukutamu_id);


--
-- TOC entry 2219 (class 2606 OID 17498)
-- Dependencies: 145 145 145
-- Name: digilib1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY digilib
    ADD CONSTRAINT digilib1 PRIMARY KEY (digilib_id, digilib_tgl);


--
-- TOC entry 2221 (class 2606 OID 17500)
-- Dependencies: 146 146 146
-- Name: dutym1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dutym
    ADD CONSTRAINT dutym1 PRIMARY KEY (dutym_id, dutym_tgl);


--
-- TOC entry 2223 (class 2606 OID 17502)
-- Dependencies: 147 147
-- Name: faq1; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq
    ADD CONSTRAINT faq1 PRIMARY KEY (faq_id);


--
-- TOC entry 2225 (class 2606 OID 17504)
-- Dependencies: 148 148 148
-- Name: faq_a_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_a
    ADD CONSTRAINT faq_a_pk PRIMARY KEY (a_q_id, a_nomor);


--
-- TOC entry 2227 (class 2606 OID 17506)
-- Dependencies: 149 149
-- Name: faq_q_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY faq_q
    ADD CONSTRAINT faq_q_pk PRIMARY KEY (q_id);


--
-- TOC entry 2305 (class 2606 OID 17508)
-- Dependencies: 204 204
-- Name: kd_pinjam; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_pinjam
    ADD CONSTRAINT kd_pinjam PRIMARY KEY (kd_pinjam);


--
-- TOC entry 2229 (class 2606 OID 17510)
-- Dependencies: 150 150
-- Name: konsultasi_primary; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY konsultasi
    ADD CONSTRAINT konsultasi_primary PRIMARY KEY (konsultasi_id);


--
-- TOC entry 2255 (class 2606 OID 17512)
-- Dependencies: 169 169
-- Name: level_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_level
    ADD CONSTRAINT level_pk PRIMARY KEY (kd_level);


--
-- TOC entry 2231 (class 2606 OID 17514)
-- Dependencies: 152 152 152
-- Name: logincode_p; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logincode
    ADD CONSTRAINT logincode_p PRIMARY KEY (logincode_id, logincode_tg);


--
-- TOC entry 2233 (class 2606 OID 17516)
-- Dependencies: 154 154
-- Name: m_bahasa_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_bahasa
    ADD CONSTRAINT m_bahasa_pkey PRIMARY KEY (kd_bahasa);


--
-- TOC entry 2235 (class 2606 OID 17518)
-- Dependencies: 155 155
-- Name: m_benua_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_benua
    ADD CONSTRAINT m_benua_pkey PRIMARY KEY (kd_benua);


--
-- TOC entry 2237 (class 2606 OID 17520)
-- Dependencies: 160 160
-- Name: m_ddc_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_ddc
    ADD CONSTRAINT m_ddc_pkey PRIMARY KEY (kd_ddc);


--
-- TOC entry 2239 (class 2606 OID 17522)
-- Dependencies: 161 161 161
-- Name: m_identitas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_identitas
    ADD CONSTRAINT m_identitas_pkey PRIMARY KEY (kd_prop, kd_kab);


--
-- TOC entry 2241 (class 2606 OID 17524)
-- Dependencies: 162 162
-- Name: m_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_info
    ADD CONSTRAINT m_info_pkey PRIMARY KEY (kd_info);


--
-- TOC entry 2243 (class 2606 OID 17526)
-- Dependencies: 163 163 163
-- Name: m_instansi_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_instansi
    ADD CONSTRAINT m_instansi_pkey PRIMARY KEY (kd_instansi, kd_negara);


--
-- TOC entry 2245 (class 2606 OID 17528)
-- Dependencies: 164 164
-- Name: m_jenisbahanpustaka_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_jenis_bahan_pustaka
    ADD CONSTRAINT m_jenisbahanpustaka_pkey PRIMARY KEY (kd_bahan_pustaka);


--
-- TOC entry 2247 (class 2606 OID 17530)
-- Dependencies: 165 165 165
-- Name: m_kab_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_kab
    ADD CONSTRAINT m_kab_pkey PRIMARY KEY (kd_kab, kd_prop);


--
-- TOC entry 2249 (class 2606 OID 17532)
-- Dependencies: 166 166 166 166
-- Name: m_kec_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_kec
    ADD CONSTRAINT m_kec_pkey PRIMARY KEY (kd_kec, kd_kab, kd_prop);


--
-- TOC entry 2251 (class 2606 OID 17534)
-- Dependencies: 167 167
-- Name: m_kegiatan_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_kegiatan
    ADD CONSTRAINT m_kegiatan_pkey PRIMARY KEY (kd_kegiatan);


--
-- TOC entry 2253 (class 2606 OID 17536)
-- Dependencies: 168 168
-- Name: m_label_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_label
    ADD CONSTRAINT m_label_pkey PRIMARY KEY (kd_label);


--
-- TOC entry 2257 (class 2606 OID 17538)
-- Dependencies: 170 170 170 170 170
-- Name: m_lokasi_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_lokasi
    ADD CONSTRAINT m_lokasi_pkey PRIMARY KEY (kd_ruang, rak, lorong, baris);


--
-- TOC entry 2259 (class 2606 OID 17540)
-- Dependencies: 171 171
-- Name: m_masapajang_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_masa_pajang
    ADD CONSTRAINT m_masapajang_pkey PRIMARY KEY (kd_masa_pajang);


--
-- TOC entry 2261 (class 2606 OID 17542)
-- Dependencies: 172 172
-- Name: m_negara_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_negara
    ADD CONSTRAINT m_negara_pkey PRIMARY KEY (kd_negara);


--
-- TOC entry 2263 (class 2606 OID 17544)
-- Dependencies: 173 173
-- Name: m_pengadaan_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_pengadaan
    ADD CONSTRAINT m_pengadaan_pkey PRIMARY KEY (kd_pengadaan);


--
-- TOC entry 2267 (class 2606 OID 17546)
-- Dependencies: 178 178 178
-- Name: m_produsen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_produsen
    ADD CONSTRAINT m_produsen_pkey PRIMARY KEY (kd_produsen, kd_table);


--
-- TOC entry 2269 (class 2606 OID 17548)
-- Dependencies: 179 179
-- Name: m_prop_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_prop
    ADD CONSTRAINT m_prop_pkey PRIMARY KEY (kd_prop);


--
-- TOC entry 2271 (class 2606 OID 17550)
-- Dependencies: 181 181
-- Name: m_ruang_p_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_ruang
    ADD CONSTRAINT m_ruang_p_key PRIMARY KEY (kd_ruang);


--
-- TOC entry 2273 (class 2606 OID 17552)
-- Dependencies: 182 182
-- Name: m_subyek_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_subyek
    ADD CONSTRAINT m_subyek_pkey PRIMARY KEY (kd_subyek);


--
-- TOC entry 2275 (class 2606 OID 17554)
-- Dependencies: 183 183
-- Name: m_tableprod_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_table_prod
    ADD CONSTRAINT m_tableprod_pkey PRIMARY KEY (kd_table);


--
-- TOC entry 2277 (class 2606 OID 17556)
-- Dependencies: 185 185
-- Name: m_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_user
    ADD CONSTRAINT m_user_pkey PRIMARY KEY (nip);


--
-- TOC entry 2279 (class 2606 OID 17558)
-- Dependencies: 187 187
-- Name: m_usertab_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_usertab
    ADD CONSTRAINT m_usertab_pkey PRIMARY KEY (id);


--
-- TOC entry 2301 (class 2606 OID 17560)
-- Dependencies: 200 200
-- Name: option_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_option
    ADD CONSTRAINT option_key PRIMARY KEY (id);


--
-- TOC entry 2281 (class 2606 OID 17562)
-- Dependencies: 188 188
-- Name: penjualan_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY penjualan
    ADD CONSTRAINT penjualan_pk PRIMARY KEY (p_id);


--
-- TOC entry 2265 (class 2606 OID 17564)
-- Dependencies: 174 174
-- Name: periode_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY m_periode
    ADD CONSTRAINT periode_pk PRIMARY KEY (kd_periode);


--
-- TOC entry 2307 (class 2606 OID 17566)
-- Dependencies: 205 205 205 205
-- Name: print_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_print
    ADD CONSTRAINT print_pk PRIMARY KEY (print_id, print_profile, print_tg);


--
-- TOC entry 2287 (class 2606 OID 17568)
-- Dependencies: 192 192
-- Name: profile_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profile_group
    ADD CONSTRAINT profile_group_pkey PRIMARY KEY (group_id);


--
-- TOC entry 2285 (class 2606 OID 17570)
-- Dependencies: 190 190
-- Name: profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY profile
    ADD CONSTRAINT profile_pkey PRIMARY KEY (profile_id);


--
-- TOC entry 2313 (class 2606 OID 17572)
-- Dependencies: 208 208 208
-- Name: pub_lokasi_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_pub_lokasi
    ADD CONSTRAINT pub_lokasi_pk PRIMARY KEY (id_publikasi, no_eks);


--
-- TOC entry 2289 (class 2606 OID 17574)
-- Dependencies: 194 194 194
-- Name: t_bukuinduk_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_buku_induk
    ADD CONSTRAINT t_bukuinduk_pkey PRIMARY KEY (id, id_publikasi);


--
-- TOC entry 2291 (class 2606 OID 17576)
-- Dependencies: 195 195 195
-- Name: t_bukutable_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_buku_table
    ADD CONSTRAINT t_bukutable_pkey PRIMARY KEY (kd_buku_table, id_publikasi);


--
-- TOC entry 2293 (class 2606 OID 17578)
-- Dependencies: 196 196 196
-- Name: t_historyunitker_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_history_unit_kerja
    ADD CONSTRAINT t_historyunitker_pkey PRIMARY KEY (kd_unit_kerja, no_urut);


--
-- TOC entry 2297 (class 2606 OID 17580)
-- Dependencies: 198 198
-- Name: t_instrumen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_instrumen
    ADD CONSTRAINT t_instrumen_pkey PRIMARY KEY (id_publikasi);


--
-- TOC entry 2299 (class 2606 OID 17582)
-- Dependencies: 199 199
-- Name: t_jurnal_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_jurnal
    ADD CONSTRAINT t_jurnal_pkey PRIMARY KEY (id_publikasi);


--
-- TOC entry 2303 (class 2606 OID 17584)
-- Dependencies: 202 202
-- Name: t_paparan_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_paparan
    ADD CONSTRAINT t_paparan_pkey PRIMARY KEY (kd_paparan);


--
-- TOC entry 2309 (class 2606 OID 17586)
-- Dependencies: 206 206
-- Name: t_pubbps_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_pub_bps
    ADD CONSTRAINT t_pubbps_pkey PRIMARY KEY (id_publikasi);


--
-- TOC entry 2311 (class 2606 OID 17588)
-- Dependencies: 207 207
-- Name: t_publain_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_pub_lain
    ADD CONSTRAINT t_publain_pkey PRIMARY KEY (id_publikasi);


--
-- TOC entry 2315 (class 2606 OID 17590)
-- Dependencies: 209 209
-- Name: t_publikasi_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_pkey PRIMARY KEY (id_publikasi);


--
-- TOC entry 2317 (class 2606 OID 17592)
-- Dependencies: 210 210 210 210 210
-- Name: t_statistikperpustakaan_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_statistik_perpustakaan
    ADD CONSTRAINT t_statistikperpustakaan_pkey PRIMARY KEY (kd_prop, kd_kab, kd_kec, no_urut);


--
-- TOC entry 2295 (class 2606 OID 17594)
-- Dependencies: 197 197 197 197 197
-- Name: thistorywilda; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_history_wilda
    ADD CONSTRAINT thistorywilda PRIMARY KEY (kd_prop, kd_kab, kd_kec, no_urut);


--
-- TOC entry 2283 (class 2606 OID 17596)
-- Dependencies: 189 189 189
-- Name: tr_pk; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY penjualan_tr
    ADD CONSTRAINT tr_pk PRIMARY KEY (tr_p_id, tr_nomor);


--
-- TOC entry 2318 (class 2606 OID 17597)
-- Dependencies: 192 2286 144
-- Name: bukutamu_group_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bukutamu
    ADD CONSTRAINT bukutamu_group_fkey FOREIGN KEY (bukutamu_group) REFERENCES profile_group(group_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2319 (class 2606 OID 17602)
-- Dependencies: 144 2284 190
-- Name: bukutamu_profile_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bukutamu
    ADD CONSTRAINT bukutamu_profile_fkey FOREIGN KEY (bukutamu_profile) REFERENCES profile(profile_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2320 (class 2606 OID 17607)
-- Dependencies: 148 2226 149
-- Name: f_faq_q_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY faq_a
    ADD CONSTRAINT f_faq_q_id FOREIGN KEY (a_q_id) REFERENCES faq_q(q_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2333 (class 2606 OID 17612)
-- Dependencies: 2284 188 190
-- Name: f_profile; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY penjualan
    ADD CONSTRAINT f_profile FOREIGN KEY (p_profile) REFERENCES profile(profile_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2334 (class 2606 OID 17617)
-- Dependencies: 189 188 2280
-- Name: f_tr_p; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY penjualan_tr
    ADD CONSTRAINT f_tr_p FOREIGN KEY (tr_p_id) REFERENCES penjualan(p_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2321 (class 2606 OID 17622)
-- Dependencies: 149 190 2284
-- Name: foreignk_profile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY faq_q
    ADD CONSTRAINT foreignk_profile_id FOREIGN KEY (q_profile) REFERENCES profile(profile_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2344 (class 2606 OID 17627)
-- Dependencies: 2312 208 208 204 204
-- Name: id_publikasi; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pinjam
    ADD CONSTRAINT id_publikasi FOREIGN KEY (id_publikasi, no_eks) REFERENCES t_pub_lokasi(id_publikasi, no_eks) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2322 (class 2606 OID 17632)
-- Dependencies: 2260 163 172
-- Name: instansi_kd_negara_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_instansi
    ADD CONSTRAINT instansi_kd_negara_fkey FOREIGN KEY (kd_negara) REFERENCES m_negara(kd_negara) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2323 (class 2606 OID 17637)
-- Dependencies: 168 164 2252
-- Name: m_jenisbahanpustaka_kdlabel_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_jenis_bahan_pustaka
    ADD CONSTRAINT m_jenisbahanpustaka_kdlabel_fkey FOREIGN KEY (kd_label) REFERENCES m_label(kd_label) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2324 (class 2606 OID 17642)
-- Dependencies: 179 165 2268
-- Name: m_kab_kdprop_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_kab
    ADD CONSTRAINT m_kab_kdprop_fkey FOREIGN KEY (kd_prop) REFERENCES m_prop(kd_prop) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2325 (class 2606 OID 17647)
-- Dependencies: 166 2246 165 165 166
-- Name: m_kec_kdkab_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_kec
    ADD CONSTRAINT m_kec_kdkab_fkey FOREIGN KEY (kd_kab, kd_prop) REFERENCES m_kab(kd_kab, kd_prop) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2326 (class 2606 OID 17652)
-- Dependencies: 2292 167 167 196 196
-- Name: m_kegiatan_kdunitbaru_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_kegiatan
    ADD CONSTRAINT m_kegiatan_kdunitbaru_fkey FOREIGN KEY (kd_unit_baru, no_unit_baru) REFERENCES t_history_unit_kerja(kd_unit_kerja, no_urut) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2327 (class 2606 OID 17657)
-- Dependencies: 196 167 167 196 2292
-- Name: m_kegiatan_kdunitlama_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_kegiatan
    ADD CONSTRAINT m_kegiatan_kdunitlama_fkey FOREIGN KEY (kd_unit_lama, no_unit_lama) REFERENCES t_history_unit_kerja(kd_unit_kerja, no_urut) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2332 (class 2606 OID 17662)
-- Dependencies: 169 185 2254
-- Name: m_level_kd_level_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_user
    ADD CONSTRAINT m_level_kd_level_fkey FOREIGN KEY (level_user) REFERENCES m_level(kd_level) MATCH FULL ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2328 (class 2606 OID 17667)
-- Dependencies: 181 170 2270
-- Name: m_lokasi_kd_ruang_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_lokasi
    ADD CONSTRAINT m_lokasi_kd_ruang_fkey FOREIGN KEY (kd_ruang) REFERENCES m_ruang(kd_ruang) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2329 (class 2606 OID 17672)
-- Dependencies: 183 178 2274
-- Name: m_produsen_kdtable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_produsen
    ADD CONSTRAINT m_produsen_kdtable_fkey FOREIGN KEY (kd_table) REFERENCES m_table_prod(kd_table) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2330 (class 2606 OID 17677)
-- Dependencies: 160 182 2236
-- Name: m_subyek_kdddc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_subyek
    ADD CONSTRAINT m_subyek_kdddc_fkey FOREIGN KEY (kd_ddc) REFERENCES m_ddc(kd_ddc) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2331 (class 2606 OID 17682)
-- Dependencies: 171 182 2258
-- Name: m_subyek_kdmasapajang_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY m_subyek
    ADD CONSTRAINT m_subyek_kdmasapajang_fkey FOREIGN KEY (kd_masa_pajang) REFERENCES m_masa_pajang(kd_masa_pajang) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2345 (class 2606 OID 17687)
-- Dependencies: 190 204 2284
-- Name: profile_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pinjam
    ADD CONSTRAINT profile_id FOREIGN KEY (profile_id) REFERENCES profile(profile_id);


--
-- TOC entry 2335 (class 2606 OID 17692)
-- Dependencies: 209 194 2314
-- Name: t_bukuinduk_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_buku_induk
    ADD CONSTRAINT t_bukuinduk_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2336 (class 2606 OID 17697)
-- Dependencies: 209 195 2314
-- Name: t_bukutable_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_buku_table
    ADD CONSTRAINT t_bukutable_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2337 (class 2606 OID 17702)
-- Dependencies: 209 198 2314
-- Name: t_instrumen_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_instrumen
    ADD CONSTRAINT t_instrumen_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2338 (class 2606 OID 17707)
-- Dependencies: 167 198 2250
-- Name: t_instrumen_kdkegiatan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_instrumen
    ADD CONSTRAINT t_instrumen_kdkegiatan_fkey FOREIGN KEY (kd_kegiatan) REFERENCES m_kegiatan(kd_kegiatan) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2339 (class 2606 OID 17712)
-- Dependencies: 209 2314 199
-- Name: t_jurnal_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_jurnal
    ADD CONSTRAINT t_jurnal_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2340 (class 2606 OID 17717)
-- Dependencies: 199 2262 173
-- Name: t_jurnal_kdpengadaan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_jurnal
    ADD CONSTRAINT t_jurnal_kdpengadaan_fkey FOREIGN KEY (kd_pengadaan) REFERENCES m_pengadaan(kd_pengadaan) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2341 (class 2606 OID 17722)
-- Dependencies: 2232 154 202
-- Name: t_paparan_kdbahasa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_paparan
    ADD CONSTRAINT t_paparan_kdbahasa_fkey FOREIGN KEY (kd_bahasa) REFERENCES m_bahasa(kd_bahasa) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2342 (class 2606 OID 17727)
-- Dependencies: 170 2256 170 170 170 202 202 202 202
-- Name: t_paparan_kdlokasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_paparan
    ADD CONSTRAINT t_paparan_kdlokasi_fkey FOREIGN KEY (kd_ruang, rak, lorong, baris) REFERENCES m_lokasi(kd_ruang, rak, lorong, baris) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2343 (class 2606 OID 17732)
-- Dependencies: 173 2262 202
-- Name: t_paparan_kdpengadaan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_paparan
    ADD CONSTRAINT t_paparan_kdpengadaan_fkey FOREIGN KEY (kd_pengadaan) REFERENCES m_pengadaan(kd_pengadaan) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2346 (class 2606 OID 17737)
-- Dependencies: 2314 206 209
-- Name: t_pubbps_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_bps
    ADD CONSTRAINT t_pubbps_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2347 (class 2606 OID 17742)
-- Dependencies: 167 2250 206
-- Name: t_pubbps_kdkegiatan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_bps
    ADD CONSTRAINT t_pubbps_kdkegiatan_fkey FOREIGN KEY (kd_kegiatan) REFERENCES m_kegiatan(kd_kegiatan) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2348 (class 2606 OID 17747)
-- Dependencies: 207 209 2314
-- Name: t_publain_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_lain
    ADD CONSTRAINT t_publain_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2349 (class 2606 OID 17752)
-- Dependencies: 207 2262 173
-- Name: t_publain_kdpengadaan_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_lain
    ADD CONSTRAINT t_publain_kdpengadaan_fkey FOREIGN KEY (kd_pengadaan) REFERENCES m_pengadaan(kd_pengadaan) ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- TOC entry 2352 (class 2606 OID 17757)
-- Dependencies: 209 2244 164
-- Name: t_publikasi_kd_bahan_pustaka_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_kd_bahan_pustaka_fkey FOREIGN KEY (kd_bahan_pustaka) REFERENCES m_jenis_bahan_pustaka(kd_bahan_pustaka) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2353 (class 2606 OID 17762)
-- Dependencies: 209 154 2232
-- Name: t_publikasi_kd_bahasa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_kd_bahasa_fkey FOREIGN KEY (kd_bahasa) REFERENCES m_bahasa(kd_bahasa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2354 (class 2606 OID 17767)
-- Dependencies: 2264 174 209
-- Name: t_publikasi_kd_periode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_kd_periode_fkey FOREIGN KEY (kd_periode) REFERENCES m_periode(kd_periode) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2355 (class 2606 OID 17772)
-- Dependencies: 209 178 2266 178 209
-- Name: t_publikasi_kd_produsen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_kd_produsen_fkey FOREIGN KEY (kd_produsen, kd_table) REFERENCES m_produsen(kd_produsen, kd_table) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2356 (class 2606 OID 17777)
-- Dependencies: 182 209 2272
-- Name: t_publikasi_kd_subyek_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_publikasi
    ADD CONSTRAINT t_publikasi_kd_subyek_fkey FOREIGN KEY (kd_subyek) REFERENCES m_subyek(kd_subyek) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2350 (class 2606 OID 17782)
-- Dependencies: 2314 209 208
-- Name: t_publokasi_idpublikasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_lokasi
    ADD CONSTRAINT t_publokasi_idpublikasi_fkey FOREIGN KEY (id_publikasi) REFERENCES t_publikasi(id_publikasi) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2351 (class 2606 OID 17787)
-- Dependencies: 170 208 208 208 2256 170 208 170 170
-- Name: t_publokasi_kdlokasi_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY t_pub_lokasi
    ADD CONSTRAINT t_publokasi_kdlokasi_fkey FOREIGN KEY (kd_ruang, rak, lorong, baris) REFERENCES m_lokasi(kd_ruang, rak, lorong, baris) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2361 (class 0 OID 0)
-- Dependencies: 5
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2015-02-13 15:20:25

--
-- PostgreSQL database dump complete
--

