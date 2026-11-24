import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocket_karcha/data/models/order_model.dart';
import 'package:pocket_karcha/providers/app_settings_provider.dart';

/// Strings for the order app (store, orders, products, settings).
/// English + Urdu, same pattern as [AppStrings].
class StoreStrings {
  const StoreStrings(this.isUrdu);

  final bool isUrdu;

  String _t(String en, String ur) => isUrdu ? ur : en;

  // ── Common ──────────────────────────────────────────────────────────────
  String get save => _t('Save', 'محفوظ کریں');
  String get cancel => _t('Cancel', 'منسوخ');
  String get delete => _t('Delete', 'حذف کریں');
  String get edit => _t('Edit', 'ترمیم');
  String get done => _t('Done', 'ہو گیا');
  String get add => _t('Add', 'شامل کریں');
  String get copy => _t('Copy', 'کاپی');
  String get copied => _t('Copied', 'کاپی ہو گیا');
  String get linkCopied => _t('Link copied', 'لنک کاپی ہو گیا');
  String get seeAll => _t('See all', 'سب دیکھیں');
  String get optional => _t('optional', 'اختیاری');
  String get next => _t('Next', 'آگے');
  String get back => _t('Back', 'واپس');
  String get later => _t('Later', 'بعد میں');
  String get retry => _t('Try again', 'دوبارہ کوشش کریں');
  String get saved => _t('Saved', 'محفوظ ہو گیا');
  String get somethingWrong => _t(
        'Something went wrong. Please try again.',
        'کچھ غلط ہو گیا، دوبارہ کوشش کریں۔',
      );
  String get checkInternet => _t(
        'Could not reach the server. Check your internet and try again.',
        'سرور سے رابطہ نہیں ہو سکا۔ انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔',
      );
  String get noAccess => _t(
        'Not allowed by the server. Make sure the latest Firestore rules are deployed.',
        'سرور نے اجازت نہیں دی۔ تازہ Firestore rules ڈیپلائے کریں۔',
      );
  String get whatsappMissing => _t(
        'Could not open WhatsApp on this phone.',
        'اس فون پر واٹس ایپ نہیں کھل سکا۔',
      );
  String get discardChanges => _t('Discard changes?', 'تبدیلیاں ختم کریں؟');
  String get discardChangesBody => _t(
        'You have changes that are not saved yet.',
        'آپ کی کچھ تبدیلیاں ابھی محفوظ نہیں ہوئیں۔',
      );
  String get discard => _t('Discard', 'ختم کریں');
  String get keepEditing => _t('Keep editing', 'ترمیم جاری رکھیں');

  String itemsLabel(int n) =>
      isUrdu ? '$n آئٹم' : (n == 1 ? '1 item' : '$n items');
  String ordersLabel(int n) =>
      isUrdu ? '$n آرڈر' : (n == 1 ? '1 order' : '$n orders');
  String productsLabel(int n) =>
      isUrdu ? '$n آئٹم' : (n == 1 ? '1 item' : '$n items');

  // ── Tabs ────────────────────────────────────────────────────────────────
  String get tabHome => _t('Home', 'ہوم');
  String get tabOrders => _t('Orders', 'آرڈرز');
  String get tabProducts => _t('Menu', 'مینو');
  String get tabSettings => _t('Settings', 'سیٹنگز');
  String get tabKhata => _t('Khata', 'کھاتہ');
  String get pressBackAgain =>
      _t('Press back again to exit', 'باہر جانے کے لیے دوبارہ بیک دبائیں');

  // ── Onboarding ──────────────────────────────────────────────────────────
  String get obTag1 => _t('Customers need no app', 'گاہک کو کوئی ایپ نہیں چاہیے');
  String get obTitle1 =>
      _t('One link for your whole shop', 'پوری دکان، صرف ایک لنک');
  String get obBody1 => _t(
        'Put your items online and share the link — orders reach your phone and WhatsApp.',
        'اپنی چیزیں آن لائن لگائیں اور لنک شیئر کریں — آرڈر سیدھے آپ کے فون اور واٹس ایپ پر۔',
      );
  String get obTag2 => _t('Never miss an order', 'کوئی آرڈر نہ چھوٹے');
  String get obTitle2 => _t('All orders in one list', 'سب آرڈرز ایک جگہ');
  String get obBody2 => _t(
        "See who ordered what, the total and whether it's paid — no more scrolling through chats.",
        'کس نے کیا منگوایا، کتنے کا اور ادائیگی ہوئی یا نہیں — چیٹ میں ڈھونڈنے کی ضرورت نہیں۔',
      );
  String get obTag3 => _t('Know your money', 'اپنا حساب جانیں');
  String get obTitle3 => _t('See who still owes you', 'کس سے پیسے لینے ہیں');
  String get obBody3 => _t(
        'Mark orders paid, record part payments and send reminders on WhatsApp.',
        'آرڈر ادا شدہ کریں، جزوی ادائیگی درج کریں اور واٹس ایپ پر یاد دہانی بھیجیں۔',
      );
  String get createMyStore => _t('Create my store', 'اپنا اسٹور بنائیں');
  String get haveStore => _t('I already have a store', 'میرا اسٹور پہلے سے ہے');
  String get freeNoCommission =>
      _t('Free to start · No commission', 'مفت شروع کریں · کوئی کمیشن نہیں');
  String get quickStartUnavailable => _t(
        'Quick start is not enabled yet — create an account to continue.',
        'فوری آغاز ابھی دستیاب نہیں — جاری رکھنے کے لیے اکاؤنٹ بنائیں۔',
      );

  // ── Store setup ─────────────────────────────────────────────────────────
  String stepOf(int n, int total) =>
      _t('Step $n of $total', 'مرحلہ $n از $total');
  String get setupNameTitle =>
      _t("What's your shop called?", 'آپ کی دکان کا نام کیا ہے؟');
  String get setupNameSub => _t(
        'Customers see this name on your order page.',
        'یہ نام آپ کے آرڈر پیج پر گاہکوں کو نظر آئے گا۔',
      );
  String get shopName => _t('Shop name', 'دکان کا نام');
  String get shopNameHint => _t('e.g. Ali Juice Corner', 'مثلاً علی جوس کارنر');
  String get whatDoYouSell => _t('What do you sell?', 'آپ کیا بیچتے ہیں؟');
  String get setupWhatsappTitle =>
      _t('Where should orders come?', 'آرڈرز کہاں آئیں؟');
  String get setupWhatsappSub => _t(
        'Your WhatsApp number. Orders and customer messages come here.',
        'آپ کا واٹس ایپ نمبر — گاہکوں کے آرڈر اور پیغامات یہاں آئیں گے۔',
      );
  String get whatsappNumber => _t('WhatsApp number', 'واٹس ایپ نمبر');
  String get currency => _t('Currency', 'کرنسی');
  String get setupLinkTitle => _t('Claim your link', 'اپنا لنک بنائیں');
  String get setupLinkSub => _t(
        'Short and easy to remember. You can change it later.',
        'چھوٹا اور یاد رکھنے میں آسان — بعد میں بدل سکتے ہیں۔',
      );
  String get linkName => _t('Link name', 'لنک کا نام');
  String get slugChecking => _t('Checking…', 'چیک ہو رہا ہے…');
  String get slugAvailable => _t('Available', 'دستیاب ہے');
  String get slugYours => _t('This is your link', 'یہ آپ کا لنک ہے');
  String get slugTaken =>
      _t('Already taken — try another', 'یہ لنک لیا جا چکا ہے — کوئی اور آزمائیں');
  String get slugInvalid => _t(
        'Use 3–40 letters, numbers or dashes',
        '3 سے 40 انگریزی حروف، نمبر یا ڈیش استعمال کریں',
      );
  String get slugCheckFailed => _t(
        "Couldn't check — check your internet",
        'چیک نہیں ہو سکا — انٹرنیٹ چیک کریں',
      );
  String get setupItemsTitle => _t('Add what you sell', 'اپنی چیزیں شامل کریں');
  String get setupItemsSub => _t(
        'Start with these and fix the prices — or paste your own list.',
        'ان سے شروع کریں اور قیمتیں درست کریں — یا اپنی لسٹ پیسٹ کریں۔',
      );
  String get pasteMyList => _t('Paste my own list', 'اپنی لسٹ پیسٹ کریں');
  String get useSuggested => _t('Use suggested items', 'تجویز کردہ چیزیں');
  String itemsSelected(int n) =>
      _t('$n items selected', '$n چیزیں منتخب');
  String get skipAddLater =>
      _t("Skip — I'll add later", 'ابھی نہیں — بعد میں شامل کروں گا');
  String get settingUpStore =>
      _t('Setting up your store…', 'آپ کا اسٹور تیار ہو رہا ہے…');
  String get enterShopName => _t('Enter your shop name', 'دکان کا نام درج کریں');
  String get enterValidWhatsapp =>
      _t('Enter a valid WhatsApp number', 'درست واٹس ایپ نمبر درج کریں');
  String get pickAnotherLink => _t('Pick another link', 'کوئی اور لنک منتخب کریں');
  String get storeLiveTitle => _t('Your store is live! 🎉', 'آپ کا اسٹور لائیو ہے! 🎉');
  String get storeLiveBody => _t(
        'Share your link on WhatsApp status and Instagram, or print the QR for your counter.',
        'اپنا لنک واٹس ایپ اسٹیٹس اور انسٹاگرام پر لگائیں، یا کاؤنٹر کے لیے QR پرنٹ کریں۔',
      );
  String get remind => _t('Remind', 'یاد دہانی');
  String get noStoreTitle => _t('No store yet', 'ابھی کوئی اسٹور نہیں');
  String get noStoreBody => _t(
        'Create your store to start taking orders on WhatsApp.',
        'واٹس ایپ پر آرڈر لینے کے لیے اپنا اسٹور بنائیں۔',
      );
  String get signInTitle => _t('Open your store', 'اپنا اسٹور کھولیں');
  String get signInSub => _t(
        'Sign in with the email you used to back up your store.',
        'وہ ای میل استعمال کریں جس سے آپ نے اسٹور بیک اپ کیا تھا۔',
      );
  String get signUpTitle => _t('Create your account', 'اپنا اکاؤنٹ بنائیں');
  String get signUpSub => _t(
        'Your store will be saved to this email.',
        'آپ کا اسٹور اس ای میل کے ساتھ محفوظ رہے گا۔',
      );
  String get serviceUnavailable => _t(
        'The app could not connect to its server. Restart the app and try again.',
        'ایپ سرور سے نہیں جڑ سکی۔ ایپ دوبارہ کھول کر کوشش کریں۔',
      );

