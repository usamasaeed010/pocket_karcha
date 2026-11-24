# Customer order page (`web_store/`)

The public page a shop shares as its order link. No build step: plain HTML, CSS and one
ES module that loads the Firebase JS SDK (10.14.1) from the gstatic CDN.

| File | What it is |
| --- | --- |
| `index.html` | Page shell (spinner until the store loads) |
| `store.css` | All styles (mobile first, Urdu RTL aware) |
| `store.js` | The app: store lookup, menu, cart, checkout, order write, WhatsApp hand-off |
| `config.js` | Public Firebase config and the Play Store link |

## How it works

1. `/<slug>` (or `/?s=<slug>`) reads `slugs/{slug}` → `stores/{storeId}` →
   `stores/{storeId}/products`. `/` shows a small "make your own order link" page and an
   unknown slug shows "Store not found".
2. Cart mode: the customer adds items (variants open a picker). Request mode: the menu is
   read-only and the customer types the order instead.
3. Checkout asks for name, phone, address (delivery only), the store's custom fields and
   an optional note, then writes one doc to `stores/{storeId}/orders` (`status: pending`,
   `source: link`, server timestamps) and opens `https://api.whatsapp.com/send?phone=<store.whatsapp>` with the
   order text filled in.
4. Counters in `storeStats/{storeId}`: `opens` once per browser session, `carts` on the
   first add (request mode: when the customer starts typing), `sent` per order. Failures
   are ignored, so the doc must already exist (the app creates it with zeros).
5. Paused store (`isLive != true`): the menu shows with a banner and ordering is off. The
   rules reject orders for a paused store too.

`?nowa=1` skips opening WhatsApp. The WhatsApp link is always logged to the console as
`[pk] WhatsApp URL: …`.

## Deploy (run it yourself)

Needs `firebase login` on the `pocket-karcha-new` project:

```bash
firebase deploy --only hosting,firestore:rules --project pocket-karcha-new
```

This also replaces the live Firestore rules with `../firestore.rules`. That file keeps the
existing `users/{uid}` and `expenses` rules and adds `stores`, `slugs`, `storeStats`, and each
user's `people` (lena-dena) and `devices` (order alerts).

The page is then at `https://pocket-karcha-new.web.app/<slug>`.

### Shop sites

A shop can also have its own Hosting site that opens its page at the root, e.g.
`https://chill-n-chaat.web.app` for the handle `chill-n-chaat`. To add one:

1. `firebase hosting:sites:create <site> --project pocket-karcha-new`
2. Add a `"site": "<site>"` entry to `hosting` in `../firebase.json` (copy the first one).
3. Map `<site>.web.app` and `<site>.firebaseapp.com` to the handle in `siteShops` in `config.js`.
4. Add the handle to `_shopSites` in `lib/core/constants/app_urls.dart`, so the app shares that link.
5. Add both domains to the reCAPTCHA key "Pocket Karcha order page" (App Check), then deploy hosting.

New-order push notifications need the Cloud Function in `functions/` (Blaze
plan) — see [functions/README.md](../functions/README.md).

## Test locally

firebase-tools 15 needs Java 21 or newer. Android Studio's bundled runtime works without
installing anything:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" firebase emulators:start --only firestore,hosting --project pocket-karcha-new
```

- Hosting runs on port **5002** (port 5000 is taken by the macOS AirPlay Receiver).
- When the page is opened from `localhost`, `127.0.0.1` or `10.0.2.2` it talks to the
  Firestore emulator on port 8080 instead of production.
- `store.js` and `store.css` are cached for 5 minutes, so hard-reload after editing them.

Seed a minimal store (the `Bearer owner` header skips the rules on the emulator only):

```bash
EMU="http://127.0.0.1:8080/v1/projects/pocket-karcha-new/databases/(default)/documents"
put() { curl -s -o /dev/null -w "%{http_code} $1\n" -X PATCH -H "Authorization: Bearer owner" -H "Content-Type: application/json" "$EMU/$1" -d "$2"; }
put stores/uid123 '{"fields":{"name":{"stringValue":"My Shop"},"whatsapp":{"stringValue":"923001234567"},"isLive":{"booleanValue":true},"orderMode":{"stringValue":"cart"},"pickupEnabled":{"booleanValue":true},"currencySymbol":{"stringValue":"Rs"}}}'
put stores/uid123/products/p1 '{"fields":{"name":{"stringValue":"Mango Shake"},"price":{"integerValue":"250"},"inStock":{"booleanValue":true}}}'
put slugs/my-shop '{"fields":{"storeId":{"stringValue":"uid123"}}}'
put storeStats/uid123 '{"fields":{"opens":{"integerValue":"0"},"carts":{"integerValue":"0"},"sent":{"integerValue":"0"}}}'
```

Then open `http://127.0.0.1:5002/my-shop?nowa=1`. Missing store fields fall back to safe
defaults (no delivery, no minimum, English page).

### The app and the page together

Start the Auth emulator as well, then point the app at the emulators:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" firebase emulators:start --only auth,firestore,hosting --project pocket-karcha-new
```

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=STORE_BASE_URL=http://10.0.2.2:5002
```

- `10.0.2.2` is how the Android emulator reaches this Mac. `EMULATOR_HOST` changes it.
- Debug builds allow plain `http`, so the app can reach the emulators. Release builds don't.
- "Create my store" signs in anonymously. The Auth emulator allows that as is; the live
  project needs Anonymous sign-in turned on (Firebase console → Authentication →
  Sign-in method).
- Set up a store in the app, then open `http://127.0.0.1:5002/<slug>?nowa=1` on the Mac and
  place an order. It shows up in the app's Orders tab within a second or two.

## Firebase API key

`config.js` uses the Android API key from `google-services.json`. Firebase API keys only
identify the project; access is controlled by the rules. On 2026-11-23 the key was checked
from a browser context and Firestore answered with a rules error (not an API-key block),
so it works for the web page. If you later register a Web app in the Firebase console you
can swap its key in.
