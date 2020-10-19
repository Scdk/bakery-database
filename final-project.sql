-- Creation of the schemas

CREATE SCHEMA IF NOT EXISTS padaria;

CREATE SCHEMA IF NOT EXISTS administracao;

-- Creation of the tables

CREATE TABLE padaria.tb_cliente(
	id_cliente    SERIAL    CONSTRAINT pk_id_cliente  PRIMARY KEY,
	nome_completo   VARCHAR(200)    CONSTRAINT nn_nome_completo  NOT NULL,
	telefone    VARCHAR(11)    CONSTRAINT nn_telefone  NOT NULL,
	rua    VARCHAR(200)    CONSTRAINT nn_rua  NOT NULL,
	bairro    VARCHAR(200)    CONSTRAINT nn_bairro  NOT NULL,
	numero    INTEGER    CONSTRAINT nn_numero  NOT NULL
);

CREATE TABLE padaria.tb_item(
	id_item    SERIAL    CONSTRAINT pk_id_item  PRIMARY KEY,
	nome_item    VARCHAR(200)    CONSTRAINT nn_nome_item  NOT NULL,
	preco_custo    NUMERIC(7,2)    CONSTRAINT nn_preco_custo  NOT NULL,
	preco_venda    NUMERIC(7,2)    CONSTRAINT nn_preco_venda  NOT NULL,
	estoque    INTEGER    CONSTRAINT nn_estoque  NOT NULL
);

CREATE TABLE padaria.tb_pedido(
	id_pedido    SERIAL    CONSTRAINT pk_id_pedido    PRIMARY KEY,
	id_cliente    INTEGER,
	preco_final    NUMERIC(7,2)    CONSTRAINT nn_preco_final  NOT NULL,
	CONSTRAINT    fk_ped_id_cliente  FOREIGN KEY(id_cliente)
		REFERENCES padaria.tb_cliente(id_cliente)
);

CREATE TABLE padaria.tb_item_pedido (
      id_item_pedido    SERIAL,
      id_item     INTEGER,
      id_pedido     INTEGER,
      quantidade     INTEGER CONSTRAINT nn_quantidade NOT NULL,
      CONSTRAINT pk_item_pedido PRIMARY KEY(id_item_pedido),
      CONSTRAINT fk_ped_id_item FOREIGN KEY(id_item) 
        REFERENCES padaria.tb_item(id_item),
      CONSTRAINT fk_ped_id_pedido FOREIGN KEY(id_pedido) 
        REFERENCES padaria.tb_pedido(id_pedido)
 );

CREATE TABLE administracao.tb_funcionarios (
    id_funcionario    SERIAL,
    CONSTRAINT pk_funcionarios PRIMARY KEY(id_funcionario),
    nome             VARCHAR(300) CONSTRAINT nn_nome NOT NULL,
    salario        NUMERIC CONSTRAINT nn_salario NOT NULL,
    telefone    VARCHAR(11) CONSTRAINT nn_telefone NOT NULL
);

INSERT INTO administracao.tb_funcionarios (nome, salario, telefone)
Values ('Rodrigo Henrique', 50, '988662211')

CREATE TABLE administracao.tb_compras_log (
    id_compras_log    SERIAL,
    CONSTRAINT pk_compras_log PRIMARY KEY(id_compras_log),
    id_cliente INTEGER,
    dt_compra TIMESTAMP CONSTRAINT nn_dt_compra NOT NULL,
    preco_final NUMERIC(7, 2) CONSTRAINT nn_preco_final NOT NULL,
    CONSTRAINT fk_adm_id_cliente FOREIGN KEY(id_cliente) 
        REFERENCES padaria.tb_cliente(id_cliente)
);

-- Creation fo the functions

CREATE OR REPLACE FUNCTION administracao.fn_lucro()
RETURNS NUMERIC
LANGUAGE plpgsql AS
$$
	BEGIN 
		RETURN (SELECT
				(SELECT sum(preco_final) FROM administracao.tb_compras_log)
				- (SELECT sum(preco_custo * estoque) FROM padaria.tb_item)
				- (SELECT sum(salario) FROM administracao.tb_funcionarios));
	END;
$$

CREATE OR REPLACE FUNCTION administracao.fn_preco_final(id_p INTEGER)
RETURNS NUMERIC
LANGUAGE plpgsql AS
$$
	BEGIN 
		RETURN (SELECT sum(preco_venda * quantidade) FROM padaria.tb_item ti 
			JOIN padaria.tb_item_pedido tip ON ti.id_item = tip.id_item
			WHERE tip.id_pedido = id_p);
	END;
