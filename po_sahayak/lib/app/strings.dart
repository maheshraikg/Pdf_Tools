/// All user-facing text, in English and Kannada. Nothing is hard-coded in
/// the screens.
library;

import '../domain/engine/closure.dart';
import '../domain/engine/eligibility.dart';
import '../domain/models/scheme.dart';

/// Headings of the scheme details page.
enum SchemeFact { interest, tenure, deposit, who, tax, closure, loan, maturity }

enum Lang { en, kn }

class S {
  const S(this.lang);
  final Lang lang;

  bool get kn => lang == Lang.kn;
  String _t(String en, String kn) => this.kn ? kn : en;

  // App
  String get appTitle => _t('PO Calculator', 'ಪಿಒ ಕ್ಯಾಲ್ಕುಲೇಟರ್');
  String get tagline =>
      _t('Post Office interest calculator', 'ಅಂಚೆ ಕಚೇರಿ ಬಡ್ಡಿ ಕ್ಯಾಲ್ಕುಲೇಟರ್');
  String get notAffiliated => _t(
    'Not affiliated with India Post or the Government of India.',
    'ಭಾರತೀಯ ಅಂಚೆ ಅಥವಾ ಭಾರತ ಸರ್ಕಾರದೊಂದಿಗೆ ಸಂಬಂಧವಿಲ್ಲ.',
  );
  String get estimateOnly => _t(
    'Estimate only, confirm at your post office.',
    'ಇದು ಅಂದಾಜು ಮಾತ್ರ, ನಿಮ್ಮ ಅಂಚೆ ಕಚೇರಿಯಲ್ಲಿ ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',
  );

  // Navigation
  String get home => _t('Home', 'ಮುಖಪುಟ');
  String get compare => _t('Compare', 'ಹೋಲಿಕೆ');
  String get myAccounts => _t('My accounts', 'ನನ್ನ ಖಾತೆಗಳು');
  String get navAccounts => _t('Accounts', 'ಖಾತೆಗಳು');
  String get staff => _t('Staff', 'ಸಿಬ್ಬಂದಿ');
  String get settings => _t('Settings', 'ಸೆಟ್ಟಿಂಗ್ಸ್');

  // Home
  String get currentRates => _t('Current rates', 'ಈಗಿನ ಬಡ್ಡಿ ದರಗಳು');
  String validFrom(String date) => _t('Valid from $date', '$date ರಿಂದ ಜಾರಿ');
  String perYear(String rate) => _t('$rate% a year', 'ವಾರ್ಷಿಕ $rate%');
  String get closedForNew =>
      _t('Closed for new accounts', 'ಹೊಸ ಖಾತೆಗಳಿಗೆ ಮುಚ್ಚಲಾಗಿದೆ');

  // Schemes
  String schemeName(Scheme s) => switch (s) {
    Scheme.sb => _t('Savings Account', 'ಉಳಿತಾಯ ಖಾತೆ'),
    Scheme.rd => _t('Recurring Deposit', 'ಆವರ್ತ ಠೇವಣಿ'),
    Scheme.td1 => _t('Time Deposit 1 year', 'ಅವಧಿ ಠೇವಣಿ 1 ವರ್ಷ'),
    Scheme.td2 => _t('Time Deposit 2 years', 'ಅವಧಿ ಠೇವಣಿ 2 ವರ್ಷ'),
    Scheme.td3 => _t('Time Deposit 3 years', 'ಅವಧಿ ಠೇವಣಿ 3 ವರ್ಷ'),
    Scheme.td5 => _t('Time Deposit 5 years', 'ಅವಧಿ ಠೇವಣಿ 5 ವರ್ಷ'),
    Scheme.mis => _t('Monthly Income Scheme', 'ಮಾಸಿಕ ಆದಾಯ ಯೋಜನೆ'),
    Scheme.scss => _t(
      'Senior Citizens Savings Scheme',
      'ಹಿರಿಯ ನಾಗರಿಕರ ಉಳಿತಾಯ ಯೋಜನೆ',
    ),
    Scheme.nsc => _t('National Savings Certificate', 'ರಾಷ್ಟ್ರೀಯ ಉಳಿತಾಯ ಪತ್ರ'),
    Scheme.kvp => _t('Kisan Vikas Patra', 'ಕಿಸಾನ್ ವಿಕಾಸ ಪತ್ರ'),
    Scheme.ppf => _t('Public Provident Fund', 'ಸಾರ್ವಜನಿಕ ಭವಿಷ್ಯ ನಿಧಿ'),
    Scheme.ssy => _t('Sukanya Samriddhi Account', 'ಸುಕನ್ಯಾ ಸಮೃದ್ಧಿ ಖಾತೆ'),
    Scheme.mssc => _t(
      'Mahila Samman Savings Certificate',
      'ಮಹಿಳಾ ಸಮ್ಮಾನ್ ಉಳಿತಾಯ ಪತ್ರ',
    ),
  };

  String amountLabel(AmountKind k) => switch (k) {
    AmountKind.balance => _t('Balance (₹)', 'ಶಿಲ್ಕು (₹)'),
    AmountKind.lumpSum => _t('Deposit (₹)', 'ಠೇವಣಿ (₹)'),
    AmountKind.monthly => _t('Monthly instalment (₹)', 'ಮಾಸಿಕ ಕಂತು (₹)'),
    AmountKind.yearly => _t('Yearly deposit (₹)', 'ವಾರ್ಷಿಕ ಠೇವಣಿ (₹)'),
  };

  // Calculator
  String get openingDate => _t('Opening date', 'ಖಾತೆ ತೆರೆದ ದಿನಾಂಕ');
  String get rate => _t('Interest rate (% a year)', 'ಬಡ್ಡಿ ದರ (ವಾರ್ಷಿಕ %)');
  String get rateFromTable => _t(
    'From the rate table; change it if your account has a different rate.',
    'ದರ ಪಟ್ಟಿಯಿಂದ; ನಿಮ್ಮ ಖಾತೆಯ ದರ ಬೇರೆ ಇದ್ದರೆ ಬದಲಿಸಿ.',
  );
  String get rateMissing => _t(
    'No rate in the table for this date. Type the rate from your passbook.',
    'ಈ ದಿನಾಂಕಕ್ಕೆ ದರ ಪಟ್ಟಿಯಲ್ಲಿ ಇಲ್ಲ. ಪಾಸ್‌ಬುಕ್‌ನಲ್ಲಿರುವ ದರ ನಮೂದಿಸಿ.',
  );
  String get rateFloats => _t(
    'This rate changes every quarter; the projection uses today\'s rate.',
    'ಈ ದರ ಪ್ರತಿ ತ್ರೈಮಾಸಿಕ ಬದಲಾಗುತ್ತದೆ; ಇಂದಿನ ದರದಲ್ಲಿ ಲೆಕ್ಕ ಮಾಡಲಾಗಿದೆ.',
  );
  String get jointAccount => _t('Joint account', 'ಜಂಟಿ ಖಾತೆ');
  String get depositorAge => _t('Depositor\'s age', 'ಠೇವಣಿದಾರರ ವಯಸ್ಸು');
  String get girlAge => _t('Girl\'s age at opening', 'ತೆರೆಯುವಾಗ ಮಗುವಿನ ವಯಸ್ಸು');
  String get calculate => _t('Calculate', 'ಲೆಕ್ಕ ಮಾಡಿ');
  String get enterAmount => _t('Enter an amount', 'ಮೊತ್ತ ನಮೂದಿಸಿ');
  String get enterRate => _t('Enter the rate', 'ದರ ನಮೂದಿಸಿ');
  String get ppfNote => _t(
    'Assumes the deposit is made by 5 April every year.',
    'ಪ್ರತಿ ವರ್ಷ ಏಪ್ರಿಲ್ 5ರೊಳಗೆ ಠೇವಣಿ ಮಾಡಲಾಗುತ್ತದೆ ಎಂದು ಭಾವಿಸಲಾಗಿದೆ.',
  );
  String get rdNote => _t(
    'Assumes every instalment is paid on time.',
    'ಎಲ್ಲಾ ಕಂತುಗಳನ್ನು ಸಮಯಕ್ಕೆ ಪಾವತಿಸಲಾಗುತ್ತದೆ ಎಂದು ಭಾವಿಸಲಾಗಿದೆ.',
  );

