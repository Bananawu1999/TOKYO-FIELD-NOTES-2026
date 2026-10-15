# TOKYO FIELD NOTES 2026

Original cream-and-green travel planner for Tokyo, Kawaguchiko and Kamakura (17–22 Nov 2026).

## GitHub Pages

Website: https://bananawu1999.github.io/TOKYO-FIELD-NOTES-2026/

The site is static HTML. It works as a **local-only** planner until Supabase is configured.

## Enable share-link collaboration (no login or invitations)

1. Create your own Supabase project at https://supabase.com/.
2. Open its **SQL Editor** and run [supabase-share-link-setup.sql](./supabase-share-link-setup.sql) **once**. The last query displays a 64-character `YOUR_SHARE_LINK_SECRET`. Save it privately. **Do not commit the secret to GitHub.**
3. In Supabase **Project Settings → API**, copy **Project URL** and **publishable key** (or legacy **anon key**). **Never use `service_role` or secret API keys.**
4. Edit `index.html`: find `const CONFIG={url:'',anonKey:''};` in the second inline script. Fill only the *public* URL and publishable/anon key.
5. Commit the change. Wait for GitHub Pages deployment.
6. Open the website and press **分享共編連結**, paste the private one-time share secret, then copy the resulting link ending in `#share=...`.
7. Send that **full link** to your travel companion. Changes to itinerary stops, checklist and expenses are shared with polling approximately every 7 seconds.

### Security and limitations

- Everyone possessing the **full** share link can read, change or delete itinerary data. There are no individual accounts or per-person permissions.
- The public base website URL alone does not grant database access.
- Do not post the full share link publicly. The URL fragment is not sent to GitHub Pages; it is passed only from the app to the Supabase RPC as the secret argument.
- SQL disables direct table access to anonymous users; read and write require the secret through dedicated RPC functions.
- Concurrent writes use revision checks rather than silent last-write-wins. A conflict stops syncing and prompts a JSON backup before reloading; it does not automatically merge.
- Sync requires internet. Local edits while disconnected may conflict with remote edits later, so use the export backup feature.
- The initial trip itinerary is embedded in HTML. Later edits, new stops, checklist and expenses are synchronized. Updates to the hardcoded base itinerary still require a GitHub commit.
- Do not include sensitive financial records or passwords in a publicly accessible travel application.

## Troubleshooting

In case of `404`, check GitHub Actions deployment or Pages Source=GitHub Actions.
If the app says `本機模式`, verify that you filled in the CONFIG fields, deployed successfully and ran the SQL.
