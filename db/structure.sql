--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: batch_invitation_application_permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE batch_invitation_application_permissions (
    id integer NOT NULL,
    batch_invitation_id integer NOT NULL,
    supported_permission_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: batch_invitation_application_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE batch_invitation_application_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_invitation_application_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE batch_invitation_application_permissions_id_seq OWNED BY batch_invitation_application_permissions.id;


--
-- Name: batch_invitation_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE batch_invitation_users (
    id integer NOT NULL,
    batch_invitation_id integer,
    name character varying(255),
    email character varying(255),
    outcome character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: batch_invitation_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE batch_invitation_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_invitation_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE batch_invitation_users_id_seq OWNED BY batch_invitation_users.id;


--
-- Name: batch_invitations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE batch_invitations (
    id integer NOT NULL,
    applications_and_permissions text,
    outcome character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer NOT NULL,
    organisation_id integer
);


--
-- Name: batch_invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE batch_invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batch_invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE batch_invitations_id_seq OWNED BY batch_invitations.id;


--
-- Name: event_logs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE event_logs (
    id integer NOT NULL,
    uid character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    initiator_id integer,
    application_id integer,
    trailing_message character varying(255),
    event_id integer
);


--
-- Name: event_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE event_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE event_logs_id_seq OWNED BY event_logs.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_access_grants (
    id integer NOT NULL,
    resource_owner_id integer NOT NULL,
    application_id integer NOT NULL,
    token character varying(255) NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying(255)
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_grants_id_seq OWNED BY oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_access_tokens (
    id integer NOT NULL,
    resource_owner_id integer NOT NULL,
    application_id integer NOT NULL,
    token character varying(255) NOT NULL,
    refresh_token character varying(255),
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying(255)
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_access_tokens_id_seq OWNED BY oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE oauth_applications (
    id integer NOT NULL,
    name character varying(255),
    uid character varying(255) NOT NULL,
    secret character varying(255) NOT NULL,
    redirect_uri character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    home_uri character varying(255),
    description character varying(255),
    supports_push_updates boolean DEFAULT true
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE oauth_applications_id_seq OWNED BY oauth_applications.id;


--
-- Name: old_passwords; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE old_passwords (
    id integer NOT NULL,
    encrypted_password character varying(255) NOT NULL,
    password_salt character varying(255),
    password_archivable_id integer NOT NULL,
    password_archivable_type character varying(255) NOT NULL,
    created_at timestamp without time zone
);


--
-- Name: old_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE old_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: old_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE old_passwords_id_seq OWNED BY old_passwords.id;


--
-- Name: organisations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE organisations (
    id integer NOT NULL,
    slug character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    organisation_type character varying(255) NOT NULL,
    abbreviation character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ancestry character varying(255),
    content_id character varying(255) NOT NULL,
    closed boolean DEFAULT false
);


--
-- Name: organisations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE organisations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organisations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE organisations_id_seq OWNED BY organisations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: supported_permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE supported_permissions (
    id integer NOT NULL,
    application_id integer,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    delegatable boolean DEFAULT false,
    grantable_from_ui boolean DEFAULT true NOT NULL
);


--
-- Name: supported_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE supported_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supported_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE supported_permissions_id_seq OWNED BY supported_permissions.id;


--
-- Name: user_application_permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_application_permissions (
    id integer NOT NULL,
    user_id integer NOT NULL,
    application_id integer NOT NULL,
    supported_permission_id integer NOT NULL,
    last_synced_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_application_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_application_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_application_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_application_permissions_id_seq OWNED BY user_application_permissions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    uid character varying(255) NOT NULL,
    failed_attempts integer DEFAULT 0,
    locked_at timestamp without time zone,
    suspended_at timestamp without time zone,
    invitation_token character varying(255),
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying(255),
    reason_for_suspension character varying(255),
    password_salt character varying(255),
    confirmation_token character varying(255),
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying(255),
    role character varying(255) DEFAULT 'normal'::character varying,
    password_changed_at timestamp without time zone,
    organisation_id integer,
    api_user boolean DEFAULT false NOT NULL,
    unsuspended_at timestamp without time zone,
    invitation_created_at timestamp without time zone,
    otp_secret_key character varying(255),
    second_factor_attempts_count integer DEFAULT 0,
    unlock_token character varying(255),
    require_2sv boolean DEFAULT false NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY batch_invitation_application_permissions ALTER COLUMN id SET DEFAULT nextval('batch_invitation_application_permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY batch_invitation_users ALTER COLUMN id SET DEFAULT nextval('batch_invitation_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY batch_invitations ALTER COLUMN id SET DEFAULT nextval('batch_invitations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY event_logs ALTER COLUMN id SET DEFAULT nextval('event_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('oauth_access_grants_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('oauth_access_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY oauth_applications ALTER COLUMN id SET DEFAULT nextval('oauth_applications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY old_passwords ALTER COLUMN id SET DEFAULT nextval('old_passwords_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY organisations ALTER COLUMN id SET DEFAULT nextval('organisations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY supported_permissions ALTER COLUMN id SET DEFAULT nextval('supported_permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_application_permissions ALTER COLUMN id SET DEFAULT nextval('user_application_permissions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: batch_invitation_application_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY batch_invitation_application_permissions
    ADD CONSTRAINT batch_invitation_application_permissions_pkey PRIMARY KEY (id);


--
-- Name: batch_invitation_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY batch_invitation_users
    ADD CONSTRAINT batch_invitation_users_pkey PRIMARY KEY (id);


--
-- Name: batch_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY batch_invitations
    ADD CONSTRAINT batch_invitations_pkey PRIMARY KEY (id);


--
-- Name: event_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_logs
    ADD CONSTRAINT event_logs_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_grants_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_access_grants
    ADD CONSTRAINT oauth_access_grants_pkey PRIMARY KEY (id);


--
-- Name: oauth_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_access_tokens
    ADD CONSTRAINT oauth_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: oauth_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY oauth_applications
    ADD CONSTRAINT oauth_applications_pkey PRIMARY KEY (id);


--
-- Name: old_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY old_passwords
    ADD CONSTRAINT old_passwords_pkey PRIMARY KEY (id);


--
-- Name: organisations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organisations
    ADD CONSTRAINT organisations_pkey PRIMARY KEY (id);


--
-- Name: supported_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY supported_permissions
    ADD CONSTRAINT supported_permissions_pkey PRIMARY KEY (id);


--
-- Name: user_application_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_application_permissions
    ADD CONSTRAINT user_application_permissions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_app_permissions_on_user_and_app_and_supported_permission; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_app_permissions_on_user_and_app_and_supported_permission ON user_application_permissions USING btree (user_id, application_id, supported_permission_id);


--
-- Name: index_batch_invitation_users_on_batch_invitation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_batch_invitation_users_on_batch_invitation_id ON batch_invitation_users USING btree (batch_invitation_id);


--
-- Name: index_batch_invitations_on_outcome; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_batch_invitations_on_outcome ON batch_invitations USING btree (outcome);


--
-- Name: index_batch_invite_app_perms_on_batch_invite_and_supported_perm; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_batch_invite_app_perms_on_batch_invite_and_supported_perm ON batch_invitation_application_permissions USING btree (batch_invitation_id, supported_permission_id);


--
-- Name: index_event_logs_on_uid_and_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_event_logs_on_uid_and_created_at ON event_logs USING btree (uid, created_at);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON oauth_applications USING btree (uid);


--
-- Name: index_organisations_on_ancestry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_organisations_on_ancestry ON organisations USING btree (ancestry);


--
-- Name: index_organisations_on_content_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_organisations_on_content_id ON organisations USING btree (content_id);


--
-- Name: index_organisations_on_slug; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_organisations_on_slug ON organisations USING btree (slug);


--
-- Name: index_password_archivable; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_password_archivable ON old_passwords USING btree (password_archivable_type, password_archivable_id);


--
-- Name: index_supported_permissions_on_application_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_supported_permissions_on_application_id ON supported_permissions USING btree (application_id);


--
-- Name: index_supported_permissions_on_application_id_and_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_supported_permissions_on_application_id_and_name ON supported_permissions USING btree (application_id, name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invitation_token ON users USING btree (invitation_token);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_invited_by_id ON users USING btree (invited_by_id);


--
-- Name: index_users_on_organisation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_users_on_organisation_id ON users USING btree (organisation_id);


--
-- Name: index_users_on_otp_secret_key; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_otp_secret_key ON users USING btree (otp_secret_key);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_application_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_application_name ON oauth_applications USING btree (name);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20120402120458');

INSERT INTO schema_migrations (version) VALUES ('20120402150534');

INSERT INTO schema_migrations (version) VALUES ('20120403120725');

INSERT INTO schema_migrations (version) VALUES ('20120410094033');

INSERT INTO schema_migrations (version) VALUES ('20120410094527');

INSERT INTO schema_migrations (version) VALUES ('20120412131921');

INSERT INTO schema_migrations (version) VALUES ('20120609094354');

INSERT INTO schema_migrations (version) VALUES ('20120609094747');

INSERT INTO schema_migrations (version) VALUES ('20120611131259');

INSERT INTO schema_migrations (version) VALUES ('20120612135328');

INSERT INTO schema_migrations (version) VALUES ('20120619152849');

INSERT INTO schema_migrations (version) VALUES ('20120626083344');

INSERT INTO schema_migrations (version) VALUES ('20120626083357');

INSERT INTO schema_migrations (version) VALUES ('20120626094255');

INSERT INTO schema_migrations (version) VALUES ('20120704103854');

INSERT INTO schema_migrations (version) VALUES ('20120704154406');

INSERT INTO schema_migrations (version) VALUES ('20120704154718');

INSERT INTO schema_migrations (version) VALUES ('20120716130107');

INSERT INTO schema_migrations (version) VALUES ('20120720131717');

INSERT INTO schema_migrations (version) VALUES ('20120818153021');

INSERT INTO schema_migrations (version) VALUES ('20120828162043');

INSERT INTO schema_migrations (version) VALUES ('20120917131351');

INSERT INTO schema_migrations (version) VALUES ('20121005182447');

INSERT INTO schema_migrations (version) VALUES ('20121011155199');

INSERT INTO schema_migrations (version) VALUES ('20121011166199');

INSERT INTO schema_migrations (version) VALUES ('20121113163308');

INSERT INTO schema_migrations (version) VALUES ('20121203213600');

INSERT INTO schema_migrations (version) VALUES ('20121204162009');

INSERT INTO schema_migrations (version) VALUES ('20121206132458');

INSERT INTO schema_migrations (version) VALUES ('20130102141559');

INSERT INTO schema_migrations (version) VALUES ('20130308163556');

INSERT INTO schema_migrations (version) VALUES ('20130405143200');

INSERT INTO schema_migrations (version) VALUES ('20130405153812');

INSERT INTO schema_migrations (version) VALUES ('20130408161502');

INSERT INTO schema_migrations (version) VALUES ('20130417093614');

INSERT INTO schema_migrations (version) VALUES ('20130424141419');

INSERT INTO schema_migrations (version) VALUES ('20130430121058');

INSERT INTO schema_migrations (version) VALUES ('20130526064927');

INSERT INTO schema_migrations (version) VALUES ('20130621142506');

INSERT INTO schema_migrations (version) VALUES ('20130801170805');

INSERT INTO schema_migrations (version) VALUES ('20130913103447');

INSERT INTO schema_migrations (version) VALUES ('20130926134720');

INSERT INTO schema_migrations (version) VALUES ('20131021123740');

INSERT INTO schema_migrations (version) VALUES ('20131023081914');

INSERT INTO schema_migrations (version) VALUES ('20131101160634');

INSERT INTO schema_migrations (version) VALUES ('20131118213228');

INSERT INTO schema_migrations (version) VALUES ('20131204154029');

INSERT INTO schema_migrations (version) VALUES ('20131205160534');

INSERT INTO schema_migrations (version) VALUES ('20131216145229');

INSERT INTO schema_migrations (version) VALUES ('20140114144500');

INSERT INTO schema_migrations (version) VALUES ('20140114145520');

INSERT INTO schema_migrations (version) VALUES ('20140114151134');

INSERT INTO schema_migrations (version) VALUES ('20140115153510');

INSERT INTO schema_migrations (version) VALUES ('20140115153833');

INSERT INTO schema_migrations (version) VALUES ('20140123152440');

INSERT INTO schema_migrations (version) VALUES ('20140130155326');

INSERT INTO schema_migrations (version) VALUES ('20140203105954');

INSERT INTO schema_migrations (version) VALUES ('20140220150716');

INSERT INTO schema_migrations (version) VALUES ('20140319200000');

INSERT INTO schema_migrations (version) VALUES ('20140319222924');

INSERT INTO schema_migrations (version) VALUES ('20140320162328');

INSERT INTO schema_migrations (version) VALUES ('20140409170000');

INSERT INTO schema_migrations (version) VALUES ('20140519150300');

INSERT INTO schema_migrations (version) VALUES ('20140623065028');

INSERT INTO schema_migrations (version) VALUES ('20140723085640');

INSERT INTO schema_migrations (version) VALUES ('20140917082742');

INSERT INTO schema_migrations (version) VALUES ('20140917091319');

INSERT INTO schema_migrations (version) VALUES ('20150107063935');

INSERT INTO schema_migrations (version) VALUES ('20150109083425');

INSERT INTO schema_migrations (version) VALUES ('20150113064454');

INSERT INTO schema_migrations (version) VALUES ('20150121073933');

INSERT INTO schema_migrations (version) VALUES ('20150121092250');

INSERT INTO schema_migrations (version) VALUES ('20150204115922');

INSERT INTO schema_migrations (version) VALUES ('20150204132812');

INSERT INTO schema_migrations (version) VALUES ('20150211091009');

INSERT INTO schema_migrations (version) VALUES ('20150212133251');

INSERT INTO schema_migrations (version) VALUES ('20150420145301');

INSERT INTO schema_migrations (version) VALUES ('20150421140645');

INSERT INTO schema_migrations (version) VALUES ('20150501101146');

INSERT INTO schema_migrations (version) VALUES ('20150507135123');

INSERT INTO schema_migrations (version) VALUES ('20150507160746');

INSERT INTO schema_migrations (version) VALUES ('20150811150231');

INSERT INTO schema_migrations (version) VALUES ('20150928115351');

INSERT INTO schema_migrations (version) VALUES ('20150929135437');

INSERT INTO schema_migrations (version) VALUES ('20151001095709');

INSERT INTO schema_migrations (version) VALUES ('20151006091244');

INSERT INTO schema_migrations (version) VALUES ('20151112110911');

INSERT INTO schema_migrations (version) VALUES ('20151120134709');

INSERT INTO schema_migrations (version) VALUES ('20151202120153');

INSERT INTO schema_migrations (version) VALUES ('20151203161459');

