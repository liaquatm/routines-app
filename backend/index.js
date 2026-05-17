const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const configuration = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV || 'sandbox'],
  baseOptions: {
    headers: {
      'PLAID-CLIENT-ID': process.env.PLAID_CLIENT_ID,
      'PLAID-SECRET': process.env.PLAID_SECRET,
    },
  },
});

const plaidClient = new PlaidApi(configuration);

// 1. Create a link_token to initialize Plaid Link
app.post('/api/create_link_token', async (req, res) => {
  try {
    const response = await plaidClient.linkTokenCreate({
      user: { client_user_id: 'unique-user-id' }, // In a real app, use the actual user ID
      client_name: 'My Habit Tracker',
      products: ['transactions'],
      country_codes: ['US'],
      language: 'en',
    });
    res.json(response.data);
  } catch (error) {
    console.error('Error creating link token:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to create link token' });
  }
});

// 2. Exchange a public_token for an access_token
app.post('/api/exchange_public_token', async (req, res) => {
  const { public_token } = req.body;
  try {
    const response = await plaidClient.itemPublicTokenExchange({
      public_token: public_token,
    });
    const accessToken = response.data.access_token;
    const itemId = response.data.item_id;

    // In a full production app, you might save these to a database here.
    // For our local-first app, we will send them back to the Flutter app
    // to be stored in the device's Secure Storage.
    res.json({
      access_token: accessToken,
      item_id: itemId,
    });
  } catch (error) {
    console.error('Error exchanging public token:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to exchange token' });
  }
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Backend server running on port ${PORT}`);
});
