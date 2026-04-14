import app from './app.js';
import { env } from './config/env.js';
import { connectDatabase } from './db.js';

app.listen(env.port, '0.0.0.0', async () => {
  console.log(`Achievement backend listening on http://0.0.0.0:${env.port}`);
  await connectDatabase();
});

