--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

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
    uid integer NOT NULL,
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
    beard smallint DEFAULT 10 NOT NULL
);


ALTER TABLE public.appearance OWNER TO postgres;

--
-- Name: equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment (
    uid integer NOT NULL,
    hat integer,
    cape integer,
    amulet integer,
    shield integer,
    legs integer,
    torso integer,
    gloves integer,
    boots integer,
    ring integer,
    arrows integer
);


ALTER TABLE public.equipment OWNER TO postgres;

--
-- Name: location; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.location (
    uid integer,
    x integer DEFAULT 3240 NOT NULL,
    y integer DEFAULT 3226 NOT NULL,
    z integer DEFAULT 0 NOT NULL,
    prev_x integer DEFAULT 3240 NOT NULL,
    prev_y integer DEFAULT 3226 NOT NULL,
    prev_z integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.location OWNER TO postgres;

--
-- Name: profile; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profile (
    uid integer NOT NULL,
    banned boolean DEFAULT false NOT NULL,
    members boolean DEFAULT true NOT NULL,
    friends_list text[],
    ignore_list text[],
    muted boolean DEFAULT false NOT NULL,
    username text DEFAULT 'context_player'::text NOT NULL,
    password text DEFAULT 'womp'::text NOT NULL
);


ALTER TABLE public.profile OWNER TO postgres;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.settings (
    uid integer NOT NULL,
    move_speed integer DEFAULT 0 NOT NULL,
    energy integer DEFAULT 100 NOT NULL,
    withdraw_note boolean DEFAULT false NOT NULL,
    item_swap boolean DEFAULT false NOT NULL,
    brightness integer DEFAULT 2 NOT NULL,
    mouse_buttons integer DEFAULT 2 NOT NULL,
    chat_effects boolean DEFAULT true NOT NULL,
    auto_retaliate boolean DEFAULT true NOT NULL
);


ALTER TABLE public.settings OWNER TO postgres;

--
-- Name: stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stats (
    uid integer NOT NULL,
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
    runecrafting_exp integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.stats OWNER TO postgres;

--
-- Data for Name: appearance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.appearance (uid, gender, hair_color, torso_color, leg_color, feet_color, skin_color, head, chest, arms, hands, legs, feet, beard) FROM stdin;
\.


--
-- Data for Name: equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment (uid, hat, cape, amulet, shield, legs, torso, gloves, boots, ring, arrows) FROM stdin;
\.


--
-- Data for Name: location; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.location (uid, x, y, z, prev_x, prev_y, prev_z) FROM stdin;
\.


--
-- Data for Name: profile; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profile (uid, banned, members, friends_list, ignore_list, muted, username, password) FROM stdin;
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.settings (uid, move_speed, energy, withdraw_note, item_swap, brightness, mouse_buttons, chat_effects, auto_retaliate) FROM stdin;
\.


--
-- Data for Name: stats; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stats (uid, attack_level, attack_exp, defence_level, defence_exp, strength_level, strength_exp, hit_points_level, hit_points_exp, range_level, range_exp, prayer_level, prayer_exp, magic_level, magic_exp, cooking_level, cooking_exp, woodcutting_level, woodcutting_exp, fletching_level, fletching_exp, fishing_level, fishing_exp, firemaking_level, firemaking_exp, crafting_level, crafting_exp, smithing_level, smithing_exp, mining_level, mining_exp, herblore_level, herblore_exp, agility_level, agility_exp, thieving_level, thieving_exp, slayer_level, slayer_exp, farming_level, farming_exp, runecrafting_level, runecrafting_exp) FROM stdin;
\.


--
-- Name: profile profile_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profile
    ADD CONSTRAINT profile_pk PRIMARY KEY (uid);


--
-- Name: appearance_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX appearance_uid_uindex ON public.appearance USING btree (uid);


--
-- Name: equipment_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX equipment_uid_uindex ON public.equipment USING btree (uid);


--
-- Name: location_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX location_uid_uindex ON public.location USING btree (uid);


--
-- Name: profile_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX profile_uid_uindex ON public.profile USING btree (uid);


--
-- Name: settings_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX settings_uid_uindex ON public.settings USING btree (uid);


--
-- Name: stats_uid_uindex; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX stats_uid_uindex ON public.stats USING btree (uid);


--
-- Name: appearance appearance_profile_uid_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.appearance
    ADD CONSTRAINT appearance_profile_uid_fk FOREIGN KEY (uid) REFERENCES public.profile(uid) ON DELETE CASCADE;


--
-- Name: equipment equipment_profile_uid_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_profile_uid_fk FOREIGN KEY (uid) REFERENCES public.profile(uid) ON DELETE CASCADE;


--
-- Name: location location_profile_uid_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_profile_uid_fk FOREIGN KEY (uid) REFERENCES public.profile(uid) ON DELETE CASCADE;


--
-- Name: settings settings_profile_uid_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_profile_uid_fk FOREIGN KEY (uid) REFERENCES public.profile(uid) ON DELETE CASCADE;


--
-- Name: stats stats_profile_uid_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stats
    ADD CONSTRAINT stats_profile_uid_fk FOREIGN KEY (uid) REFERENCES public.profile(uid) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