  String issue(Issue i, Scheme s, {String? max}) => switch (i) {
    Issue.belowMin => _t(
      'Minimum is ₹${s.minAmount}.',
      'ಕನಿಷ್ಠ ₹${s.minAmount}.',
    ),
    Issue.aboveMax => _t('Maximum is $max.', 'ಗರಿಷ್ಠ $max.'),
    Issue.notMultiple => _t(
      'Amount must be in multiples of ₹${s.multipleOf}.',
      'ಮೊತ್ತ ₹${s.multipleOf}ರ ಗುಣಕದಲ್ಲಿರಬೇಕು.',
    ),
    Issue.msscClosed => _t(
      'MSSC took deposits only until 31-03-2025. Use it for existing accounts.',
      'MSSC ಠೇವಣಿ 31-03-2025ರವರೆಗೆ ಮಾತ್ರ. ಈಗಿರುವ ಖಾತೆಗಳಿಗೆ ಮಾತ್ರ ಬಳಸಿ.',
    ),
    Issue.scssAge => _t(
      'SCSS needs age 60+ (55+ for retired civilians, 50+ for retired defence staff).',
      'SCSSಗೆ 60+ ವಯಸ್ಸು ಬೇಕು (ನಿವೃತ್ತ ನಾಗರಿಕ ನೌಕರರಿಗೆ 55+, ರಕ್ಷಣಾ ನಿವೃತ್ತರಿಗೆ 50+).',
    ),
    Issue.scssEarlyRetiree => _t(
      'Below 60: only retirees, within 3 months of getting retirement benefits, up to that amount.',
      '60ಕ್ಕಿಂತ ಕಡಿಮೆ: ನಿವೃತ್ತಿ ಸೌಲಭ್ಯ ಪಡೆದ 3 ತಿಂಗಳೊಳಗೆ, ಆ ಮೊತ್ತದವರೆಗೆ ಮಾತ್ರ.',
    ),
    Issue.ssyGirlAge => _t(
      'SSY can be opened only for a girl below 10 years.',
      'SSY ಖಾತೆ 10 ವರ್ಷದೊಳಗಿನ ಹೆಣ್ಣು ಮಗುವಿಗೆ ಮಾತ್ರ.',
    ),
    Issue.noJoint => _t(
      'Joint accounts are not allowed in this scheme.',
      'ಈ ಯೋಜನೆಯಲ್ಲಿ ಜಂಟಿ ಖಾತೆ ಇಲ್ಲ.',
    ),
    Issue.noMinor => _t(
      'A minor cannot open this account.',
      'ಅಪ್ರಾಪ್ತರು ಈ ಖಾತೆ ತೆರೆಯುವಂತಿಲ್ಲ.',
    ),
  };

  // Result
  String get result => _t('Result', 'ಫಲಿತಾಂಶ');
  String get maturityValue =>
      _t('Total at maturity', 'ಮುಕ್ತಾಯದಲ್ಲಿ ಒಟ್ಟು ಮೊತ್ತ');
  String get totalReceived => _t(
    'Total received (deposit + interest)',
    'ಒಟ್ಟು ಪಡೆಯುವ ಮೊತ್ತ (ಠೇವಣಿ + ಬಡ್ಡಿ)',
  );
  String get totalDeposit => _t('Total deposit', 'ಒಟ್ಟು ಠೇವಣಿ');
  String get totalInterest => _t('Total interest', 'ಒಟ್ಟು ಬಡ್ಡಿ');
  String get maturityDate => _t('Maturity date', 'ಮುಕ್ತಾಯ ದಿನಾಂಕ');
  String payout(Payout p) => switch (p) {
    Payout.monthly => _t('Monthly interest', 'ಮಾಸಿಕ ಬಡ್ಡಿ'),
    Payout.quarterly => _t('Quarterly interest', 'ತ್ರೈಮಾಸಿಕ ಬಡ್ಡಿ'),
    Payout.yearly => _t('Yearly interest', 'ವಾರ್ಷಿಕ ಬಡ್ಡಿ'),
  };
  String get yearlyInterestSb =>
      _t('Interest for one year', 'ಒಂದು ವರ್ಷದ ಬಡ್ಡಿ');
  String rateUsed(String rate, String? from) => from == null
      ? _t('Rate used: $rate%', 'ಬಳಸಿದ ದರ: $rate%')
      : _t(
          'Rate used: $rate% (valid from $from)',
          'ಬಳಸಿದ ದರ: $rate% ($from ರಿಂದ ಜಾರಿ)',
        );
  String get yearWise => _t('Year-wise table', 'ವರ್ಷವಾರು ಪಟ್ಟಿ');
  String get year => _t('Year', 'ವರ್ಷ');
  String get deposit => _t('Deposit', 'ಠೇವಣಿ');
  String get interest => _t('Interest', 'ಬಡ್ಡಿ');
  String get balance => _t('Balance', 'ಶಿಲ್ಕು');
  String get fyInterest => _t(
    'Taxable interest per financial year',
    'ಆರ್ಥಿಕ ವರ್ಷವಾರು ತೆರಿಗೆಗೆ ಒಳಪಡುವ ಬಡ್ಡಿ',
  );
  String get fy => _t('Financial year', 'ಆರ್ಥಿಕ ವರ್ಷ');
  String get nscTaxNote => _t(
    'NSC: interest of years 1–4 counts as reinvested for section 80C.',
    'NSC: 1–4ನೇ ವರ್ಷದ ಬಡ್ಡಿ 80C ಅಡಿಯಲ್ಲಿ ಮರುಹೂಡಿಕೆ ಎಂದು ಪರಿಗಣಿತ.',
  );
  String get saveAccount => _t('Save account', 'ಖಾತೆ ಉಳಿಸಿ');
  String get saved => _t('Saved to My accounts', 'ನನ್ನ ಖಾತೆಗಳಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ');
  String get share => _t('Share', 'ಹಂಚಿಕೊಳ್ಳಿ');
  String get shareFailed => _t(
    'Could not open sharing. Please try again.',
    'ಹಂಚಿಕೊಳ್ಳಲು ಆಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
  );
  String get cancel => _t('Cancel', 'ರದ್ದು');
  String get accountName => _t('Name for this account', 'ಈ ಖಾತೆಗೆ ಹೆಸರು');
  String get accountNameHint =>
      _t('e.g. Amma TD, Ravi RD', 'ಉದಾ: ಅಮ್ಮನ TD, ರವಿ RD');
  String get save => _t('Save', 'ಉಳಿಸಿ');

