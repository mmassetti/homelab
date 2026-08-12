--
-- PostgreSQL database dump
--

\restrict R3jWY95dLycO3vA8TOrGKoJZA6zoIFE7MxAfdARcyin2GZiTaSUNx7G3SLUUJrQ

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- Name: review_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.review_images (
    id integer NOT NULL,
    review_id integer,
    image_url text NOT NULL,
    image_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: review_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.review_images_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: review_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.review_images_id_seq OWNED BY public.review_images.id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    date date NOT NULL,
    place text NOT NULL,
    masa_score numeric(3,1),
    jj_score numeric(3,1),
    bian_score numeric(3,1),
    photo_url text,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    masa_notes text,
    jj_notes text,
    bian_notes text,
    CONSTRAINT reviews_bian_score_check CHECK (((bian_score >= 1.0) AND (bian_score <= 10.0))),
    CONSTRAINT reviews_jj_score_check CHECK (((jj_score >= 1.0) AND (jj_score <= 10.0))),
    CONSTRAINT reviews_masa_score_check CHECK (((masa_score >= 1.0) AND (masa_score <= 10.0)))
);


--
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- Name: review_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_images ALTER COLUMN id SET DEFAULT nextval('public.review_images_id_seq'::regclass);


--
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- Data for Name: review_images; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.review_images (id, review_id, image_url, image_order, created_at) FROM stdin;
3	3	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755568006868-e973a0ba-3dbe-4da7-b5c7-91ac719991f3.jpeg	0	2025-08-19 01:46:47.904692+00
6	5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755632981405-1000283701.jpg	0	2025-08-19 19:49:52.509578+00
7	5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755632981405-1000283705.jpg	1	2025-08-19 19:49:52.509578+00
8	5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755632981405-1000283706.jpg	2	2025-08-19 19:49:52.509578+00
9	5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755632981405-1000283707.jpg	3	2025-08-19 19:49:52.509578+00
10	5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755632981405-1000283708.jpg	4	2025-08-19 19:49:52.509578+00
11	6	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1756411314002-1000286150.jpg	0	2025-08-28 20:02:06.832211+00
12	6	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1756411314002-1000286151.jpg	1	2025-08-28 20:02:06.832211+00
13	6	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1756411314002-1000286152.jpg	2	2025-08-28 20:02:06.832211+00
14	6	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1756411314002-1000286153.jpg	3	2025-08-28 20:02:06.832211+00
15	7	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1758052923733-1000292582.jpg	0	2025-09-16 20:02:08.723594+00
16	7	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1758052923734-1000292583.jpg	1	2025-09-16 20:02:08.723594+00
17	7	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1758052923734-1000292584.jpg	2	2025-09-16 20:02:08.723594+00
18	7	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1758052923734-1000292585.jpg	3	2025-09-16 20:02:08.723594+00
19	8	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1761165481776-1000304200.jpg	0	2025-10-22 20:38:07.637085+00
20	8	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1761165481777-1000304201.jpg	1	2025-10-22 20:38:07.637085+00
21	8	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1761165481777-1000304202.jpg	2	2025-10-22 20:38:07.637085+00
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews (id, date, place, masa_score, jj_score, bian_score, photo_url, notes, created_at, masa_notes, jj_notes, bian_notes) FROM stdin;
3	2025-08-08	Della Nonna	5.5	6.0	6.5	https://766eljnpwyiidnd3.public.blob.vercel-storage.com/ricota-1755566002830-avatar2.jpg	Primera torta del tour ricotero. No hubo foto de la torta :(	2025-08-13 02:11:13.076796+00	Es bueno haber arrancado con esta torta, porque ahora debería ir mejorando. Me parece que no era fresca. Seca, se desarmaba, mucha azucar impalpable, fea.	Se desarmaba al momento de cortar, seca. La masa no tenía mucho sabor. Difícil de comer. A la vista tampoco decía mucho	Media secarda pero para unos mates estaba okey 
9	2026-08-11	La Casa Cafe & Deco	9.0	9.0	9.0	\N	\N	2026-08-11 19:20:19.017381+00	\N	\N	\N
5	2025-08-19	La nueva sirena	8.0	7.0	8.5	\N	Segunda torta del tour. Día gris en la ciudad. Escuchando 'Jungle Radio' en la ofi	2025-08-19 19:49:03.389737+00	Muy buena presentación, clean. Buen sabor en boca luego del primer bocado. Algo polémica la base, media cruda. También dudoso el azúcar impalpable, un poco molesto.	Mejor que la anterior. Ya a la vista decía mucho. Me gusta el toque de limón. Un poco húmeda la masa	Muy buena, estaba humeda y tenia buen relleno
7	2025-09-16	Clásica	6.0	5.0	5.0	\N	Juega Mastantuono la champions. Día agradable pero con algo de viento, como siempre. A Bian le duele un ojo y a Jj la espalda. Yo de algo me queje seguro	2025-09-16 19:52:27.877774+00	Media secona. Si o si con mate. Demasiado masa poco relleno	No me gusto que tenga nueces, son las que le sobraron del pan dulce. No se nota mucho el gusto a la ricota	Seca, le falta ricota
6	2025-08-28	La Boutique del pan 	6.5	6.0	6.0	\N	Torta ¿de ricota? #3 - jueves agradable, 23 grados. Vino Ignacio 	2025-08-28 20:01:53.723228+00	\N	Muy humeda y con mucho azucar. Se perdia el sabor de la ricota	\N
8	2025-10-22	Boulangerie	9.0	1.0	8.5	\N	Miércoles 17.30 horas. Un tipo con el taladro rompiendo los huevos. A la noche flamengo racing ida semi finales copa libertadores de América	2025-10-22 20:38:01.15894+00	Llegamos de pedo a esta. La idea era comprar en otro lado. En el mostrador no tenía nada de pinta, imaginate que compramos alfajorcitos por las dudas. Pero sorprendió la guacha, estaba muy rica, es la imagen que se me viene cuando le dicen torta de ricota, volvería a comprarla 	\N	Muy rica, la naranja sumaba
\.


--
-- Name: review_images_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.review_images_id_seq', 21, true);


--
-- Name: reviews_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reviews_id_seq', 9, true);


--
-- Name: review_images review_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_images
    ADD CONSTRAINT review_images_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: idx_review_images_review_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_review_images_review_id ON public.review_images USING btree (review_id);


--
-- Name: idx_reviews_bian_notes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviews_bian_notes ON public.reviews USING gin (to_tsvector('spanish'::regconfig, bian_notes)) WHERE (bian_notes IS NOT NULL);


--
-- Name: idx_reviews_jj_notes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviews_jj_notes ON public.reviews USING gin (to_tsvector('spanish'::regconfig, jj_notes)) WHERE (jj_notes IS NOT NULL);


--
-- Name: idx_reviews_masa_notes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reviews_masa_notes ON public.reviews USING gin (to_tsvector('spanish'::regconfig, masa_notes)) WHERE (masa_notes IS NOT NULL);


--
-- Name: review_images review_images_review_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.review_images
    ADD CONSTRAINT review_images_review_id_fkey FOREIGN KEY (review_id) REFERENCES public.reviews(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict R3jWY95dLycO3vA8TOrGKoJZA6zoIFE7MxAfdARcyin2GZiTaSUNx7G3SLUUJrQ

