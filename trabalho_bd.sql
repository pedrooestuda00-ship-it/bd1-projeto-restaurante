-- Criação das tabelas do sistema

CREATE TABLE Categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL,
    descricao TEXT
);

CREATE TABLE Cliente (
    id_cliente SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20)
);

-- Endereços dos clientes (Atributo composto extraído)
CREATE TABLE Endereco (
    id_cliente INT,
    id_endereco SERIAL,
    rua VARCHAR(150) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    complemento VARCHAR(50),
    bairro VARCHAR(80) NOT NULL,
    cidade VARCHAR(80) NOT NULL,
    PRIMARY KEY (id_cliente, id_endereco),
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

CREATE TABLE Mesa (
    id_mesa SERIAL PRIMARY KEY,
    numero SMALLINT UNIQUE NOT NULL,
    status VARCHAR(30) NOT NULL
);

CREATE TABLE Veiculo (
    placa VARCHAR(10) PRIMARY KEY,
    modelo VARCHAR(60) NOT NULL
);

-- Cadastro geral dos funcionários do restaurante
CREATE TABLE Funcionario (
    id_funcionario SERIAL PRIMARY KEY,
    id_supervisor INT,
    nome VARCHAR(100) NOT NULL,
    cpf CHAR(11) UNIQUE NOT NULL,
    data_admissao DATE NOT NULL,
    salario NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (id_supervisor) REFERENCES Funcionario(id_funcionario)
);

-- Informações específicas dos garçons
CREATE TABLE Garcom (
    id_funcionario INT PRIMARY KEY,
    praca VARCHAR(80),
    FOREIGN KEY (id_funcionario) REFERENCES Funcionario(id_funcionario)
);

-- Informações específicas dos entregadores
CREATE TABLE Entregador (
    id_funcionario INT PRIMARY KEY,
    cnh VARCHAR(20) UNIQUE NOT NULL,
    FOREIGN KEY (id_funcionario) REFERENCES Funcionario(id_funcionario)
);

-- Itens disponíveis no cardápio
CREATE TABLE Item_do_cardapio (
    id_item SERIAL PRIMARY KEY,
    id_categoria INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco NUMERIC(10, 2) NOT NULL,
    disponivel BOOLEAN NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES Categoria(id_categoria)
);

-- Registro dos pedidos realizados pelos clientes
CREATE TABLE Pedido (
    id_pedido SERIAL PRIMARY KEY,
    id_cliente INT NOT NULL,
    status VARCHAR(30) NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente)
);

-- Itens que compõem cada pedido
CREATE TABLE Item_Pedido (
    id_pedido INT,
    id_item INT,
    quantidade SMALLINT NOT NULL,
    preco_unitario NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (id_pedido, id_item),
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
    FOREIGN KEY (id_item) REFERENCES Item_do_cardapio(id_item)
);

-- Dados dos pedidos realizados no salão
CREATE TABLE Pedido_Presencial (
    id_pedido INT PRIMARY KEY,
    observacoes TEXT,
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido)
);

-- Controle do relacionamento ternário entre mesa, garçom e pedido presencial
CREATE TABLE Atendimento (
    id_mesa INT,
    id_funcionario_garcom INT,
    id_pedido_presencial INT,
    horario TIMESTAMP NOT NULL,
    PRIMARY KEY (id_mesa, id_funcionario_garcom, id_pedido_presencial),
    FOREIGN KEY (id_mesa) REFERENCES Mesa(id_mesa),
    FOREIGN KEY (id_funcionario_garcom) REFERENCES Garcom(id_funcionario),
    FOREIGN KEY (id_pedido_presencial) REFERENCES Pedido_Presencial(id_pedido)
);

-- Dados dos pedidos logísticos de entrega
CREATE TABLE Pedido_Delivery (
    id_pedido INT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_endereco INT NOT NULL,
    taxa_entrega NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES Pedido(id_pedido),
    FOREIGN KEY (id_cliente, id_endereco) REFERENCES Endereco(id_cliente, id_endereco)
);

