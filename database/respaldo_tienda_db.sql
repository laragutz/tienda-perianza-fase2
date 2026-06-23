--
-- PostgreSQL database dump
--

\restrict Ni3bXi69n4JbqQC9ChX5MLOmq7uRkzcEhZsa4vOhdXmvdXlFdrFP7ptL4eGQwvK

-- Dumped from database version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.14 (Ubuntu 16.14-0ubuntu0.24.04.1)

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
-- Name: sp_productos(json, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_productos(p_json json, p_delete boolean DEFAULT false) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id        INT;
    v_nombre    VARCHAR(150);
    v_sku       VARCHAR(50);
    v_categoria VARCHAR(100);
    v_precio    DECIMAL(10,2);
    v_stock     INT;
    v_activo    BOOLEAN;
BEGIN
    v_id        := NULLIF(p_json->>'id', '')::INT;
    v_nombre    := p_json->>'nombre';
    v_sku       := p_json->>'sku';
    v_categoria := p_json->>'categoria';
    v_precio    := NULLIF(p_json->>'precio', '')::DECIMAL;
    v_stock     := NULLIF(p_json->>'stock', '')::INT;
    v_activo    := COALESCE((p_json->>'activo')::BOOLEAN, TRUE);

    IF NOT p_delete THEN
        IF v_nombre IS NULL OR TRIM(v_nombre) = '' THEN RETURN 'ERROR: El nombre es requerido'; END IF;
        IF v_sku IS NULL OR TRIM(v_sku) = '' THEN RETURN 'ERROR: El SKU es requerido'; END IF;
        IF v_categoria IS NULL OR TRIM(v_categoria) = '' THEN RETURN 'ERROR: La categoría es requerida'; END IF;
        IF v_precio IS NULL OR v_precio <= 0 THEN RETURN 'ERROR: El precio debe ser mayor a 0'; END IF;
        IF v_stock IS NULL OR v_stock < 0 THEN RETURN 'ERROR: El stock no puede ser negativo'; END IF;
    END IF;

    IF p_delete THEN
        UPDATE productos SET activo = FALSE WHERE id = v_id;
    ELSIF v_id IS NOT NULL THEN
        UPDATE productos SET
            nombre    = v_nombre,
            sku       = v_sku,
            categoria = v_categoria,
            precio    = v_precio,
            stock     = v_stock,
            activo    = v_activo
        WHERE id = v_id;
    ELSE
        INSERT INTO productos (nombre, sku, categoria, precio, stock, activo, fecha_registro)
        VALUES (v_nombre, v_sku, v_categoria, v_precio, v_stock, v_activo, NOW());
    END IF;

    RETURN 'EXITO: Operación realizada correctamente';

EXCEPTION WHEN OTHERS THEN
    RETURN 'ERROR: ' || SQLERRM;
END;
$$;


ALTER FUNCTION public.sp_productos(p_json json, p_delete boolean) OWNER TO postgres;

--
-- Name: sp_productos_get(text, text, date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sp_productos_get(p_buscar text DEFAULT NULL::text, p_categoria text DEFAULT NULL::text, p_fecha_inicio date DEFAULT NULL::date, p_fecha_fin date DEFAULT NULL::date) RETURNS TABLE(id integer, nombre character varying, sku character varying, categoria character varying, precio numeric, stock integer, activo boolean, fecha_registro timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.nombre,
        p.sku,
        p.categoria,
        p.precio,
        p.stock,
        p.activo,
        p.fecha_registro
    FROM productos p
    WHERE p.activo = TRUE
      AND (p_buscar IS NULL OR (
            p.nombre    ILIKE '%' || p_buscar || '%' OR
            p.sku       ILIKE '%' || p_buscar || '%' OR
            p.categoria ILIKE '%' || p_buscar || '%'
          ))
      AND (p_categoria IS NULL OR p.categoria = p_categoria)
      AND (p_fecha_inicio IS NULL OR p.fecha_registro::DATE >= p_fecha_inicio)
      AND (p_fecha_fin    IS NULL OR p.fecha_registro::DATE <= p_fecha_fin)
    ORDER BY p.id;
END;
$$;


ALTER FUNCTION public.sp_productos_get(p_buscar text, p_categoria text, p_fecha_inicio date, p_fecha_fin date) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cache; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache OWNER TO tienda_user;

--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration bigint NOT NULL
);


ALTER TABLE public.cache_locks OWNER TO tienda_user;

--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection character varying(255) NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.failed_jobs OWNER TO tienda_user;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: tienda_user
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.failed_jobs_id_seq OWNER TO tienda_user;

--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tienda_user
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


ALTER TABLE public.job_batches OWNER TO tienda_user;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


ALTER TABLE public.jobs OWNER TO tienda_user;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: tienda_user
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.jobs_id_seq OWNER TO tienda_user;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tienda_user
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


ALTER TABLE public.migrations OWNER TO tienda_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: tienda_user
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO tienda_user;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tienda_user
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


ALTER TABLE public.password_reset_tokens OWNER TO tienda_user;

--
-- Name: personal_access_tokens; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.personal_access_tokens (
    id bigint NOT NULL,
    tokenable_type character varying(255) NOT NULL,
    tokenable_id bigint NOT NULL,
    name text NOT NULL,
    token character varying(64) NOT NULL,
    abilities text,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.personal_access_tokens OWNER TO tienda_user;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: tienda_user
--

CREATE SEQUENCE public.personal_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personal_access_tokens_id_seq OWNER TO tienda_user;

--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tienda_user
--

ALTER SEQUENCE public.personal_access_tokens_id_seq OWNED BY public.personal_access_tokens.id;


--
-- Name: productos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.productos (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    sku character varying(50) NOT NULL,
    categoria character varying(100) NOT NULL,
    precio numeric(10,2) NOT NULL,
    stock integer NOT NULL,
    activo boolean DEFAULT true,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.productos OWNER TO postgres;

--
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.productos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.productos_id_seq OWNER TO postgres;

--
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


ALTER TABLE public.sessions OWNER TO tienda_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: tienda_user
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    email_verified_at timestamp(0) without time zone,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


ALTER TABLE public.users OWNER TO tienda_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: tienda_user
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO tienda_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: tienda_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: personal_access_tokens id; Type: DEFAULT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.personal_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.personal_access_tokens_id_seq'::regclass);


--
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.cache (key, value, expiration) FROM stdin;
\.


--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.cache_locks (key, owner, expiration) FROM stdin;
\.


--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.failed_jobs (id, uuid, connection, queue, payload, exception, failed_at) FROM stdin;
\.


--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.job_batches (id, name, total_jobs, pending_jobs, failed_jobs, failed_job_ids, options, cancelled_at, created_at, finished_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.jobs (id, queue, payload, attempts, reserved_at, available_at, created_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.migrations (id, migration, batch) FROM stdin;
1	0001_01_01_000000_create_users_table	1
2	0001_01_01_000001_create_cache_table	1
3	0001_01_01_000002_create_jobs_table	1
4	2026_06_22_230908_create_personal_access_tokens_table	1
\.


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.password_reset_tokens (email, token, created_at) FROM stdin;
\.


--
-- Data for Name: personal_access_tokens; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.personal_access_tokens (id, tokenable_type, tokenable_id, name, token, abilities, last_used_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.productos (id, nombre, sku, categoria, precio, stock, activo, fecha_registro) FROM stdin;
102	Audífonos Bluetooth Pro	AUD-BT-02	Electrónica	89.99	45	t	2025-02-20 11:30:00
103	Laptop Pro 16GB RAM	LAP-PRO-16	Cómputo	1200.00	8	t	2025-03-05 09:15:00
104	Mouse Ergonómico	MOU-ERG-04	Cómputo	35.50	120	t	2025-04-12 14:00:00
105	Refrigerador No Frost 400L	REF-NF-400	Línea Blanca	650.00	5	t	2025-05-18 16:45:00
106	Tenis Deportivos Running	TEN-RUN-88	Moda	75.00	60	t	2025-06-01 12:00:00
107	Chaqueta de Cuero Sintético	CHA-CUE-07	Moda	120.00	25	t	2025-06-15 08:30:00
108	Sofá Cama Contemporáneo	SOF-CAM-05	Hogar y Cocina	350.00	12	t	2025-07-02 11:00:00
109	Cafetera de Goteo Programable	CAF-GOT-09	Hogar y Cocina	45.00	40	t	2025-07-22 15:20:00
110	Bicicleta de Montaña R29	BIC-MON-29	Deportes	580.00	7	t	2025-08-05 09:00:00
111	Set de Mancuernas 20kg	SET-MAN-20	Deportes	65.00	30	t	2025-08-19 17:10:00
101	Smart TV 55 Pulgadas 4K	TV-55-4K-01	Electrónica	450.00	15	t	2025-01-15 10:00:00
115	Sérum Facial Ácido Hialurónico	BEL-SER-15	Belleza	24.50	100	t	2025-10-20 16:00:00
114	Compresor de Aire Portátil	AUT-COM-14	Automotriz	55.00	18	t	2025-10-02 11:15:00
113	Set de Bloques de Construcción	JUG-BLO-13	Juguetes	29.99	85	t	2025-09-15 14:30:00
112	Libro: Clean Code	LIB-CC-2022	Libros	42.00	50	t	2025-09-01 10:45:00
116	eliseo perianza	115	Electrónica	10.00	10	f	2026-06-23 00:47:47.602724
118	eliseo 02	0	Electrónica	10.00	15	f	2026-06-23 00:55:24.137596
119	eliseo 3	a	Electrónica	10.00	10	f	2026-06-23 01:32:27.56821
121	aaa	aaa	Electrónica	10.00	11	f	2026-06-23 01:32:55.793651
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: tienda_user
--

COPY public.users (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) FROM stdin;
\.


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tienda_user
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tienda_user
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tienda_user
--

SELECT pg_catalog.setval('public.migrations_id_seq', 4, true);


--
-- Name: personal_access_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tienda_user
--

SELECT pg_catalog.setval('public.personal_access_tokens_id_seq', 1, false);


--
-- Name: productos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.productos_id_seq', 121, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: tienda_user
--

SELECT pg_catalog.setval('public.users_id_seq', 1, false);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: personal_access_tokens personal_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: personal_access_tokens personal_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.personal_access_tokens
    ADD CONSTRAINT personal_access_tokens_token_unique UNIQUE (token);


--
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- Name: productos productos_sku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_sku_key UNIQUE (sku);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_unique; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_unique UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: tienda_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- Name: failed_jobs_connection_queue_failed_at_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX failed_jobs_connection_queue_failed_at_index ON public.failed_jobs USING btree (connection, queue, failed_at);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: personal_access_tokens_expires_at_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX personal_access_tokens_expires_at_index ON public.personal_access_tokens USING btree (expires_at);


--
-- Name: personal_access_tokens_tokenable_type_tokenable_id_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX personal_access_tokens_tokenable_type_tokenable_id_index ON public.personal_access_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: tienda_user
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: FUNCTION sp_productos(p_json json, p_delete boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_productos(p_json json, p_delete boolean) TO tienda_user;


--
-- Name: FUNCTION sp_productos_get(p_buscar text, p_categoria text, p_fecha_inicio date, p_fecha_fin date); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.sp_productos_get(p_buscar text, p_categoria text, p_fecha_inicio date, p_fecha_fin date) TO tienda_user;


--
-- Name: TABLE productos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.productos TO tienda_user;


--
-- Name: SEQUENCE productos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.productos_id_seq TO tienda_user;


--
-- PostgreSQL database dump complete
--

\unrestrict Ni3bXi69n4JbqQC9ChX5MLOmq7uRkzcEhZsa4vOhdXmvdXlFdrFP7ptL4eGQwvK

