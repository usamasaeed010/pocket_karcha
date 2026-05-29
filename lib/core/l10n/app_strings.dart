import 'package:pocket_karcha/features/expenses/models/transaction_type.dart';
import 'package:pocket_karcha/features/settings/models/app_terminology.dart';
import 'package:pocket_karcha/providers/dashboard_provider.dart';

class AppStrings {
  AppStrings(this.isUrdu, {this.terminologyMode = AppTerminology.gotGave});

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
  String get noExpenses => isUrdu ? 'ابھی کوئی خرچ نہیں' : 'No expenses yet';
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
      ? 'پاکستان کے لیے آسان expense tracker۔'
      : 'Simple expense tracker built for Pakistan.';
  String get onboardingTitle2 =>
      isUrdu ? 'سب کچھ ایک جگہ' : 'All in one place';
  String get onboardingBody2 => isUrdu
      ? 'اقسام، چارٹ، رسید، تیز تجاویز۔'
      : 'Categories, charts, receipts, quick adds.';
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
            ? 'آج کا خرچ یا آمدنی شامل کریں'
            : 'Add your first expense or income for today';
      case DashboardPeriod.week:
        return isUrdu
            ? 'اس ہفتے کی لین دین یہاں دکھائی جائے گی'
            : 'Transactions for this week will appear here';
      case DashboardPeriod.month:
        return isUrdu
            ? 'اس ماہ کی لین دین یہاں دکھائی جائے گی'
            : 'Transactions for this month will appear here';
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
      isUrdu ? 'پیسے دیے / خرچ' : 'Money paid out';
  String get youGotHint =>
      isUrdu ? 'پیسے ملے / آمدنی' : 'Money received';
  String get chooseTransactionType => isUrdu
      ? 'لین دین کی قسم منتخب کریں'
      : 'Choose transaction type';

  String recordingLabel(TransactionType type) {
    switch (type) {
      case TransactionType.gave:
        return isUrdu ? 'خرچ درج ہو رہا ہے' : 'Recording money you gave';
      case TransactionType.got:
        return isUrdu ? 'آمدنی درج ہو رہی ہے' : 'Recording money you got';
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
      ? 'You Gave یا You Got بٹن سے شامل کریں'
      : 'Add with You Gave or You Got buttons';
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
      ? 'You Gave / You Got اقسام'
      : 'Manage You Gave & You Got categories';
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
      ? 'پاکٹ خرچہ — Pakistan expense tracker'
      : 'Pocket Karcha — expense tracker for Pakistan';
  String get languageDesc => isUrdu
      ? 'ایپ کی زبان منتخب کریں'
      : 'Choose app display language';
  String get terminologyDesc => isUrdu
      ? 'You Got / You Gave labels'
      : 'Customize income & expense labels';
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
  String get snackTransactionAdded => isUrdu
      ? 'لین دین شامل ہو گئی'
      : 'Transaction added successfully';
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
}
