const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const app = express();

const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'postgres',
    password: 'postgres',
    port: 5432,
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname)));  // Servindo arquivos estáticos da pasta atual

// Rota para servir o arquivo index.html
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Rota para servir o arquivo crud-options.html na rota /api/pets
app.get('/api/pets', (req, res) => {
    res.sendFile(path.join(__dirname, 'crud-options.html'));
    console.log('Rota /api/pets servindo crud-options.html');
});

app.get('/api/pets/delete-options', (req, res) => {
    res.sendFile(path.join(__dirname, 'crud-options.html'));
    console.log('Rota /api/pets/delete-options servindo crud-options.html');
});

app.get('/api/pets/update-options', (req, res) => {
    res.sendFile(path.join(__dirname, 'crud-options.html'));
    console.log('Rota /api/pets/update-options servindo crud-options.html');
});

// Rota para servir o arquivo view-data.html na rota /api/pets/view-data
app.get('/api/pets/view-data', (req, res) => {
    res.sendFile(path.join(__dirname, 'view-data.html'));
    console.log('Rota /api/pets/view-data servindo view-data.html');
});

// Rota para retornar os dados dos pets em JSON
app.get('/api/pets/data', async (req, res) => {
    try {
        const pets = await pool.query('SELECT * FROM PETs');
        res.json(pets.rows);
    } catch (err) {
        console.error('Erro ao buscar pets:', err.message);
        res.status(500).send('Erro ao buscar pets');
    }
});

// Rota para retornar os dados dos clientes em JSON
app.get('/api/clients/data', async (req, res) => {
    try {
        const clients = await pool.query('SELECT * FROM Cliente');
        res.json(clients.rows);
    } catch (err) {
        console.error('Erro ao buscar clientes:', err.message);
        res.status(500).send('Erro ao buscar clientes');
    }
});

// Rota para retornar os dados de um pet específico em JSON
app.get('/api/pets/:id', async (req, res) => {
    const id = req.params.id;
    try {
        const pet = await pool.query('SELECT * FROM PETs WHERE p_id = \$1', [id]);
        if (pet.rows.length === 0) {
            return res.status(404).send('Pet não encontrado');
        }
        res.json(pet.rows[0]);
    } catch (err) {
        console.error('Erro ao buscar pet:', err.message);
        res.status(500).send('Erro ao buscar pet');
    }
});

// Create (Cria um novo pet)
app.post('/api/pets', async (req, res) => {
    const { nome, email, telefone, cidade, address, estado, cor, genero, animal, identification, nascimento, breed, descricao } = req.body;
    try {
        await pool.query('BEGIN');

        // Verifica se o cliente já existe
        const clientResult = await pool.query(
            'SELECT c_id FROM Cliente WHERE nome = \$1 AND email = \$2',
            [nome, email]
        );
        
        let newClientId;
        if (clientResult.rows.length > 0) {
            // Cliente já existe
            newClientId = clientResult.rows[0].c_id;
        } else {
            // Verifica se o estado já existe na tabela Estados
            let stateResult = await pool.query('SELECT state_id FROM Estados WHERE estado = \$1', [estado]);
            let stateId;
            if (stateResult.rows.length === 0) {
                const insertStateQuery = 'INSERT INTO Estados (estado) VALUES (\$1) RETURNING state_id';
                const insertStateResult = await pool.query(insertStateQuery, [estado]);
                stateId = insertStateResult.rows[0].state_id;
            } else {
                stateId = stateResult.rows[0].state_id;
            }

            // Verifica se a cidade já existe na tabela Cidades
            let cityResult = await pool.query('SELECT city_id FROM Cidades WHERE cidade = \$1 AND state_id = \$2', [cidade, stateId]);
            let cityId;
            if (cityResult.rows.length === 0) {
                const insertCityQuery = 'INSERT INTO Cidades (cidade, state_id) VALUES (\$1, \$2) RETURNING city_id';
                const insertCityResult = await pool.query(insertCityQuery, [cidade, stateId]);
                cityId = insertCityResult.rows[0].city_id;
            } else {
                cityId = cityResult.rows[0].city_id;
            }

            // Insere o novo cliente na tabela Cliente
            const insertClientQuery = `INSERT INTO Cliente (nome, email, telefone, adress, city_id) VALUES (\$1, \$2, \$3, \$4, \$5) RETURNING c_id`;
            const insertClientValues = [nome, email, telefone, address, cityId];
            const clientInsertResult = await pool.query(insertClientQuery, insertClientValues);
            newClientId = clientInsertResult.rows[0].c_id;
        }

        // Verifica se a raça já existe na tabela Breeds
        let breedResult = await pool.query('SELECT breed FROM Breeds WHERE breed = \$1', [breed]);
        if (breedResult.rows.length === 0) {
            await pool.query('INSERT INTO Breeds (breed) VALUES (\$1)', [breed]);
            console.log('Nova raça inserida na tabela Breeds:', breed);
        }

        // Insere o novo pet na tabela PETs
        const newPet = await pool.query(
            'INSERT INTO PETs (cor, genero, animal, identification, nascimento, breed, c_id, descricao) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8) RETURNING *',
            [cor, genero, animal, identification, nascimento, breed, newClientId, descricao]
        );

        await pool.query('COMMIT');
        console.log('Novo pet inserido:', newPet.rows[0]);
        res.redirect('/api/pets');
    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Erro ao inserir novo pet no banco de dados:', err.message);
        res.status(500).send('Erro ao criar novo pet');
    }
});