  // Premature closure / extension
  String get prematureClosure => _t('Premature closure', 'ಅವಧಿಪೂರ್ವ ಮುಕ್ತಾಯ');
  String get closingDate => _t('Closing date', 'ಮುಚ್ಚುವ ದಿನಾಂಕ');
  String get payable => _t('Amount payable', 'ಪಾವತಿಸುವ ಮೊತ್ತ');
  String get interestAllowed => _t('Interest allowed', 'ಅನುಮತಿಸಿದ ಬಡ್ಡಿ');
  String get alreadyPaid =>
      _t('Interest already paid', 'ಈಗಾಗಲೇ ಪಾವತಿಸಿದ ಬಡ್ಡಿ');
  String get deduction => _t('Deduction', 'ಕಡಿತ');
  String closureRule(ClosureRule r, {int? months, String? rate}) => switch (r) {
    ClosureRule.notYet => _t(
      'Not allowed before $months months.',
      '$months ತಿಂಗಳ ಮೊದಲು ಅನುಮತಿ ಇಲ್ಲ.',
    ),
    ClosureRule.notAllowed => _t(
      'Premature closure is allowed only on death of the holder or by court order.',
      'ಖಾತೆದಾರರ ಮರಣ ಅಥವಾ ನ್ಯಾಯಾಲಯದ ಆದೇಶದ ಮೇಲೆ ಮಾತ್ರ ಅವಧಿಪೂರ್ವ ಮುಕ್ತಾಯ.',
    ),
    ClosureRule.useWithdrawal => _t(
      'Use the withdrawal rules below.',
      'ಕೆಳಗಿನ ಹಿಂಪಡೆಯುವ ನಿಯಮಗಳನ್ನು ನೋಡಿ.',
    ),
    ClosureRule.afterMaturity => _t(
      'On or after maturity: full value.',
      'ಮುಕ್ತಾಯದ ನಂತರ: ಪೂರ್ಣ ಮೊತ್ತ.',
    ),
    ClosureRule.tdSbRate => _t(
      '6–12 months: savings account rate ($rate%).',
      '6–12 ತಿಂಗಳು: ಉಳಿತಾಯ ಖಾತೆ ದರ ($rate%).',
    ),
    ClosureRule.tdMinus2 => _t(
      'After 1 year: TD rate minus 2% ($rate%).',
      '1 ವರ್ಷದ ನಂತರ: TD ದರದಲ್ಲಿ 2% ಕಡಿತ ($rate%).',
    ),
    ClosureRule.td5NewSbRate => _t(
      '5-year TD opened on/after 09-11-2023, after 4 years: savings rate ($rate%).',
      '09-11-2023ರ ನಂತರ ತೆರೆದ 5 ವರ್ಷದ TD, 4 ವರ್ಷದ ನಂತರ: ಉಳಿತಾಯ ದರ ($rate%).',
    ),
    ClosureRule.td5OldMinus2 => _t(
      '5-year TD opened before 09-11-2023: 3-year TD rate minus 2% ($rate%).',
      '09-11-2023ರ ಮೊದಲು ತೆರೆದ 5 ವರ್ಷದ TD: 3 ವರ್ಷದ TD ದರದಲ್ಲಿ 2% ಕಡಿತ ($rate%).',
    ),
    ClosureRule.rdSbRate => _t(
      'After 3 years: savings account rate ($rate%).',
      '3 ವರ್ಷದ ನಂತರ: ಉಳಿತಾಯ ಖಾತೆ ದರ ($rate%).',
    ),
    ClosureRule.misDeduct => _t(
      '1–3 years: 2% of the deposit deducted; after 3 years: 1%.',
      '1–3 ವರ್ಷ: ಠೇವಣಿಯ 2% ಕಡಿತ; 3 ವರ್ಷದ ನಂತರ: 1%.',
    ),
    ClosureRule.scssRecover => _t(
      'Before 1 year: interest paid is recovered from the deposit.',
      '1 ವರ್ಷದ ಮೊದಲು: ಪಾವತಿಸಿದ ಬಡ್ಡಿಯನ್ನು ಠೇವಣಿಯಿಂದ ವಸೂಲಿ.',
    ),
    ClosureRule.scssDeduct => _t(
      '1–2 years: 1.5% deducted; after 2 years: 1%. Extended accounts: no deduction after 1 year.',
      '1–2 ವರ್ಷ: 1.5% ಕಡಿತ; 2 ವರ್ಷದ ನಂತರ: 1%. ವಿಸ್ತರಿಸಿದ ಖಾತೆ: 1 ವರ್ಷದ ನಂತರ ಕಡಿತ ಇಲ್ಲ.',
    ),
    ClosureRule.kvpTable => _t(
      'After 2½ years, as per the official table (estimated here).',
      '2½ ವರ್ಷದ ನಂತರ, ಅಧಿಕೃತ ಪಟ್ಟಿಯಂತೆ (ಇಲ್ಲಿ ಅಂದಾಜು).',
    ),
    ClosureRule.msscMinus2 => _t(
      'After 6 months: rate minus 2% ($rate%).',
      '6 ತಿಂಗಳ ನಂತರ: ದರದಲ್ಲಿ 2% ಕಡಿತ ($rate%).',
    ),
  };
  String get extension => _t('Extension options', 'ವಿಸ್ತರಣೆ ಆಯ್ಕೆಗಳು');
  String extensionKind(ExtensionKind k) => switch (k) {
    ExtensionKind.ppfWithDeposits => _t(
      'Extend 5 years with deposits',
      'ಠೇವಣಿಯೊಂದಿಗೆ 5 ವರ್ಷ ವಿಸ್ತರಣೆ',
    ),
    ExtensionKind.ppfWithoutDeposits => _t(
      'Extend 5 years without deposits',
      'ಠೇವಣಿ ಇಲ್ಲದೆ 5 ವರ್ಷ ವಿಸ್ತರಣೆ',
    ),
    ExtensionKind.scss3Years => _t(
      'Extend 3 years (rate on maturity date, no penalty)',
      '3 ವರ್ಷ ವಿಸ್ತರಣೆ (ಮುಕ್ತಾಯ ದಿನದ ದರ, ದಂಡ ಇಲ್ಲ)',
    ),
    ExtensionKind.rd5Years => _t(
      'Continue 5 more years',
      'ಇನ್ನೂ 5 ವರ್ಷ ಮುಂದುವರಿಸಿ',
    ),
  };
  String get withdrawals => _t('Partial withdrawal', 'ಭಾಗಶಃ ಹಿಂಪಡೆಯುವಿಕೆ');
  String get ppfWithdrawalNote => _t(
    'Once a year from year 7: up to 50% of the lower of the balance 4 years earlier or last year.',
    '7ನೇ ವರ್ಷದಿಂದ ವರ್ಷಕ್ಕೊಮ್ಮೆ: 4 ವರ್ಷ ಹಿಂದಿನ ಅಥವಾ ಕಳೆದ ವರ್ಷದ ಶಿಲ್ಕಿನಲ್ಲಿ ಕಡಿಮೆಯದರ 50%ವರೆಗೆ.',
  );
  String get ssyWithdrawalNote => _t(
    'After the girl turns 18 (or passes 10th): up to 50% of last year\'s balance.',
    'ಮಗುವಿಗೆ 18 ತುಂಬಿದ ನಂತರ (ಅಥವಾ 10ನೇ ತರಗತಿ ಪಾಸಾದ ನಂತರ): ಕಳೆದ ವರ್ಷದ ಶಿಲ್ಕಿನ 50%ವರೆಗೆ.',
  );
  String get limit => _t('Limit', 'ಮಿತಿ');

  // Compare
  String get compareTitle =>
      _t('Same amount, about 5 years', 'ಒಂದೇ ಮೊತ್ತ, ಸುಮಾರು 5 ವರ್ಷ');
  String get compareNote => _t(
    'RD: the amount is split into 60 monthly instalments. MIS and TD pay interest out; the total includes it.',
    'RD: ಮೊತ್ತವನ್ನು 60 ಮಾಸಿಕ ಕಂತುಗಳಾಗಿ ಹಂಚಲಾಗಿದೆ. MIS ಮತ್ತು TD ಬಡ್ಡಿ ಪಾವತಿಸುತ್ತವೆ; ಒಟ್ಟಿನಲ್ಲಿ ಸೇರಿದೆ.',
  );
  String get amount => _t('Amount (₹)', 'ಮೊತ್ತ (₹)');
  String get scheme => _t('Scheme', 'ಯೋಜನೆ');
  String get period => _t('Period', 'ಅವಧಿ');
  String months(int m) => _t('$m months', '$m ತಿಂಗಳು');

  // Accounts
  String get noAccounts => _t(
    'No saved accounts. Calculate a scheme and tap "Save account".',
    'ಉಳಿಸಿದ ಖಾತೆಗಳಿಲ್ಲ. ಲೆಕ್ಕ ಮಾಡಿ "ಖಾತೆ ಉಳಿಸಿ" ಒತ್ತಿ.',
  );
  String get portfolio => _t('Total deposited', 'ಒಟ್ಟು ಠೇವಣಿ');
  String get portfolioAtMaturity =>
      _t('Total at maturity', 'ಮುಕ್ತಾಯದಲ್ಲಿ ಒಟ್ಟು');
  String get upcoming => _t('Upcoming maturities', 'ಮುಂಬರುವ ಮುಕ್ತಾಯಗಳು');
  String get reminder => _t('Remind me', 'ನೆನಪಿಸಿ');
  String get reminderHelp => _t(
    'Notification 7 days and 1 day before maturity',
    'ಮುಕ್ತಾಯಕ್ಕೆ 7 ದಿನ ಮತ್ತು 1 ದಿನ ಮೊದಲು ಸೂಚನೆ',
  );
  String get delete => _t('Delete', 'ಅಳಿಸಿ');
  String get matured => _t('Matured', 'ಮುಕ್ತಾಯವಾಗಿದೆ');
  String inDays(int d) => _t('in $d days', '$d ದಿನಗಳಲ್ಲಿ');
  String get permissionDenied => _t(
    'Notifications are off for this app. Turn them on in phone settings.',
    'ಈ ಆ್ಯಪ್‌ಗೆ ಸೂಚನೆಗಳು ಆಫ್ ಆಗಿವೆ. ಫೋನ್ ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಆನ್ ಮಾಡಿ.',
  );
  String reminderTitle(String name) =>
      _t('$name matures soon', '$name ಶೀಘ್ರದಲ್ಲಿ ಮುಕ್ತಾಯ');
  String reminderBody(String date, String amount) =>
      _t('Maturity on $date: $amount', '$date ರಂದು ಮುಕ್ತಾಯ: $amount');
  String get reminderChannel => _t('Maturity reminders', 'ಮುಕ್ತಾಯ ಜ್ಞಾಪನೆಗಳು');

