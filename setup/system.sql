--
-- PostgreSQL database dump
--

-- Dumped from database version 13.1 (Debian 13.1-1.pgdg100+1)
-- Dumped by pg_dump version 13.1 (Debian 13.1-1.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: rune_rb_system; Type: DATABASE;
--

CREATE DATABASE rune_rb_system ENCODING = 'UTF8';


ALTER DATABASE rune_rb_system OWNER TO pat;

\connect rune_rb_system

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: banned_names; Type: TABLE; Schema: public; Owner: pat
--

CREATE TABLE public.banned_names (
    names text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.banned_names OWNER TO pat;

--
-- Name: snapshots; Type: TABLE; Schema: public; Owner: pat
--

CREATE TABLE public.snapshots (
    id bigint DEFAULT '-1'::integer NOT NULL,
    dump text DEFAULT '{}'::text NOT NULL,
    created timestamp without time zone
);


ALTER TABLE public.snapshots OWNER TO pat;

--
-- Data for Name: banned_names; Type: TABLE DATA; Schema: public; Owner: pat
--

COPY public.banned_names (names) FROM stdin;

mod
admin
owner
cunt
fuck
fag
\.


--
-- Data for Name: snapshots; Type: TABLE DATA; Schema: public; Owner: pat
--

COPY public.snapshots (id, dump, created) FROM stdin;
\.


--
-- Name: snapshots snapshots_pk; Type: CONSTRAINT; Schema: public; Owner: pat
--

ALTER TABLE ONLY public.snapshots
    ADD CONSTRAINT snapshots_pk PRIMARY KEY (id);


--
-- Name: snapshots_id_uindex; Type: INDEX; Schema: public; Owner: pat
--

CREATE UNIQUE INDEX snapshots_id_uindex ON public.snapshots USING btree (id);


--
-- PostgreSQL database dump complete
--

