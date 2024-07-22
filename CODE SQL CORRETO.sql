
-- Dropping existing tables and types
DROP TABLE IF EXISTS PETs CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;
DROP TABLE IF EXISTS Tipos CASCADE;
DROP TABLE IF EXISTS Identifications CASCADE;
DROP TYPE IF EXISTS genero CASCADE;
DROP TABLE IF EXISTS Breeds CASCADE;
DROP TABLE IF EXISTS Estados CASCADE;
DROP TABLE IF EXISTS Cidades CASCADE;


-- Criação das tabelas e inserção de dados iniciais
CREATE TABLE Estados (
    state_id SERIAL PRIMARY KEY,
    estado VARCHAR(20) NOT NULL
);

INSERT INTO Estados (estado) VALUES
('BA'),
('RJ'),
('SP'),
('SC');

CREATE TABLE Cidades (
    city_id SERIAL PRIMARY KEY,
    cidade VARCHAR(60) NOT NULL,
    state_id INTEGER REFERENCES Estados(state_id)
);

INSERT INTO Cidades (cidade, state_id) VALUES
('Salvador', 1),
('Rio de Janeiro', 2),
('Guarulhos', 3),
('Lauro de Freitas', 1),
('Florianopolis', 4),
('Camaçari', 1);

CREATE TABLE Breeds (
    breed VARCHAR(60) NOT NULL PRIMARY KEY
);

INSERT INTO Breeds (breed) VALUES
('Labrador Retriever'),
('Poodle'),
('German Shepherd'),
('Golden Retriever'),
('Siamese'),
('Maine Coon'),
('Persian'),
('Ragdoll');

CREATE TYPE genero AS ENUM (
    'Masculino', 'Feminino'
);

CREATE TABLE Identifications (
    identification VARCHAR(50) NOT NULL PRIMARY KEY
);

INSERT INTO Identifications (identification) VALUES
('Tattooed'),
('Microchipped'),
('Outros');

CREATE TABLE Tipos (
    animal VARCHAR(60) NOT NULL PRIMARY KEY
);

INSERT INTO Tipos (animal) VALUES
('Gato'),
('Cachorro'),
('Outros');

CREATE TABLE Cliente (
    c_id SERIAL PRIMARY KEY,
    nome VARCHAR(40) NOT NULL,
    email VARCHAR(50) NOT NULL,
    telefone VARCHAR(15) NOT NULL,
    adress TEXT NOT NULL,
    city_id INTEGER REFERENCES Cidades(city_id)
);


-- Insere dados na tabela de Clientes
INSERT INTO Cliente (nome, email, telefone, adress, city_id) VALUES
('João Silva', 'joao@email.com', '123456789', 'Rua A, 123', 1),
('Maria Souza', 'maria@email.com', '987654321', 'Rua B, 456', 2),
('Carlos Santos', 'carlos@email.com', '456123789', 'Rua C, 789', 3),
('Ana Oliveira', 'ana@email.com', '987654321', 'Rua D, 101', 1),
('Pedro Lima', 'pedro@email.com', '123456789', 'Rua E, 202', 4),
('Juliana Pereira', 'juliana@email.com', '456123789', 'Rua F, 303', 1),
('Mariana Santos', 'mariana@email.com', '111222333', 'Rua G, 404', 1),
('Rafael Silva', 'rafael@email.com', '444555666', 'Rua H, 505', 2),
('Fernanda Costa', 'fernanda@email.com', '777888999', 'Rua I, 606', 3),
('Gustavo Oliveira', 'gustavo@email.com', '333444555', 'Rua J, 707', 1);

CREATE TABLE PETs (
    p_id SERIAL PRIMARY KEY,
    cor VARCHAR(60),
    genero genero NOT NULL,
    animal VARCHAR(60) REFERENCES Tipos(animal),
    identification VARCHAR(50) REFERENCES Identifications(identification),
    nascimento DATE NOT NULL,
    breed VARCHAR(60) REFERENCES Breeds(breed),
    c_id INTEGER REFERENCES Cliente(c_id),
    descricao TEXT
);


