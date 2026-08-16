-- =====================================================================
-- MODELO DE BANCO DE DADOS - NOTA FISCAL DE CONSUMIDOR ELETRÔNICA (NFC-e)
-- Baseado no cupom fiscal da Riachuelo (notafiscal.pdf)
-- =====================================================================

CREATE TABLE emitente (
    id                     SERIAL PRIMARY KEY,
    razao_social           VARCHAR(150) NOT NULL,
    cnpj                   VARCHAR(18)  NOT NULL UNIQUE,
    inscricao_estadual     VARCHAR(20),
    endereco               VARCHAR(255),
    numero_loja            VARCHAR(20)  -- ex: "446" (código interno da loja)
);

CREATE TABLE consumidor (
    id          SERIAL PRIMARY KEY,
    cpf_cnpj    VARCHAR(18) NOT NULL UNIQUE
);

CREATE TABLE forma_pagamento (
    id      SERIAL PRIMARY KEY,
    nome    VARCHAR(50) NOT NULL UNIQUE  -- Dinheiro, Credito, Debito, CreditoLoja, CartaoPresente, Pix, Outros
);

CREATE TABLE nota_fiscal (
    id                      SERIAL PRIMARY KEY,
    emitente_id             INTEGER NOT NULL REFERENCES emitente(id),
    consumidor_id           INTEGER REFERENCES consumidor(id),

    numero_nfce             VARCHAR(20),      -- "00038213"
    serie                   VARCHAR(10),      -- "301"
    chave_acesso            VARCHAR(60) UNIQUE, -- ex: "3326 0733 2000 5605 4745 6530 1000 0362 1318 0350 2857"
    protocolo               VARCHAR(30),      -- "233261737173493"

    pdv                     INTEGER,          -- "301"
    coo                     INTEGER,          -- "175727"
    caixa                   INTEGER,          -- "301"
    operador                VARCHAR(20),      -- "4134269"
    versao_app              VARCHAR(20),      -- "1.26.3"

    data_emissao            TIMESTAMP NOT NULL, -- "22/07/2026 18:03:26"

    qtd_itens               INTEGER NOT NULL DEFAULT 0,
    valor_total_bruto       NUMERIC(10,2) NOT NULL,  -- 389.93
    valor_desconto_total    NUMERIC(10,2) NOT NULL DEFAULT 0, -- -59.98
    valor_total_pago        NUMERIC(10,2) NOT NULL,  -- 329.95

    troca_ate               DATE,             -- "20/09/2026"
    codigo_troca            VARCHAR(40)       -- "446#301#175727#22072026"
);

CREATE TABLE item_nota (
    id                  SERIAL PRIMARY KEY,
    nota_id             INTEGER NOT NULL REFERENCES nota_fiscal(id) ON DELETE CASCADE,

    codigo_produto      VARCHAR(30) NOT NULL,  -- "15591000003"
    descricao           VARCHAR(255) NOT NULL, -- "Jaqueta esportiva feminina em plush | Body Work"
    quantidade          NUMERIC(10,3) NOT NULL DEFAULT 1,
    unidade             VARCHAR(5) NOT NULL DEFAULT 'PC',  -- PC

    valor_unitario       NUMERIC(10,2) NOT NULL, -- 79.99
    valor_desconto       NUMERIC(10,2) NOT NULL DEFAULT 0, -- 12.31
    valor_tributos_aprox NUMERIC(10,2), -- coluna "Tr(R$)" - 19.89
    valor_total          NUMERIC(10,2) NOT NULL  -- 67.68
);

CREATE TABLE pagamento_nota (
    id                    SERIAL PRIMARY KEY,
    nota_id               INTEGER NOT NULL REFERENCES nota_fiscal(id) ON DELETE CASCADE,
    forma_pagamento_id    INTEGER NOT NULL REFERENCES forma_pagamento(id),
    valor                 NUMERIC(10,2) NOT NULL
);

