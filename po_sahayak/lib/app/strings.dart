/// All user-facing text, in English and Kannada. Nothing is hard-coded in
/// the screens.
library;

import '../domain/engine/closure.dart';
import '../domain/engine/eligibility.dart';
import '../domain/models/scheme.dart';

enum Lang { en, kn }

class S {
  const S(this.lang);
  final Lang lang;

  bool get kn => lang == Lang.kn;
  String _t(String en, String kn) => this.kn ? kn : en;

  // App
  String get appTitle => _t('PO Sahayak', 'ಪಿಒ ಸಹಾಯಕ');
  String get tagline => _t(
    'PO Calculator · Post Office interest',
    'ಪಿಒ ಕ್ಯಾಲ್ಕುಲೇಟರ್ · ಅಂಚೆ ಕಚೇರಿ ಬಡ್ಡಿ',
  );
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
      'Below 60: only retirees, within 1 month of getting retirement benefits, up to that amount.',
      '60ಕ್ಕಿಂತ ಕಡಿಮೆ: ನಿವೃತ್ತಿ ಸೌಲಭ್ಯ ಪಡೆದ 1 ತಿಂಗಳೊಳಗೆ, ಆ ಮೊತ್ತದವರೆಗೆ ಮಾತ್ರ.',
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
  String get privacyText => _t(
    'PO Sahayak works fully offline. It has no internet permission, collects no data and shares nothing. Saved accounts stay only on this phone and are removed when you uninstall the app.',
    'ಪಿಒ ಸಹಾಯಕ ಸಂಪೂರ್ಣ ಆಫ್‌ಲೈನ್. ಇಂಟರ್ನೆಟ್ ಅನುಮತಿ ಇಲ್ಲ, ಯಾವುದೇ ಮಾಹಿತಿ ಸಂಗ್ರಹಿಸುವುದಿಲ್ಲ ಅಥವಾ ಹಂಚುವುದಿಲ್ಲ. ಉಳಿಸಿದ ಖಾತೆಗಳು ಈ ಫೋನ್‌ನಲ್ಲಿ ಮಾತ್ರ ಇರುತ್ತವೆ.',
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
  String growthPct(String p) => _t('+$p%', '+$p%');
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
