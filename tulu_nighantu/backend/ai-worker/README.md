# Tulu Nighantu AI server (Cloudflare Worker)

This small server makes **Ask AI** work for every user without putting your
Gemini key in the app. The app sends the text to this Worker. The Worker adds
your key (stored as a Cloudflare secret), asks Gemini, and returns the answer.

- It only translates into Tulu, because the prompt is built here. It can't be
  used as a general AI endpoint.
- Text is limited to 300 characters. There is an optional per-user daily limit
  (`DAILY_LIMIT`, default 60, active when a KV namespace is bound).
- Gemini's key errors are never passed back to the app.
- Cloudflare Workers' free plan allows 100,000 requests a day.

## One-time setup (about 10 minutes, all in the browser)

1. **Gemini key:** go to <https://aistudio.google.com>, open **Get API key**,
   click **Create API key** and copy it.
2. **Cloudflare account:** sign up free at <https://dash.cloudflare.com>. Open
   **Workers & Pages** once so your `*.workers.dev` subdomain is created.
3. **Cloudflare account ID:** in the dashboard, go to **Workers & Pages**. The
   Account ID is on the right; copy it.
4. **Cloudflare API token:** go to **My Profile › API Tokens › Create Token**,
   choose the **Edit Cloudflare Workers** template, then **Create** and copy the
   token.
5. **GitHub secrets:** in the repo go to **Settings › Secrets and variables ›
   Actions › New repository secret** and add:
   - `GEMINI_API_KEY`: the Gemini key
   - `CLOUDFLARE_ACCOUNT_ID`: the account ID
   - `CLOUDFLARE_API_TOKEN`: the API token
6. **Deploy:** go to **Actions › "Tulu Nighantu AI server (deploy)" › Run
   workflow**. When it finishes, the log shows the Worker URL, for example
   `https://tulu-nighantu-ai.<your-subdomain>.workers.dev`. Opening that URL in
   a browser should show `{"ok":true,...}`.
7. **Connect the app:** in **Settings › Secrets and variables › Actions ›
   Variables**, add a **New repository variable** named `AI_PROXY_URL` whose
   value is the Worker URL. Then re-run **Actions › "Tulu Nighantu (Flutter)"**.
   The new APK has AI built in, and Settings shows "AI is built in – no key
   needed".

To change the key later, update the `GEMINI_API_KEY` secret and run the deploy
workflow again. Users don't need a new APK.

### Optional: per-user daily limit
```sh
npx wrangler kv namespace create RATE_KV
```
Put the printed id into the commented `[[kv_namespaces]]` block in
`wrangler.toml`, commit, and deploy again.

## Local development
```sh
npm test                           # unit tests (Node 20+)
npx wrangler dev                   # run locally
npx wrangler secret put GEMINI_API_KEY
npx wrangler deploy
```

## Word suggestions (review page)

App users can send new words ("Send to the dictionary"). They are stored in a
Workers KV namespace (`SUGGEST_KV`), which the deploy workflow creates and
binds automatically.

1. Add a repository secret **`TULU_ADMIN_PASSWORD`** (any password you choose).
2. Run the **Tulu Nighantu AI server (deploy)** workflow.
3. Open `https://<your-worker>.workers.dev/admin`, enter the password, and
   **Approve** or **Delete** each suggestion. Approved words appear as JSON in
   the `words.json` format; copy it and add it to `assets/data/words.json`.

Limits: 30 suggestions per user per day; fields are length-limited and the
Tulu word must be in Kannada script.