$$

CREATE OR REPLACE FUNCTION administracao.fn_compras_log()
RETURNS trigger AS 
$$
    BEGIN 
        INSERT INTO administracao.tb_compras_log (id_cliente, dt_compra, preco_final)
        SELECT NEW.id_cliente, now(), NEW.preco_final;
        RETURN NEW;
    END
$$
LANGUAGE plpgsql;

CREATE TRIGGER tg_compras_log 
AFTER UPDATE ON padaria.tb_pedido
FOR EACH ROW EXECUTE PROCEDURE administracao.fn_compras_log();

-- Update that changes the preco_final of the table pedido

UPDATE padaria.tb_pedido SET preco_final = administracao.fn_preco_final(:id_p)
	WHERE id_pedido = :id_p;

SELECT * FROM administracao.tb_compras_log tcl

-- Creation of the users

CREATE GROUP Gerente;
GRANT ALL ON ALL TABLES IN SCHEMA padaria TO GROUP Gerente WITH GRANT OPTION;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA padaria to Gerente WITH GRANT OPTION;
GRANT ALL ON SCHEMA padaria TO Gerente;
GRANT ALL ON ALL TABLES IN SCHEMA administracao TO GROUP Gerente WITH GRANT OPTION;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA administracao to Gerente WITH GRANT OPTION;
GRANT ALL ON SCHEMA administracao TO Gerente;

CREATE GROUP Aplicacao;
GRANT insert, select, delete, update ON ALL TABLES IN SCHEMA padaria TO GROUP Aplicacao;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA padaria to Aplicacao;
GRANT USAGE ON SCHEMA padaria TO Aplicacao;
GRANT insert, select, delete, update ON ALL TABLES IN SCHEMA administracao TO GROUP Aplicacao;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA administracao to Aplicacao;
GRANT USAGE ON SCHEMA administracao TO Aplicacao;

CREATE GROUP Contador;
GRANT select ON ALL TABLES IN SCHEMA padaria TO GROUP Contador;
GRANT USAGE ON SCHEMA padaria TO Contador;
GRANT select ON ALL TABLES IN SCHEMA administracao TO GROUP Contador;
GRANT USAGE ON SCHEMA administracao TO Contador;

-- Insertion of data for tests

INSERT INTO padaria.tb_cliente (NOME_COMPLETO, TELEFONE, RUA, BAIRRO, NUMERO) VALUES ('Carlos Ferreira de Albuquerque', '992528647', 'Rua A', 'Aparecida', 686);
INSERT INTO padaria.tb_item (nome_item , preco_custo, preco_venda, estoque) VALUES ('pão', '0.50', '0.70', 32);
INSERT INTO padaria.tb_item (nome_item , preco_custo, preco_venda, estoque) VALUES ('leite', '2.00', '3.65', 40);
INSERT INTO padaria.tb_pedido (id_cliente, preco_final) VALUES (1, -1);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (1, 1, 4);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (1, 2, 2);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (3, 1, 10);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (3, 2, 1);

select * from padaria.tb_cliente;
select * from padaria.tb_item;
select * from padaria.tb_pedido;
select * from padaria.tb_item_pedido;
select * from administracao.tb_funcionarios;
select * from administracao.tb_compras_log;

-- Test of the function fn_lucro

SELECT administracao.fn_lucro()

-- Exemple

INSERT INTO padaria.tb_cliente (NOME_COMPLETO, TELEFONE, RUA, BAIRRO, NUMERO) VALUES ('Gabriel Cardoso', '988986535', 'Rua Maria das Dores Dias', 'Santa Mônica', 666);
INSERT INTO padaria.tb_item (nome_item , preco_custo, preco_venda, estoque) VALUES ('café', '0.50', '1.00', 40);
INSERT INTO padaria.tb_pedido (id_cliente, preco_final) VALUES (2, -1);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (4, 1, 10);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (4, 2, 2);
INSERT INTO padaria.tb_item_pedido (id_pedido, id_item, quantidade) VALUES (4, 3, 1);

-- Order 66

DROP FUNCTION administracao.fn_preco_final
DROP FUNCTION administracao.fn_lucro

DROP TABLE administracao.tb_compras_log
DROP TABLE administracao.tb_funcionarios
DROP TABLE padaria.tb_item_pedido
DROP TABLE padaria.tb_pedido
DROP TABLE padaria.tb_item
DROP TABLE padaria.tb_cliente

 
