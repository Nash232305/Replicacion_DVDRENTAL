--Crea rol de empleado
CREATE ROLE emp;

-- crea las funciones
CREATE OR REPLACE PROCEDURE registrar_alquiler(
    in_rental_date TIMESTAMP WITHOUT TIME ZONE,
    in_inventory_id INT,
    in_customer_id SMALLINT,
    in_return_date TIMESTAMP WITHOUT TIME ZONE,
    in_staff_id SMALLINT,
    in_last_update TIMESTAMP WITHOUT TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Registra un alquiler en la tabla de alquileres
    INSERT INTO rental (
        rental_date, inventory_id, customer_id, return_date, staff_id, last_update
    )
    VALUES (
        in_rental_date, in_inventory_id, in_customer_id,
        in_return_date, in_staff_id, in_last_update
    );

	RAISE NOTICE 'Alquiler registrado correctamente';
	
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'El ID de alquiler ya existe.';
      
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'El inventory_id, customer_id o staff_id no son válidos.';
  
    WHEN others THEN
        RAISE NOTICE 'Ocurrió un error: %', SQLERRM;

END;
$$;

CREATE OR REPLACE PROCEDURE registrar_devolucion(InRental_id INT, InReturn_date DATE)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    IdInventory INT;
BEGIN
    -- Actualizar la fecha de devolución en la tabla rental
    UPDATE rental
    SET return_date = InReturn_date
    WHERE rental_id = InRental_id;

    -- Obtener el inventory_id asociado con el rental_id
    SELECT inventory_id INTO IdInventory
    FROM rental
    WHERE rental_id = InRental_id;

    -- Actualizar la disponibilidad en la tabla inventory
    UPDATE inventory
    SET last_update= NOW()
    WHERE inventory_id = IdInventory;

    -- Confirmar la transacción
    RAISE NOTICE 'Devolución registrada exitosamente para rental_id: %',InRental_id;
    
EXCEPTION
    WHEN OTHERS THEN
     -- Revertir la transacción en caso de error
         RAISE NOTICE 'Error al registrar la devolución: %', SQLERRM;
    
END;
$$;


CREATE OR REPLACE PROCEDURE buscar_pelicula(
	IN titulo character varying)
LANGUAGE 'plpgsql'
SECURITY DEFINER
AS $$
DECLARE
    v_title character varying;  -- Variable para almacenar cada título de la película encontrada
BEGIN
    -- Buscar películas por título y mostrar los resultados
    FOR v_title IN
        SELECT title FROM film
        WHERE title ILIKE '%' || titulo || '%'
    LOOP
        -- Imprimir cada título encontrado
        RAISE NOTICE 'Título encontrado: %', v_title;
    END LOOP;

    -- Mensaje de finalización
    RAISE NOTICE 'Búsqueda completada.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error al buscar la película: %', SQLERRM;
END;
$$




--Asigna funciones al rol de empleado 
GRANT EXECUTE ON PROCEDURE registrar_alquiler(TIMESTAMP WITHOUT TIME ZONE, INT, SMALLINT, TIMESTAMP WITHOUT TIME ZONE, SMALLINT, TIMESTAMP WITHOUT TIME ZONE) TO emp; 
GRANT EXECUTE ON PROCEDURE registrar_devolucion(INT, DATE) TO emp;
GRANT EXECUTE ON PROCEDURE buscar_pelicula(VARCHAR) TO emp;

--crea rol para un empleado como administrados
CREATE ROLE admin;
GRANT emp TO admin;

--Crea la funcion
CREATE OR REPLACE PROCEDURE insertar_nuevo_cliente(
    in_first_name VARCHAR,
    in_last_name VARCHAR,
    in_email VARCHAR,
    in_address_id INT,
    in_store_id INT,
    in_active_bool BOOLEAN,
    in_create_date DATE,
    in_last_update TIMESTAMP WITHOUT TIME ZONE,
    in_active INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Insertar cliente
    INSERT INTO public.customer(
        store_id, first_name, last_name, email, address_id, activebool, create_date, last_update, active
    )
    VALUES (
        in_store_id, in_first_name, in_last_name, in_email,
        in_address_id, in_active_bool, in_create_date, in_last_update, in_active
    );

	RAISE NOTICE 'Nuevo cliente registrado correctamente, nombre: % %', in_first_name, in_last_name;

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'El cliente ya existe con el email %.', in_email;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'El store_id o address_id no son válidos.';
    WHEN others THEN
        RAISE NOTICE 'Ocurrió un error: %', SQLERRM;
END;
$$;


--Asigna funciones al rol de administrador 
GRANT EXECUTE ON PROCEDURE insertar_nuevo_cliente(VARCHAR, VARCHAR, VARCHAR, INT, INT, BOOLEAN, DATE, TIMESTAMP WITHOUT TIME ZONE, INT) TO admin;

--Crea rol de video
CREATE ROLE video NOLOGIN;

--crea un empleado con password
CREATE USER empleado1 WITH PASSWORD '12345'; 
GRANT emp TO empleado1;

--crea un adminstrador con password
CREATE USER administrador1 WITH PASSWORD '12345'; 
GRANT admin TO administrador1;

--Permite uso de funciones a al rol video
ALTER PROCEDURE registrar_alquiler(TIMESTAMP WITHOUT TIME ZONE, INT, SMALLINT, TIMESTAMP WITHOUT TIME ZONE, SMALLINT, TIMESTAMP WITHOUT TIME ZONE) OWNER TO video;
ALTER PROCEDURE registrar_devolucion(INT, DATE) OWNER TO video;
ALTER PROCEDURE buscar_pelicula(VARCHAR) OWNER TO video;
ALTER PROCEDURE insertar_nuevo_cliente(VARCHAR, VARCHAR, VARCHAR, INT, INT, BOOLEAN, DATE, TIMESTAMP WITHOUT TIME ZONE, INT) OWNER TO video;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO video;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO video;


GRANT USAGE, SELECT ON SEQUENCE public.customer_customer_id_seq TO video;
GRANT USAGE, SELECT ON SEQUENCE public.rental_rental_id_seq TO video;


----------------------------------------------------------------------------------------------
CREATE TABLE rental_fact (
    rental_id BIGINT PRIMARY KEY,
    film_id INT,
    customer_id INT,
    store_id INT,
    address_id INT,
    rental_date DATE,
    payment_amount NUMERIC(10, 2)
);

CREATE TABLE dim_film (
    film_id INT PRIMARY KEY,
    title VARCHAR(255),
    category_name VARCHAR(100),
    release_year INT,
    actor_names TEXT
);

CREATE TABLE dim_address (
    address_id INT PRIMARY KEY,
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE dim_date (
    rental_date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT
);

CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    manager_staff_id INT,
    address_id INT
);
----------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE populate_dim_film()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dim_film (film_id, title, category_name, release_year, actor_names)
    SELECT
        f.film_id,
        f.title,
        c.name AS category_name,
        f.release_year,
        STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', ') AS actor_names
    FROM film f
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY f.film_id, f.title, c.name, f.release_year;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_dim_address()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dim_address (address_id, address, city, country)
    SELECT
        a.address_id,
        a.address,
        ci.city,
        co.country
    FROM address a
    JOIN city ci ON a.city_id = ci.city_id
    JOIN country co ON ci.country_id = co.country_id;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_dim_date()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dim_date (rental_date, year, month, day)
    SELECT DISTINCT
        DATE_TRUNC('day', r.rental_date) AS rental_date,
        EXTRACT(YEAR FROM r.rental_date) AS year,
        EXTRACT(MONTH FROM r.rental_date) AS month,
        EXTRACT(DAY FROM r.rental_date) AS day
    FROM rental r
    WHERE DATE_TRUNC('day', r.rental_date) NOT IN (
        SELECT rental_date FROM dim_date
    );
END;
$$;

CREATE OR REPLACE PROCEDURE populate_dim_store()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dim_store (store_id, manager_staff_id, address_id)
    SELECT
        s.store_id,
        s.manager_staff_id,
        s.address_id
    FROM store s;
END;
$$;

CREATE OR REPLACE PROCEDURE populate_rental_fact()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO rental_fact (rental_id, film_id, customer_id, store_id, address_id, rental_date, payment_amount)
    SELECT
        r.rental_id,
        i.film_id,
        r.customer_id,
        c.store_id,
        c.address_id,
        r.rental_date,
        p.amount
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    JOIN customer c ON r.customer_id = c.customer_id
    ON CONFLICT (rental_id) DO NOTHING;
END;
$$;
----------------------------------------------------------------------------------------------
CALL populate_dim_film();
CALL populate_dim_address();
CALL populate_dim_date();
CALL populate_dim_store();
CALL populate_rental_fact();
----------------------------------------------------------------------------------------------
SELECT * FROM dim_film;
SELECT * FROM dim_address;
SELECT * FROM dim_store;
SELECT * FROM rental_fact;
SELECT * FROM dim_date;
----------------------------------------------------------------------------------------------
CREATE VIEW film_actor_detail AS
SELECT 
    f.film_id, 
    f.title, 
    c.name AS category_name, 
    f.release_year, 
    a.actor_id, 
    a.first_name || ' ' || a.last_name AS actor_name
FROM film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor a ON fa.actor_id = a.actor_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id;