-- Insere dados na tabela de Pets
INSERT INTO PETs (cor, genero, animal, identification, nascimento, breed, c_id, descricao) VALUES
('Preto', 'Masculino', 'Cachorro', 'Microchipped', '2022-01-01', 'Labrador Retriever', 1, 'Labrador preto muito amigável'),
('Marrom', 'Feminino', 'Cachorro', 'Tattooed', '2024-03-15', 'Poodle', 2, 'Poodle marrom, gosta de brincar'),
('Branco', 'Masculino', 'Cachorro', 'Outros', '2022-11-20', 'German Shepherd', 3, 'Pastor Alemão branco, muito ativo'),
('Caramelo', 'Feminino', 'Cachorro', 'Microchipped', '2024-03-10', 'Golden Retriever', 4, 'Golden Retriever caramelo, muito dócil'),
('Preto e Branco', 'Masculino', 'Cachorro', 'Tattooed', '2022-09-05', 'Labrador Retriever', 5, 'Labrador preto e branco, adora correr'),
('Marrom', 'Feminino', 'Cachorro', 'Microchipped', '2024-02-28', 'Labrador Retriever', 10, 'Labrador marrom, muito amigável'),
('Cinza', 'Masculino', 'Cachorro', 'Outros', '2022-05-12', 'German Shepherd', 7, 'Pastor Alemão cinza, muito protetor'),
('Branco', 'Feminino', 'Cachorro', 'Tattooed', '2024-01-03', 'Poodle', 8, 'Poodle branco, muito brincalhona'),
('Preto', 'Masculino', 'Gato', 'Microchipped', '2022-08-18', 'Siamese', 10, 'Siamês preto, muito curioso'),
('Branco e Preto', 'Feminino', 'Gato', 'Tattooed', '2024-01-30', 'Maine Coon', 10, 'Maine Coon branco e preto, muito carinhosa'),
('Caramelo', 'Masculino', 'Gato', 'Outros', '2022-04-03', 'Persian', 1, 'Persa caramelo, muito elegante');


-- Reinicie a sequência de IDs para as tabelas Cliente e PETs
SELECT setval('cliente_c_id_seq', (SELECT MAX(c_id) FROM Cliente));
SELECT setval('pets_p_id_seq', (SELECT MAX(p_id) FROM PETs));


