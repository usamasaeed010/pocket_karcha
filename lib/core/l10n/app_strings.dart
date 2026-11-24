import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/settings/models/app_terminology.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

class AppStrings {
  AppStrings(this.isUrdu, {this.terminologyMode = AppTerminology.shop});

  final bool isUrdu;
  final AppTerminology terminologyMode;

  String get appTitle => isUrdu ? 'پاکٹ خرچہ' : 'Pocket Karcha';
  String get home => isUrdu ? 'ہوم' : 'Home';
  String get addExpense => isUrdu ? 'خرچ شامل کریں' : 'Add expense';
  String get addTransaction =>
      isUrdu ? 'لین دین شامل کریں' : 'Add Transaction';
  String get enterAmount =>
      isUrdu ? 'رقم درج کریں' : 'Enter the amount';
  String get enterValue => isUrdu ? 'یہاں درج کریں' : 'Enter value';
  String get date => isUrdu ? 'تاریخ' : 'Date';
  String get select => isUrdu ? 'منتخب کریں' : 'Select';
  String get attachFile => isUrdu ? 'فائل منسلک' : 'Attach File';
  String get uploadFile =>
      isUrdu ? 'فائل اپ لوڈ کریں' : 'Upload a file';
  String get enterNote => isUrdu ? 'نوٹ لکھیں' : 'Enter note';
  String get cancel => isUrdu ? 'منسوخ' : 'Cancel';
  String get invalidAmount =>
      isUrdu ? 'درست رقم درج کریں' : 'Please enter a valid amount';
  String get selectCategory =>
      isUrdu ? 'قسم منتخب کریں' : 'Please select a category';
  String get totalThisMonth => isUrdu ? 'اس ماہ کا خرچ' : 'This month';
  String get suggestions => isUrdu ? 'تجویز' : 'Quick add';
  String get amount => isUrdu ? 'رقم' : 'Amount';
  String get note => isUrdu ? 'نوٹ' : 'Note';
  String get category => isUrdu ? 'قسم' : 'Category';
  String get save => isUrdu ? 'محفوظ کریں' : 'Save';
  String get recent => isUrdu ? 'حالیہ' : 'Recent';
  String get byCategory => isUrdu ? 'قسم کے حساب سے' : 'By category';
  String get settings => isUrdu ? 'ترتیبات' : 'Settings';
  String get language => isUrdu ? 'زبان' : 'Language';
  String get english => 'English';
  String get urdu => 'اردو';
  String get noExpenses => isUrdu ? 'ابھی کوئی اندراج نہیں' : 'No entries yet';
  String get loginHint => isUrdu
      ? 'اکاؤنٹ بنائیں یا سائن ان کریں'
      : 'Create an account or sign in';
  String get email => isUrdu ? 'ای میل' : 'Email';
  String get password => isUrdu ? 'پاس ورڈ' : 'Password';
  String get signIn => isUrdu ? 'داخل ہوں' : 'Sign in';
  String get signUp => isUrdu ? 'اکاؤنٹ بنائیں' : 'Sign up';
  String get name => isUrdu ? 'نام' : 'Full name';
  String get confirmPassword => isUrdu ? 'پاس ورڈ دوبارہ' : 'Confirm password';
  String get account => isUrdu ? 'اکاؤنٹ' : 'Account';
  String get profilePhoto => isUrdu ? 'پروفائل تصویر' : 'Profile photo';
  String get changeProfilePhoto =>
      isUrdu ? 'تصویر تبدیل کریں' : 'Change photo';
  String get profilePhotoUnavailable => isUrdu
      ? 'تصویر اپ لوڈ کے لیے سائن ان کریں'
      : 'Sign in to upload a profile photo';
  String get signOut => isUrdu ? 'سائن آؤٹ' : 'Sign out';
  String get signedInAs => isUrdu ? 'سائن ان:' : 'Signed in as';
  String get guestMode => isUrdu ? 'مہمان موڈ' : 'Guest mode';
  String get syncCloud => isUrdu ? 'کلاؤڈ سنک' : 'Cloud synced';
  String get receipt => isUrdu ? 'رسید' : 'Receipt';
  String get takePhoto => isUrdu ? 'تصویر لیں' : 'Take photo';
  String get chooseGallery => isUrdu ? 'گیلری' : 'Gallery';
  String get removeReceipt => isUrdu ? 'ہٹائیں' : 'Remove';
  String get viewReceipt => isUrdu ? 'رسید دیکھیں' : 'View receipt';
  String get tapReceiptHint =>
      isUrdu ? 'رسید دیکھنے کے لیے ٹیپ کریں' : 'Tap to view receipt';
  String get passwordsMismatch =>
      isUrdu ? 'پاس ورڈ میل نہیں کھاتے' : 'Passwords do not match';
  String get passwordTooShort =>
      isUrdu ? 'کم از کم 6 حروف' : 'At least 6 characters';
  String get loginToSync =>
      isUrdu ? 'سائن ان کریں' : 'Sign in to sync';
  String get next => isUrdu ? 'آگے' : 'Next';
  String get skip => isUrdu ? 'چھوڑیں' : 'Skip';
  String get getStarted => isUrdu ? 'شروع کریں' : 'Get started';
  String get onboardingTitle1 =>
      isUrdu ? 'خوش آمدید!' : 'Welcome to Pocket Karcha';
  String get onboardingBody1 => isUrdu
      ? 'دکانوں، ٹھیلوں اور چھوٹے کاروبار کا آسان کھاتہ۔'
      : 'Simple business khata for shops, stalls & small businesses.';
  String get onboardingTitle2 =>
      isUrdu ? 'اپنا اصل منافع جانیں' : 'Know your real profit';
  String get onboardingBody2 => isUrdu
      ? 'فروخت، مال کی خریداری اور دکان کے خرچ درج کریں — ہر ماہ کا منافع دیکھیں۔'
      : 'Record sales, bulk stock purchases & shop expenses — see your profit every month.';
  String get onboardingTitle3 =>
      isUrdu ? 'زبان منتخب کریں' : 'Choose language';
  String get onboardingBody3 => isUrdu
      ? 'اردو یا English۔'
      : 'Urdu or English.';
  String get completeProfile =>
      isUrdu ? 'پروفائل مکمل کریں' : 'Complete your profile';
  String get completeProfileSubtitle => isUrdu
      ? 'اکاؤنٹ کے لیے نمبر اور کرنسی درکار ہے۔'
      : 'Add your mobile number and currency to finish setup.';
  String get selectCurrency =>
      isUrdu ? 'کرنسی' : 'Currency';
  String get selectCurrencyHint => isUrdu
      ? 'خرچ اسی کرنسی میں دکھایا جائے گا'
      : 'Expenses will be shown in this currency';
  String get continueToApp =>
      isUrdu ? 'ڈیش بورڈ پر جائیں' : 'Continue to dashboard';
  String get firebaseNotReady => isUrdu
      ? 'Firebase سیٹ اپ کریں (flutterfire configure)'
      : 'Set up Firebase first (run flutterfire configure)';
  String get nameRequired =>
      isUrdu ? 'نام درج کریں' : 'Please enter your name';
  String get welcomeBack => isUrdu ? 'خوش آمدید!' : 'Welcome back!';
  String greeting(String name) => isUrdu ? 'سلام، $name' : 'Hi, $name';
  String periodSummaryTitle(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.day:
        return isUrdu ? 'آج کا خلاصہ' : "Today's summary";
      case DashboardPeriod.week:
        return isUrdu ? 'اس ہفتے کا خلاصہ' : "This week's summary";
      case DashboardPeriod.month:
        return isUrdu ? 'اس ماہ کا خلاصہ' : "This month's summary";
    }
  }

  String periodTransactionCount(int count, DashboardPeriod period) {
    final periodWord = switch (period) {
      DashboardPeriod.day => isUrdu ? 'آج' : 'today',
      DashboardPeriod.week => isUrdu ? 'اس ہفتے' : 'this week',
      DashboardPeriod.month => isUrdu ? 'اس ماہ' : 'this month',
    };
    if (isUrdu) {
      return count == 0
          ? '$periodWord کوئی لین دین نہیں'
          : '$periodWord $count لین دین';
    }
    return count == 0
        ? 'No transactions $periodWord'
        : '$count transaction${count == 1 ? '' : 's'} $periodWord';
  }

  String periodEmptyHint(DashboardPeriod period) {
    switch (period) {
      case DashboardPeriod.day:
        return isUrdu
            ? 'آج کی فروخت، خریداری یا خرچ شامل کریں'
            : "Add today's sale, stock purchase or expense";
      case DashboardPeriod.week:
        return isUrdu
            ? 'اس ہفتے کے اندراجات یہاں دکھائی دیں گے'
            : "This week's entries will appear here";
      case DashboardPeriod.month:
        return isUrdu
            ? 'اس ماہ کے اندراجات یہاں دکھائی دیں گے'
            : "This month's entries will appear here";
    }
  }

  String get add => isUrdu ? 'شامل کریں' : 'Add';
  String get createAccountTitle =>
      isUrdu ? 'نیا اکاؤنٹ' : 'Create your account';
  String get personal => isUrdu ? 'ذاتی' : 'Personal';
  String get upgrade => isUrdu ? 'اپ گریڈ' : 'UPGRADE';
  String get todaysFinances =>
      isUrdu ? 'آج کا خرچ' : "TODAY'S FINANCES";
  String get spent => isUrdu ? 'خرچ' : 'SPENT';
  String get available => isUrdu ? 'باقی' : 'AVAILABLE';
  String get youGot => terminologyMode.pair(isUrdu).positive;
  String get youGave => terminologyMode.pair(isUrdu).negative;
  String get youGaveHint =>
      isUrdu ? 'کرایہ، بل، تنخواہ، گیس' : 'Rent, bills, salary, gas';
  String get youGotHint =>
      isUrdu ? 'فروخت و آمدنی' : 'Sales & money in';
  String get purchase => isUrdu ? 'خریداری' : 'Purchase';
  String get purchaseHint =>
      isUrdu ? 'مال و خام سامان' : 'Stock & raw material';

  /// Title for an entry kind (respects the terminology setting).
  String typeLabel(TransactionType type) => switch (type) {
        TransactionType.got => youGot,
        TransactionType.purchase => purchase,
        TransactionType.gave => youGave,
      };
  String get chooseTransactionType => isUrdu
      ? 'لین دین کی قسم منتخب کریں'
      : 'Choose transaction type';

  String recordingLabel(TransactionType type) {
    switch (type) {
      case TransactionType.gave:
        return isUrdu
            ? 'دکان کا خرچہ درج ہو رہا ہے'
            : 'Recording a shop expense';
      case TransactionType.purchase:
        return isUrdu
            ? 'مال کی خریداری درج ہو رہی ہے'
            : 'Recording a stock purchase';
      case TransactionType.got:
        return isUrdu ? 'فروخت درج ہو رہی ہے' : 'Recording a sale';
    }
  }
  String get balance => isUrdu ? 'بیلنس' : 'Balance';
  String get recentTransactions =>
      isUrdu ? 'حالیہ لین دین' : 'Recent Transactions';
  String get viewAll => isUrdu ? 'سب دیکھیں' : 'View all';
  String get addExpenseShort => isUrdu ? '+ ${youGave}' : '+ $youGave';
  String get addIncomeShort => isUrdu ? '+ ${youGot}' : '+ $youGot';
  String get history => isUrdu ? 'تاریخ' : 'History';
  String get people => isUrdu ? 'لوگ' : 'People';
  String get more => isUrdu ? 'مزید' : 'More';
  String get day => isUrdu ? 'دن' : 'Day';
  String get week => isUrdu ? 'ہفتہ' : 'Week';
  String get month => isUrdu ? 'مہینہ' : 'Month';
  String get chartsAndReports =>
      isUrdu ? 'چارٹ اور رپورٹ' : 'Charts & reports';
  String get comingSoon => isUrdu ? 'جلد آ رہا ہے' : 'Coming soon';
  String get openingBalance =>
      isUrdu ? 'ابتدائی بیلنس' : 'Opening Balance';
  String get closingBalance =>
      isUrdu ? 'اختتامی بیلنس' : 'Closing Balance';
  String get spentOn => isUrdu ? 'خرچ' : 'Spent on';
  String get searchTransactions =>
      isUrdu ? 'لین دین تلاش کریں' : 'Search Transactions';
  String get sortBy => isUrdu ? 'ترتیب' : 'Sort by';
  String get newestFirst => isUrdu ? 'نیا پہلے' : 'Newest first';
  String get oldestFirst => isUrdu ? 'پرانا پہلے' : 'Oldest first';
  String get amountHighToLow =>
      isUrdu ? 'زیادہ رقم پہلے' : 'Amount high to low';
  String get amountLowToHigh =>
      isUrdu ? 'کم رقم پہلے' : 'Amount low to high';
  String get exportReport =>
      isUrdu ? 'رپورٹ ڈاؤن لوڈ' : 'Export report';
  String get filters => isUrdu ? 'فلٹر' : 'Filters';
  String get manage => isUrdu ? 'منظم کریں' : 'Manage';
  String get editProfile => isUrdu ? 'پروفائل میں ترمیم' : 'Edit profile';
  String get editProfileDesc => isUrdu
      ? 'نام اور تصویر اپ ڈیٹ کریں'
      : 'Update your name and photo';
  String get saveChanges => isUrdu ? 'محفوظ کریں' : 'Save changes';
  String get toolsAndCategories =>
      isUrdu ? 'ٹولز اور اقسام' : 'Tools & Categories';
  String get general => isUrdu ? 'عام' : 'General';
  String get categories => isUrdu ? 'اقسام' : 'Categories';
  String get timePeriod => isUrdu ? 'وقت کی مدت' : 'Time Period';
  String get currencySymbol =>
      isUrdu ? 'کرنسی کا نشان' : 'Currency Symbol';
  String get terminology => isUrdu ? 'اصطلاح' : 'Terminology';
  String get syncNow => isUrdu ? 'ابھی سنک کریں' : 'Sync Now';
  String get deleteAccount =>
      isUrdu ? 'اکاؤنٹ حذف کریں' : 'Delete Account';
  String get privacyPolicy =>
      isUrdu ? 'پرائیویسی پالیسی' : 'Privacy Policy';
  String get aboutUs => isUrdu ? 'ہمارے بارے میں' : 'About Us';
  String get logout => isUrdu ? 'لاگ آؤٹ' : 'Logout';
  String get logoutConfirm => isUrdu
      ? 'کیا آپ لاگ آؤٹ کرنا چاہتے ہیں؟'
      : 'Are you sure you want to logout?';
  String get logoutWarning => isUrdu
      ? 'آپ کو دوبارہ سائن ان کرنا ہوگا۔'
      : 'You will need to sign in again to access your account.';
  String get loanCalculators =>
      isUrdu ? 'قرض کیلکولیٹر' : 'Loan Calculators';
  String get investmentCalculators => isUrdu
      ? 'سرمایہ کاری کیلکولیٹر'
      : 'Investment Calculators';
  String get businessCalculators => isUrdu
      ? 'کاروبار کیلکولیٹر'
      : 'Business Calculators';
  String get selectLanguage =>
      isUrdu ? 'زبان منتخب کریں' : 'Select language';
  String get appVersion => isUrdu ? 'ورژن' : 'Version';
  String get daily => isUrdu ? 'روزانہ' : 'Daily';
  String get weekly => isUrdu ? 'ہفتہ وار' : 'Weekly';
  String get monthly => isUrdu ? 'ماہانہ' : 'Monthly';
  String get yearly => isUrdu ? 'سالانہ' : 'Yearly';
  String periodLabel(DashboardPeriod p) {
    switch (p) {
      case DashboardPeriod.day:
        return daily;
      case DashboardPeriod.week:
        return weekly;
      case DashboardPeriod.month:
        return monthly;
    }
  }

  String get deleteAccountConfirm => isUrdu
      ? 'کیا آپ واقعی اپنا اکاؤنٹ حذف کرنا چاہتے ہیں؟'
      : 'Are you sure you want to delete your account?';
  String get deleteAccountWarning => isUrdu
      ? 'آپ کا اکاؤنٹ غیر فعال ہو جائے گا اور آپ دوبارہ لاگ ان نہیں کر سکیں گے۔'
      : 'Your account will be disabled and you will not be able to sign in again.';
  String get addCategory => isUrdu ? 'نئی قسم' : 'Add category';
  String get editCategory => isUrdu ? 'قسم میں ترمیم' : 'Edit category';
  String get categoryName => isUrdu ? 'قسم کا نام' : 'Category name';
  String get selectIcon => isUrdu ? 'آئیکن منتخب کریں' : 'Select icon';
  String get customRange =>
      isUrdu ? 'تاریخ منتخب کریں' : 'Select date';
  String get customRangeDesc => isUrdu
      ? 'آخری 7 دن کا ڈیٹا (مثلاً 30 مئی → 23–30 مئی)'
      : 'Last 7 days ending on this date (e.g. May 30 → 23–30 May)';
  String get selectEndDate => isUrdu ? 'آخری تاریخ' : 'End date';
  String last7DaysPreview(String range) => isUrdu
      ? 'دکھایا جائے گا: $range (7 دن)'
      : 'Showing: $range (7 days)';
  String get fromDate => isUrdu ? 'سے' : 'From';
  String get toDate => isUrdu ? 'تک' : 'To';
  String get apply => isUrdu ? 'لاگو کریں' : 'Apply';
  String get addPeople => isUrdu ? 'لوگ شامل کریں' : 'Add people';
  String get addPeopleDesc => isUrdu
      ? 'رابطوں میں سے لوگ منتخب کریں'
      : 'Pick someone from your contacts';
  String get addPeopleFormDesc => isUrdu
      ? 'نام اور فون نمبر درست کریں'
      : 'Confirm name and phone number';
  String get selectContact => isUrdu ? 'رابطے' : 'Contacts';
  String get selectContactDesc => isUrdu
      ? 'شامل کرنے کے لیے رابطہ منتخب کریں'
      : 'Select a contact to add';
  String get searchContacts => isUrdu ? 'رابطے تلاش کریں' : 'Search contacts';
  String get noContacts => isUrdu ? 'کوئی رابطہ نہیں' : 'No contacts found';
  String get retry => isUrdu ? 'دوبارہ کوشش' : 'Retry';
  String get personAlreadyAdded => isUrdu
      ? 'یہ رابطہ پہلے سے شامل ہے'
      : 'This contact is already added';
  String get credit => isUrdu ? 'کریڈٹ' : 'Credit';
  String get debit => isUrdu ? 'ڈیبٹ' : 'Debit';
  String get transactions => isUrdu ? 'لین دین' : 'Transactions';
  String get selectPerson => isUrdu ? 'شخص منتخب کریں' : 'Select person';
  String get linkedPerson => isUrdu ? 'شخص' : 'Person';
  String get noPerson => isUrdu ? 'کوئی نہیں' : 'None';
  String get noTransactionsForPerson => isUrdu
      ? 'ابھی کوئی لین دین نہیں'
      : 'No transactions yet';
  String get noTransactionsForPersonDesc => isUrdu
      ? 'نیچے دیے گئے بٹن سے فروخت، خریداری یا خرچ شامل کریں'
      : 'Add a sale, purchase or expense with the buttons below';
  String get contactsPermissionDenied => isUrdu
      ? 'رابطوں کی اجازت درکار ہے'
      : 'Contacts permission is required';
  String setBudgetFor(String name) =>
      isUrdu ? '$name کا بجٹ' : 'Budget for $name';
  String peopleCount(int n) =>
      isUrdu ? '$n لوگ' : '$n ${n == 1 ? 'person' : 'people'}';
  String get accountDisabled => isUrdu
      ? 'یہ اکاؤنٹ غیر فعال ہے'
      : 'This account has been disabled';
  String get accountDeletedSoon => isUrdu
      ? 'اکاؤنٹ حذف کی درخواست موصول ہوئی'
      : 'Account deletion request received';
  String get settingsDesc => isUrdu
      ? 'مدت، کرنسی، زبان اور مزید'
      : 'Period, currency, language & more';
  String get categoriesDesc => isUrdu
      ? 'فروخت، خریداری اور خرچ کی اقسام'
      : 'Sale, purchase & expense categories';
  String get loanCalculatorsDesc => isUrdu
      ? 'EMI، فلیٹ اور ریڈucing balance'
      : 'EMI, flat & reducing balance loans';
  String get investmentCalculatorsDesc => isUrdu
      ? 'SIP اور fixed deposit'
      : 'SIP & fixed deposit returns';
  String get businessCalculatorsDesc => isUrdu
      ? 'Markup، break-even، margin'
      : 'Markup, break-even & profit margin';
  String get privacyPolicyDesc => isUrdu
      ? 'آن لائن پرائیویسی پالیسی پڑھیں'
      : 'Read our online privacy policy';
  String get privacyPolicyLoadError => isUrdu
      ? 'پالیسی لوڈ نہیں ہو سکی۔ انٹرنیٹ چیک کریں۔'
      : 'Could not load the privacy policy. Check your internet connection.';
  String get aboutUsDesc => isUrdu
      ? 'پاکٹ خرچہ — دکان کا خرچ و منافع ٹریکر'
      : 'Pocket Karcha — shop expense & profit tracker';
  String get languageDesc => isUrdu
      ? 'ایپ کی زبان منتخب کریں'
      : 'Choose app display language';
  String get terminologyDesc => isUrdu
      ? 'فروخت / خرچ کے نام'
      : 'Customize sale & expense labels';
  String get timePeriodDesc => isUrdu
      ? 'ڈیش بورڈ کی default مدت'
      : 'Default dashboard time period';
  String get syncNowDesc => isUrdu
      ? 'کلاؤڈ سے ڈیٹا سنک'
      : 'Sync your data with cloud';
  String get deleteAccountDesc => isUrdu
      ? 'مستقل طور پر اکاؤنٹ حذف'
      : 'Permanently remove your account';
  String get enabled => isUrdu ? 'فعال' : 'Enabled';
  String get disabled => isUrdu ? 'غیر فعال' : 'Disabled';
  String get syncReady => isUrdu ? 'سنک تیار' : 'Ready to sync';
  String get syncUnavailable => isUrdu ? 'سنک دستیاب نہیں' : 'Sync unavailable';
  String get syncReadyDesc => isUrdu
      ? 'آپ کا ڈیٹا کلاؤڈ سے منسلک ہے'
      : 'Your account is connected to cloud';
  String get calculate => isUrdu ? 'حساب کریں' : 'Calculate';
  String get emiCalculator => isUrdu ? 'EMI کیلکولیٹر' : 'EMI Calculator';
  String get emiCalculatorDesc => isUrdu ? 'ماہانہ قسط' : 'Monthly installment';
  String get flatRateLoan => isUrdu ? 'فلیٹ ریٹ قرض' : 'Flat Rate Loan';
  String get flatRateLoanDesc => isUrdu ? 'سادہ سود' : 'Simple flat interest';
  String get reducingBalanceLoan =>
      isUrdu ? 'ریڈucing balance' : 'Reducing Balance Loan';
  String get reducingBalanceLoanDesc =>
      isUrdu ? 'کم ہوتا بیلنس' : 'Declining balance interest';
  String get sipCalculator => isUrdu ? 'SIP کیلکولیٹر' : 'SIP Calculator';
  String get sipCalculatorDesc =>
      isUrdu ? 'ماہانہ سرمایہ کاری' : 'Monthly investment plan';
  String get fdCalculator => isUrdu ? 'FD کیلکولیٹر' : 'FD Calculator';
  String get fdCalculatorDesc =>
      isUrdu ? 'فکسڈ ڈپازٹ' : 'Fixed deposit maturity';
  String get markupCalculator =>
      isUrdu ? 'Markup کیلکولیٹر' : 'Markup Calculator';
  String get markupCalculatorDesc =>
      isUrdu ? 'فروخت قیمت' : 'Selling price from cost';
  String get breakEvenCalculator =>
      isUrdu ? 'Break-even' : 'Break-even Calculator';
  String get breakEvenCalculatorDesc =>
      isUrdu ? 'منافع کا نقطہ' : 'Units to cover costs';
  String get profitMarginCalculator =>
      isUrdu ? 'Profit Margin' : 'Profit Margin Calculator';
  String get profitMarginCalculatorDesc =>
      isUrdu ? 'منافع کا %' : 'Profit percentage';
  String get loanAmount => isUrdu ? 'قرض کی رقم' : 'Loan Amount';
  String get annualInterestRate =>
      isUrdu ? 'سالانہ سود %' : 'Annual Interest Rate';
  String get tenureMonths => isUrdu ? 'مدت (مہینے)' : 'Tenure (months)';
  String get tenureYears => isUrdu ? 'مدت (سال)' : 'Tenure (years)';
  String get monthsShort => isUrdu ? 'ماہ' : 'mo';
  String get yearsShort => isUrdu ? 'سال' : 'yr';
  String get monthlyEmi => isUrdu ? 'ماہانہ EMI' : 'Monthly EMI';
  String get totalPayment => isUrdu ? 'کل ادائیگی' : 'Total Payment';
  String get totalInterest => isUrdu ? 'کل سود' : 'Total Interest';
  String get monthlyInvestment =>
      isUrdu ? 'ماہانہ سرمایہ' : 'Monthly Investment';
  String get expectedReturn => isUrdu ? 'متوقع منافع %' : 'Expected Return';
  String get totalInvested => isUrdu ? 'کل سرمایہ' : 'Total Invested';
  String get futureValue => isUrdu ? 'مستقبل کی قیمت' : 'Future Value';
  String get estimatedGain => isUrdu ? 'تخمینی منافع' : 'Estimated Gain';
  String get depositAmount => isUrdu ? 'ڈپازٹ رقم' : 'Deposit Amount';
  String get maturityAmount => isUrdu ? 'میچورٹی رقم' : 'Maturity Amount';
  String get costPrice => isUrdu ? 'لاگت' : 'Cost Price';
  String get markupPercent => isUrdu ? 'Markup %' : 'Markup %';
  String get sellingPrice => isUrdu ? 'فروخت قیمت' : 'Selling Price';
  String get fixedCost => isUrdu ? 'فکسڈ لاگت' : 'Fixed Cost';
  String get variableCost => isUrdu ? 'متغیر لاگت' : 'Variable Cost';
  String get breakEvenUnits => isUrdu ? 'Break-even یونٹ' : 'Break-even Units';
  String get revenue => isUrdu ? 'آمدنی' : 'Revenue';
  String get totalCost => isUrdu ? 'کل لاگت' : 'Total Cost';
  String get profitMargin => isUrdu ? 'منافع %' : 'Profit Margin';

  String get snackSavedSuccess =>
      isUrdu ? 'کامیابی سے محفوظ ہو گیا' : 'Saved successfully';
  String get receiptAttached =>
      isUrdu ? 'رسید منسلک ہے' : 'Receipt attached';
  String get snackTransactionAdded => isUrdu
      ? 'لین دین شامل ہو گئی'
      : 'Transaction added successfully';
  String get editTransaction =>
      isUrdu ? 'لین دین میں ترمیم' : 'Edit transaction';
  String get deleteTransaction =>
      isUrdu ? 'لین دین حذف کریں' : 'Delete transaction';
  String get transactionOptions =>
      isUrdu ? 'لین دین کے اختیارات' : 'Transaction options';
  String get transaction => isUrdu ? 'لین دین' : 'Transaction';
  String get deleteTransactionConfirm => isUrdu
      ? 'کیا آپ یہ لین دین حذف کرنا چاہتے ہیں؟'
      : 'Delete this transaction?';
  String get deleteTransactionWarning => isUrdu
      ? 'یہ عمل واپس نہیں ہو سکتا۔'
      : 'This action cannot be undone.';
  String get snackTransactionUpdated => isUrdu
      ? 'لین دین اپ ڈیٹ ہو گئی'
      : 'Transaction updated successfully';
  String get snackTransactionDeleted => isUrdu
      ? 'لین دین حذف ہو گئی'
      : 'Transaction deleted successfully';
  String get snackPersonAdded =>
      isUrdu ? 'شخص شامل ہو گیا' : 'Person added successfully';
  String get snackCategorySaved =>
      isUrdu ? 'قسم محفوظ ہو گئی' : 'Category saved successfully';
  String get snackProfilePhotoUpdated => isUrdu
      ? 'پروفائل تصویر اپ ڈیٹ ہو گئی'
      : 'Profile photo updated';
  String get snackProfileUpdated => isUrdu
      ? 'پروفائل اپ ڈیٹ ہو گئی'
      : 'Profile updated';
  String get pressBackAgainToExit => isUrdu
      ? 'ایپ بند کرنے کے لیے دوبارہ بیک دبائیں'
      : 'Press back again to exit the app';
  String get snackAccountDeleted => isUrdu
      ? 'اکاؤنٹ غیر فعال کر دیا گیا'
      : 'Account has been disabled';
  String get snackSomethingWrong => isUrdu
      ? 'کچھ غلط ہو گیا — دوبارہ کوشش کریں'
      : 'Something went wrong — please try again';
  String get snackEnterCategoryName => isUrdu
      ? 'قسم کا نام درج کریں'
      : 'Please enter a category name';

  // ── Shop / business ────────────────────────────────────────────────────
  String get shopTagline => isUrdu
      ? 'فروخت، خریداری اور منافع کا حساب'
      : 'Sales, stock & profit — all in one place';
  String get profit => isUrdu ? 'منافع' : 'Profit';
  String get loss => isUrdu ? 'نقصان' : 'Loss';
  String get netProfit => isUrdu ? 'خالص منافع' : 'Net profit';
  String get netLoss => isUrdu ? 'خالص نقصان' : 'Net loss';
  String profitOrLoss(double value) => value < 0 ? loss : profit;
  String periodResultTitle(DashboardPeriod period, {required bool loss}) {
    final word = loss ? this.loss : profit;
    switch (period) {
      case DashboardPeriod.day:
        return isUrdu ? 'آج کا $word' : "Today's ${word.toLowerCase()}";
      case DashboardPeriod.week:
        return isUrdu
            ? 'اس ہفتے کا $word'
            : "This week's ${word.toLowerCase()}";
      case DashboardPeriod.month:
        return isUrdu
            ? 'اس ماہ کا $word'
            : "This month's ${word.toLowerCase()}";
    }
  }

  String marginLabel(String percent) =>
      isUrdu ? 'مارجن $percent%' : '$percent% margin';
  String profitShort(String amount) =>
      isUrdu ? 'منافع $amount' : 'Profit $amount';
  String lossShort(String amount) => isUrdu ? 'نقصان $amount' : 'Loss $amount';
  String get spending => isUrdu ? 'کل خرچ' : 'Total spent';
  String get moneyIn => isUrdu ? 'آمدن' : 'Money in';
  String get moneyOut => isUrdu ? 'اخراجات' : 'Money out';
  String get quickAdd => isUrdu ? 'فوری اندراج' : 'Quick add';
  String get all => isUrdu ? 'سب' : 'All';

  // Budget
  String get monthlyBudget => isUrdu ? 'ماہانہ بجٹ' : 'Monthly budget';
  String get monthlyBudgetDesc => isUrdu
      ? 'مال اور دکان کے خرچ کی ماہانہ حد'
      : 'Monthly limit for stock & shop expenses';
  String get setBudget => isUrdu ? 'بجٹ مقرر کریں' : 'Set budget';
  String get editBudget => isUrdu ? 'بجٹ تبدیل کریں' : 'Edit budget';
  String get removeBudget => isUrdu ? 'بجٹ ہٹائیں' : 'Remove budget';
  String get budgetAmount => isUrdu ? 'بجٹ کی رقم' : 'Budget amount';
  String get setBudgetHint => isUrdu
      ? 'اس ماہ مال کی خریداری اور دکان کے خرچ کے لیے کتنی رقم رکھنی ہے؟'
      : 'How much can you spend on stock and shop expenses this month?';
  String get setBudgetCta => isUrdu
      ? 'بجٹ مقرر کریں اور ہر روز دیکھیں کتنا خرچ کر سکتے ہیں'
      : 'Set a budget and see how much you can spend each day';
  String get remaining => isUrdu ? 'باقی' : 'Remaining';
  String get overBudget => isUrdu ? 'بجٹ سے زیادہ' : 'Over budget';
  String budgetUsed(int percent) =>
      isUrdu ? '$percent% استعمال ہوا' : '$percent% used';
  String spentOfBudget(String spent, String budget) =>
      isUrdu ? '$budget میں سے $spent خرچ' : '$spent spent of $budget';
  String perDayAllowance(String amount, int days) => isUrdu
      ? 'باقی $days دن کے لیے روزانہ $amount تک خرچ کر سکتے ہیں'
      : 'You can spend $amount/day for the next $days days';
  String get budgetExceededHint => isUrdu
      ? 'اس ماہ کا بجٹ ختم ہو گیا — خرچ پر نظر رکھیں'
      : 'Budget used up for this month — keep an eye on spending';
  String get snackBudgetSaved =>
      isUrdu ? 'بجٹ محفوظ ہو گیا' : 'Budget saved';
  String get snackBudgetRemoved =>
      isUrdu ? 'بجٹ ہٹا دیا گیا' : 'Budget removed';

  // Reports
  String get reports => isUrdu ? 'رپورٹس' : 'Reports';
  String get reportsDesc =>
      isUrdu ? 'ماہانہ نفع و نقصان' : 'Monthly profit & loss';
  String get last6Months => isUrdu ? 'پچھلے 6 ماہ' : 'Last 6 months';
  String get whereMoneyWent =>
      isUrdu ? 'پیسہ کہاں خرچ ہوا' : 'Where your money went';
  String get stockByCategory =>
      isUrdu ? 'خریداری بلحاظ قسم' : 'Purchases by category';
  String get expensesByCategory =>
      isUrdu ? 'خرچ بلحاظ قسم' : 'Expenses by category';
  String get salesByCategory =>
      isUrdu ? 'فروخت بلحاظ قسم' : 'Sales by category';
  String get topPurchasedItems =>
      isUrdu ? 'سب سے زیادہ خریدا گیا مال' : 'Top purchased items';
  String get topSoldItems =>
      isUrdu ? 'سب سے زیادہ بکنے والی اشیاء' : 'Top selling items';
  String get avgDailySales =>
      isUrdu ? 'اوسط روزانہ فروخت' : 'Avg. daily sale';
  String get entries => isUrdu ? 'اندراجات' : 'Entries';
  String entriesCount(int n) =>
      isUrdu ? '$n اندراجات' : '$n ${n == 1 ? 'entry' : 'entries'}';
  String get noDataForMonth =>
      isUrdu ? 'اس ماہ کوئی اندراج نہیں' : 'No entries for this month';
  String get noDataForMonthHint => isUrdu
      ? 'منافع کی رپورٹ دیکھنے کے لیے فروخت، خریداری اور خرچ شامل کریں۔'
      : 'Add sales, purchases and expenses to see your profit report.';
  String avgRate(String rate, String unit) =>
      isUrdu ? 'اوسط $rate فی $unit' : 'avg $rate / $unit';
  String timesCount(int n) => isUrdu ? '$n بار' : '${n}x';
  String get myShop => isUrdu ? 'میری دکان' : 'My shop';
  String get calculators => isUrdu ? 'کیلکولیٹرز' : 'Calculators';

  // Item details (add screen)
  String get itemDetails => isUrdu ? 'سامان کی تفصیل' : 'Item details';
  String get itemName => isUrdu ? 'چیز کا نام' : 'Item name';
  String get itemNameHint =>
      isUrdu ? 'مثلاً کیلے، سیب، برگر بن' : 'e.g. Bananas, Apples, Burger buns';
  String get saleItemNameHint =>
      isUrdu ? 'مثلاً جوس گلاس، فروٹ چاٹ' : 'e.g. Juice glass, Fruit chaat';
  String get quantity => isUrdu ? 'مقدار' : 'Quantity';
  String get unit => isUrdu ? 'یونٹ' : 'Unit';
  String get selectUnit => isUrdu ? 'یونٹ منتخب کریں' : 'Select unit';
  String get rate => isUrdu ? 'ریٹ' : 'Rate';
  String ratePer(String unit) => isUrdu ? 'فی $unit ریٹ' : 'Rate / $unit';
  String get totalAmount => isUrdu ? 'کل رقم' : 'Total amount';
  String get autoCalculated => isUrdu
      ? 'مقدار × ریٹ سے خودکار حساب'
      : 'Auto-calculated from quantity × rate';
  String get recentItems => isUrdu ? 'حالیہ اشیاء' : 'Recent items';
  String get addQtyRate =>
      isUrdu ? 'مقدار اور ریٹ شامل کریں' : 'Add quantity & rate';
  String get optional => isUrdu ? 'اختیاری' : 'Optional';
}
