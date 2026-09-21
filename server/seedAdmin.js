require('dotenv').config();
const { connectDB } = require('./config/config');
const Admin = require('./models/Admin');

(async () => {
  try {
    await connectDB();

    console.log('🔍 Connected to:', process.env.DB_HOST, '/', process.env.DB_NAME);

    const email = 'admin1@gmail.com';
    const plainPassword = 'Azxcv@123';

    // Delete any existing admin with this email
    const deleted = await Admin.destroy({ where: { email } });
    console.log('🗑️  Deleted existing rows:', deleted);

    // Create new admin — model auto-hashes the password
    const admin = await Admin.create({
      email,
      password: plainPassword,
      role: 'admin',
    });

    console.log('✅ Admin created!');
    console.log('   ID:    ', admin.id);
    console.log('   Email: ', admin.email);
    console.log('   Role:  ', admin.role);
    console.log('   Hash:  ', admin.password.substring(0, 30) + '...');
    console.log('   Hash length:', admin.password.length);

    process.exit(0);
  } catch (err) {
    console.error('❌ Seed error:', err);
    process.exit(1);
  }
})();