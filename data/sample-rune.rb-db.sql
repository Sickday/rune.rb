--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

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

DROP DATABASE IF EXISTS "rune.rb";
--
-- Name: rune.rb; Type: DATABASE; Schema: -; Owner: rune.rb
--

CREATE DATABASE "rrb" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';

-- User is required. Password is randomly generated. Change it if you like.
CREATE USER "rune.rb" WITH PASSWORD 'XNzla1nFaI3nz0vU297Tm3s7EA8gmbREfo70FiTpTLPN5ztKs894hRVA0z68S67D';

ALTER DATABASE "rrb" OWNER TO "rune.rb";

\connect "rrb"

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
-- Name: game; Type: SCHEMA; Schema: -; Owner: rune.rb
--

CREATE SCHEMA game;


ALTER SCHEMA game OWNER TO "rune.rb";

--
-- Name: SCHEMA game; Type: COMMENT; Schema: -; Owner: rune.rb
--

COMMENT ON SCHEMA game IS 'Game-related data';


--
-- Name: mob; Type: SCHEMA; Schema: -; Owner: rune.rb
--

CREATE SCHEMA mob;


ALTER SCHEMA mob OWNER TO "rune.rb";

--
-- Name: SCHEMA mob; Type: COMMENT; Schema: -; Owner: rune.rb
--

COMMENT ON SCHEMA mob IS 'Mob-related data';


--
-- Name: player; Type: SCHEMA; Schema: -; Owner: rune.rb
--

CREATE SCHEMA player;


ALTER SCHEMA player OWNER TO "rune.rb";

--
-- Name: SCHEMA player; Type: COMMENT; Schema: -; Owner: rune.rb
--

COMMENT ON SCHEMA player IS 'Player-related data';


--
-- Name: system; Type: SCHEMA; Schema: -; Owner: rune.rb
--

CREATE SCHEMA system;


ALTER SCHEMA system OWNER TO "rune.rb";

--
-- Name: SCHEMA system; Type: COMMENT; Schema: -; Owner: rune.rb
--

COMMENT ON SCHEMA system IS 'System-related data';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: appearance; Type: TABLE; Schema: player; Owner: rune.rb
--

CREATE TABLE player.appearance (
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
    stand_emote integer DEFAULT 808 NOT NULL,
    stand_turn_emote integer DEFAULT 823 NOT NULL,
    walk_emote integer DEFAULT 819 NOT NULL,
    turn_180_emote integer DEFAULT 820 NOT NULL,
    turn_90_cw_emote integer DEFAULT 821 NOT NULL,
    turn_90_ccw_emote integer DEFAULT 822 NOT NULL,
    run_emote integer DEFAULT 824 NOT NULL,
    head_icon integer DEFAULT 0 NOT NULL,
    id integer NOT NULL,
    skulled boolean DEFAULT false NOT NULL
);


ALTER TABLE player.appearance OWNER TO "rune.rb";

--
-- Name: location; Type: TABLE; Schema: player; Owner: rune.rb
--

CREATE TABLE player.location (
    x integer DEFAULT 3222 NOT NULL,
    y integer DEFAULT 3222 NOT NULL,
    z integer DEFAULT 0 NOT NULL,
    prev_x integer DEFAULT 2606 NOT NULL,
    prev_y integer DEFAULT 3095 NOT NULL,
    prev_z integer DEFAULT 0 NOT NULL,
    id integer NOT NULL
);


ALTER TABLE player.location OWNER TO "rune.rb";

--
-- Name: profile; Type: TABLE; Schema: player; Owner: rune.rb
--

CREATE TABLE player.profile (
    banned boolean DEFAULT false NOT NULL,
    muted boolean DEFAULT false NOT NULL,
    members boolean DEFAULT false NOT NULL,
    friends text[] NOT NULL,
    ignores text[] NOT NULL,
    rights smallint DEFAULT 0 NOT NULL,
    inventory json NOT NULL,
    equipment json NOT NULL,
    password text DEFAULT 'passw0rd'::text NOT NULL,
    username character varying(20) DEFAULT 'context'::character varying NOT NULL,
    name_hash bigint DEFAULT 0 NOT NULL,
    id integer NOT NULL

);


ALTER TABLE player.profile OWNER TO "rune.rb";

--
-- Name: settings; Type: TABLE; Schema: player; Owner: rune.rb
--

CREATE TABLE player.settings (
    movement_speed smallint DEFAULT 0 NOT NULL,
    energy smallint DEFAULT 0 NOT NULL,
    bank_noted_withdrawal boolean DEFAULT false NOT NULL,
    bank_item_swap boolean DEFAULT false NOT NULL,
    multi_mouse_button boolean DEFAULT true NOT NULL,
    chat_effects boolean DEFAULT true NOT NULL,
    auto_retaliate boolean DEFAULT true NOT NULL,
    id integer NOT NULL
);


ALTER TABLE player.settings OWNER TO "rune.rb";

--
-- Name: skills; Type: TABLE; Schema: player; Owner: rune.rb
--