// Update (Atualiza informações de um pet)
app.put('/api/pets/:id', async (req, res) => {
    const id = req.params.id;
    const { cor, genero, animal, identification, nascimento, breed, c_id, descricao } = req.body;
    try {
        await pool.query('BEGIN');

        // Verifica se a raça já existe na tabela Breeds
        let breedResult = await pool.query('SELECT breed FROM Breeds WHERE breed = \$1', [breed]);
        if (breedResult.rows.length === 0) {
            await pool.query('INSERT INTO Breeds (breed) VALUES (\$1)', [breed]);
            console.log('Nova raça inserida na tabela Breeds:', breed);
        }

        // Atualiza os dados do pet
        const updatePetQuery = `
            UPDATE PETs 
            SET cor = \$1, 
                genero = \$2, 
                animal = \$3, 
                identification = \$4, 
                nascimento = \$5, 
                breed = \$6,
                c_id = \$7,
                descricao = \$8
            WHERE p_id = \$9 
            RETURNING *
        `;
        const updatePetValues = [cor, genero, animal, identification, nascimento, breed, c_id, descricao, id];
        const updatedPet = await pool.query(updatePetQuery, updatePetValues);

        await pool.query('COMMIT');
        console.log('Pet atualizado:', updatedPet.rows[0]);
        res.json(updatedPet.rows[0]);
    } catch (err) {
        await pool.query('ROLLBACK');
        console.error('Erro ao atualizar pet:', err.message);
        res.status(500).send('Erro ao atualizar pet');
    }
});

// Delete (Exclui um pet)
app.delete('/api/pets/:id', async (req, res) => {
    const id = req.params.id;
    try {
        await pool.query('DELETE FROM PETs WHERE p_id = \$1', [id]);
        res.sendStatus(204);
    } catch (err) {
        console.error('Erro ao excluir pet:', err.message);
        res.status(500).send('Erro ao excluir pet');
    }
});

// Rota para deletar todos os dados chamando a função no PostgreSQL
app.delete('/api/delete-all', async (req, res) => {
    try {
        await pool.query('SELECT delete_all_data()');
        res.send('Todos os dados foram deletados');
    } catch (err) {
        console.error('Erro ao deletar todos os dados:', err.message);
        res.status(500).send('Erro ao deletar todos os dados');
    }
});

// Rota para buscar informações de uma cidade pelo ID
app.get('/api/cities/:id', async (req, res) => {
    const cityId = req.params.id;
    try {
        const cityQuery = `
            SELECT c.cidade, e.estado
            FROM Cidades c
            JOIN Estados e ON c.state_id = e.state_id
            WHERE c.city_id = \$1
        `;
        const cityResult = await pool.query(cityQuery, [cityId]);
        if (cityResult.rows.length === 0) {
            return res.status(404).send('Cidade não encontrada');
        }
        res.json(cityResult.rows[0]);
    } catch (err) {
        console.error('Erro ao buscar cidade:', err.message);
        res.status(500).send('Erro ao buscar cidade');
    }
});

// Inicia o servidor na porta 3000
app.listen(3000, () => {
    console.log('Servidor rodando na porta 3000: http://localhost:3000');
});