-- Controle das entregas realizadas pela frota
CREATE TABLE Entrega (
    id_entrega SERIAL PRIMARY KEY,
    id_pedido_delivery INT NOT NULL,
    id_entregador INT NOT NULL,
    placa_veiculo VARCHAR(10) NOT NULL,
    horario_saida TIMESTAMP NOT NULL,
    horario_entrega TIMESTAMP,
    status_entrega VARCHAR(30) NOT NULL,
    FOREIGN KEY (id_pedido_delivery) REFERENCES Pedido_Delivery(id_pedido),
    FOREIGN KEY (id_entregador) REFERENCES Entregador(id_funcionario),
    FOREIGN KEY (placa_veiculo) REFERENCES Veiculo(placa)
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

-- Gatilho executado após o registro de um atendimento de salão
CREATE TRIGGER trg_ocupar_mesa
AFTER INSERT ON Atendimento
FOR EACH ROW
EXECUTE FUNCTION fn_ocupar_mesa();


-- View que apresenta o detalhamento dos itens de cada pedido
CREATE VIEW vw_extrato_pedido AS
SELECT 
    p.id_pedido, 
    c.nome AS cliente, 
    ic.nome AS produto, 
    ip.quantidade, 
    ip.preco_unitario, 
    (ip.quantidade * ip.preco_unitario) AS subtotal
FROM Pedido p
JOIN Cliente c ON p.id_cliente = c.id_cliente
JOIN Item_Pedido ip ON p.id_pedido = ip.id_pedido
JOIN Item_do_cardapio ic ON ip.id_item = ic.id_item;

-- View que exibe a relação entre funcionários e seu supervisor
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

INSERT INTO Cliente (id_cliente, nome, telefone) VALUES
(1, 'Professor Eric', '21988887777'),
(2, 'Vitoria Santos', '21977776666');

INSERT INTO Endereco (id_cliente, id_endereco, rua, numero, complemento, bairro, cidade) VALUES
(1, 1, 'Rua da Universidade', '1', 'Sala de Professores', 'Centro', 'Seropédica'),
(2, 1, 'Avenida Principal', '200', 'Apto 302', 'Jardim', 'Itaguaí');

INSERT INTO Mesa (id_mesa, numero, status) VALUES
(1, 10, 'Livre'),
(2, 11, 'Livre'),
(3, 12, 'Livre');

INSERT INTO Veiculo (placa, modelo) VALUES
('RUR4L1N', 'Honda CG 160 Titan'),
('UFR1R26', 'Yamaha Fazer 250');

INSERT INTO Funcionario (id_funcionario, id_supervisor, nome, cpf, data_admissao, salario) VALUES
(1, NULL, 'Pedro Paulo', '12312312312', '2025-06-01', 5000.00),
(2, 1, 'Arthur Herbert', '23423423423', '2025-06-15', 2500.00),
(3, 1, 'Gilmar Silas', '34534534534', '2026-01-10', 2800.00);

INSERT INTO Garcom (id_funcionario, praca) VALUES
(2, 'Salão Principal');

INSERT INTO Entregador (id_funcionario, cnh) VALUES
(3, '98765432100');

INSERT INTO Item_do_cardapio (id_item, id_categoria, nome, descricao, preco, disponivel) VALUES
(1, 1, 'Hambúrguer Rural', 'Pão brioche, blend 200g, queijo prato', 32.90, TRUE),
(2, 2, 'Suco de Laranja', 'Copo 500ml', 8.50, TRUE),
(3, 3, 'Pudim', 'Fatia de pudim de leite condensado', 12.00, TRUE);

-- Fluxo de demonstração 1: Pedido Delivery
INSERT INTO Pedido (id_pedido, id_cliente, status, data_hora) VALUES
(1, 1, 'Finalizado', '2026-06-08 19:00:00');

INSERT INTO Item_Pedido (id_pedido, id_item, quantidade, preco_unitario) VALUES
(1, 1, 2, 32.90),
(1, 2, 2, 8.50);

INSERT INTO Pedido_Delivery (id_pedido, id_cliente, id_endereco, taxa_entrega) VALUES
(1, 1, 1, 6.00);

INSERT INTO Entrega (id_entrega, id_pedido_delivery, id_entregador, placa_veiculo, horario_saida, horario_entrega, status_entrega) VALUES
(1, 1, 3, 'RUR4L1N', '2026-06-08 19:20:00', '2026-06-08 19:50:00', 'Entregue');

-- Fluxo de demonstração 2: Pedido Presencial e Atendimento Ternário
INSERT INTO Pedido (id_pedido, id_cliente, status, data_hora) VALUES
(2, 2, 'Em andamento', '2026-06-08 20:00:00');

INSERT INTO Item_Pedido (id_pedido, id_item, quantidade, preco_unitario) VALUES
(2, 3, 1, 12.00);

INSERT INTO Pedido_Presencial (id_pedido, observacoes) VALUES
(2, 'Servir logo após a refeição principal');

-- O INSERT na tabela Atendimento acionará a trigger trg_ocupar_mesa automaticamente
INSERT INTO Atendimento (id_mesa, id_funcionario_garcom, id_pedido_presencial, horario) VALUES
(2, 2, 2, '2026-06-08 20:05:00');