CREATE TABLE player.skills (
    attack_level smallint DEFAULT 1 NOT NULL,
    attack_experience bigint DEFAULT 0 NOT NULL,
    defence_level smallint DEFAULT 1 NOT NULL,
    defence_experience bigint DEFAULT 0 NOT NULL,
    strength_level smallint DEFAULT 1 NOT NULL,
    strength_experience bigint DEFAULT 0 NOT NULL,
    hit_points_level smallint DEFAULT 10 NOT NULL,
    hit_points_experience bigint DEFAULT 1184 NOT NULL,
    range_level smallint DEFAULT 1 NOT NULL,
    range_experience bigint DEFAULT 0 NOT NULL,
    prayer_level smallint DEFAULT 1 NOT NULL,
    prayer_experience bigint DEFAULT 0 NOT NULL,
    magic_level smallint DEFAULT 1 NOT NULL,
    magic_experience bigint DEFAULT 0 NOT NULL,
    cooking_level smallint DEFAULT 1 NOT NULL,
    cooking_experience bigint DEFAULT 0 NOT NULL,
    woodcutting_level smallint DEFAULT 1 NOT NULL,
    woodcutting_experience bigint DEFAULT 0 NOT NULL,
    fletching_level smallint DEFAULT 1 NOT NULL,
    fletching_experience bigint DEFAULT 0 NOT NULL,
    fishing_level smallint DEFAULT 1 NOT NULL,
    fishing_experience bigint DEFAULT 0 NOT NULL,
    firemaking_level smallint DEFAULT 1 NOT NULL,
    firemaking_experience bigint DEFAULT 0 NOT NULL,
    crafting_level smallint DEFAULT 1 NOT NULL,
    crafting_experience bigint DEFAULT 0 NOT NULL,
    smithing_level smallint DEFAULT 1 NOT NULL,
    smithing_experience bigint DEFAULT 0 NOT NULL,
    mining_level smallint DEFAULT 1 NOT NULL,
    mining_experience bigint DEFAULT 0 NOT NULL,
    herblore_level smallint DEFAULT 1 NOT NULL,
    herblore_experience bigint DEFAULT 0 NOT NULL,
    agility_level smallint DEFAULT 1 NOT NULL,
    agility_experience bigint DEFAULT 0 NOT NULL,
    thieving_level smallint DEFAULT 1 NOT NULL,
    thieving_experience bigint DEFAULT 0 NOT NULL,
    slayer_level smallint DEFAULT 1 NOT NULL,
    slayer_experience bigint DEFAULT 0 NOT NULL,
    farming_level smallint DEFAULT 1 NOT NULL,
    farming_experience bigint DEFAULT 0 NOT NULL,
    runecrafting_level smallint DEFAULT 1 NOT NULL,
    runecrafting_experience bigint DEFAULT 0 NOT NULL,
    id integer NOT NULL
);


ALTER TABLE player.skills OWNER TO "rune.rb";

--
-- Name: banned_names; Type: TABLE; Schema: system; Owner: rune.rb
--

CREATE TABLE system.banned_names (
    name text NOT NULL,
    "regex?" boolean DEFAULT false NOT NULL
);


ALTER TABLE system.banned_names OWNER TO "rune.rb";

--
-- Data for Name: banned_names; Type: TABLE DATA; Schema: system; Owner: rune.rb
--

INSERT INTO system.banned_names VALUES ('', false);


--
-- Name: appearance appearance_pk; Type: CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.appearance
    ADD CONSTRAINT appearance_pk PRIMARY KEY (id);


--
-- Name: location location_pk; Type: CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.location
    ADD CONSTRAINT location_pk PRIMARY KEY (id);


--
-- Name: profile profile_pk; Type: CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.profile
    ADD CONSTRAINT profile_pk PRIMARY KEY (id);


--
-- Name: settings settings_pk; Type: CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.settings
    ADD CONSTRAINT settings_pk PRIMARY KEY (id);


--
-- Name: skills skills_pk; Type: CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.skills
    ADD CONSTRAINT skills_pk PRIMARY KEY (id);


--
-- Name: appearance_id_uindex; Type: INDEX; Schema: player; Owner: rune.rb
--

CREATE UNIQUE INDEX appearance_id_uindex ON player.appearance USING btree (id);


--
-- Name: location_id_uindex; Type: INDEX; Schema: player; Owner: rune.rb
--

CREATE UNIQUE INDEX location_id_uindex ON player.location USING btree (id);


--
-- Name: profile_id_uindex; Type: INDEX; Schema: player; Owner: rune.rb
--

CREATE UNIQUE INDEX profile_id_uindex ON player.profile USING btree (id);


--
-- Name: settings_id_uindex; Type: INDEX; Schema: player; Owner: rune.rb
--

CREATE UNIQUE INDEX settings_id_uindex ON player.settings USING btree (id);


--
-- Name: skills_id_uindex; Type: INDEX; Schema: player; Owner: rune.rb
--

CREATE UNIQUE INDEX skills_id_uindex ON player.skills USING btree (id);


--
-- Name: banned_names_name_uindex; Type: INDEX; Schema: system; Owner: rune.rb
--

CREATE UNIQUE INDEX banned_names_name_uindex ON system.banned_names USING btree (name);


--
-- Name: appearance appearance_profile_id_fk; Type: FK CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.appearance
    ADD CONSTRAINT appearance_profile_id_fk FOREIGN KEY (id) REFERENCES player.profile(id) ON DELETE CASCADE;


--
-- Name: location location_profile_id_fk; Type: FK CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.location
    ADD CONSTRAINT location_profile_id_fk FOREIGN KEY (id) REFERENCES player.profile(id) ON DELETE CASCADE;


--
-- Name: settings settings_profile_id_fk; Type: FK CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.settings
    ADD CONSTRAINT settings_profile_id_fk FOREIGN KEY (id) REFERENCES player.profile(id) ON DELETE CASCADE;


--
-- Name: skills skills_profile_id_fk; Type: FK CONSTRAINT; Schema: player; Owner: rune.rb
--

ALTER TABLE ONLY player.skills
    ADD CONSTRAINT skills_profile_id_fk FOREIGN KEY (id) REFERENCES player.profile(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

