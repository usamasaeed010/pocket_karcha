# Cloud Functions (`functions/`)

## `notifyNewOrder` — new-order push to the shop owner

When a customer orders from the store link, the page writes
`stores/{storeId}/orders/{orderId}` with `source: "link"`. This function then
sends a push notification to every phone the owner turned alerts on for
(`users/{storeId}/devices/{token}`, saved by the app — Home card or
Settings → New-order notifications).

- Text is in the owner's app language (English or Urdu), e.g.
  "New order #1042 · Rs 1,350" / "Ali · 3 items · Delivery".
- Android channel `orders` (high importance, made in `MainActivity.kt`).
- Tapping the notification opens that order in the app.
- Phones that uninstalled the app are removed automatically.
- Orders the owner types in the app send nothing.

## Deploy (run it yourself)

Cloud Functions need the **Blaze (pay as you go)** plan on
`pocket-karcha-new`. A small shop stays far inside the free monthly quota.

```bash
cd functions && npm install && cd ..
firebase deploy --only functions --project pocket-karcha-new
```

If the Firestore database is not in the US, set the same region for the
function first (Firestore triggers must run where the database is), e.g. in
`index.js`: `const { setGlobalOptions } = require('firebase-functions/v2');
setGlobalOptions({ region: 'asia-south1' });`

Without Blaze, deploy only the page and rules (everything else still works;
the app also shows a banner for new orders while it is open):

```bash
firebase deploy --only hosting,firestore:rules --project pocket-karcha-new
```

## Test

```bash
cd functions && npm test
```

Locally the function runs in the Functions emulator (port 5001) when an
order is placed on the emulated page, and its log shows the message it
built. The emulator cannot deliver a real push (FCM is not emulated), so
the phone notification itself is only seen after deploying.
