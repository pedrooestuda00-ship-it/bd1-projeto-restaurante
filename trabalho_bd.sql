-- Criação das tabelas do sistema

CREATE TABLE Categoria (
id_categoria INT PRIMARY KEY,
nome VARCHAR(100) NOT NULL,
descricao VARCHAR(255)
);

CREATE TABLE Cliente (
id_cliente INT PRIMARY KEY,
nome VARCHAR(100) NOT NULL,
cpf VARCHAR(14) UNIQUE NOT NULL,
telefone VARCHAR(20),
logradouro VARCHAR(150),
bairro VARCHAR(100),
cidade VARCHAR(100)
);

CREATE TABLE Mesa (
id_mesa INT PRIMARY KEY,
numero INT UNIQUE NOT NULL,
status VARCHAR(50)
);

CREATE TABLE Veiculo (
id_veiculo INT PRIMARY KEY,
placa VARCHAR(10) UNIQUE NOT NULL,
modelo VARCHAR(100)
);

-- Cadastro geral dos funcionários do restaurante
CREATE TABLE Funcionario (
id_funcionario INT PRIMARY KEY,
id_supervisor INT,
nome VARCHAR(100) NOT NULL,
cpf VARCHAR(14) UNIQUE NOT NULL,
data_admissao DATE,
salario DECIMAL(10, 2),
FOREIGN KEY (id_supervisor) REFERENCES Funcionario(id_funcionario)
);

-- Informações específicas dos garçons
CREATE TABLE Garcom (
id_funcionario INT PRIMARY KEY,
turno VARCHAR(50),
FOREIGN KEY (id_funcionario) REFERENCES Funcionario(id_funcionario)
);

-- Informações específicas dos entregadores
CREATE TABLE Entregador (
id_funcionario INT PRIMARY KEY,
cnh VARCHAR(20) UNIQUE NOT NULL,
FOREIGN KEY (id_funcionario) REFERENCES Funcionario(id_funcionario)
);

-- Produtos oferecidos pelo restaurante
CREATE TABLE Produto (
id_produto INT PRIMARY KEY,
id_categoria INT,
nome VARCHAR(100) NOT NULL,
descricao VARCHAR(255),
preco DECIMAL(10, 2) NOT NULL,
disponivel BOOLEAN,
FOREIGN KEY (id_categoria) REFERENCES Categoria(id_categoria)
);

-- Registro dos pedidos realizados pelos clientes
CREATE TABLE Pedido (
id_pedido INT PRIMARY KEY,
id_cliente INT NOT NULL,
status VARCHAR(50),
data_hora TIMESTAMP,
FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

-- Itens que compõem cada pedido
CREATE TABLE Item_Pedido (
id_pedido INT,
id_produto INT,
quantidade INT NOT NULL,
preco_unitario DECIMAL(10, 2) NOT NULL,
observacao VARCHAR(255),
PRIMARY KEY (id_pedido, id_produto),
FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
);

-- Dados dos pedidos realizados no salão
CREATE TABLE Pedido_Presencial (
id_pedido INT PRIMARY KEY,
id_mesa INT,
id_garcom INT,
FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
FOREIGN KEY (id_mesa) REFERENCES Mesa(id_mesa),
FOREIGN KEY (id_garcom) REFERENCES Garcom(id_funcionario)
);

-- Dados dos pedidos realizados por delivery
CREATE TABLE Pedido_Delivery (
id_pedido INT PRIMARY KEY,
endereco_entrega VARCHAR(255) NOT NULL,
taxa_entrega DECIMAL(10, 2),
FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido)
);

-- Controle das entregas realizadas
CREATE TABLE Entrega (
id_entrega INT PRIMARY KEY,
id_pedido INT NOT NULL,
id_entregador INT NOT NULL,
id_veiculo INT NOT NULL,
horario_saida TIMESTAMP,
horario_chegada TIMESTAMP,
status_entrega VARCHAR(50),
FOREIGN KEY (id_pedido) REFERENCES Pedido_Delivery(id_pedido),
FOREIGN KEY (id_entregador) REFERENCES Entregador(id_funcionario),
FOREIGN KEY (id_veiculo) REFERENCES Veiculo(id_veiculo)
);

