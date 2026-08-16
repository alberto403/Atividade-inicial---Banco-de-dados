-- Modelo de banco de dados para o "Comprovante de Vacinação do Adulto"
-- Compatível com PostgreSQL (ajustar tipos se for usar MySQL/SQLite)

CREATE TABLE paciente (
    id                SERIAL PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL,
    cpf               VARCHAR(14) UNIQUE,           -- formato 000.000.000-00
    data_nascimento   DATE,
    criado_em         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE unidade_saude (
    id                SERIAL PRIMARY KEY,
    nome              VARCHAR(150) NOT NULL UNIQUE  -- ex: "CMS Dom Helder Câmara"
);

CREATE TABLE vacina (
    id                SERIAL PRIMARY KEY,
    nome              VARCHAR(80) NOT NULL UNIQUE   -- ex: "Covid-19", "Febre Amarela"
);

CREATE TABLE vacinador (
    id                SERIAL PRIMARY KEY,
    nome              VARCHAR(150),
    registro          VARCHAR(30)                   -- ex: "163713-7"
);

CREATE TABLE aplicacao (
    id                SERIAL PRIMARY KEY,
    paciente_id       INTEGER NOT NULL REFERENCES paciente(id),
    unidade_id        INTEGER REFERENCES unidade_saude(id),
    vacina_id         INTEGER NOT NULL REFERENCES vacina(id),
    vacinador_id      INTEGER REFERENCES vacinador(id),
    numero_dose       VARCHAR(10) NOT NULL,          -- '1', '2', '3', 'reforco_1', 'reforco_2'...
    fabricante        VARCHAR(80),                   -- ex: "AstraZeneca"
    lote              VARCHAR(40),                   -- ex: "CTMAV506"
    data_aplicacao    DATE,
    observacao        VARCHAR(255),

    UNIQUE (paciente_id, vacina_id, numero_dose)
);

-- Índices para consultas frequentes
CREATE INDEX idx_aplicacao_paciente ON aplicacao (paciente_id);
CREATE INDEX idx_aplicacao_vacina   ON aplicacao (vacina_id);
CREATE INDEX idx_aplicacao_data     ON aplicacao (data_aplicacao);

-- Exemplo de carga inicial do catálogo de vacinas do formulário
INSERT INTO vacina (nome) VALUES
    ('Covid-19'),
    ('Dupla Adulto'),
    ('Tríplice Viral'),
    ('Febre Amarela'),
    ('Hepatite B'),
    ('Outra');

-- Exemplo de inserção baseada no comprovante da imagem
INSERT INTO unidade_saude (nome) VALUES ('CMS Dom Helder Câmara');

INSERT INTO paciente (nome, cpf, data_nascimento)
VALUES ('Nome do paciente', NULL, NULL);

INSERT INTO vacinador (nome, registro) VALUES ('Vacinador', '163713-7');

INSERT INTO aplicacao (paciente_id, unidade_id, vacina_id, vacinador_id, numero_dose, fabricante, lote, data_aplicacao)
VALUES
    (1, 1, (SELECT id FROM vacina WHERE nome = 'Covid-19'), 1, '1', 'AstraZeneca', 'CTMAV506', '2021-04-10'),
    (1, 1, (SELECT id FROM vacina WHERE nome = 'Covid-19'), 1, '3', 'AstraZeneca', '215VCD1B4W', NULL),
    (1, 1, (SELECT id FROM vacina WHERE nome = 'Dupla Adulto'), 1, '2', NULL, NULL, NULL);

-- Consulta útil: histórico completo de doses de um paciente
-- SELECT p.nome, v.nome AS vacina, a.numero_dose, a.fabricante, a.lote, a.data_aplicacao, u.nome AS unidade
-- FROM aplicacao a
-- JOIN paciente p ON p.id = a.paciente_id
-- JOIN vacina v ON v.id = a.vacina_id
-- LEFT JOIN unidade_saude u ON u.id = a.unidade_id
-- WHERE p.id = 1
-- ORDER BY a.data_aplicacao;
