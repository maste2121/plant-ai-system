// server/config/config.js
const { Sequelize } = require('sequelize');
const dotenv = require('dotenv');

dotenv.config(); // Load environment variables

const sequelize = new Sequelize(
  process.env.DB_NAME || 'plant_disease_admin',
  process.env.DB_USER || 'avnadmin',
  process.env.DB_PASSWORD,
  {
    host: process.env.DB_HOST || 'mysql-394de76a-mastewalkihnet-7fb8.a.aivencloud.com',
    port: process.env.DB_PORT || 23751,
    dialect: 'mysql', // Hardcoded fallback ensures dialect is never missing
    dialectOptions: {
      ssl: {
        rejectUnauthorized: false // Required for Aiven SSL connection
      }
    },
    logging: false, // Set to true to see SQL queries in console
    define: {
      timestamps: true, // Adds createdAt and updatedAt fields automatically
      underscored: true, // Use snake_case for column names
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connection to MySQL has been established successfully.');

    // FIX: Set to false so your mock data never gets dropped or wiped on restart!
    await sequelize.sync({ alter: false, force: false });
    console.log('All models were synchronized successfully.');

  } catch (error) {
    console.error('Unable to connect to the database:', error);
    process.exit(1); // Exit process with failure
  }
};

module.exports = { sequelize, connectDB };