require('dotenv').config();

const express = require('express');

const cors = require('cors');

const authRoutes = require('./routes/authRoutes');

const plateRoutes = require('./routes/plateRoutes');

const userRoutes = require('./routes/userRoutes');

const app = express();

app.use(cors());

app.use(express.json());

app.use('/api/auth', authRoutes);

app.use('/api/plate', plateRoutes);

app.use('/api/user', userRoutes);

app.get('/test', (req, res) => {
 res.send('API is working');
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
 