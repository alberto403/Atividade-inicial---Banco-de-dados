-- Modelo de banco de dados para o "Documento Auxiliar da Nota Fiscal de Consumidor Eletrônica" (NFC-e)
-- Compatível com PostgreSQL (ajustar tipos se for usar MySQL/SQLite)

CREATE TABLE loja (
    id                    SERIAL PRIMARY KEY,
    razao_social          VARCHAR(150) NOT NULL,
    cnpj                  VARCHAR(18) NOT NULL UNIQUE,   -- formato 00.000.000/0000-00
    inscricao_estadual    VARCHAR(20),
    endereco              VARCHAR(255)
);

CREATE TABLE nota_fiscal (
    id                       SERIAL PRIMARY KEY,
    loja_id                  INTEGER NOT NULL REFERENCES loja(id),
    numero_nfce              VARCHAR(20) NOT NULL,          -- ex: 00038213
    serie                    VARCHAR(10),                   -- ex: 301
    coo                      VARCHAR(20),                   -- Contador de Ordem de Operação
    pdv                      VARCHAR(10),
    caixa                    VARCHAR(10),
    operador                 VARCHAR(20),
    chave_acesso             VARCHAR(50) UNIQUE,            -- ex: 3326 0733 2000 5605 ...
    protocolo_autorizacao    VARCHAR(30),
    data_emissao             TIMESTAMP,
    cpf_cnpj_consumidor      VARCHAR(18),
    valor_total_itens        NUMERIC(10,2) NOT NULL DEFAULT 0,
    valor_desconto_total     NUMERIC(10,2) NOT NULL DEFAULT 0,
    valor_total_pagar        NUMERIC(10,2) NOT NULL DEFAULT 0,
    valor_tributos_aprox     NUMERIC(10,2),
    troco                    NUMERIC(10,2) NOT NULL DEFAULT 0,
    prazo_troca              DATE,
    criado_em                TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE item_nota (
    id                SERIAL PRIMARY KEY,
    nota_id           INTEGER NOT NULL REFERENCES nota_fiscal(id) ON DELETE CASCADE,
    codigo_produto    VARCHAR(30) NOT NULL,           -- ex: 15591000003
    descricao         VARCHAR(150) NOT NULL,
    quantidade        NUMERIC(10,3) NOT NULL DEFAULT 1,
    unidade           VARCHAR(10),                    -- ex: PC
    valor_unitario    NUMERIC(10,2) NOT NULL,
    desconto          NUMERIC(10,2) NOT NULL DEFAULT 0,
    acrescimo         NUMERIC(10,2) NOT NULL DEFAULT 0,
    valor_total        NUMERIC(10,2) NOT NULL
);

CREATE TABLE forma_pagamento (
    id      SERIAL PRIMARY KEY,
    nome    VARCHAR(40) NOT NULL UNIQUE     -- Dinheiro, Crédito, Débito, Crédito Loja, Cartão Presente, Pix, Outros
);

CREATE TABLE pagamento_nota (
    id                    SERIAL PRIMARY KEY,
    nota_id               INTEGER NOT NULL REFERENCES nota_fiscal(id) ON DELETE CASCADE,
    forma_pagamento_id    INTEGER NOT NULL REFERENCES forma_pagamento(id),
    valor                 NUMERIC(10,2) NOT NULL DEFAULT 0,

    UNIQUE (nota_id, forma_pagamento_id)
);

-- Índices para consultas frequentes
CREATE INDEX idx_nota_loja        ON nota_fiscal (loja_id);
CREATE INDEX idx_nota_data        ON nota_fiscal (data_emissao);
CREATE INDEX idx_item_nota        ON item_nota (nota_id);
CREATE INDEX idx_pagamento_nota   ON pagamento_nota (nota_id);

-- Catálogo de formas de pagamento
INSERT INTO forma_pagamento (nome) VALUES
    ('Dinheiro'), ('Credito'), ('Debito'), ('Credito Loja'), ('Cartao Presente'), ('Pix'), ('Outros');

-- Exemplo de carga baseado no cupom da imagem
INSERT INTO loja (razao_social, cnpj, inscricao_estadual, endereco)
VALUES ('Lojas Riachuelo SA', '33.200.056/0054-72', '12510-870',
        'Estrada Rodrigues Caldas Rodrigues Caldas');

INSERT INTO nota_fiscal (
    loja_id, numero_nfce, serie, coo, pdv, caixa, operador,
    chave_acesso, protocolo_autorizacao, data_emissao, cpf_cnpj_consumidor,
    valor_total_itens, valor_desconto_total, valor_total_pagar, valor_tributos_aprox, troco, prazo_troca
) VALUES (
    1, '00038213', '301', '175727', '301', '301', '4134269',
    '3326073320005605474565301000036213183503857', '2S3261737173493', '2026-07-22 18:03:26', '77517784749',
    389.93, 59.98, 329.95, 72.60, 0.00, '2026-09-20'
);

INSERT INTO item_nota (nota_id, codigo_produto, descricao, quantidade, unidade, valor_unitario, desconto, acrescimo, valor_total) VALUES
    (1, '15591000003', 'Jaqueta esportiva feminina em plush', 1, 'PC', 79.99, 12.31, 19.89, 67.68),
    (1, '15511642001', 'Colar feminino corrente trancada prata', 1, 'PC', 19.99, 3.08, 4.97, 16.91),
    (1, '16115015002', 'Blusa feminina em nodal basica', 1, 'PC', 79.99, 12.30, 19.90, 67.69),
    (1, '16386973004', 'Blusa feminina de poliamida decote quadrado', 1, 'PC', 69.99, 10.76, 17.41, 59.23),
    (1, '15898008004', 'Blusa feminina fefe viscose ampla gola alta', 1, 'PC', 49.99, 7.69, 12.44, 42.30),
    (1, '15725421005', 'Camiseta feminina Tech UltraFresh', 1, 'PC', 49.99, 6.15, 9.96, 33.84),
    (1, '15504255005', 'Body feminino poliamida alcas finas branca', 1, 'PC', 49.99, 7.69, 12.44, 42.30);

INSERT INTO pagamento_nota (nota_id, forma_pagamento_id, valor)
SELECT 1, id, 329.95 FROM forma_pagamento WHERE nome = 'Dinheiro';

-- Consulta útil: itens de uma nota com totais e forma de pagamento
-- SELECT n.numero_nfce, n.data_emissao, i.descricao, i.quantidade, i.valor_total, fp.nome AS forma_pagto, p.valor
-- FROM nota_fiscal n
-- JOIN item_nota i ON i.nota_id = n.id
-- LEFT JOIN pagamento_nota p ON p.nota_id = n.id
-- LEFT JOIN forma_pagamento fp ON fp.id = p.forma_pagamento_id
-- WHERE n.id = 1;