  // Staff
  String get eligibility => _t('Eligibility check', 'ಅರ್ಹತೆ ಪರಿಶೀಲನೆ');
  String get documents => _t('Documents needed', 'ಬೇಕಾದ ದಾಖಲೆಗಳು');
  String get quickCalc => _t('Quick calculation', 'ತ್ವರಿತ ಲೆಕ್ಕ');
  String get eligible => _t('Eligible', 'ಅರ್ಹರು');
  String get age => _t('Age', 'ವಯಸ್ಸು');
  String holding(Holding h) => switch (h) {
    Holding.single => _t('Single', 'ಏಕ'),
    Holding.joint => _t('Joint', 'ಜಂಟಿ'),
    Holding.minor => _t('Minor', 'ಅಪ್ರಾಪ್ತ'),
  };
  String get check => _t('Check', 'ಪರಿಶೀಲಿಸಿ');
  String doc(Doc d) => switch (d) {
    Doc.form => _t('Account opening form', 'ಖಾತೆ ತೆರೆಯುವ ಅರ್ಜಿ'),
    Doc.kyc => _t('KYC form', 'KYC ಅರ್ಜಿ'),
    Doc.aadhaar => _t('Aadhaar', 'ಆಧಾರ್'),
    Doc.pan => _t(
      'PAN (or Form 60); must be given within 6 months',
      'PAN (ಅಥವಾ ಫಾರ್ಮ್ 60); 6 ತಿಂಗಳೊಳಗೆ ನೀಡಬೇಕು',
    ),
    Doc.photo => _t('Passport-size photo', 'ಪಾಸ್‌ಪೋರ್ಟ್ ಅಳತೆಯ ಫೋಟೋ'),
    Doc.payInSlip => _t('Pay-in slip', 'ಪೇ-ಇನ್ ಸ್ಲಿಪ್'),
    Doc.addressProof => _t(
      'Address proof, if different from Aadhaar',
      'ವಿಳಾಸ ಪುರಾವೆ, ಆಧಾರ್‌ಗಿಂತ ಬೇರೆ ಇದ್ದರೆ',
    ),
    Doc.guardianKyc => _t('Guardian\'s KYC', 'ಪೋಷಕರ KYC'),
    Doc.birthCert => _t('Child\'s birth certificate', 'ಮಗುವಿನ ಜನನ ಪ್ರಮಾಣಪತ್ರ'),
    Doc.ageProof => _t('Age proof', 'ವಯಸ್ಸಿನ ಪುರಾವೆ'),
    Doc.retirementProof => _t(
      'Below 60: retirement benefit papers',
      '60ಕ್ಕಿಂತ ಕಡಿಮೆ: ನಿವೃತ್ತಿ ಸೌಲಭ್ಯದ ದಾಖಲೆಗಳು',
    ),
    Doc.jointKyc => _t('KYC of each joint holder', 'ಪ್ರತಿ ಜಂಟಿ ಖಾತೆದಾರರ KYC'),
    Doc.nomination => _t('Nomination form', 'ನಾಮನಿರ್ದೇಶನ ಅರ್ಜಿ'),
  };
  String get howToOpen => _t('How to open the account', 'ಖಾತೆ ತೆರೆಯುವ ವಿಧಾನ');

