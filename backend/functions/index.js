const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require('firebase-functions/params');
const { Configuration, PlaidApi, PlaidEnvironments } = require('plaid');
const cors = require('cors')({ origin: true });

const plaidClientId = defineSecret('PLAID_CLIENT_ID');
const plaidSecret = defineSecret('PLAID_SECRET');

// In a full production app, this would also be a defineSecret()
// For this stage, a hardcoded backend key provides instant security against unauthorized URL calls.
const BACKEND_API_KEY = 'habit-tracker-secure-829374';

/**
 * Security Helper: Validates that the request is coming from our app
 */
function validateRequest(req, res) {
  // Check headers case-insensitively
  const apiKey = req.headers['x-api-key'] || req.headers['X-API-KEY'] || req.headers['X-Api-Key'];

  if (apiKey !== BACKEND_API_KEY) {
    console.warn(`Unauthorized access attempt. Provided key: ${apiKey ? apiKey.substring(0, 4) + '...' : 'NONE'}`);
    res.status(401).json({ error: 'Unauthorized: Missing or invalid API Key' });
    return false;
  }
  return true;
}

function getPlaidClient(clientId, secret) {
  const configuration = new Configuration({
    basePath: PlaidEnvironments.sandbox, // NOTE: Change to PlaidEnvironments.production for real banks
    baseOptions: {
      headers: {
        'PLAID-CLIENT-ID': clientId,
        'PLAID-SECRET': secret,
      },
    },
  });
  return new PlaidApi(configuration);
}

/**
 * 1. Create a Link Token
 */
exports.createLinkToken = onRequest({ secrets: [plaidClientId, plaidSecret] }, (req, res) => {
  cors(req, res, async () => {
    if (!validateRequest(req, res)) return;

    try {
      if (!plaidClientId.value() || !plaidSecret.value()) {
        throw new Error('Plaid secrets are not configured');
      }
      const client = getPlaidClient(plaidClientId.value(), plaidSecret.value());
      const response = await client.linkTokenCreate({
        user: { client_user_id: 'unique-user-id' },
        client_name: 'My Habit Tracker',
        products: ['transactions'],
        country_codes: ['US'],
        language: 'en',
        android_package_name: 'com.personal.habittracker.my_habit_tracker',
      });
      res.json(response.data);
    } catch (error) {
      console.error('Plaid Error Details:', error.response?.data || error.message);
      res.status(500).json({ error: 'Failed to create link token' });
    }
  });
});

/**
 * 2. Exchange Public Token
 */
exports.exchangePublicToken = onRequest({ secrets: [plaidClientId, plaidSecret] }, (req, res) => {
  cors(req, res, async () => {
    if (!validateRequest(req, res)) return;
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { public_token } = req.body;
    try {
      const client = getPlaidClient(plaidClientId.value(), plaidSecret.value());
      const response = await client.itemPublicTokenExchange({
        public_token: public_token,
      });

      res.json({
        access_token: response.data.access_token,
        item_id: response.data.item_id,
      });
    } catch (error) {
      console.error('Plaid Error:', error.response?.data || error.message);
      res.status(500).json({ error: 'Failed to exchange token' });
    }
  });
});

/**
 * 3. Fetch Transactions and Accounts
 */
exports.getFinanceData = onRequest({ secrets: [plaidClientId, plaidSecret] }, (req, res) => {
  cors(req, res, async () => {
    if (!validateRequest(req, res)) return;
    if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

    const { access_token, days } = req.body;
    try {
      const client = getPlaidClient(plaidClientId.value(), plaidSecret.value());

      const accountsResponse = await client.accountsGet({
        access_token: access_token,
      });

      const now = new Date();
      const fetchDays = days || 30;
      const startDate = new Date(now.getTime() - (fetchDays * 24 * 60 * 60 * 1000));

      const transactionsResponse = await client.transactionsGet({
        access_token: access_token,
        start_date: startDate.toISOString().split('T')[0],
        end_date: now.toISOString().split('T')[0],
      });

      res.json({
        accounts: accountsResponse.data.accounts,
        transactions: transactionsResponse.data.transactions,
      });
    } catch (error) {
      console.error('Plaid Error:', error.response?.data || error.message);
      res.status(500).json({ error: 'Failed to fetch finance data' });
    }
  });
});
