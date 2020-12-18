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
-- Name: rune_rb_profiles; Type: DATABASE;
--

CREATE DATABASE rune_rb_profiles ENCODING = 'UTF8';


\connect rune_rb_profiles

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
-- Name: appearance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.appearance (
    gender smallint DEFAULT 0 NOT NULL,
    hair_color smallint DEFAULT 7 NOT NULL,
    torso_color smallint DEFAULT 8 NOT NULL,
    leg_color smallint DEFAULT 9 NOT NULL,
    feet_color smallint DEFAULT 5 NOT NULL,
    skin_color smallint DEFAULT 0 NOT NULL,
    head smallint DEFAULT 0 NOT NULL,
    chest smallint DEFAULT 18 NOT NULL,
    arms smallint DEFAULT 26 NOT NULL,
    hands smallint DEFAULT 33 NOT NULL,
    legs smallint DEFAULT 36 NOT NULL,
    feet smallint DEFAULT 42 NOT NULL,
    beard smallint DEFAULT 10 NOT NULL,
    name character varying(20) DEFAULT 'context'::character varying NOT NULL,
    mob_id integer DEFAULT '-1'::integer NOT NULL,
    stand integer DEFAULT 808 NOT NULL,
    stand_turn integer DEFAULT 823 NOT NULL,
    walk integer DEFAULT 819 NOT NULL,
    turn_180 integer DEFAULT 820 NOT NULL,
    turn_90_cw integer DEFAULT 821 NOT NULL,
    turn_90_ccw integer DEFAULT 822 NOT NULL,
    run integer DEFAULT 824 NOT NULL,
    head_icon integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.appearance OWNER TO postgres;

--
-- Name: location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location (
    x integer DEFAULT 3222 NOT NULL,
    y integer DEFAULT 3222 NOT NULL,
    z integer DEFAULT 0 NOT NULL,
    prev_x integer DEFAULT 2606 NOT NULL,
    prev_y integer DEFAULT 3095 NOT NULL,
    prev_z integer DEFAULT 0 NOT NULL,
    name character varying(20) DEFAULT 'context'::character varying NOT NULL
);


ALTER TABLE public.location OWNER TO postgres;

--
-- Name: profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile (
    banned boolean DEFAULT false NOT NULL,
    members boolean DEFAULT true NOT NULL,
    friends_list text[],
    ignore_list text[],
    muted boolean DEFAULT false NOT NULL,
    name text DEFAULT 'context_player'::text NOT NULL,
    password text DEFAULT 'womp'::text NOT NULL,
    name_hash bigint,
    rights integer DEFAULT 0 NOT NULL,
    inventory text DEFAULT '{}'::text NOT NULL,
    equipment text DEFAULT '{}'::text NOT NULL
);


ALTER TABLE public.profile OWNER TO postgres;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    move_speed integer DEFAULT 0 NOT NULL,
    energy integer DEFAULT 100 NOT NULL,
    withdraw_note boolean DEFAULT false NOT NULL,
    item_swap boolean DEFAULT false NOT NULL,
    brightness integer DEFAULT 2 NOT NULL,
    mouse_buttons integer DEFAULT 2 NOT NULL,
    chat_effects boolean DEFAULT true NOT NULL,
    auto_retaliate boolean DEFAULT true NOT NULL,
    name character varying(20) DEFAULT 'context'::character varying NOT NULL
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stats (
    attack_level smallint DEFAULT 1 NOT NULL,
    attack_exp integer DEFAULT 0 NOT NULL,
    defence_level smallint DEFAULT 1 NOT NULL,
    defence_exp integer DEFAULT 0 NOT NULL,
    strength_level smallint DEFAULT 1 NOT NULL,
    strength_exp integer DEFAULT 0 NOT NULL,
    hit_points_level smallint DEFAULT 10 NOT NULL,
    hit_points_exp integer DEFAULT 1184 NOT NULL,
    range_level smallint DEFAULT 1 NOT NULL,
    range_exp integer DEFAULT 0 NOT NULL,
    prayer_level smallint DEFAULT 1 NOT NULL,
    prayer_exp integer DEFAULT 0 NOT NULL,
    magic_level smallint DEFAULT 1 NOT NULL,
    magic_exp integer DEFAULT 0 NOT NULL,
    cooking_level smallint DEFAULT 1 NOT NULL,
    cooking_exp integer DEFAULT 0 NOT NULL,
    woodcutting_level smallint DEFAULT 1 NOT NULL,
    woodcutting_exp integer DEFAULT 0 NOT NULL,
    fletching_level smallint DEFAULT 1 NOT NULL,
    fletching_exp integer DEFAULT 0 NOT NULL,
    fishing_level smallint DEFAULT 1 NOT NULL,
    fishing_exp integer DEFAULT 0 NOT NULL,
    firemaking_level smallint DEFAULT 1 NOT NULL,
    firemaking_exp integer DEFAULT 0 NOT NULL,
    crafting_level smallint DEFAULT 1 NOT NULL,
    crafting_exp integer DEFAULT 0 NOT NULL,
    smithing_level smallint DEFAULT 1 NOT NULL,
    smithing_exp integer DEFAULT 0 NOT NULL,
    mining_level smallint DEFAULT 1 NOT NULL,
    mining_exp integer DEFAULT 0 NOT NULL,
    herblore_level smallint DEFAULT 1 NOT NULL,
    herblore_exp integer DEFAULT 0 NOT NULL,
    agility_level smallint DEFAULT 1 NOT NULL,
    agility_exp integer DEFAULT 0 NOT NULL,
    thieving_level smallint DEFAULT 1 NOT NULL,
    thieving_exp integer DEFAULT 0 NOT NULL,
    slayer_level smallint DEFAULT 1 NOT NULL,
    slayer_exp integer DEFAULT 0 NOT NULL,
    farming_level smallint DEFAULT 1 NOT NULL,
    farming_exp integer DEFAULT 0 NOT NULL,
    runecrafting_level smallint DEFAULT 1 NOT NULL,
    runecrafting_exp integer DEFAULT 0 NOT NULL,
    name character varying(20) DEFAULT 'context'::character varying NOT NULL
);


ALTER TABLE public.stats OWNER TO postgres;

--
-- Data for Name: appearance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appearance (gender, hair_color, torso_color, leg_color, feet_color, skin_color, head, chest, arms, hands, legs, feet, beard, name, mob_id, stand, stand_turn, walk, turn_180, turn_90_cw, turn_90_ccw, run, head_icon) FROM stdin;
\.


--
-- Data for Name: location; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.location (x, y, z, prev_x, prev_y, prev_z, name) FROM stdin;
\.


--
-- Data for Name: profile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile (banned, members, friends_list, ignore_list, muted, name, password, name_hash, rights, inventory, equipment) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (move_speed, energy, withdraw_note, item_swap, brightness, mouse_buttons, chat_effects, auto_retaliate, name) FROM stdin;
\.


--
-- Data for Name: stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stats (attack_level, attack_exp, defence_level, defence_exp, strength_level, strength_exp, hit_points_level, hit_points_exp, range_level, range_exp, prayer_level, prayer_exp, magic_level, magic_exp, cooking_level, cooking_exp, woodcutting_level, woodcutting_exp, fletching_level, fletching_exp, fishing_level, fishing_exp, firemaking_level, firemaking_exp, crafting_level, crafting_exp, smithing_level, smithing_exp, mining_level, mining_exp, herblore_level, herblore_exp, agility_level, agility_exp, thieving_level, thieving_exp, slayer_level, slayer_exp, farming_level, farming_exp, runecrafting_level, runecrafting_exp, name) FROM stdin;
\.


--
-- Name: appearance appearance_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appearance
    ADD CONSTRAINT appearance_pk PRIMARY KEY (name);


--
-- Name: location location_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pk PRIMARY KEY (name);


--
-- Name: profile profile_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_pk PRIMARY KEY (name);


--
-- Name: settings settings_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pk PRIMARY KEY (name);


--
-- Name: stats stats_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stats
    ADD CONSTRAINT stats_pk PRIMARY KEY (name);


--
-- Name: appearance_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX appearance_name_uindex ON public.appearance USING btree (name);


--
-- Name: location_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX location_name_uindex ON public.location USING btree (name);


--
-- Name: profile_username_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX profile_username_uindex ON public.profile USING btree (name);


--
-- Name: settings_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX settings_name_uindex ON public.settings USING btree (name);


--
-- Name: stats_name_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX stats_name_uindex ON public.stats USING btree (name);


--
-- Name: appearance appearance_profile_name_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appearance
    ADD CONSTRAINT appearance_profile_name_fk FOREIGN KEY (name) REFERENCES public.profile(name) ON DELETE CASCADE;


--
-- Name: location location_profile_name_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_profile_name_fk FOREIGN KEY (name) REFERENCES public.profile(name) ON DELETE CASCADE;


--
-- Name: settings settings_profile_name_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_profile_name_fk FOREIGN KEY (name) REFERENCES public.profile(name) ON DELETE CASCADE;


--
-- Name: stats stats_profile_name_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stats
    ADD CONSTRAINT stats_profile_name_fk FOREIGN KEY (name) REFERENCES public.profile(name) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