  /// Counter steps to open [s] for a [h] holder, in order.
  List<String> openingSteps(Scheme s, Holding h) {
    if (s == Scheme.mssc) {
      return [
        _t(
          'Closed for new accounts since 1 April 2025. Use this app only for existing accounts.',
          '1 ಏಪ್ರಿಲ್ 2025ರಿಂದ ಹೊಸ ಖಾತೆಗಳಿಗೆ ಮುಚ್ಚಲಾಗಿದೆ. ಈಗಿನ ಖಾತೆಗಳಿಗೆ ಮಾತ್ರ ಈ ಆ್ಯಪ್ ಬಳಸಿ.',
        ),
      ];
    }
    final certificate = s == Scheme.nsc || s == Scheme.kvp;
    return [
      _t(
        'Check eligibility and the deposit limit above.',
        'ಮೇಲೆ ಅರ್ಹತೆ ಮತ್ತು ಠೇವಣಿ ಮಿತಿ ಪರಿಶೀಲಿಸಿ.',
      ),
      _t(
        'Fill the Account Opening Form (one common form for all schemes) and tick ${s.code}.',
        'ಖಾತೆ ತೆರೆಯುವ ಅರ್ಜಿ (ಎಲ್ಲಾ ಯೋಜನೆಗಳಿಗೆ ಒಂದೇ ಸಾಮಾನ್ಯ ಅರ್ಜಿ) ತುಂಬಿ, ${s.code} ಆಯ್ಕೆ ಮಾಡಿ.',
      ),
      _t(
        'New customer: fill the KYC form. Take Aadhaar, PAN (or Form 60) and a photo.',
        'ಹೊಸ ಗ್ರಾಹಕರು: KYC ಅರ್ಜಿ ತುಂಬಿ. ಆಧಾರ್, PAN (ಅಥವಾ ಫಾರ್ಮ್ 60) ಮತ್ತು ಫೋಟೋ ಪಡೆಯಿರಿ.',
      ),
      if (h == Holding.joint)
        _t(
          'Joint: up to 3 adults; each one gives KYC and signs. For SCSS the joint holder can only be the spouse.',
          'ಜಂಟಿ: 3 ವಯಸ್ಕರವರೆಗೆ; ಪ್ರತಿಯೊಬ್ಬರೂ KYC ನೀಡಿ ಸಹಿ ಮಾಡಬೇಕು. SCSSನಲ್ಲಿ ಜಂಟಿ ಖಾತೆದಾರರು ಪತಿ/ಪತ್ನಿ ಮಾತ್ರ.',
        ),
      if (h == Holding.minor)
        _t(
          'Minor: the guardian signs the form and gives their own KYC, with the child\'s birth certificate.',
          'ಅಪ್ರಾಪ್ತ: ಪೋಷಕರು ಅರ್ಜಿಗೆ ಸಹಿ ಮಾಡಿ ತಮ್ಮ KYC ಮತ್ತು ಮಗುವಿನ ಜನನ ಪ್ರಮಾಣಪತ್ರ ನೀಡಬೇಕು.',
        ),
      ...switch (s) {
        Scheme.sb => [_t('Minimum ₹500 to open.', 'ತೆರೆಯಲು ಕನಿಷ್ಠ ₹500.')],
        Scheme.rd => [
          _t(
            'Take the first instalment now. Opened on days 1–15: pay each month by the 15th; opened on the 16th or later: by the month end.',
            'ಮೊದಲ ಕಂತು ಈಗಲೇ ಪಡೆಯಿರಿ. 1–15ರಂದು ತೆರೆದರೆ ಪ್ರತಿ ತಿಂಗಳು 15ರೊಳಗೆ; 16 ಅಥವಾ ನಂತರ ತೆರೆದರೆ ತಿಂಗಳ ಕೊನೆಯೊಳಗೆ ಕಟ್ಟಬೇಕು.',
          ),
          _t(
            'A missed month costs a default fee of ₹1 for every ₹100.',
            'ತಪ್ಪಿದ ತಿಂಗಳಿಗೆ ಪ್ರತಿ ₹100ಕ್ಕೆ ₹1 ದಂಡ.',
          ),
        ],
        Scheme.td1 || Scheme.td2 || Scheme.td3 || Scheme.td5 => [
          _t(
            'Choose the term: 1, 2, 3 or 5 years. Only the 5-year TD counts for section 80C.',
            'ಅವಧಿ ಆಯ್ಕೆ ಮಾಡಿ: 1, 2, 3 ಅಥವಾ 5 ವರ್ಷ. 5 ವರ್ಷದ TD ಮಾತ್ರ 80C ಸೆಕ್ಷನ್‌ಗೆ ಅರ್ಹ.',
          ),
        ],
        Scheme.mis => [
          _t(
            'Link a Post Office savings account; monthly interest is credited there.',
            'ಅಂಚೆ ಉಳಿತಾಯ ಖಾತೆ ಜೋಡಿಸಿ; ಮಾಸಿಕ ಬಡ್ಡಿ ಅದಕ್ಕೆ ಜಮೆಯಾಗುತ್ತದೆ.',
          ),
        ],
        Scheme.scss => [
          _t(
            'Link a Post Office savings account for the quarterly interest.',
            'ತ್ರೈಮಾಸಿಕ ಬಡ್ಡಿಗಾಗಿ ಅಂಚೆ ಉಳಿತಾಯ ಖಾತೆ ಜೋಡಿಸಿ.',
          ),
          _t(
            'Below 60: take the retirement benefit papers; open within 3 months of getting the benefits.',
            '60ಕ್ಕಿಂತ ಕಡಿಮೆ: ನಿವೃತ್ತಿ ಸೌಲಭ್ಯದ ದಾಖಲೆ ಪಡೆಯಿರಿ; ಸೌಲಭ್ಯ ಪಡೆದ 3 ತಿಂಗಳೊಳಗೆ ತೆರೆಯಬೇಕು.',
          ),
        ],
        Scheme.ppf => [
          _t(
            'Only one PPF account per person. Deposit ₹500 to ₹1.5 lakh in each financial year.',
            'ಒಬ್ಬರಿಗೆ ಒಂದೇ PPF ಖಾತೆ. ಪ್ರತಿ ಹಣಕಾಸು ವರ್ಷ ₹500ರಿಂದ ₹1.5 ಲಕ್ಷ ಠೇವಣಿ.',
          ),
        ],
        Scheme.ssy => [
          _t(
            'Opened by the parent or guardian for a girl below 10, with her birth certificate. At most two girls per family (more only for twins or triplets).',
            'ಪೋಷಕರು 10 ವರ್ಷದೊಳಗಿನ ಹೆಣ್ಣು ಮಗುವಿಗೆ ಜನನ ಪ್ರಮಾಣಪತ್ರದೊಂದಿಗೆ ತೆರೆಯುತ್ತಾರೆ. ಕುಟುಂಬಕ್ಕೆ ಗರಿಷ್ಠ ಇಬ್ಬರು ಹೆಣ್ಣು ಮಕ್ಕಳು (ಅವಳಿ/ತ್ರಿವಳಿಗೆ ಮಾತ್ರ ಹೆಚ್ಚು).',
          ),
          _t(
            'Deposit ₹250 to ₹1.5 lakh in each financial year.',
            'ಪ್ರತಿ ಹಣಕಾಸು ವರ್ಷ ₹250ರಿಂದ ₹1.5 ಲಕ್ಷ ಠೇವಣಿ.',
          ),
        ],
        _ => const <String>[],
      },
      _t(
        'Fill the nomination (it can also be added later).',
        'ನಾಮನಿರ್ದೇಶನ ತುಂಬಿ (ನಂತರವೂ ಸೇರಿಸಬಹುದು).',
      ),
      _t(
        'Take the deposit in cash or by cheque with a pay-in slip. With a cheque, the account opens on the date the cheque is credited.',
        'ನಗದು ಅಥವಾ ಚೆಕ್ ಮೂಲಕ ಪೇ-ಇನ್ ಸ್ಲಿಪ್‌ನೊಂದಿಗೆ ಠೇವಣಿ ಪಡೆಯಿರಿ. ಚೆಕ್ ಆದರೆ, ಹಣ ಜಮೆಯಾದ ದಿನಾಂಕದಿಂದ ಖಾತೆ ತೆರೆಯುತ್ತದೆ.',
      ),
      certificate
          ? _t(
              'Verify the originals and return them, open the account in CBS and issue the certificate.',
              'ಮೂಲ ದಾಖಲೆ ಪರಿಶೀಲಿಸಿ ಹಿಂತಿರುಗಿಸಿ, CBSನಲ್ಲಿ ಖಾತೆ ತೆರೆದು ಪ್ರಮಾಣಪತ್ರ ನೀಡಿ.',
            )
          : _t(
              'Verify the originals and return them, open the account in CBS and give the passbook.',
              'ಮೂಲ ದಾಖಲೆ ಪರಿಶೀಲಿಸಿ ಹಿಂತಿರುಗಿಸಿ, CBSನಲ್ಲಿ ಖಾತೆ ತೆರೆದು ಪಾಸ್‌ಬುಕ್ ನೀಡಿ.',
            ),
    ];
  }

  // Scheme details
  String get schemeDetails => _t('Scheme details', 'ಯೋಜನೆಯ ವಿವರಗಳು');
  String get fullDetails => _t('Full scheme details', 'ಯೋಜನೆಯ ಪೂರ್ಣ ವಿವರ');
  String get shareDetails =>
      _t('Share details with customer', 'ಗ್ರಾಹಕರಿಗೆ ವಿವರ ಕಳುಹಿಸಿ');