CREATE TABLE tributo_nota (
    id                   SERIAL PRIMARY KEY,
    nota_id              INTEGER NOT NULL REFERENCES nota_fiscal(id) ON DELETE CASCADE,
    tipo                 VARCHAR(15) NOT NULL,  -- FEDERAL, ESTADUAL, MUNICIPAL
    aliquota_percentual  NUMERIC(5,2),           -- 9.25 / 22.00 / 0.00
    valor_aproximado     NUMERIC(10,2)           -- 24.41 / 72.60 / 0.00
);

-- =====================================================================
-- ÍNDICES ÚTEIS
-- =====================================================================
CREATE INDEX idx_nota_fiscal_chave_acesso ON nota_fiscal(chave_acesso);
CREATE INDEX idx_nota_fiscal_data_emissao ON nota_fiscal(data_emissao);
CREATE INDEX idx_item_nota_nota_id ON item_nota(nota_id);
CREATE INDEX idx_item_nota_codigo_produto ON item_nota(codigo_produto);
CREATE INDEX idx_pagamento_nota_nota_id ON pagamento_nota(nota_id);

-- =====================================================================
-- DADOS FIXOS (catálogo de formas de pagamento)
-- =====================================================================
INSERT INTO forma_pagamento (nome) VALUES
    ('Dinheiro'), ('Credito'), ('Debito'),
    ('CreditoLoja'), ('CartaoPresente'), ('Pix'), ('Outros');

-- =====================================================================
-- EXEMPLO DE INSERÇÃO A PARTIR DO CUPOM ANALISADO
-- =====================================================================
INSERT INTO emitente (razao_social, cnpj, inscricao_estadual, endereco, numero_loja)
VALUES ('Lojas Riachuelo SA', '33.200.056/0054-745', '1251.6870',
        'Estrada Rodrigues Caldas Rodrigues Caldas', '446');

INSERT INTO consumidor (cpf_cnpj) VALUES ('775.177.847-49');

INSERT INTO nota_fiscal (
    emitente_id, consumidor_id, numero_nfce, serie, chave_acesso, protocolo,
    pdv, coo, caixa, operador, versao_app, data_emissao,
    qtd_itens, valor_total_bruto, valor_desconto_total, valor_total_pago,
    troca_ate, codigo_troca
) VALUES (
    1, 1, '00038213', '301',
    '3326073320005605474565301000036213183502857', '233261737173493',
    301, 175727, 301, '4134269', '1.26.3', '2026-07-22 18:03:26',
    7, 389.93, 59.98, 329.95,
    '2026-09-20', '446#301#175727#22072026'
);

INSERT INTO item_nota (nota_id, codigo_produto, descricao, quantidade, unidade, valor_unitario, valor_desconto, valor_tributos_aprox, valor_total) VALUES
    (1, '15591000003', 'Jaqueta esportiva feminina em plush | Body Work', 1, 'PC', 79.99, 12.31, 19.89, 67.68),
    (1, '15511642001', 'Colar feminino corrente trançada prata',          1, 'PC', 19.99,  3.08,  4.97, 16.91),
    (1, '16115015002', 'Blusa feminina em modal básica | Body Work',       1, 'PC', 79.99, 12.30, 19.90, 67.69),
    (1, '16386973004', 'Blusa feminina de polianida decote quadrado',      1, 'PC', 69.99, 10.76, 17.41, 59.23),
    (1, '15898008004', 'Blusa feminina Fefe viscose ampla gola alta azul', 1, 'PC', 49.99,  7.69, 12.44, 42.30),
    (1, '15725421005', 'Camiseta feminina Tech UltraFresh',                1, 'PC', 39.99,  6.15,  9.96, 33.84),
    (1, '15504255005', 'Body feminino polianida alças finas branca | Pool',1, 'PC', 49.99,  7.69, 12.44, 42.30);

INSERT INTO pagamento_nota (nota_id, forma_pagamento_id, valor) VALUES
    (1, (SELECT id FROM forma_pagamento WHERE nome = 'Dinheiro'), 329.95);

INSERT INTO tributo_nota (nota_id, tipo, aliquota_percentual, valor_aproximado) VALUES
    (1, 'FEDERAL',   9.25, 24.41),
    (1, 'ESTADUAL', 22.00, 72.60),
    (1, 'MUNICIPAL', 0.00,  0.00);