-- Funções CRUD para a tabela PETs
CREATE OR REPLACE FUNCTION create_pet(
    p_cor VARCHAR,
    p_genero genero,
    p_animal VARCHAR,
    p_identification VARCHAR,
    p_nascimento DATE,
    p_breed VARCHAR,
    p_c_id INTEGER,
    p_descricao TEXT
) RETURNS TABLE (p_id INTEGER, cor VARCHAR, genero genero, animal VARCHAR, identification VARCHAR, nascimento DATE, breed VARCHAR, c_id INTEGER, descricao TEXT) AS $$
BEGIN
    -- Verifica se a raça já existe na tabela Breeds
    IF NOT EXISTS (SELECT 1 FROM Breeds WHERE breed = p_breed) THEN
        INSERT INTO Breeds (breed) VALUES (p_breed);
    END IF;

    -- Insere o novo pet na tabela PETs
    RETURN QUERY
    INSERT INTO PETs (cor, genero, animal, identification, nascimento, breed, c_id, descricao)
    VALUES (p_cor, p_genero, p_animal, p_identification, p_nascimento, p_breed, p_c_id, p_descricao)
    RETURNING *;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_pet(pet_id INTEGER) RETURNS TABLE (p_id INTEGER, cor VARCHAR, genero genero, animal VARCHAR, identification VARCHAR, nascimento DATE, breed VARCHAR, c_id INTEGER, descricao TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT p.p_id, p.cor, p.genero, p.animal, p.identification, p.nascimento, p.breed, p.c_id, p.descricao
    FROM PETs p
    WHERE p.p_id = pet_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_pet(
    pet_id INTEGER,
    p_cor VARCHAR,
    p_genero genero,
    p_animal VARCHAR,
    p_identification VARCHAR,
    p_nascimento DATE,
    p_breed VARCHAR,
    p_c_id INTEGER,
    p_descricao TEXT
) RETURNS TABLE (p_id INTEGER, cor VARCHAR, genero genero, animal VARCHAR, identification VARCHAR, nascimento DATE, breed VARCHAR, c_id INTEGER, descricao TEXT) AS $$
BEGIN
    -- Verifica se a raça já existe na tabela Breeds
    IF NOT EXISTS (SELECT 1 FROM Breeds WHERE breed = p_breed) THEN
        INSERT INTO Breeds (breed) VALUES (p_breed);
    END IF;

    -- Atualiza os dados do pet
    RETURN QUERY
    UPDATE PETs SET
        cor = p_cor,
        genero = p_genero,
        animal = p_animal,
        identification = p_identification,
        nascimento = p_nascimento,
        breed = p_breed,
        c_id = p_c_id,
        descricao = p_descricao
        WHERE p_id = pet_id
    RETURNING *;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_pet(pet_id INTEGER) RETURNS VOID AS $$
BEGIN
    DELETE FROM PETs WHERE p_id = pet_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_all_data() RETURNS void AS $$
BEGIN
    -- Desabilite temporariamente as restrições de chave estrangeira
    EXECUTE 'ALTER TABLE pets DISABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE cliente DISABLE TRIGGER ALL';

    -- Exclua os dados das tabelas
    EXECUTE 'DELETE FROM pets';
    EXECUTE 'DELETE FROM cliente';

    -- Reinicie as sequências
    EXECUTE 'ALTER SEQUENCE cliente_c_id_seq RESTART WITH 1';
    EXECUTE 'ALTER SEQUENCE pets_p_id_seq RESTART WITH 1';

    -- Reabilite as restrições de chave estrangeira
    EXECUTE 'ALTER TABLE pets ENABLE TRIGGER ALL';
    EXECUTE 'ALTER TABLE cliente ENABLE TRIGGER ALL';
END;
$$ LANGUAGE plpgsql;


-- Consultas de exemplo
SELECT * FROM Cliente;
SELECT * FROM PETs;

SELECT nome FROM Cliente WHERE city_id = (SELECT city_id FROM Cidades WHERE cidade = 'Salvador');

SELECT c_id FROM Cliente WHERE nome = 'Pedro Lima';

SELECT DISTINCT breed FROM PETs WHERE c_id IN (SELECT c_id FROM Cliente WHERE city_id = (SELECT city_id FROM Cidades WHERE cidade = 'Guarulhos'));

SELECT nome FROM Cliente WHERE c_id = 4;

SELECT p_id FROM PETs WHERE c_id = (SELECT c_id FROM Cliente WHERE nome = 'João Silva');

SELECT DISTINCT breed FROM PETs WHERE c_id IN (SELECT c_id FROM Cliente WHERE city_id = (SELECT city_id FROM Cidades WHERE cidade = 'Lauro de Freitas'));

SELECT * FROM PETs WHERE c_id = (SELECT c_id FROM Cliente WHERE nome = 'Gustavo Oliveira');

SELECT c_id FROM Cliente WHERE c_id IN (SELECT c_id FROM PETs WHERE identification = 'Outros');

SELECT c_id FROM Cliente WHERE c_id IN (SELECT c_id FROM PETs WHERE animal = 'Cachorro' AND genero = 'Feminino');

SELECT c_id FROM Cliente WHERE c_id IN (SELECT c_id FROM PETs WHERE animal = 'Gato') AND city_id IN (SELECT city_id FROM Cidades WHERE cidade IN ('Salvador', 'Rio de Janeiro'));

SELECT c_id FROM Cliente WHERE c_id IN (SELECT c_id FROM PETs WHERE animal = 'Gato' AND nascimento >= '2022-01-01' AND nascimento <= '2023-01-01');

SELECT Cliente.c_id, nome AS cliente_nome, email AS cliente_email, telefone AS cliente_telefone, adress AS cliente_adress, ci.cidade AS cliente_cidade, p_id, cor AS pet_cor, genero AS pet_genero, animal AS pet_animal, identification AS pet_identification, nascimento AS pet_nascimento, breed AS pet_breed 
FROM Cliente 
LEFT JOIN PETs ON Cliente.c_id = PETs.c_id 
LEFT JOIN Cidades ci ON Cliente.city_id = ci.city_id;

SELECT p_id, cor AS pet_cor, genero AS pet_genero, animal AS pet_animal, identification AS pet_identification, nascimento AS pet_nascimento, breed AS pet_breed, Cliente.c_id AS cliente_id, nome AS cliente_nome, email AS cliente_email, telefone AS cliente_telefone, adress AS cliente_adress, Cidades.cidade AS cliente_cidade 
FROM PETs 
LEFT JOIN Cliente ON PETs.c_id = Cliente.c_id 
LEFT JOIN Cidades ON Cliente.city_id = Cidades.city_id;

SELECT DISTINCT c.c_id, c.nome AS cliente_nome, c.email AS cliente_email, c.telefone AS cliente_telefone, c.adress AS cliente_adress, ci.cidade AS cliente_cidade, e.estado AS cliente_estado, p.p_id, p.cor AS pet_cor, p.genero AS pet_genero, p.animal AS pet_animal, p.identification AS pet_identification, p.nascimento AS pet_nascimento, p.breed AS pet_breed 
FROM Cliente c 
LEFT JOIN PETs p ON c.c_id = p.c_id 
LEFT JOIN Cidades ci ON c.city_id = ci.city_id 
LEFT JOIN Estados e ON ci.state_id = e.state_id;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public';