  // ── Home ────────────────────────────────────────────────────────────────
  String get live => _t('Live', 'لائیو');
  String get paused => _t('Paused', 'بند');
  String get shareLinkHint => _t(
        'Share this link — orders come to your WhatsApp.',
        'یہ لنک شیئر کریں — آرڈرز آپ کے واٹس ایپ پر آئیں گے۔',
      );
  String linkStats(int opens, int carts, int sent) => isUrdu
      ? '$opens وزٹ · $carts کارٹ · $sent آرڈر بھیجے'
      : '$opens link ${opens == 1 ? 'open' : 'opens'} · '
          '$carts ${carts == 1 ? 'cart' : 'carts'} · $sent sent';
  String get toConfirm => _t('To confirm', 'کنفرم کرنا ہے');
  String get toDispatch => _t('To dispatch', 'بھیجنا ہے');
  String get toCollect => _t('To collect', 'وصول کرنا ہے');
  String get bioPromoTitle => _t('Add your link to your bio', 'لنک اپنی بائیو میں لگائیں');
  String get bioPromoBody => _t(
        'Instagram, Facebook, WhatsApp status — one link with all your items.',
        'انسٹاگرام، فیس بک، واٹس ایپ اسٹیٹس — ایک لنک میں سب چیزیں۔',
      );
  String get shareOnWhatsapp => _t('Share on WhatsApp', 'واٹس ایپ پر شیئر کریں');
  String get viewStore => _t('View your store', 'اپنا اسٹور دیکھیں');
  String get counterOrder => _t('Counter order', 'کاؤنٹر آرڈر');
  String get recentOrders => _t('RECENT ORDERS', 'حالیہ آرڈرز');
  String get noOrdersTitle => _t('No orders yet', 'ابھی کوئی آرڈر نہیں');
  String get noOrdersBody => _t(
        'Share your link — new orders will show up here.',
        'اپنا لنک شیئر کریں — نئے آرڈرز یہاں نظر آئیں گے۔',
      );
  String get backupTitle => _t('Back up your store', 'اپنا اسٹور محفوظ کریں');
  String get backupBody => _t(
        'Add an email so you never lose your store, even on a new phone.',
        'ای میل شامل کریں تاکہ نئے فون پر بھی آپ کا اسٹور محفوظ رہے۔',
      );
  String get backupCta => _t('Back up', 'محفوظ کریں');
  String get addProductsTitle => _t('Add your menu', 'اپنا مینو بنائیں');
  String get addProductsBody => _t(
        'Your page is empty. Add items with prices so customers can order.',
        'آپ کا پیج خالی ہے۔ قیمت کے ساتھ چیزیں شامل کریں تاکہ گاہک آرڈر کر سکیں۔',
      );
  String shareStoreMessage(String store, String link) => _t(
        'Order from $store 👇\n$link\n\nPick what you want and send — it comes straight to my WhatsApp.',
        '$store سے آرڈر کریں 👇\n$link\n\nجو چاہیے منتخب کریں اور بھیج دیں — آرڈر سیدھا میرے واٹس ایپ پر آئے گا۔',
      );
  String get takingOrders => _t('Taking orders', 'آرڈرز وصول کرنا');
  String get liveOnDesc => _t(
        'Your page is open for orders',
        'آپ کا پیج آرڈرز کے لیے کھلا ہے',
      );
  String get liveOffDesc => _t(
        "Paused — customers can look but can't order",
        'بند — گاہک دیکھ سکتے ہیں مگر آرڈر نہیں کر سکتے',
      );
  String get pausedMessageLabel =>
      _t('Message while paused', 'بند ہونے پر پیغام');
  String get pausedMessageHint => _t(
        'e.g. Closed today, back tomorrow at 10 AM',
        'مثلاً آج بند ہے، کل صبح 10 بجے کھلے گا',
      );
  String get storePaused => _t('Store paused', 'اسٹور بند کر دیا گیا');
  String get storeLiveNow => _t('Store is live', 'اسٹور لائیو ہے');
  String newOrderFrom(String name, String amount) =>
      _t('New order from $name · $amount', '$name کا نیا آرڈر · $amount');
  String get view => _t('View', 'دیکھیں');
  String get newOrder => _t('New order', 'نیا آرڈر');

  // ── Orders list ─────────────────────────────────────────────────────────
  String get ordersTitle => _t('Orders', 'آرڈرز');
  String get customersTab => _t('Customers', 'گاہک');
  String get searchOrders =>
      _t('Search name, phone or order #', 'نام، فون یا آرڈر نمبر تلاش کریں');
  String get searchCustomers => _t('Search name or phone', 'نام یا فون تلاش کریں');
  String get filterAll => _t('All', 'سب');
  String get filterUnpaid => _t('Unpaid', 'ادائیگی باقی');
  String dayHeader(int count, String amount, int pending) => isUrdu
      ? '$count آرڈر · $amount${pending > 0 ? ' · $pending زیر التوا' : ''}'
      : '${ordersLabel(count)} · $amount${pending > 0 ? ' · $pending pending' : ''}';
  String get walkIn => _t('Walk-in customer', 'کاؤنٹر گاہک');
  String get delivery => _t('Delivery', 'ڈیلیوری');
  String get pickup => _t('Pickup', 'پک اپ');
  String get request => _t('Request', 'درخواست');
  String get noOrdersMatch => _t('No orders match', 'کوئی آرڈر نہیں ملا');
  String get noCustomersTitle => _t('No customers yet', 'ابھی کوئی گاہک نہیں');
  String get noCustomersBody => _t(
        'Customers appear here after their first order.',
        'پہلے آرڈر کے بعد گاہک یہاں نظر آئیں گے۔',
      );
  String dueAmount(String amount) => _t('$amount due', '$amount باقی');
  String get paymentPending => _t('Payment pending', 'ادائیگی باقی');
  String get paidLabel => _t('Paid', 'ادا شدہ');
  String get partPaid => _t('Part paid', 'جزوی ادا');

  String statusLabel(OrderStatus status, {Fulfillment? fulfillment}) {
    final pickup = fulfillment == Fulfillment.pickup;
    return switch (status) {
      OrderStatus.pending => _t('Pending', 'زیر التوا'),
      OrderStatus.confirmed => _t('Confirmed', 'کنفرم'),
      OrderStatus.dispatched =>
        pickup ? _t('Ready', 'تیار') : _t('Dispatched', 'روانہ'),
      OrderStatus.delivered =>
        pickup ? _t('Picked up', 'لے گئے') : _t('Delivered', 'پہنچ گیا'),
      OrderStatus.cancelled => _t('Cancelled', 'منسوخ'),
    };
  }