  /// Main facts of [s] as (label, text) pairs. [rate] is today's rate,
  /// [kvpMonths] the KVP doubling period at that rate.
  List<(SchemeFact, String)> schemeFacts(
    Scheme s,
    String rate, {
    int kvpMonths = 115,
  }) {
    final td = s.isTd;
    final common = _t(
      'One adult, up to 3 adults jointly, a guardian for a minor, or a minor of 10 or more in their own name.',
      'ಒಬ್ಬ ವಯಸ್ಕ, 3 ವಯಸ್ಕರವರೆಗೆ ಜಂಟಿಯಾಗಿ, ಅಪ್ರಾಪ್ತರ ಪರವಾಗಿ ಪೋಷಕರು, ಅಥವಾ 10 ವರ್ಷ ಮೇಲ್ಪಟ್ಟ ಅಪ್ರಾಪ್ತರು ತಮ್ಮ ಹೆಸರಲ್ಲಿ.',
    );
    final taxable = _t(
      'Interest is taxable; no 80C benefit.',
      'ಬಡ್ಡಿಗೆ ತೆರಿಗೆ ಇದೆ; 80C ಲಾಭ ಇಲ್ಲ.',
    );
    final eee = _t(
      'Fully tax-free (EEE): the deposit counts for 80C; interest and maturity are not taxed.',
      'ಸಂಪೂರ್ಣ ತೆರಿಗೆ ಮುಕ್ತ (EEE): ಠೇವಣಿ 80Cಗೆ ಅರ್ಹ; ಬಡ್ಡಿ ಮತ್ತು ಮುಕ್ತಾಯ ಮೊತ್ತಕ್ಕೆ ತೆರಿಗೆ ಇಲ್ಲ.',
    );
    final pledge = _t(
      'Can be pledged as security for a loan.',
      'ಸಾಲಕ್ಕೆ ಭದ್ರತೆಯಾಗಿ ಅಡವಿಡಬಹುದು.',
    );
    final lump1000 = _t(
      'Minimum ₹1,000, in multiples of ₹100; no upper limit.',
      'ಕನಿಷ್ಠ ₹1,000, ₹100ರ ಗುಣಕಗಳಲ್ಲಿ; ಗರಿಷ್ಠ ಮಿತಿ ಇಲ್ಲ.',
    );
    return switch (s) {
      Scheme.sb => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, on the lowest balance between the 10th and the month end; credited every 31 March.',
            'ವಾರ್ಷಿಕ $rate%, ಪ್ರತಿ ತಿಂಗಳ 10ರಿಂದ ತಿಂಗಳ ಕೊನೆಯವರೆಗಿನ ಕನಿಷ್ಠ ಶಿಲ್ಕಿನ ಮೇಲೆ; ಪ್ರತಿ ಮಾರ್ಚ್ 31ರಂದು ಜಮೆ.',
          ),
        ),
        (
          SchemeFact.deposit,
          _t(
            'Minimum balance ₹500; no upper limit.',
            'ಕನಿಷ್ಠ ಶಿಲ್ಕು ₹500; ಗರಿಷ್ಠ ಮಿತಿ ಇಲ್ಲ.',
          ),
        ),
        (SchemeFact.who, common),
        (
          SchemeFact.tax,
          _t(
            'Interest up to ₹10,000 a year is tax-free under 80TTA (senior citizens: up to ₹50,000 under 80TTB).',
            'ವರ್ಷಕ್ಕೆ ₹10,000ವರೆಗಿನ ಬಡ್ಡಿ 80TTA ಅಡಿ ತೆರಿಗೆ ಮುಕ್ತ (ಹಿರಿಯ ನಾಗರಿಕರು: 80TTB ಅಡಿ ₹50,000ವರೆಗೆ).',
          ),
        ),
        (
          SchemeFact.closure,
          _t('Can be closed at any time.', 'ಯಾವಾಗ ಬೇಕಾದರೂ ಮುಚ್ಚಬಹುದು.'),
        ),
      ],
      Scheme.rd => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded every quarter; paid with the deposits at maturity.',
            'ವಾರ್ಷಿಕ $rate%, ಪ್ರತಿ ತ್ರೈಮಾಸಿಕ ಚಕ್ರಬಡ್ಡಿ; ಮುಕ್ತಾಯದಲ್ಲಿ ಠೇವಣಿಯೊಂದಿಗೆ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (
          SchemeFact.deposit,
          _t(
            'Minimum ₹100 a month, in multiples of ₹10; no upper limit. A missed month costs ₹1 for every ₹100.',
            'ತಿಂಗಳಿಗೆ ಕನಿಷ್ಠ ₹100, ₹10ರ ಗುಣಕಗಳಲ್ಲಿ; ಗರಿಷ್ಠ ಮಿತಿ ಇಲ್ಲ. ತಪ್ಪಿದ ತಿಂಗಳಿಗೆ ಪ್ರತಿ ₹100ಕ್ಕೆ ₹1 ದಂಡ.',
          ),
        ),
        (SchemeFact.who, common),
        (SchemeFact.tax, taxable),
        (
          SchemeFact.closure,
          _t(
            'Allowed after 3 years; interest at the savings account rate.',
            '3 ವರ್ಷದ ನಂತರ ಅನುಮತಿ; ಉಳಿತಾಯ ಖಾತೆ ದರದಲ್ಲಿ ಬಡ್ಡಿ.',
          ),
        ),
        (
          SchemeFact.loan,
          _t(
            'After 12 instalments: a loan of up to 50% of the balance, at the RD rate plus 2%.',
            '12 ಕಂತುಗಳ ನಂತರ: ಶಿಲ್ಕಿನ 50%ವರೆಗೆ ಸಾಲ, RD ದರಕ್ಕಿಂತ 2% ಹೆಚ್ಚು ಬಡ್ಡಿಯಲ್ಲಿ.',
          ),
        ),
        (
          SchemeFact.maturity,
          _t(
            'Can be continued for 5 more years.',
            'ಇನ್ನೂ 5 ವರ್ಷ ಮುಂದುವರಿಸಬಹುದು.',
          ),
        ),
      ],
      _ when td => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded every quarter and paid out every year.',
            'ವಾರ್ಷಿಕ $rate%, ತ್ರೈಮಾಸಿಕ ಚಕ್ರಬಡ್ಡಿ, ಪ್ರತಿ ವರ್ಷ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (SchemeFact.deposit, lump1000),
        (SchemeFact.who, common),
        (
          SchemeFact.tax,
          s == Scheme.td5
              ? _t(
                  'The deposit counts for 80C (5-year TD only); interest is taxable.',
                  'ಠೇವಣಿ 80Cಗೆ ಅರ್ಹ (5 ವರ್ಷದ TD ಮಾತ್ರ); ಬಡ್ಡಿಗೆ ತೆರಿಗೆ ಇದೆ.',
                )
              : taxable,
        ),
        (
          SchemeFact.closure,
          _t(
                'Not before 6 months. 6–12 months: savings account rate. After 1 year: TD rate minus 2%.',
                '6 ತಿಂಗಳ ಮೊದಲು ಇಲ್ಲ. 6–12 ತಿಂಗಳು: ಉಳಿತಾಯ ಖಾತೆ ದರ. 1 ವರ್ಷದ ನಂತರ: TD ದರದಲ್ಲಿ 2% ಕಡಿತ.',
              ) +
              (s == Scheme.td5
                  ? _t(
                      ' Opened on/after 09-11-2023: closure only after 4 years, at the savings rate.',
                      ' 09-11-2023ರ ನಂತರ ತೆರೆದದ್ದು: 4 ವರ್ಷದ ನಂತರ ಮಾತ್ರ, ಉಳಿತಾಯ ದರದಲ್ಲಿ.',
                    )
                  : ''),
        ),
        (
          SchemeFact.maturity,
          _t(
            'Paid out, or extended for the same term on request.',
            'ಪಾವತಿ, ಅಥವಾ ಕೋರಿಕೆಯ ಮೇರೆಗೆ ಅದೇ ಅವಧಿಗೆ ವಿಸ್ತರಣೆ.',
          ),
        ),
      ],
      Scheme.mis => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, paid every month to the linked Post Office savings account.',
            'ವಾರ್ಷಿಕ $rate%, ಪ್ರತಿ ತಿಂಗಳು ಜೋಡಿಸಿದ ಅಂಚೆ ಉಳಿತಾಯ ಖಾತೆಗೆ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (
          SchemeFact.deposit,
          _t(
            'Minimum ₹1,000, in multiples of ₹1,000; up to ₹9 lakh single, ₹15 lakh joint.',
            'ಕನಿಷ್ಠ ₹1,000, ₹1,000ರ ಗುಣಕಗಳಲ್ಲಿ; ಏಕ ಖಾತೆ ₹9 ಲಕ್ಷ, ಜಂಟಿ ₹15 ಲಕ್ಷವರೆಗೆ.',
          ),
        ),
        (SchemeFact.who, common),
        (SchemeFact.tax, taxable),
        (
          SchemeFact.closure,
          _t(
            'Not before 1 year. 1–3 years: 2% of the deposit deducted; after 3 years: 1%.',
            '1 ವರ್ಷದ ಮೊದಲು ಇಲ್ಲ. 1–3 ವರ್ಷ: ಠೇವಣಿಯ 2% ಕಡಿತ; 3 ವರ್ಷದ ನಂತರ: 1%.',
          ),
        ),
        (
          SchemeFact.maturity,
          _t('The deposit is returned.', 'ಠೇವಣಿ ಹಿಂತಿರುಗಿಸಲಾಗುತ್ತದೆ.'),
        ),
      ],
      Scheme.scss => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, paid every quarter (1 April, 1 July, 1 October, 1 January) to the linked savings account.',
            'ವಾರ್ಷಿಕ $rate%, ಪ್ರತಿ ತ್ರೈಮಾಸಿಕ (ಏಪ್ರಿಲ್ 1, ಜುಲೈ 1, ಅಕ್ಟೋಬರ್ 1, ಜನವರಿ 1) ಜೋಡಿಸಿದ ಉಳಿತಾಯ ಖಾತೆಗೆ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (
          SchemeFact.deposit,
          _t(
            'Minimum ₹1,000, in multiples of ₹1,000; up to ₹30 lakh across all SCSS accounts.',
            'ಕನಿಷ್ಠ ₹1,000, ₹1,000ರ ಗುಣಕಗಳಲ್ಲಿ; ಎಲ್ಲಾ SCSS ಖಾತೆಗಳು ಸೇರಿ ₹30 ಲಕ್ಷವರೆಗೆ.',
          ),
        ),
        (
          SchemeFact.who,
          _t(
            'Age 60 or more. Retired civilians aged 55–60 and retired defence staff aged 50–60, within 3 months of getting retirement benefits. Joint account only with the spouse.',
            '60 ಅಥವಾ ಹೆಚ್ಚು ವಯಸ್ಸು. 55–60ರ ನಿವೃತ್ತ ನಾಗರಿಕ ನೌಕರರು ಮತ್ತು 50–60ರ ರಕ್ಷಣಾ ನಿವೃತ್ತರು, ನಿವೃತ್ತಿ ಸೌಲಭ್ಯ ಪಡೆದ 3 ತಿಂಗಳೊಳಗೆ. ಜಂಟಿ ಖಾತೆ ಪತಿ/ಪತ್ನಿಯೊಂದಿಗೆ ಮಾತ್ರ.',
          ),
        ),
        (
          SchemeFact.tax,
          _t(
            'The deposit counts for 80C; interest is taxable.',
            'ಠೇವಣಿ 80Cಗೆ ಅರ್ಹ; ಬಡ್ಡಿಗೆ ತೆರಿಗೆ ಇದೆ.',
          ),
        ),
        (
          SchemeFact.closure,
          _t(
            'Any time. Before 1 year: interest paid is recovered. 1–2 years: 1.5% deducted; after 2 years: 1%.',
            'ಯಾವಾಗ ಬೇಕಾದರೂ. 1 ವರ್ಷದ ಮೊದಲು: ಪಾವತಿಸಿದ ಬಡ್ಡಿ ವಸೂಲಿ. 1–2 ವರ್ಷ: 1.5% ಕಡಿತ; 2 ವರ್ಷದ ನಂತರ: 1%.',
          ),
        ),
        (
          SchemeFact.maturity,
          _t(
            'Can be extended in blocks of 3 years.',
            '3 ವರ್ಷಗಳ ಅವಧಿಗೆ ಪದೇ ಪದೇ ವಿಸ್ತರಿಸಬಹುದು.',
          ),
        ),
      ],
      Scheme.nsc => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded yearly; paid at maturity.',
            'ವಾರ್ಷಿಕ $rate%, ವಾರ್ಷಿಕ ಚಕ್ರಬಡ್ಡಿ; ಮುಕ್ತಾಯದಲ್ಲಿ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (SchemeFact.deposit, lump1000),
        (SchemeFact.who, common),
        (
          SchemeFact.tax,
          _t(
            'The deposit counts for 80C; interest of years 1–4 counts as reinvested for 80C. Interest is taxable.',
            'ಠೇವಣಿ 80Cಗೆ ಅರ್ಹ; 1–4ನೇ ವರ್ಷದ ಬಡ್ಡಿ 80C ಅಡಿ ಮರುಹೂಡಿಕೆ ಎಂದು ಪರಿಗಣಿತ. ಬಡ್ಡಿಗೆ ತೆರಿಗೆ ಇದೆ.',
          ),
        ),
        (SchemeFact.closure, closureRule(ClosureRule.notAllowed)),
        (SchemeFact.loan, pledge),
      ],
      Scheme.kvp => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded yearly; the money doubles in $kvpMonths months.',
            'ವಾರ್ಷಿಕ $rate%, ವಾರ್ಷಿಕ ಚಕ್ರಬಡ್ಡಿ; $kvpMonths ತಿಂಗಳಲ್ಲಿ ಹಣ ದ್ವಿಗುಣ.',
          ),
        ),
        (SchemeFact.tenure, months(kvpMonths)),
        (SchemeFact.deposit, lump1000),
        (SchemeFact.who, common),
        (SchemeFact.tax, taxable),
        (
          SchemeFact.closure,
          _t(
            'After 2½ years, as per the official table.',
            '2½ ವರ್ಷದ ನಂತರ, ಅಧಿಕೃತ ಪಟ್ಟಿಯಂತೆ.',
          ),
        ),
        (SchemeFact.loan, pledge),
      ],
      Scheme.ppf => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded yearly and credited every 31 March. The rate can change every quarter.',
            'ವಾರ್ಷಿಕ $rate%, ವಾರ್ಷಿಕ ಚಕ್ರಬಡ್ಡಿ, ಪ್ರತಿ ಮಾರ್ಚ್ 31ರಂದು ಜಮೆ. ದರ ಪ್ರತಿ ತ್ರೈಮಾಸಿಕ ಬದಲಾಗಬಹುದು.',
          ),
        ),
        (
          SchemeFact.tenure,
          _t(
            '15 full financial years after the year of opening.',
            'ತೆರೆದ ವರ್ಷದ ನಂತರ 15 ಪೂರ್ಣ ಹಣಕಾಸು ವರ್ಷ.',
          ),
        ),
        (
          SchemeFact.deposit,
          _t(
            '₹500 to ₹1.5 lakh in each financial year, in multiples of ₹50.',
            'ಪ್ರತಿ ಹಣಕಾಸು ವರ್ಷ ₹500ರಿಂದ ₹1.5 ಲಕ್ಷ, ₹50ರ ಗುಣಕಗಳಲ್ಲಿ.',
          ),
        ),
        (
          SchemeFact.who,
          _t(
            'Any adult, or a guardian for a minor. Only one account per person; no joint accounts.',
            'ಯಾವುದೇ ವಯಸ್ಕರು, ಅಥವಾ ಅಪ್ರಾಪ್ತರ ಪರವಾಗಿ ಪೋಷಕರು. ಒಬ್ಬರಿಗೆ ಒಂದೇ ಖಾತೆ; ಜಂಟಿ ಖಾತೆ ಇಲ್ಲ.',
          ),
        ),
        (SchemeFact.tax, eee),
        (
          SchemeFact.closure,
          _t(
            'After 5 years, only for serious illness, higher education or change of residency; 1% less interest.',
            '5 ವರ್ಷದ ನಂತರ, ಗಂಭೀರ ಅನಾರೋಗ್ಯ, ಉನ್ನತ ಶಿಕ್ಷಣ ಅಥವಾ ನಿವಾಸ ಬದಲಾವಣೆಗೆ ಮಾತ್ರ; 1% ಕಡಿಮೆ ಬಡ್ಡಿ.',
          ),
        ),
        (
          SchemeFact.loan,
          _t(
                'Loan from the 3rd to the 6th year. ',
                '3ರಿಂದ 6ನೇ ವರ್ಷದವರೆಗೆ ಸಾಲ. ',
              ) +
              ppfWithdrawalNote,
        ),
        (
          SchemeFact.maturity,
          _t(
            'Can be extended in blocks of 5 years, with or without deposits.',
            'ಠೇವಣಿಯೊಂದಿಗೆ ಅಥವಾ ಇಲ್ಲದೆ 5 ವರ್ಷಗಳ ಅವಧಿಗೆ ವಿಸ್ತರಿಸಬಹುದು.',
          ),
        ),
      ],
      Scheme.ssy => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded yearly. The rate can change every quarter.',
            'ವಾರ್ಷಿಕ $rate%, ವಾರ್ಷಿಕ ಚಕ್ರಬಡ್ಡಿ. ದರ ಪ್ರತಿ ತ್ರೈಮಾಸಿಕ ಬದಲಾಗಬಹುದು.',
          ),
        ),
        (
          SchemeFact.tenure,
          _t(
            '21 years from opening; deposits for the first 15 years.',
            'ತೆರೆದಂದಿನಿಂದ 21 ವರ್ಷ; ಮೊದಲ 15 ವರ್ಷ ಠೇವಣಿ.',
          ),
        ),
        (
          SchemeFact.deposit,
          _t(
            '₹250 to ₹1.5 lakh in each financial year, in multiples of ₹50.',
            'ಪ್ರತಿ ಹಣಕಾಸು ವರ್ಷ ₹250ರಿಂದ ₹1.5 ಲಕ್ಷ, ₹50ರ ಗುಣಕಗಳಲ್ಲಿ.',
          ),
        ),
        (
          SchemeFact.who,
          _t(
            'A parent or guardian, for a girl below 10. One account per girl; at most two girls per family (more only for twins or triplets).',
            'ಪೋಷಕರು, 10 ವರ್ಷದೊಳಗಿನ ಹೆಣ್ಣು ಮಗುವಿಗೆ. ಒಂದು ಮಗುವಿಗೆ ಒಂದು ಖಾತೆ; ಕುಟುಂಬಕ್ಕೆ ಗರಿಷ್ಠ ಇಬ್ಬರು (ಅವಳಿ/ತ್ರಿವಳಿಗೆ ಮಾತ್ರ ಹೆಚ್ಚು).',
          ),
        ),
        (SchemeFact.tax, eee),
        (
          SchemeFact.closure,
          _t(
            'After 5 years for serious illness or death of the guardian; from age 18 for the girl\'s marriage.',
            '5 ವರ್ಷದ ನಂತರ ಗಂಭೀರ ಅನಾರೋಗ್ಯ ಅಥವಾ ಪೋಷಕರ ಮರಣದಲ್ಲಿ; 18 ವರ್ಷದ ನಂತರ ಮಗುವಿನ ಮದುವೆಗೆ.',
          ),
        ),
        (SchemeFact.loan, ssyWithdrawalNote),
      ],
      Scheme.mssc => [
        (
          SchemeFact.interest,
          _t(
            '$rate% a year, compounded every quarter; paid at maturity.',
            'ವಾರ್ಷಿಕ $rate%, ತ್ರೈಮಾಸಿಕ ಚಕ್ರಬಡ್ಡಿ; ಮುಕ್ತಾಯದಲ್ಲಿ ಪಾವತಿ.',
          ),
        ),
        (SchemeFact.tenure, tenureOf(s)),
        (
          SchemeFact.deposit,
          _t(
            '₹1,000 to ₹2 lakh, in multiples of ₹100.',
            '₹1,000ರಿಂದ ₹2 ಲಕ್ಷ, ₹100ರ ಗುಣಕಗಳಲ್ಲಿ.',
          ),
        ),
        (
          SchemeFact.who,
          _t(
            'Women, and guardians for girls. Closed for new accounts since 1 April 2025.',
            'ಮಹಿಳೆಯರು, ಮತ್ತು ಹೆಣ್ಣು ಮಕ್ಕಳ ಪರವಾಗಿ ಪೋಷಕರು. 1 ಏಪ್ರಿಲ್ 2025ರಿಂದ ಹೊಸ ಖಾತೆಗಳಿಗೆ ಮುಚ್ಚಲಾಗಿದೆ.',
          ),
        ),
        (SchemeFact.tax, taxable),
        (
          SchemeFact.closure,
          _t(
            'After 6 months: rate minus 2%.',
            '6 ತಿಂಗಳ ನಂತರ: ದರದಲ್ಲಿ 2% ಕಡಿತ.',
          ),
        ),
        (
          SchemeFact.loan,
          _t(
            'One withdrawal of up to 40% of the balance after 1 year.',
            '1 ವರ್ಷದ ನಂತರ ಶಿಲ್ಕಿನ 40%ವರೆಗೆ ಒಮ್ಮೆ ಹಿಂಪಡೆಯಬಹುದು.',
          ),
        ),
      ],
      _ => const [],
    };
  }

  String factLabel(SchemeFact f) => switch (f) {
    SchemeFact.interest => _t('Interest', 'ಬಡ್ಡಿ'),
    SchemeFact.tenure => tenure,
    SchemeFact.deposit => _t('Deposit', 'ಠೇವಣಿ'),
    SchemeFact.who => _t('Who can open', 'ಯಾರು ತೆರೆಯಬಹುದು'),
    SchemeFact.tax => _t('Tax', 'ತೆರಿಗೆ'),
    SchemeFact.closure => _t('Early closure', 'ಅವಧಿಪೂರ್ವ ಮುಕ್ತಾಯ'),
    SchemeFact.loan => _t('Loan / withdrawal', 'ಸಾಲ / ಹಿಂಪಡೆಯುವಿಕೆ'),
    SchemeFact.maturity => _t('At maturity', 'ಮುಕ್ತಾಯದಲ್ಲಿ'),
  };

  String get documentsNote => _t(
    'General list; check the latest SB order at your office.',
    'ಸಾಮಾನ್ಯ ಪಟ್ಟಿ; ನಿಮ್ಮ ಕಚೇರಿಯಲ್ಲಿ ಇತ್ತೀಚಿನ SB ಆದೇಶ ನೋಡಿ.',
  );

  // Settings
  String get language => _t('Language', 'ಭಾಷೆ');
  String get theme => _t('Theme', 'ಥೀಮ್');
  String get themeSystem => _t('System', 'ಸಿಸ್ಟಮ್');
  String get themeLight => _t('Light', 'ಬೆಳಕು');
  String get themeDark => _t('Dark', 'ಕತ್ತಲು');
  String get about => _t('About', 'ಕುರಿತು');
  String get rateVersion => _t('Rate table', 'ದರ ಪಟ್ಟಿ');
  String get privacy => _t('Privacy policy', 'ಗೌಪ್ಯತಾ ನೀತಿ');
  String get shareApp => _t('Share this app', 'ಈ ಆ್ಯಪ್ ಹಂಚಿಕೊಳ್ಳಿ');
  String get shareAppSub =>
      _t('Send the download link', 'ಡೌನ್‌ಲೋಡ್ ಲಿಂಕ್ ಕಳುಹಿಸಿ');
  String get copyLink => _t('Copy link', 'ಲಿಂಕ್ ನಕಲಿಸಿ');
  String get linkCopied => _t('Link copied', 'ಲಿಂಕ್ ನಕಲಿಸಲಾಗಿದೆ');
  String shareAppText(String url) => _t(
    'PO Calculator: offline Post Office interest calculator in Kannada and English. Download: $url',
    'ಪಿಒ ಕ್ಯಾಲ್ಕುಲೇಟರ್: ಕನ್ನಡ ಮತ್ತು ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿ ಆಫ್‌ಲೈನ್ ಅಂಚೆ ಕಚೇರಿ ಬಡ್ಡಿ ಕ್ಯಾಲ್ಕುಲೇಟರ್. ಡೌನ್‌ಲೋಡ್: $url',
  );
  String get privacyText => _t(
    'PO Calculator works fully offline. It has no internet permission, collects no data and shares nothing. Saved accounts stay only on this phone and are removed when you uninstall the app.',
    'ಪಿಒ ಕ್ಯಾಲ್ಕುಲೇಟರ್ ಸಂಪೂರ್ಣ ಆಫ್‌ಲೈನ್. ಇಂಟರ್ನೆಟ್ ಅನುಮತಿ ಇಲ್ಲ, ಯಾವುದೇ ಮಾಹಿತಿ ಸಂಗ್ರಹಿಸುವುದಿಲ್ಲ ಅಥವಾ ಹಂಚುವುದಿಲ್ಲ. ಉಳಿಸಿದ ಖಾತೆಗಳು ಈ ಫೋನ್‌ನಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತವೆ.',
  );
  String get version => _t('Version', 'ಆವೃತ್ತಿ');
  String get ok => _t('OK', 'ಸರಿ');

  // Redesign: home groups, charts, labels
  String get groupDeposits => _t('Deposits', 'ಠೇವಣಿಗಳು');
  String get groupIncome => _t('Regular income', 'ನಿಯಮಿತ ಆದಾಯ');
  String get groupCertificates => _t('Savings certificates', 'ಉಳಿತಾಯ ಪತ್ರಗಳು');
  String get groupLongTerm =>
      _t('Long term & tax saving', 'ದೀರ್ಘಾವಧಿ ಮತ್ತು ತೆರಿಗೆ ಉಳಿತಾಯ');
  String get highestRate => _t('Highest rate now', 'ಈಗಿನ ಅತ್ಯಧಿಕ ದರ');
  String get tapToCalculate =>
      _t('Tap a scheme to calculate', 'ಲೆಕ್ಕ ಮಾಡಲು ಯೋಜನೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ');
  String get yourMoney => _t('Your deposit', 'ನಿಮ್ಮ ಠೇವಣಿ');
  String get interestEarned => _t('Interest earned', 'ಗಳಿಸಿದ ಬಡ್ಡಿ');
  String get growth => _t('Growth year by year', 'ವರ್ಷವಾರು ಬೆಳವಣಿಗೆ');
  String get breakup => _t('Deposit and interest', 'ಠೇವಣಿ ಮತ್ತು ಬಡ್ಡಿ');
  String get aYear => _t('a year', 'ವಾರ್ಷಿಕ');
  String get quickAmounts => _t('Quick amounts', 'ತ್ವರಿತ ಮೊತ್ತಗಳು');
  String get highestReturn => _t('Highest return', 'ಅತ್ಯಧಿಕ ಆದಾಯ');
  String get tenure => _t('Tenure', 'ಅವಧಿ');
  String years(int y) => _t(y == 1 ? '1 year' : '$y years', '$y ವರ್ಷ');
  String tenureOf(Scheme s) => switch (s) {
    Scheme.sb => _t('No fixed term', 'ನಿಗದಿತ ಅವಧಿ ಇಲ್ಲ'),
    Scheme.kvp => months(115),
    Scheme.mssc => years(2),
    _ => years(s.tenureMonths ~/ 12),
  };
  String percentDone(int p) => _t('$p% of term done', 'ಅವಧಿಯ $p% ಮುಗಿದಿದೆ');
  String get details => _t('Details', 'ವಿವರಗಳು');
  String get saveShare => _t('Save or share', 'ಉಳಿಸಿ ಅಥವಾ ಹಂಚಿಕೊಳ್ಳಿ');
}