-- Função responsável por atualizar automaticamente o status da mesa
CREATE OR REPLACE FUNCTION fn_ocupar_mesa()
RETURNS TRIGGER AS $$
BEGIN
UPDATE Mesa
SET status = 'Ocupada'
WHERE id_mesa = NEW.id_mesa;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gatilho executado após o registro de um pedido presencial
CREATE TRIGGER trg_ocupar_mesa
AFTER INSERT ON Pedido_Presencial
FOR EACH ROW
EXECUTE FUNCTION fn_ocupar_mesa();

-- View que apresenta o detalhamento dos itens de cada pedido
CREATE VIEW vw_extrato_pedido AS
SELECT
p.id_pedido,
c.nome AS cliente,
pr.nome AS produto,
ip.quantidade,
ip.preco_unitario,
(ip.quantidade * ip.preco_unitario) AS subtotal,
ip.observacao
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN Item_Pedido ip ON p.id_pedido = ip.id_pedido
JOIN Produto pr ON ip.id_produto = pr.id_produto;

-- View que exibe a relação entre funcionários e seus supervisores
CREATE VIEW vw_hierarquia_equipe AS
SELECT
subordinado.nome AS funcionario,
subordinado.cpf,
chefe.nome AS supervisor
FROM Funcionario subordinado
LEFT JOIN Funcionario chefe
ON subordinado.id_supervisor = chefe.id_funcionario;

-- Inserção de dados para teste e validação do sistema

INSERT INTO Categoria (id_categoria, nome, descricao) VALUES
(1, 'Lanches', 'Hambúrgueres e porções artesanais'),
(2, 'Bebidas', 'Refrigerantes e sucos naturais'),
(3, 'Sobremesas', 'Doces e sorvetes');

INSERT INTO Cliente (id_cliente, nome, cpf, telefone, logradouro, bairro, cidade) VALUES
(1, 'Professor Eric', '11122233344', '21988887777', 'Rua da Universidade, 1', 'Centro', 'Seropédica'),
(2, 'Vitoria Santos', '55566677788', '21977776666', 'Avenida Principal, 200', 'Jardim', 'Itaguaí');

INSERT INTO Mesa (id_mesa, numero, status) VALUES
(1, 10, 'Livre'),
(2, 11, 'Livre'),
(3, 12, 'Livre');

INSERT INTO Veiculo (id_veiculo, placa, modelo) VALUES
(1, 'RUR-4L1N', 'Honda CG 160 Titan'),
(2, 'UFR-1R26', 'Yamaha Fazer 250');

INSERT INTO Funcionario (id_funcionario, id_supervisor, nome, cpf, data_admissao, salario) VALUES
(1, NULL, 'Pedro Paulo', '12312312312', '2025-06-01', 5000.00),
(2, 1, 'Arthur Herbert', '23423423423', '2025-06-15', 2500.00),
(3, 1, 'Gilmar Silas', '34534534534', '2026-01-10', 2800.00);

INSERT INTO Garcom (id_funcionario, turno) VALUES
(2, 'Noturno');

INSERT INTO Entregador (id_funcionario, cnh) VALUES
(3, '98765432100');

INSERT INTO Produto (id_produto, id_categoria, nome, descricao, preco, disponivel) VALUES
(1, 1, 'Hambúrguer Rural', 'Pão brioche, blend 200g, queijo prato', 32.90, TRUE),
(2, 2, 'Suco de Laranja', 'Copo 500ml', 8.50, TRUE),
(3, 3, 'Pudim', 'Fatia de pudim de leite condensado', 12.00, TRUE);

-- Pedido utilizado para demonstrar o fluxo de delivery
INSERT INTO Pedido (id_pedido, id_cliente, status, data_hora) VALUES
(1, 1, 'Finalizado', '2026-06-08 19:00:00');

INSERT INTO Item_Pedido (id_pedido, id_produto, quantidade, preco_unitario, observacao) VALUES
(1, 1, 2, 32.90, 'Ao ponto'),
(1, 2, 2, 8.50, 'Sem gelo');

INSERT INTO Pedido_Delivery (id_pedido, endereco_entrega, taxa_entrega) VALUES
(1, 'Rua da Universidade, 1, Centro, Seropédica', 6.00);

INSERT INTO Entrega (
id_entrega,
id_pedido,
id_entregador,
id_veiculo,
horario_saida,
horario_chegada,
status_entrega
) VALUES
(
1,
1,
3,
1,
'2026-06-08 19:20:00',
'2026-06-08 19:50:00',
'Entregue'
);