  String filterStatusLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => _t('Pending', 'زیر التوا'),
        OrderStatus.confirmed => _t('Confirmed', 'کنفرم'),
        OrderStatus.dispatched => _t('Dispatched', 'روانہ'),
        OrderStatus.delivered => _t('Delivered', 'پہنچ گئے'),
        OrderStatus.cancelled => _t('Cancelled', 'منسوخ'),
      };

  // ── Order detail ────────────────────────────────────────────────────────
  String get orderItems => _t('ORDER ITEMS', 'آرڈر کی چیزیں');
  String get customerRequest => _t("CUSTOMER'S REQUEST", 'گاہک کی درخواست');
  String get subtotal => _t('Subtotal', 'ذیلی کل');
  String get deliveryFeeShort => _t('Delivery', 'ڈیلیوری');
  String get total => _t('Total', 'کل');
  String get free => _t('Free', 'مفت');
  String amountChangedFrom(String old) =>
      _t('Amount changed from $old', 'رقم $old سے تبدیل ہوئی');
  String get payment => _t('PAYMENT', 'ادائیگی');
  String get orderTotal => _t('Order total', 'آرڈر کی کل رقم');
  String get markPaid => _t('Mark paid', 'ادا شدہ کریں');
  String get recordPayment => _t('Record a payment', 'ادائیگی درج کریں');
  String get addPayment => _t('Add payment', 'ادائیگی درج کریں');
  String get paidInFull => _t('Paid in full', 'مکمل ادائیگی ہو گئی');
  String get clearPayments => _t('Clear payments', 'ادائیگیاں ختم کریں');
  String get clearPaymentsConfirm => _t(
        'Remove all payments recorded on this order?',
        'اس آرڈر کی تمام درج ادائیگیاں ختم کریں؟',
      );
  String get methodCash => _t('Cash', 'نقد');
  String get methodOnline => _t('Online / bank', 'آن لائن / بینک');
  String get methodOther => _t('Other', 'دیگر');
  String methodLabel(String key) => switch (key) {
        'online' => methodOnline,
        'other' => methodOther,
        _ => methodCash,
      };
  String get amountReceived => _t('Amount received', 'وصول شدہ رقم');
  String get paidBy => _t('Paid by', 'ادائیگی کا طریقہ');
  String get savePayment => _t('Save payment', 'ادائیگی محفوظ کریں');
  String get enterAmount => _t('Enter an amount', 'رقم درج کریں');
  String get paymentSaved => _t('Payment saved', 'ادائیگی محفوظ ہو گئی');
  String get customer => _t('CUSTOMER', 'گاہک');
  String get call => _t('Call', 'کال');
  String get whatsapp => _t('WhatsApp', 'واٹس ایپ');
  String get address => _t('Address', 'پتہ');
  String get noPhone => _t('No phone number', 'فون نمبر نہیں');
  String get details => _t('DETAILS', 'تفصیلات');
  String get noteLabel => _t('Note', 'نوٹ');
  String get notifyBuyer =>
      _t('Notify buyer on WhatsApp', 'گاہک کو واٹس ایپ پر بتائیں');
  String get confirmOrder => _t('Confirm order', 'آرڈر کنفرم کریں');
  String get markDispatched => _t('Mark dispatched', 'روانہ کر دیا');
  String get markReady => _t('Mark ready for pickup', 'پک اپ کے لیے تیار');
  String get markDelivered => _t('Mark delivered', 'پہنچا دیا');
  String get markPickedUp => _t('Mark picked up', 'گاہک لے گیا');
  String get reopenOrder => _t('Reopen order', 'آرڈر دوبارہ کھولیں');
  String get cancelOrder => _t('Cancel order', 'آرڈر منسوخ کریں');
  String get cancelOrderConfirm => _t('Cancel this order?', 'یہ آرڈر منسوخ کریں؟');
  String get cancelOrderBody => _t(
        'It moves to Cancelled. You can reopen it later.',
        'یہ منسوخ شدہ میں چلا جائے گا۔ بعد میں دوبارہ کھول سکتے ہیں۔',
      );
  String get keepOrder => _t('Keep order', 'آرڈر رکھیں');
  String get orderComplete => _t('Order complete', 'آرڈر مکمل');
  String get shareOrder => _t('Share order details', 'آرڈر کی تفصیل شیئر کریں');
  String get sendReminder => _t('Send payment reminder', 'ادائیگی کی یاد دہانی بھیجیں');
  String get deleteOrder => _t('Delete order', 'آرڈر حذف کریں');
  String get deleteOrderConfirm =>
      _t('Delete this order permanently?', 'یہ آرڈر ہمیشہ کے لیے حذف کریں؟');
  String get deleteOrderBody => _t(
        "This can't be undone. Use Cancel if you only want to stop it.",
        'یہ واپس نہیں ہو سکتا۔ صرف روکنا ہو تو منسوخ کریں۔',
      );

  // ── Blocking fake orders ────────────────────────────────────────────────
  String get blockCustomer => _t('Block customer', 'گاہک کو بلاک کریں');
  String get unblockCustomer => _t('Unblock customer', 'گاہک کو ان بلاک کریں');
  String blockCustomerTitle(String name) =>
      _t('Block $name?', '$name کو بلاک کریں؟');
  String get blockCustomerBody => _t(
        "New orders from this number won't reach you. You can unblock any time in Settings → Blocked customers.",
        'اس نمبر سے نئے آرڈر آپ تک نہیں آئیں گے۔ سیٹنگز ← بلاک گاہک میں کبھی بھی ان بلاک کر سکتے ہیں۔',
      );
  String get block => _t('Block', 'بلاک کریں');
  String get unblock => _t('Unblock', 'ان بلاک');
  String get customerBlocked => _t('Customer blocked', 'گاہک بلاک ہو گیا');
  String get customerUnblocked =>
      _t('Customer unblocked', 'گاہک ان بلاک ہو گیا');
  String get blockedCustomers => _t('Blocked customers', 'بلاک گاہک');
  String get blockedCustomersSub => _t(
        'Their orders from your link are refused',
        'آپ کے لنک سے ان کے آرڈر نہیں آتے',
      );
  String blockedCount(int n) =>
      _t(n == 1 ? '1 blocked' : '$n blocked', '$n بلاک');
  String get noBlockedTitle => _t('No one is blocked', 'کوئی بلاک نہیں');
  String get noBlockedBody => _t(
        'If someone sends fake orders, open the order, tap ⋮ and choose Block customer.',
        'اگر کوئی جعلی آرڈر بھیجے تو آرڈر کھولیں، ⋮ دبائیں اور "گاہک کو بلاک کریں" چنیں۔',
      );
  String blockedOn(String date) => _t('Blocked on $date', 'بلاک: $date');
  String get blockedBadge => _t('Blocked', 'بلاک');
  String get viaLink => _t('Via link', 'لنک سے');
  String get viaCounter => _t('Counter', 'کاؤنٹر');
  String get orderDeleted => _t('This order was deleted.', 'یہ آرڈر حذف ہو چکا ہے۔');
  String get stepPending => _t('Pending', 'زیر التوا');
  String get stepConfirmed => _t('Confirmed', 'کنفرم');
  String stepDispatched(bool pickup) =>
      pickup ? _t('Ready', 'تیار') : _t('Dispatched', 'روانہ');
  String stepDelivered(bool pickup) =>
      pickup ? _t('Picked up', 'لے گئے') : _t('Delivered', 'پہنچ گیا');
  String orderNumber(String number) => '#$number';
  String get setPrice => _t('Set price', 'قیمت لگائیں');

  // ── WhatsApp messages to the customer ──────────────────────────────────
  String _hi(String name) {
    final n = name.trim();
    if (isUrdu) return n.isEmpty ? 'السلام علیکم' : 'السلام علیکم $n';
    return n.isEmpty ? 'Hi' : 'Hi $n';
  }

  String msgConfirmed({
    required String name,
    required String store,
    required String number,
    required String total,
    String? changedFrom,
  }) {
    final changed = changedFrom == null
        ? ''
        : _t(
            '\n(The amount was updated from $changedFrom to $total.)',
            '\n(رقم $changedFrom سے بدل کر $total کر دی گئی ہے۔)',
          );
    return _t(
      '${_hi(name)}, your order #$number at $store is confirmed ✅\nTotal: $total$changed\nThank you!',
      '${_hi(name)}، $store پر آپ کا آرڈر #$number کنفرم ہو گیا ہے ✅\nکل رقم: $total$changed\nشکریہ!',
    );
  }

  String msgDispatched({required String name, required String store, required String number}) => _t(
        '${_hi(name)}, your order #$number from $store is on the way 🛵',
        '${_hi(name)}، $store سے آپ کا آرڈر #$number روانہ کر دیا گیا ہے 🛵',
      );

  String msgReady({
    required String name,
    required String store,
    required String number,
    String pickupAddress = '',
  }) {
    final where = pickupAddress.trim().isEmpty
        ? ''
        : _t('\nPickup: ${pickupAddress.trim()}', '\nپک اپ: ${pickupAddress.trim()}');
    return _t(
      '${_hi(name)}, your order #$number at $store is ready for pickup 🛍️$where',
      '${_hi(name)}، $store پر آپ کا آرڈر #$number پک اپ کے لیے تیار ہے 🛍️$where',
    );
  }

  String msgDelivered({required String name, required String store, required String number}) => _t(
        '${_hi(name)}, your order #$number has been delivered. Thank you for ordering from $store! 🙏',
        '${_hi(name)}، آپ کا آرڈر #$number پہنچا دیا گیا ہے۔ $store سے آرڈر کرنے کا شکریہ! 🙏',
      );

  String msgCancelled({required String name, required String store, required String number}) => _t(
        '${_hi(name)}, sorry — your order #$number at $store has been cancelled.',
        '${_hi(name)}، معذرت — $store پر آپ کا آرڈر #$number منسوخ کر دیا گیا ہے۔',
      );

  String msgReminder({
    required String name,
    required String store,
    required String number,
    required String amount,
  }) =>
      _t(
        '${_hi(name)}, a gentle reminder from $store: $amount is still due for order #$number. Thank you!',
        '${_hi(name)}، $store کی طرف سے یاد دہانی: آرڈر #$number کے $amount ابھی باقی ہیں۔ شکریہ!',
      );

  String msgCustomerReminder({
    required String name,
    required String store,
    required String amount,
  }) =>
      _t(
        '${_hi(name)}, a gentle reminder from $store: $amount is still due on your orders. Thank you!',
        '${_hi(name)}، $store کی طرف سے یاد دہانی: آپ کے آرڈرز کے $amount ابھی باقی ہیں۔ شکریہ!',
      );

  String msgPaid({
    required String name,
    required String number,
    required String amount,
  }) =>
      _t(
        'Received $amount for order #$number. Thank you${name.trim().isEmpty ? '' : ', ${name.trim()}'}! 🙏',
        'آرڈر #$number کے $amount وصول ہو گئے۔ شکریہ${name.trim().isEmpty ? '' : ' ${name.trim()}'}! 🙏',
      );

  String msgHello({required String name, required String store}) => _t(
        '${_hi(name)}, this is $store.',
        '${_hi(name)}، $store سے بات کر رہے ہیں۔',
      );

  // ── Order editor (counter order / edit items) ──────────────────────────
  String get counterOrderTitle => _t('Counter order', 'کاؤنٹر آرڈر');
  String get editOrderTitle => _t('Edit order', 'آرڈر میں ترمیم');
  String get searchProducts => _t('Search menu', 'مینو میں تلاش کریں');
  String get customItem => _t('Custom item', 'اپنی مرضی کی چیز');
  String get itemName => _t('Item name', 'چیز کا نام');
  String get price => _t('Price', 'قیمت');
  String get quantity => _t('Quantity', 'تعداد');
  String get customerOptional => _t('CUSTOMER · OPTIONAL', 'گاہک · اختیاری');
  String get customerName => _t('Name', 'نام');
  String get customerPhone => _t('Phone', 'فون');
  String get howTheyGetItCaps => _t('HOW THEY GET IT', 'آرڈر کیسے ملے گا');
  String get customerHasPaid => _t('Customer has paid', 'گاہک نے ادائیگی کر دی');
  String get saveOrder => _t('Save order', 'آرڈر محفوظ کریں');
  String get saveChanges => _t('Save changes', 'تبدیلیاں محفوظ کریں');
  String get addAtLeastOne =>
      _t('Add at least one item', 'کم از کم ایک چیز شامل کریں');
  String get outOfStock => _t('Out of stock', 'اسٹاک ختم');
  String get chooseOption => _t('Choose an option', 'آپشن منتخب کریں');
  String get orderSaved => _t('Order saved', 'آرڈر محفوظ ہو گیا');
  String get noProductsForOrder => _t(
        'Your menu is empty. Add a custom item, or add menu items first.',
        'ابھی مینو خالی ہے۔ اپنی مرضی کی چیز شامل کریں یا پہلے مینو میں آئٹم شامل کریں۔',
      );
  String get itemsInOrder => _t('IN THIS ORDER', 'اس آرڈر میں');
  String get handedOver =>
      _t('Customer already has the items', 'گاہک کو چیزیں مل گئیں');
  String get handedOverSub =>
      _t('The order is marked complete', 'آرڈر مکمل شمار ہوگا');
  String get orderNoteHint => _t(
        'Anything to remember about this order',
        'اس آرڈر کے بارے میں کوئی بات',
      );
  String get orderUpdated => _t('Order updated', 'آرڈر اپڈیٹ ہو گیا');
  String get orderCancelled =>
      _t('This order was cancelled', 'یہ آرڈر منسوخ ہو چکا ہے');
  String get addCustomItem => _t('Add custom item', 'اپنی چیز شامل کریں');

  // ── Customers ───────────────────────────────────────────────────────────
  String get ordersCaps => _t('ORDERS', 'آرڈرز');
  String get totalLabel => _t('Total', 'کل');
  String get dueLabel => _t('Due', 'باقی');
  String get ordersCountLabel => _t('Orders', 'آرڈرز');

  // ── Products ────────────────────────────────────────────────────────────
  String get productsTitle => _t('Menu', 'مینو');
  String get editPrices => _t('Edit prices', 'قیمتیں بدلیں');
  String get changeAllPrices => _t('Change all prices', 'سب قیمتیں بدلیں');
  String get dragToReorder => _t('Drag to reorder', 'ترتیب بدلنے کے لیے کھینچیں');
  String get inStock => _t('In stock', 'اسٹاک میں');
  String get addProduct => _t('Add item', 'آئٹم شامل کریں');
  String get pasteList => _t('Paste a list', 'لسٹ پیسٹ کریں');
  String get duplicate => _t('Duplicate', 'کاپی بنائیں');
  String get markOutOfStock => _t('Mark out of stock', 'اسٹاک ختم کریں');
  String get markInStock => _t('Mark in stock', 'اسٹاک میں کریں');
  String deleteProductConfirm(String name) =>
      _t('Delete $name?', '$name حذف کریں؟');
  String get deleteProductBody => _t(
        'It will be removed from your order page.',
        'یہ آپ کے آرڈر پیج سے ہٹ جائے گی۔',
      );
  String fromPrice(String price) => _t('from $price', '$price سے');
  String get savePrices => _t('Save prices', 'قیمتیں محفوظ کریں');
  String get pricesSaved => _t('Prices saved', 'قیمتیں محفوظ ہو گئیں');
  String get noProductsTitle => _t('Your menu is empty', 'ابھی مینو خالی ہے');
  String get noProductsBody => _t(
        'Add items one by one, or paste your whole menu at once.',
        'ایک ایک کر کے شامل کریں یا پورا مینیو ایک ساتھ پیسٹ کریں۔',
      );
  String get sharePriceList => _t('Share price list', 'قیمتوں کی لسٹ شیئر کریں');
  String priceListHeader(String store) =>
      _t('$store — price list', '$store — قیمتوں کی لسٹ');
  String orderAt(String link) =>
      _t('Order here: $link', 'یہاں آرڈر کریں: $link');
  String priceFor(String name) => _t('Price for $name', '$name کی قیمت');
  String get increase => _t('Increase', 'بڑھائیں');
  String get decrease => _t('Decrease', 'کم کریں');
  String get byPercent => _t('By %', 'فیصد سے');
  String get byAmount => _t('By amount', 'رقم سے');
  String get howMuch => _t('How much?', 'کتنا؟');
  String get roundTo => _t('Round to nearest', 'قریب ترین تک گول کریں');
  String get noRounding => _t('None', 'کوئی نہیں');
  String get preview => _t('Preview', 'پیش منظر');
  String updatePricesN(int n) =>
      _t('Update $n prices', '$n قیمتیں اپڈیٹ کریں');
  String get productDuplicated => _t('Copy added', 'کاپی بن گئی');
  String copyOf(String name) => _t('$name (copy)', '$name (کاپی)');
  String get productDeleted => _t('Item deleted', 'آئٹم حذف ہو گیا');
  String get noProductsMatch => _t('No items match', 'کوئی آئٹم نہیں ملا');

  // ── Product form ────────────────────────────────────────────────────────
  String get addProductTitle => _t('Add menu item', 'مینو آئٹم شامل کریں');
  String get editProductTitle => _t('Edit menu item', 'مینو آئٹم میں ترمیم');
  String get productName => _t('Item name', 'آئٹم کا نام');
  String get productNameHint => _t('e.g. Dahi Bhalla', 'مثلاً دہی بھلے');
  String get description => _t('Description', 'تفصیل');
  String get descriptionHint => _t(
        'Size, ingredients — anything useful',
        'سائز، اجزاء — کوئی بھی مفید بات',
      );
  String get category => _t('Category', 'کیٹیگری');
  String get categoryHint => _t('e.g. Chaat', 'مثلاً چاٹ');
  String get optionsTitle => _t('Sizes & prices', 'سائز اور قیمتیں');
  String get optionsHint => _t(
        'Half / Full, Small / Large — each size with its own price.',
        'ہاف / فل، چھوٹا / بڑا — ہر سائز کی اپنی قیمت۔',
      );
  String get addOption => _t('Add size', 'سائز شامل کریں');
  String get optionName => _t('Option', 'آپشن');
  String get optionNameHint => _t('e.g. Half', 'مثلاً ہاف');
  String get inStockSub =>
      _t('Customers can order this item', 'گاہک یہ چیز آرڈر کر سکتے ہیں');
  String get productNameRequired =>
      _t('Enter the item name', 'آئٹم کا نام درج کریں');
  String get priceRequired => _t('Enter a price', 'قیمت درج کریں');
  String get optionsIncomplete => _t(
        'Each size needs a name and a price',
        'ہر سائز کا نام اور قیمت درج کریں',
      );
  String get productSaved => _t('Item saved', 'آئٹم محفوظ ہو گیا');

  // ── Menu sizes ──────────────────────────────────────────────────────────
  String get quickSizes => _t('Quick sizes', 'فوری سائز');
  String get fromYourMenu => _t('From your menu', 'آپ کے مینو سے');

  // ── Voice entry ─────────────────────────────────────────────────────────
  String get voiceEntry => _t('Voice entry', 'بول کر لکھیں');
  String get voiceTitle => _t('Speak a sale', 'بول کر سیل لکھیں');
  String get voiceBarTitle =>
      _t('Speak to write in khata', 'بول کر کھاتے میں لکھیں');
  String voiceSay(String example) => _t('Say “$example”', 'بولیں: “$example”');
  String get voiceTapToSpeak =>
      _t('Tap the mic and speak', 'مائیک دبائیں اور بولیں');
  String get voiceListening => _t('Listening…', 'سن رہا ہوں…');
  String get voiceTypeHint =>
      _t('What you said shows here — you can type too',
          'آپ کی بات یہاں لکھی آئے گی — آپ خود بھی لکھ سکتے ہیں');
  String get voiceLangRoman => _t('Roman / English', 'رومن / انگلش');
  String get voiceLangUrdu => _t('Urdu', 'اردو');
  String get voiceNotAvailable => _t(
        'Voice is not available on this phone. You can type instead.',
        'اس فون پر آواز سے لکھنا دستیاب نہیں۔ آپ لکھ کر بھی کر سکتے ہیں۔',
      );
  String get voiceMicDenied => _t(
        'Allow the microphone to speak entries.',
        'بول کر لکھنے کے لیے مائیک کی اجازت دیں۔',
      );
  String get voiceHeardNothing => _t(
        'Didn’t catch that — tap the mic and try again.',
        'آواز سمجھ نہیں آئی — مائیک دبا کر دوبارہ بولیں۔',
      );
  String get voiceNothingFound => _t(
        'No menu item found in that. Say the item name, e.g. “2 samosa”.',
        'اس میں مینو کا کوئی آئٹم نہیں ملا۔ آئٹم کا نام بولیں، جیسے “2 سموسے”۔',
      );
  String voiceNotOnMenu(String words) =>
      _t('Not on your menu: “$words”', '“$words” مینو میں نہیں ملا');
  String get voicePickItem => _t('Pick item', 'آئٹم چنیں');
  String get voiceChooseSize => _t('Choose a size', 'سائز چنیں');
  String get voiceCustomer => _t('Customer', 'گاہک');
  String get voiceNoName => _t('No name · cash sale', 'بغیر نام · نقد سیل');
  String get voiceNewPerson => _t('New', 'نیا');
  String get voiceChange => _t('Change', 'بدلیں');
  String voiceSaveOn(String amount, String name) =>
      _t('Save $amount on $name', '$amount $name کے نام لکھیں');
  String voiceSaveSale(String amount) =>
      _t('Save sale · $amount', 'سیل لکھیں · $amount');
  String get voiceSaved => _t('Written in khata', 'کھاتے میں لکھ دیا');
  String get voiceMenuEmptyTitle =>
      _t('Add your menu first', 'پہلے اپنا مینو بنائیں');
  String get voiceMenuEmptyBody => _t(
        'Voice entry takes item prices from your menu.',
        'بول کر لکھتے وقت قیمتیں آپ کے مینو سے لی جاتی ہیں۔',
      );
  String get voiceOpenMenu => _t('Open menu', 'مینو کھولیں');
  String get voiceNeedsNet => _t(
        'Voice needs the internet. Check it and try again.',
        'آواز سے لکھنے کے لیے انٹرنیٹ چاہیے۔ چیک کر کے دوبارہ کوشش کریں۔',
      );
  String get voiceLangMissing => _t(
        'This language is not set up for voice on your phone. Try Roman / English.',
        'آپ کے فون پر اس زبان میں آواز دستیاب نہیں۔ رومن / انگلش آزمائیں۔',
      );
  String get choosePerson => _t('Choose person', 'شخص چنیں');
  String get noPersonOption => _t('No name (cash sale)', 'بغیر نام (نقد سیل)');
  String addNewPersonNamed(String name) =>
      _t('Add “$name” as new', '“$name” کو نیا شامل کریں');
  String get voiceHowTo => _t(
        'Item, size, how many — and the name if it goes on someone’s khata.',
        'آئٹم، سائز، کتنے — اور اگر کسی کے کھاتے میں ہے تو اس کا نام۔',
      );

  // ── Paste list ──────────────────────────────────────────────────────────
  String get pasteListTitle => _t('Paste a list', 'لسٹ پیسٹ کریں');
  String get pasteListHint => _t(
        'One item per line, with its price:\nMango Shake - 250\nZinger Burger 450\nFries: 150',
        'ہر لائن میں ایک چیز اور اس کی قیمت:\nMango Shake - 250\nZinger Burger 450\nFries: 150',
      );
  String itemsFound(int n) => _t('$n items found', '$n چیزیں ملیں');
  String get noPriceYet => _t('No price — add later', 'قیمت نہیں — بعد میں لگائیں');
  String addNProducts(int n) =>
      _t('Add $n items', '$n آئٹم شامل کریں');
  String get pasteFromClipboard =>
      _t('Paste from clipboard', 'کلپ بورڈ سے پیسٹ کریں');
  String productsAdded(int n) =>
      _t('$n items added', '$n آئٹم شامل ہو گئے');

  // ── Settings ────────────────────────────────────────────────────────────
  String get settingsTitle => _t('Settings', 'سیٹنگز');
  String get sectionStore => _t('YOUR STORE', 'آپ کا اسٹور');
  String get sectionData => _t('ORDERS & DATA', 'آرڈرز اور ڈیٹا');
  String get sectionApp => _t('APP', 'ایپ');
  String get sectionAccount => _t('ACCOUNT', 'اکاؤنٹ');
  String get editStore => _t('Edit store', 'اسٹور میں ترمیم');
  String get storeDetails => _t('Store details', 'اسٹور کی تفصیل');
  String get storeDetailsSub =>
      _t('Name, WhatsApp number, about', 'نام، واٹس ایپ نمبر، تعارف');
  String get yourLink => _t('Your link', 'آپ کا لنک');
  String get orderSettings => _t('Order settings', 'آرڈر سیٹنگز');
  String get orderSettingsSub => _t(
        'Delivery, pickup, charges & questions',
        'ڈیلیوری، پک اپ، چارجز اور سوالات',
      );
  String get shareKit => _t('Share kit & QR poster', 'شیئر کٹ اور QR پوسٹر');
  String get shareKitSub =>
      _t('Print or post your link', 'اپنا لنک پرنٹ یا پوسٹ کریں');
  String get khata => _t('Full khata — reports & budget', 'مکمل کھاتہ — رپورٹس اور بجٹ');
  String get khataSub => _t(
        'Shop sale, purchase & expense book',
        'دکان کی فروخت، خریداری اور خرچ کا حساب',
      );
  String get language => _t('Language', 'زبان');
  String get privacyPolicy => _t('Privacy policy', 'پرائیویسی پالیسی');
  String get about => _t('About', 'ہمارے بارے میں');
  String get backupStore => _t('Back up store', 'اسٹور بیک اپ کریں');
  String backedUpAs(String email) => _t('Backed up · $email', 'محفوظ · $email');
  String get notBackedUp => _t('Not backed up yet', 'ابھی بیک اپ نہیں ہوا');
  String get logout => _t('Log out', 'لاگ آؤٹ');
  String get deleteAccount => _t('Delete account', 'اکاؤنٹ حذف کریں');
  String get logoutAnonTitle => _t('Back up before logging out', 'لاگ آؤٹ سے پہلے بیک اپ کریں');
  String get logoutAnonBody => _t(
        "Your store isn't backed up. If you log out now you will lose it. Back it up first.",
        'آپ کا اسٹور بیک اپ نہیں ہے۔ ابھی لاگ آؤٹ کیا تو اسٹور ضائع ہو جائے گا۔ پہلے بیک اپ کریں۔',
      );
  String get logoutAnyway => _t('Log out anyway', 'پھر بھی لاگ آؤٹ کریں');
  String logoutConfirm(String email) => _t(
        'Log out of this phone? Sign in with $email to open your store again.',
        'اس فون سے لاگ آؤٹ کریں؟ اسٹور دوبارہ کھولنے کے لیے $email سے سائن ان کریں۔',
      );
  String get deleteAccountTitle =>
      _t('Delete your account and store?', 'اکاؤنٹ اور اسٹور حذف کریں؟');
  String get deleteAccountBody => _t(
        'Your order page goes offline, your link is freed and you are signed out. This cannot be undone.',
        'آپ کا آرڈر پیج بند ہو جائے گا، لنک ختم ہو جائے گا اور آپ سائن آؤٹ ہو جائیں گے۔ یہ واپس نہیں ہو سکتا۔',
      );
  String get accountDeleted => _t('Account deleted', 'اکاؤنٹ حذف ہو گیا');
  String get storeCard => _t('Your store', 'آپ کا اسٹور');
  String get takingOrdersSub => _t(
        'Turn off to pause new orders',
        'نئے آرڈر روکنے کے لیے بند کریں',
      );

  // ── Backup & export ─────────────────────────────────────────────────────
  String get backupExport => _t('Backup & export', 'بیک اپ اور ایکسپورٹ');
  String get backupExportSub => _t(
        'Khata, orders & menu as Excel or PDF',
        'کھاتہ، آرڈرز اور مینو — Excel یا PDF',
      );
  String get cloudSavedTitle => _t('Saved online', 'آن لائن محفوظ ہے');
  String cloudSavedBody(String email) => _t(
        'Your khata and orders are saved online with $email. Log in on any phone to get them back.',
        'آپ کا کھاتہ اور آرڈرز $email کے ساتھ آن لائن محفوظ ہیں۔ کسی بھی فون پر لاگ اِن کر کے واپس لے سکتے ہیں۔',
      );
  String get cloudGuestTitle => _t('Only on this phone', 'صرف اس فون پر');
  String get cloudGuestBody => _t(
        "Your data is saved online, but on a guest account. If this phone is lost or the app is removed, it can't be opened again. Link an email to keep it safe.",
        'آپ کا ڈیٹا آن لائن محفوظ ہے، لیکن مہمان اکاؤنٹ پر۔ فون گم ہو جائے یا ایپ ہٹ جائے تو دوبارہ نہیں کھلے گا۔ محفوظ رکھنے کے لیے ای میل جوڑیں۔',
      );
  String get exportPeriod => _t('Period', 'مدت');
  String get periodThisMonth => _t('This month', 'اس مہینے');
  String get periodLastMonth => _t('Last month', 'پچھلے مہینے');
  String get periodThisYear => _t('This year', 'اس سال');
  String get periodAll => _t('All time', 'شروع سے اب تک');
  String exportCounts(int entries, int orders, int people) => _t(
        '$entries khata entries · $orders orders · $people people',
        '$entries کھاتہ اندراج · $orders آرڈرز · $people لوگ',
      );
  String get excelBackup => _t('Excel file', 'Excel فائل');
  String get excelBackupSub => _t(
        'Every detail in sheets: khata, lena-dena, orders, menu',
        'ہر تفصیل شیٹس میں: کھاتہ، لینا دینا، آرڈرز، مینو',
      );
  String get pdfReport => _t('PDF report', 'PDF رپورٹ');
  String get pdfReportSub => _t(
        'Totals, balances, entries and orders — to print or share',
        'ٹوٹل، بقایا، اندراج اور آرڈرز — پرنٹ یا شیئر کے لیے',
      );
  String get exportLoading => _t('Getting your data…', 'ڈیٹا لایا جا رہا ہے…');
  String get exportFailed =>
      _t("Couldn't make the file. Try again.", 'فائل نہیں بن سکی۔ دوبارہ کوشش کریں۔');
  String get exportNote => _t(
        'Files are made on this phone. Share them to WhatsApp, Drive or email to keep a copy.',
        'فائل اسی فون پر بنتی ہے۔ کاپی رکھنے کے لیے واٹس ایپ، ڈرائیو یا ای میل پر شیئر کریں۔',
      );

  // ── Store details ───────────────────────────────────────────────────────
  String get storeName => _t('Store name', 'اسٹور کا نام');
  String get aboutStore => _t('About your store', 'اسٹور کا تعارف');
  String get aboutStoreHint => _t(
        'e.g. Fresh juices & shakes since 2010',
        'مثلاً 2010 سے تازہ جوس اور شیک',
      );
  String get businessType => _t('Type of business', 'کاروبار کی قسم');
  String get storeSaved => _t('Store details saved', 'اسٹور کی تفصیل محفوظ ہو گئی');

  // ── Link ────────────────────────────────────────────────────────────────
  String get changeLinkNote => _t(
        'Changing your link stops the old one working. Update it wherever you shared it.',
        'لنک بدلنے سے پرانا لنک کام نہیں کرے گا۔ جہاں شیئر کیا تھا وہاں اپڈیٹ کریں۔',
      );
  String get saveLink => _t('Save link', 'لنک محفوظ کریں');
  String get linkSaved => _t('Link updated', 'لنک اپڈیٹ ہو گیا');

  // ── Order settings ──────────────────────────────────────────────────────
  String get previewPage => _t('Preview page', 'پیج دیکھیں');
  String storeOrders(String store) => _t('$store · Orders', '$store · آرڈرز');
  String get howCustomersSend => _t('How customers send', 'گاہک آرڈر کیسے بھیجیں');
  String get howCustomersSendSub => _t(
        'With a cart and totals, or as a single request.',
        'کارٹ اور کل رقم کے ساتھ، یا ایک پیغام کی صورت میں۔',
      );
  String get orderWithCart => _t('Order with a cart', 'کارٹ سے آرڈر');
  String get sendARequest => _t('Send a request', 'درخواست بھیجیں');
  String get cartDesc => _t(
        'Customers add items to a cart and place an order with quantities and totals.',
        'گاہک چیزیں کارٹ میں ڈال کر مقدار اور کل رقم کے ساتھ آرڈر کرتے ہیں۔',
      );
  String get requestDesc => _t(
        'Customers write what they need in one message — you reply with the price.',
        'گاہک ایک پیغام میں لکھتے ہیں کہ کیا چاہیے — آپ قیمت بتاتے ہیں۔',
      );
  String previewSample(String amount) =>
      _t('Preview · sample $amount order', 'پیش منظر · $amount کا نمونہ آرڈر');
  String get howTheyGetIt => _t('How they get it', 'آرڈر کیسے ملے گا');
  String get howTheyGetItSub => _t(
        'Delivery, pickup, fees and minimum order.',
        'ڈیلیوری، پک اپ، فیس اور کم از کم آرڈر۔',
      );
  String get deliverySub => _t('You deliver to the customer', 'آپ گاہک تک پہنچاتے ہیں');
  String get pickupSub => _t('Customer collects from you', 'گاہک خود آ کر لے جاتا ہے');
  String get deliveryArea => _t('DELIVERY AREA · OPTIONAL', 'ڈیلیوری ایریا · اختیاری');
  String get deliveryAreaHint => _t(
        'e.g. within 5 km of the shop — shown to customers',
        'مثلاً دکان سے 5 کلومیٹر تک — گاہکوں کو نظر آئے گا',
      );
  String get deliveryFee => _t('Delivery fee', 'ڈیلیوری فیس');
  String get freeAbove => _t('Free delivery above', 'اس سے اوپر مفت ڈیلیوری');
  String get zeroNever => _t('0 = never free', '0 = کبھی مفت نہیں');
  String get pickupAddress =>
      _t('Pickup address / directions', 'پک اپ کا پتہ / رہنمائی');
  String get minOrder => _t('Minimum order', 'کم از کم آرڈر');
  String get zeroNoMin => _t('0 = no minimum', '0 = کوئی حد نہیں');
  String get keepOneMode =>
      _t('Keep delivery or pickup on', 'ڈیلیوری یا پک اپ میں سے ایک آن رکھیں');
  String get whatYouAsk => _t('What you ask', 'آپ کیا پوچھتے ہیں');
  String get whatYouAskSub => _t(
        'Name and phone are always asked. Add your own questions.',
        'نام اور فون ہمیشہ پوچھے جاتے ہیں۔ اپنے سوالات بھی شامل کریں۔',
      );
  String get askPhone => _t('Phone number', 'فون نمبر');
  String get askAddress => _t('Address (for delivery)', 'پتہ (ڈیلیوری کے لیے)');
  String get always => _t('Always', 'ہمیشہ');
  String get askNoteTitle => _t('Order note', 'آرڈر نوٹ');
  String get askNoteSub => _t('Let customers add a note', 'گاہک نوٹ لکھ سکیں');
  String get question => _t('Question', 'سوال');
  String get questionHint =>
      _t('e.g. Preferred delivery time', 'مثلاً ڈیلیوری کا پسندیدہ وقت');
  String get requiredLabel => _t('Required', 'لازمی');
  String get addQuestion => _t('Add a question', 'سوال شامل کریں');
  String get pageLanguage => _t('Page language', 'پیج کی زبان');
  String get pageLanguageSub => _t(
        'Language customers see on your order page',
        'آرڈر پیج پر گاہکوں کو نظر آنے والی زبان',
      );
  String get whenPaused => _t('When orders are paused', 'جب آرڈرز بند ہوں');
  String get saveSettings => _t('Save settings', 'سیٹنگز محفوظ کریں');
  String get settingsSaved =>
      _t('Order settings saved', 'آرڈر سیٹنگز محفوظ ہو گئیں');

  // ── Share kit ───────────────────────────────────────────────────────────
  String get shareKitTitle => _t('Share kit', 'شیئر کٹ');
  String get shareKitIntro => _t(
        'Ready-made artwork with your link — print it or post it as it is.',
        'آپ کے لنک کے ساتھ تیار ڈیزائن — پرنٹ کریں یا ایسے ہی پوسٹ کریں۔',
      );
  String get counterPoster => _t('COUNTER POSTER', 'کاؤنٹر پوسٹر');
  String get scanToOrder => _t('SCAN TO ORDER', 'آرڈر کے لیے اسکین کریں');
  String get posterLine => _t(
        'Orders come straight to our WhatsApp',
        'آرڈر سیدھا ہمارے واٹس ایپ پر آتا ہے',
      );
  String get madeWith => _t('Made with Pocket Karcha', 'پاکٹ خرچہ کے ساتھ بنایا گیا');
  String get savePoster => _t('Save / Share poster', 'پوسٹر محفوظ / شیئر کریں');
  String get statusCard => _t('WHATSAPP STATUS', 'واٹس ایپ اسٹیٹس');
  String get statusHeadline =>
      _t('Order online from us!', 'اب ہم سے آن لائن آرڈر کریں!');
  String get statusSub => _t(
        "Tap the link, pick your items and send — it's that easy.",
        'لنک کھولیں، چیزیں منتخب کریں اور بھیج دیں — بس اتنا آسان۔',
      );
  String get shareStatus => _t('Share status image', 'اسٹیٹس تصویر شیئر کریں');
  String get bioCard => _t('INSTAGRAM / FACEBOOK BIO', 'انسٹاگرام / فیس بک بائیو');
  String bioText(String link) =>
      _t('🛒 Order online 👉 $link', '🛒 آن لائن آرڈر کریں 👉 $link');
  String get copyBio => _t('Copy bio text', 'بائیو ٹیکسٹ کاپی کریں');

  // ── Backup ──────────────────────────────────────────────────────────────
  String get backupScreenTitle => _t('Back up your store', 'اسٹور بیک اپ کریں');
  String get backupIntro => _t(
        "Your store is saved to this phone's account. Add an email and password so you can open it on any phone.",
        'آپ کا اسٹور اس فون کے اکاؤنٹ میں محفوظ ہے۔ ای میل اور پاس ورڈ شامل کریں تاکہ کسی بھی فون پر کھول سکیں۔',
      );
  String get email => _t('Email', 'ای میل');
  String get password => _t('Password', 'پاس ورڈ');
  String get confirmPassword => _t('Confirm password', 'پاس ورڈ دوبارہ');
  String get backupNow => _t('Back up my store', 'میرا اسٹور بیک اپ کریں');
  String get backedUpTitle => _t('Your store is backed up', 'آپ کا اسٹور بیک اپ ہو گیا');
  String backedUpBody(String email) => _t(
        'Sign in with $email on any phone to open it.',
        'کسی بھی فون پر $email سے سائن ان کر کے اسٹور کھولیں۔',
      );
  String get emailInUse => _t(
        'This email already has an account. Use another email.',
        'اس ای میل پر پہلے سے اکاؤنٹ ہے۔ کوئی اور ای میل استعمال کریں۔',
      );
  String get invalidEmail => _t('Enter a valid email', 'درست ای میل درج کریں');
  String get passwordShort => _t('At least 6 characters', 'کم از کم 6 حروف');
  String get passwordsMismatch => _t('Passwords do not match', 'پاس ورڈ میل نہیں کھاتے');
  String get signInAgain => _t(
        'Please sign in again and retry.',
        'دوبارہ سائن ان کر کے کوشش کریں۔',
      );

  // ── Khata tab: shop, personal, lena-dena ────────────────────────────────
  String get khataTitle => _t('Khata', 'کھاتہ');
  String get segShop => _t('Shop', 'دکان');
  String get segPersonal => _t('Personal', 'ذاتی');
  String get segPeople => _t('Lena-dena', 'لین دین');
  String get calculator => _t('Calculator', 'کیلکولیٹر');

  String get thisMonth => _t('This month', 'اس مہینے');
  String get khSales => _t('Sales', 'فروخت');
  String get khPurchases => _t('Stock purchases', 'مال کی خریداری');
  String get khExpenses => _t('Shop expenses', 'دکان کے اخراجات');
  String get khProfit => _t('Profit', 'منافع');
  String get khLoss => _t('Loss', 'نقصان');
  String get khAddSale => _t('Sale', 'فروخت');
  String get khAddPurchase => _t('Purchase', 'خریداری');
  String get khAddExpense => _t('Expense', 'خرچہ');
  String get fullKhata => _t('Full khata', 'مکمل کھاتہ');
  String get fullKhataSub => _t(
        'Reports, budget, history and more',
        'رپورٹس، بجٹ، ہسٹری اور مزید',
      );
  String get recentEntries => _t('Recent entries', 'حالیہ اندراج');
  String get noShopEntries => _t(
        'No shop entries yet. Add sales, stock purchases and expenses to see your profit.',
        'ابھی دکان کا کوئی اندراج نہیں۔ منافع دیکھنے کے لیے فروخت، خریداری اور اخراجات لکھیں۔',
      );
  String get ordersNotInKhata => _t(
        'Orders from your link stay in the Orders tab.',
        'لنک سے آنے والے آرڈر آرڈرز ٹیب میں رہتے ہیں۔',
      );

  String get spent => _t('Spent', 'خرچ ہوئے');
  String ofBudget(String budget) =>
      _t('of $budget budget', '$budget بجٹ میں سے');
  String moneyLeft(String amount) => _t('$amount left', '$amount باقی');
  String overBy(String amount) => _t('Over by $amount', '$amount زیادہ خرچ');
  String get setBudget => _t('Set a monthly budget', 'ماہانہ بجٹ مقرر کریں');
  String get budgetTitle => _t('Monthly budget', 'ماہانہ بجٹ');
  String get budgetHint => _t(
        'How much do you want to spend on home and personal things each month?',
        'ہر مہینے گھر اور ذاتی چیزوں پر کتنا خرچ کرنا چاہتے ہیں؟',
      );
  String get removeBudget => _t('Remove budget', 'بجٹ ہٹائیں');
  String get byCategory => _t('By category', 'کیٹیگری کے حساب سے');
  String get entriesLabel => _t('Entries', 'اندراج');
  String get noEntriesThisMonth =>
      _t('Nothing written for this month.', 'اس مہینے کچھ نہیں لکھا گیا۔');
  String get noPersonalTitle => _t('Your personal expenses', 'آپ کے ذاتی اخراجات');
  String get noPersonalBody => _t(
        'Write down home and personal spending here. It stays separate from the shop, so your shop profit does not change.',
        'گھر اور ذاتی خرچ یہاں لکھیں۔ یہ دکان سے الگ رہتا ہے، اس لیے دکان کا منافع نہیں بدلتا۔',
      );
  String get addPersonalExpense => _t('Add expense', 'خرچہ لکھیں');
  String get personalExpense => _t('Personal expense', 'ذاتی خرچہ');

  String get youWillGet => _t("You'll get", 'آپ نے لینے ہیں');
  String get youWillGive => _t("You'll give", 'آپ نے دینے ہیں');
  String get settledUp => _t('Settled', 'حساب برابر');
  String get searchPeople => _t('Search people', 'نام تلاش کریں');
  String get addPerson => _t('Add person', 'شخص شامل کریں');
  String get noPeopleTitle =>
      _t('Lena-dena with people', 'لوگوں کے ساتھ لین دین');
  String get noPeopleBody => _t(
        'Keep track of money you give and get: customers on udhaar, suppliers, staff advances, friends and family.',
        'جو پیسے دیے اور لیے ان کا حساب رکھیں: ادھار والے گاہک، سپلائر، ملازم کا ایڈوانس، دوست اور رشتہ دار۔',
      );
  String get pickFromContacts => _t('Pick from contacts', 'کانٹیکٹس سے چنیں');
  String get personNameLabel => _t('Name', 'نام');
  String get personPhoneLabel =>
      _t('Phone number (optional)', 'فون نمبر (اختیاری)');
  String get nameNeeded => _t('Enter a name', 'نام لکھیں');
  String get editPerson => _t('Edit name or number', 'نام یا نمبر بدلیں');
  String get deletePerson => _t('Delete person', 'شخص حذف کریں');
  String deletePersonTitle(String name) =>
      _t('Delete $name?', '$name کو حذف کریں؟');
  String deletePersonBody(int entries) => entries == 0
      ? _t('This person will be removed.', 'یہ شخص ہٹا دیا جائے گا۔')
      : _t(
          'Their ${entries == 1 ? '1 entry' : '$entries entries'} will be deleted too.',
          'ان کے $entries اندراج بھی حذف ہو جائیں گے۔',
        );
  String willGiveYou(String name) =>
      _t('$name will give you', '$name نے آپ کو دینے ہیں');
  String youWillGiveTo(String name) =>
      _t('You will give $name', 'آپ نے $name کو دینے ہیں');
  String get allSettled => _t('All settled', 'حساب برابر ہے');
  String get youGave => _t('You gave', 'آپ نے دیے');
  String get youGot => _t('You got', 'آپ کو ملے');
  String youGaveTo(String name) => _t('You gave $name', 'آپ نے $name کو دیے');
  String youGotFrom(String name) =>
      _t('You got from $name', 'آپ کو $name سے ملے');
  String get remindOnWhatsApp =>
      _t('Send reminder on WhatsApp', 'واٹس ایپ پر یاد دہانی بھیجیں');
  String reminderText(String name, String amount, String from) => _t(
        'Assalam o Alaikum $name, $amount is still due from you. Please pay when you can. Thank you!${from.isEmpty ? '' : '\n— $from'}',
        'السلام علیکم $name، آپ کی طرف $amount ابھی باقی ہیں۔ مہربانی کر کے جب ہو سکے ادا کر دیں۔ شکریہ!${from.isEmpty ? '' : '\n— $from'}',
      );
  String get noLedgerEntries => _t(
        'No entries yet. Tap "You gave" or "You got" below.',
        'ابھی کوئی اندراج نہیں۔ نیچے "آپ نے دیے" یا "آپ کو ملے" دبائیں۔',
      );
  String get shopEntryTag => _t('Shop', 'دکان');

  String get entryAmount => _t('Amount', 'رقم');
  String get entryNote => _t('What for?', 'کس چیز کا؟');
  String get notePersonalHint =>
      _t('e.g. milk, petrol, school fee', 'مثلاً دودھ، پیٹرول، اسکول فیس');
  String get noteLedgerHint =>
      _t('e.g. 2 kg sugar on udhaar', 'مثلاً 2 کلو چینی ادھار');
  String get entryCategory => _t('Category', 'کیٹیگری');
  String get entryDate => _t('Date', 'تاریخ');
  String get editEntry => _t('Edit entry', 'اندراج میں ترمیم');
  String get deleteEntryTitle => _t('Delete this entry?', 'یہ اندراج حذف کریں؟');
  String get deleteEntryBody =>
      _t('It will be removed from your khata.', 'یہ آپ کے کھاتے سے ہٹ جائے گا۔');

  // ── Calculator ──────────────────────────────────────────────────────────
  String get calcTitle => _t('Expense calculator', 'خرچہ کیلکولیٹر');
  String get calcHistory => _t('History', 'ہسٹری');
  String get calcClear => _t('Clear', 'صاف کریں');
  String get calcEmpty => _t(
        'Add up bills, items and costs. Press = to keep a line here.',
        'بل، چیزیں اور خرچ جمع کریں۔ لائن یہاں رکھنے کے لیے = دبائیں۔',
      );
  String get calcSplit => _t('Split', 'تقسیم');
  String get calcShare => _t('Share', 'شیئر');
  String get calcSave => _t('Save', 'لکھیں');
  String get splitTitle => _t('Split the amount', 'رقم تقسیم کریں');
  String get splitPeople => _t('Number of people', 'افراد کی تعداد');
  String eachPays(String amount) => _t('$amount each', 'ہر ایک $amount');
  String get saveWhere => _t('Write this amount in', 'یہ رقم کہاں لکھیں؟');
  String get asPersonal => _t('Personal expense', 'ذاتی خرچہ');
  String get asShopExpense => _t('Shop expense', 'دکان کا خرچہ');
  String get asShopPurchase => _t('Stock purchase', 'مال کی خریداری');
  String useAmount(String amount) => _t('Use $amount', '$amount استعمال کریں');
  String get moreCalculators => _t('More calculators', 'مزید کیلکولیٹر');
  String get calcPricing => _t('Profit & pricing', 'منافع اور قیمت');
  String get calcPricingSub =>
      _t('Markup, margin, break-even', 'مارک اپ، مارجن، بریک ایون');
  String get calcLoan => _t('Loan & installments', 'قرض اور قسطیں');
  String get calcLoanSub => _t('EMI, flat and reducing rate', 'ای ایم آئی، فلیٹ اور ریڈیوسنگ ریٹ');
  String get calcSavings => _t('Savings & investment', 'بچت اور سرمایہ کاری');
  String get calcSavingsSub => _t('SIP and fixed deposit', 'ایس آئی پی اور فکسڈ ڈپازٹ');

  // ── New-order alerts ────────────────────────────────────────────────────
  String get alertsCardTitle =>
      _t('Get new-order alerts', 'نئے آرڈر کی اطلاع پائیں');
  String get alertsCardBody => _t(
        'Your phone will ring when a customer orders from your link, even when the app is closed.',
        'جب کوئی گاہک آپ کے لنک سے آرڈر کرے گا تو فون بجے گا، چاہے ایپ بند ہو۔',
      );
  String get alertsTurnOn => _t('Turn on', 'آن کریں');
  String get alertsOn => _t(
        'Done! You will get a notification for every new order.',
        'ہو گیا! ہر نئے آرڈر پر اطلاع آئے گی۔',
      );
  String get alertsBlocked => _t(
        'Notifications are off for Pocket Karcha. Turn them on in phone settings.',
        'Pocket Karcha کی اطلاعات بند ہیں۔ فون کی سیٹنگز میں آن کریں۔',
      );
  String get openSettings => _t('Open settings', 'سیٹنگز کھولیں');
  String get orderAlerts =>
      _t('New-order notifications', 'نئے آرڈر کی اطلاعات');
  String get orderAlertsOnSub =>
      _t('On — your phone rings for every order', 'آن — ہر آرڈر پر فون بجے گا');
  String get orderAlertsOffSub =>
      _t('Off — tap to turn on', 'بند — آن کرنے کے لیے دبائیں');

  // ── Paid / pending ──────────────────────────────────────────────────────
  String get recordStatus => _t('Payment', 'ادائیگی');
  String get statusPaid => _t('Paid', 'ادا ہو گیا');
  String get statusPending => _t('Pending', 'باقی ہے');
  String get statusPersonal => _t('Personal', 'ذاتی');
  String get hintPaidIn => _t('Money received in full.', 'پوری رقم مل گئی۔');
  String get hintPaidOut => _t('Money paid in full.', 'پوری رقم دے دی۔');
  String get hintPendingIn => _t(
        'Udhaar: the customer pays later. Shows under "To collect" in Khata.',
        'ادھار: گاہک بعد میں دے گا۔ کھاتے میں "وصول کرنا ہے" میں نظر آئے گا۔',
      );
  String get hintPendingOut => _t(
        'Udhaar: you pay later. Shows under "To pay" in Khata.',
        'ادھار: آپ بعد میں دیں گے۔ کھاتے میں "دینا ہے" میں نظر آئے گا۔',
      );
  String get hintPersonal => _t(
        'Saved in your personal khata. It does not change the shop profit.',
        'آپ کے ذاتی کھاتے میں جائے گا۔ دکان کا منافع نہیں بدلے گا۔',
      );
  String get hintPendingPersonal => _t(
        'A bill or expense you still have to pay.',
        'بل یا خرچہ جو ابھی دینا ہے۔',
      );
  String get pendingTitle => _t('Pending payments', 'باقی ادائیگیاں');
  String get toPayLabel => _t('To pay', 'دینا ہے');
  String get markedPaid => _t('Marked as paid', 'ادا شدہ ہو گیا');
  String stillToPay(String amount) =>
      _t('$amount still to pay', '$amount ابھی دینے ہیں');
}

final storeStringsProvider = Provider<StoreStrings>((ref) {
  return StoreStrings(ref.watch(appSettingsProvider).urdu);
});
