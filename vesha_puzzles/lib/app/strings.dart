/// UI strings in English, Kannada and Tulu (Kannada script).
///
/// Where no Tulu string is given, Kannada is shown. Every Tulu string is
/// listed in docs/CONTENT_TO_REVIEW.md for a native speaker's check.
library;

import 'package:flutter/widgets.dart';

import '../jigsaw/cut.dart';
import '../packs/content.dart';
import 'scope.dart';

class S {
  const S(this.lang);
  final Lang lang;

  static S of(BuildContext context) => S(AppScope.of(context).settings.lang);

  String _t(String en, String kn, [String? tcy]) => switch (lang) {
    Lang.en => en,
    Lang.kn => kn,
    Lang.tcy => tcy ?? kn,
  };

  String get appTitle => _t('Vesha Puzzles', 'ವೇಷ ಪಝಲ್', 'ವೇಷ ಪಝಲ್');
  String get tagline => _t(
    'Jigsaw stories from Karnataka',
    'ಕರ್ನಾಟಕದ ಕಥೆಗಳ ಜಿಗ್ಸಾ ಪಝಲ್',
    'ಕರ್ನಾಟಕದ ಕತೆಲೆನ ಜಿಗ್ಸಾ ಪಝಲ್',
  );

  // Home
  String get puzzles => _t('Puzzles', 'ಪಝಲ್‌ಗಳು', 'ಪಝಲ್‌ಲು');
  String get daily => _t('Daily puzzle', 'ಇಂದಿನ ಪಝಲ್', 'ಇನಿತ ಪಝಲ್');
  String get dailyDone => _t('Done for today!', 'ಇಂದಿನದು ಮುಗಿಯಿತು!', 'ಇನಿತ ಮುಗಿಂಡ್!');
  String get play => _t('Play', 'ಆಡಿ', 'ಗೊಬ್ಬುಲೆ');
  String get continueGame => _t('Continue', 'ಮುಂದುವರಿಸಿ');
  String get dressUp => _t('Dress-up', 'ವೇಷ ತೊಡಿಸಿ');
  String get achievements => _t('Achievements', 'ಸಾಧನೆಗಳು');
  String get progress => _t('Progress', 'ಪ್ರಗತಿ');
  String get settings => _t('Settings', 'ಸೆಟ್ಟಿಂಗ್ಸ್');
  String get credits => _t('Credits', 'ಕೃತಜ್ಞತೆಗಳು');
  String get stories => _t('Stories', 'ಕಥೆಗಳು', 'ಕತೆಲು');
  String streakDays(int n) =>
      _t('$n-day streak', '$n ದಿನಗಳ ಸರಣಿ', '$n ದಿನೊತ ಸರಣಿ');
  String get eventNow => _t('Happening now', 'ಈಗ ನಡೆಯುತ್ತಿದೆ', 'ಇತ್ತೆ ನಡತೊಂದುಂಡು');
  String get featured => _t('Featured', 'ವಿಶೇಷ');

  // Library
  String get locked => _t('Locked', 'ಲಾಕ್ ಆಗಿದೆ');
  String get unlockHint => _t(
    'Finish the puzzle before this one to unlock it.',
    'ಇದನ್ನು ತೆರೆಯಲು ಹಿಂದಿನ ಪಝಲ್ ಮುಗಿಸಿ.',
  );
  String get placeholderArt => _t('Placeholder art', 'ತಾತ್ಕಾಲಿಕ ಚಿತ್ರ');
  String puzzleCount(int done, int total) =>
      _t('$done of $total done', '$total ರಲ್ಲಿ $done ಮುಗಿದಿದೆ');
  String percentDone(int pct) => _t('$pct% done', '$pct% ಮುಗಿದಿದೆ');

  // Difficulty
  String get chooseDifficulty => _t('Choose difficulty', 'ಕಷ್ಟದ ಮಟ್ಟ ಆಯ್ಕೆಮಾಡಿ');
  String difficulty(Difficulty d) => switch (d) {
    Difficulty.easy => _t('Easy', 'ಸುಲಭ'),
    Difficulty.medium => _t('Medium', 'ಮಧ್ಯಮ'),
    Difficulty.hard => _t('Hard', 'ಕಠಿಣ'),
    Difficulty.expert => _t('Expert', 'ಪರಿಣತ'),
  };
  String pieces(int n) => _t('$n pieces', '$n ತುಂಡುಗಳು', '$n ತುಂಡುಲು');
  String get resume => _t('Resume', 'ಮುಂದುವರಿಸಿ');
  String get startOver => _t('Start over', 'ಮತ್ತೆ ಆರಂಭಿಸಿ');
  String best(String time) => _t('Best $time', 'ಉತ್ತಮ $time');

  // Puzzle
  String get hint => _t('Hint', 'ಸುಳಿವು');
  String hintsLeft(int n) => _t('$n hints left', '$n ಸುಳಿವು ಉಳಿದಿವೆ');
  String get noHints => _t('No hints left', 'ಸುಳಿವುಗಳು ಮುಗಿದಿವೆ');
  String get ghost => _t('Show picture', 'ಚಿತ್ರ ತೋರಿಸಿ');
  String get edgesOnly => _t('Edge pieces', 'ಅಂಚಿನ ತುಂಡುಗಳು');
  String get zoomIn => _t('Zoom in', 'ದೊಡ್ಡದು');
  String get zoomOut => _t('Zoom out', 'ಚಿಕ್ಕದು');
  String get fit => _t('Fit to screen', 'ಪರದೆಗೆ ಹೊಂದಿಸಿ');
  String placed(int a, int b) => _t('$a / $b placed', '$a / $b ಜೋಡಿಸಲಾಗಿದೆ');
  String get preview => _t('Preview', 'ಮುನ್ನೋಟ');
  String get restart => _t('Restart', 'ಮರುಆರಂಭ');
  String get restartConfirm => _t(
    'Start this puzzle again? Your progress on it will be lost.',
    'ಈ ಪಝಲ್ ಮತ್ತೆ ಆರಂಭಿಸಬೇಕೇ? ಈಗಿನ ಪ್ರಗತಿ ಅಳಿಸುತ್ತದೆ.',
  );
  String get cancel => _t('Cancel', 'ರದ್ದು');
  String get ok => _t('OK', 'ಸರಿ', 'ಆವು');
  String get trayEmpty => _t('All pieces are on the board', 'ಎಲ್ಲ ತುಂಡುಗಳು ಬೋರ್ಡಿನಲ್ಲಿವೆ');
  String get trayHelp => _t(
    'Drag a piece up onto the board, or tap it. Double-tap a loose piece to send it back.',
    'ತುಂಡನ್ನು ಮೇಲಕ್ಕೆ ಎಳೆಯಿರಿ ಅಥವಾ ಒತ್ತಿ. ಬಿಡಿ ತುಂಡನ್ನು ಎರಡು ಬಾರಿ ಒತ್ತಿದರೆ ಹಿಂದೆ ಹೋಗುತ್ತದೆ.',
  );
  String get loadFailed => _t('Could not open this picture.', 'ಈ ಚಿತ್ರ ತೆರೆಯಲಾಗಲಿಲ್ಲ.');

  // Completion
  String get wellDone => _t('Well done!', 'ಶಹಬ್ಬಾಸ್!', 'ಭಾರೀ ಎಡ್ಡೆ!');
  String time(String t) => _t('Time $t', 'ಸಮಯ $t');
  String hintsUsed(int n) => _t('Hints used: $n', 'ಬಳಸಿದ ಸುಳಿವು: $n');
  String get newBest => _t('New best time!', 'ಹೊಸ ಉತ್ತಮ ಸಮಯ!');
  String get readStory => _t('Read the story', 'ಕಥೆ ಓದಿ', 'ಕತೆ ಓದುಲೆ');
  String get share => _t('Share', 'ಹಂಚಿಕೊಳ್ಳಿ');
  String get playAgain => _t('Play again', 'ಮತ್ತೆ ಆಡಿ');
  String get next => _t('Next puzzle', 'ಮುಂದಿನ ಪಝಲ್');
  String get done => _t('Done', 'ಮುಗಿಯಿತು', 'ಆಂಡ್');
  String shareText(String title, String time) => _t(
    'I finished "$title" in $time on Vesha Puzzles!',
    'ವೇಷ ಪಝಲ್‌ನಲ್ಲಿ "$title" ಅನ್ನು $time ಸಮಯದಲ್ಲಿ ಮುಗಿಸಿದೆ!',
  );
  String get unlockedAchievement => _t('Achievement unlocked', 'ಸಾಧನೆ ತೆರೆಯಿತು');
  String get newStory => _t('New story unlocked', 'ಹೊಸ ಕಥೆ ತೆರೆಯಿತು');

  // Stories
  String get didYouKnow => _t('Did you know?', 'ನಿಮಗೆ ಗೊತ್ತೇ?', 'ಇರೆಗ್ ಗೊತ್ತುಂಡಾ?');
  String get underReview => _t(
    'Draft – awaiting expert review',
    'ಕರಡು – ತಜ್ಞರ ಪರಿಶೀಲನೆ ಬಾಕಿ',
  );
  String get storyLocked => _t(
    'Finish the puzzle to unlock this story.',
    'ಈ ಕಥೆ ತೆರೆಯಲು ಪಝಲ್ ಮುಗಿಸಿ.',
  );
  String get sources => _t('Sources', 'ಆಧಾರಗಳು');

  // Dress-up
  String get none => _t('None', 'ಯಾವುದೂ ಇಲ್ಲ', 'ಒವ್ವಲಾ ಇಜ್ಜಿ');
  String get saveLook => _t('Save look', 'ಉಳಿಸಿ');
  String get lookSaved => _t('Look saved!', 'ಉಳಿಸಲಾಗಿದೆ!');
  String get surprise => _t('Surprise me', 'ಅಚ್ಚರಿ');
  String get reset => _t('Reset', 'ಮರುಹೊಂದಿಸಿ');
  String unlockBy(String puzzle) =>
      _t('Finish "$puzzle" to unlock', '"$puzzle" ಮುಗಿಸಿ ತೆರೆಯಿರಿ');

  // Progress
  String get completedPuzzles => _t('Puzzles finished', 'ಮುಗಿಸಿದ ಪಝಲ್‌ಗಳು');
  String get currentStreak => _t('Daily streak', 'ದೈನಂದಿನ ಸರಣಿ');
  String get bestStreak => _t('Best streak', 'ಉತ್ತಮ ಸರಣಿ');
  String get storiesRead => _t('Stories read', 'ಓದಿದ ಕಥೆಗಳು');
  String get totalHints => _t('Hints used', 'ಬಳಸಿದ ಸುಳಿವುಗಳು');
  String get badges => _t('Event badges', 'ಉತ್ಸವ ಬ್ಯಾಡ್ಜ್‌ಗಳು');

  String achievementTitle(String id, {String? packName}) => switch (id) {
    'first_puzzle' => _t('First picture', 'ಮೊದಲ ಚಿತ್ರ'),
    'five_puzzles' => _t('Five pictures', 'ಐದು ಚಿತ್ರಗಳು'),
    'all_puzzles' => _t('Complete collection', 'ಪೂರ್ಣ ಸಂಗ್ರಹ'),
    'no_hints' => _t('On my own', 'ನಾನೇ ಮಾಡಿದೆ'),
    'expert' => _t('Expert hands', 'ಪರಿಣತ ಕೈಗಳು'),
    'speedy' => _t('Quick as a chende beat', 'ಚೆಂಡೆ ಬಡಿತದಷ್ಟು ವೇಗ'),
    'daily_1' => _t('Daily player', 'ದಿನದ ಆಟಗಾರ'),
    'streak_3' => _t('Three days running', 'ಮೂರು ದಿನ ಸತತ'),
    'streak_7' => _t('A whole week', 'ಇಡೀ ವಾರ'),
    'stories_5' => _t('Story lover', 'ಕಥಾ ಪ್ರೇಮಿ'),
    'dress_up' => _t('Ready for the stage', 'ರಂಗಕ್ಕೆ ಸಿದ್ಧ'),
    'event_badge' => _t('Festival spirit', 'ಹಬ್ಬದ ಸಂಭ್ರಮ'),
    _ when id.startsWith('pack_') => _t(
      'All of ${packName ?? id.substring(5)}',
      '${packName ?? id.substring(5)} ಸಂಪೂರ್ಣ',
    ),
    _ => id,
  };

  String achievementDesc(String id, int goal) => switch (id) {
    'first_puzzle' => _t('Finish your first puzzle.', 'ಮೊದಲ ಪಝಲ್ ಮುಗಿಸಿ.'),
    'five_puzzles' => _t('Finish 5 different puzzles.', '5 ಬೇರೆ ಪಝಲ್‌ಗಳನ್ನು ಮುಗಿಸಿ.'),
    'all_puzzles' => _t('Finish every puzzle.', 'ಎಲ್ಲ ಪಝಲ್‌ಗಳನ್ನು ಮುಗಿಸಿ.'),
    'no_hints' => _t('Finish a puzzle without hints.', 'ಸುಳಿವಿಲ್ಲದೆ ಪಝಲ್ ಮುಗಿಸಿ.'),
    'expert' => _t('Finish an Expert puzzle.', 'ಪರಿಣತ ಮಟ್ಟದ ಪಝಲ್ ಮುಗಿಸಿ.'),
    'speedy' => _t(
      'Finish Medium or harder in under 5 minutes.',
      'ಮಧ್ಯಮ ಅಥವಾ ಕಠಿಣ ಪಝಲ್ 5 ನಿಮಿಷದೊಳಗೆ ಮುಗಿಸಿ.',
    ),
    'daily_1' => _t('Finish a daily puzzle.', 'ಒಂದು ದೈನಂದಿನ ಪಝಲ್ ಮುಗಿಸಿ.'),
    'streak_3' => _t('Daily puzzles 3 days in a row.', 'ಸತತ 3 ದಿನ ದೈನಂದಿನ ಪಝಲ್.'),
    'streak_7' => _t('Daily puzzles 7 days in a row.', 'ಸತತ 7 ದಿನ ದೈನಂದಿನ ಪಝಲ್.'),
    'stories_5' => _t('Read 5 stories.', '5 ಕಥೆಗಳನ್ನು ಓದಿ.'),
    'dress_up' => _t('Save a dress-up look.', 'ಒಂದು ವೇಷ ಉಳಿಸಿ.'),
    'event_badge' => _t(
      'Finish a featured puzzle during a festival event.',
      'ಉತ್ಸವದ ಸಮಯದಲ್ಲಿ ವಿಶೇಷ ಪಝಲ್ ಮುಗಿಸಿ.',
    ),
    _ when id.startsWith('pack_') => _t(
      'Finish all $goal puzzles in the pack.',
      'ಈ ಸಂಗ್ರಹದ ಎಲ್ಲಾ $goal ಪಝಲ್‌ಗಳನ್ನು ಮುಗಿಸಿ.',
    ),
    _ => '',
  };

  // Settings
  String get language => _t('Language', 'ಭಾಷೆ', 'ಬಾಸೆ');
  String get soundEffects => _t('Sound effects', 'ಧ್ವನಿ ಪರಿಣಾಮಗಳು');
  String get music => _t('Music', 'ಸಂಗೀತ');
  String get volume => _t('Volume', 'ಧ್ವನಿ ಮಟ್ಟ');
  String get haptics => _t('Vibration', 'ಕಂಪನ');
  String get ghostDefault => _t('Show faint picture on the board', 'ಬೋರ್ಡಿನಲ್ಲಿ ಮಸುಕು ಚಿತ್ರ ತೋರಿಸಿ');
  String get reduceMotion => _t('Reduce motion', 'ಕಡಿಮೆ ಚಲನೆ');
  String get theme => _t('Theme', 'ಥೀಮ್');
  String get themeSystem => _t('System', 'ಸಿಸ್ಟಮ್');
  String get themeLight => _t('Light', 'ಬೆಳಕು');
  String get themeDark => _t('Dark', 'ಕತ್ತಲು');
  String get guideTips => _t('Tips from Vesha', 'ವೇಷನ ಸಲಹೆಗಳು');
  String get resetProgress => _t('Reset all progress', 'ಎಲ್ಲ ಪ್ರಗತಿ ಅಳಿಸಿ');
  String get resetConfirm => _t(
    'Delete all progress, saved games, streaks and achievements?',
    'ಎಲ್ಲ ಪ್ರಗತಿ, ಉಳಿಸಿದ ಆಟಗಳು, ಸರಣಿ ಮತ್ತು ಸಾಧನೆಗಳನ್ನು ಅಳಿಸಬೇಕೇ?',
  );
  String get delete => _t('Delete', 'ಅಳಿಸಿ');
  String get supportArtists => _t('Support the artists', 'ಕಲಾವಿದರಿಗೆ ಬೆಂಬಲ');
  String get supportUnavailable => _t(
    'Not available in this build.',
    'ಈ ಆವೃತ್ತಿಯಲ್ಲಿ ಲಭ್ಯವಿಲ್ಲ.',
  );
  String get about => _t('About', 'ಬಗ್ಗೆ');
  String get licences => _t('Open-source licences', 'ಮುಕ್ತ ತಂತ್ರಾಂಶ ಪರವಾನಗಿಗಳು');
  String get artCredits => _t('Art', 'ಚಿತ್ರಕಲೆ');
  String get contentCredits => _t('Stories and facts', 'ಕಥೆ ಮತ್ತು ಮಾಹಿತಿ');
  String get contentNote => _t(
    'Stories and cultural notes were drafted for this app and are being '
        'checked by Yakshagana artists and Tulu/Kannada speakers. '
        'Corrections are welcome.',
    'ಕಥೆಗಳು ಮತ್ತು ಸಾಂಸ್ಕೃತಿಕ ಟಿಪ್ಪಣಿಗಳನ್ನು ಈ ಆಪ್‌ಗಾಗಿ ಬರೆಯಲಾಗಿದೆ; '
        'ಯಕ್ಷಗಾನ ಕಲಾವಿದರು ಮತ್ತು ತುಳು/ಕನ್ನಡ ಭಾಷಿಕರು ಪರಿಶೀಲಿಸುತ್ತಿದ್ದಾರೆ. '
        'ತಿದ್ದುಪಡಿಗಳಿಗೆ ಸ್ವಾಗತ.',
  );
  String get soundCredits => _t('Sounds', 'ಧ್ವನಿಗಳು');
  String get soundNote => _t(
    'Placeholder sounds generated for this app (public domain).',
    'ಈ ಆಪ್‌ಗಾಗಿ ರಚಿಸಿದ ತಾತ್ಕಾಲಿಕ ಧ್ವನಿಗಳು (ಸಾರ್ವಜನಿಕ ಸ್ವತ್ತು).',
  );
  String get privacy => _t(
    'No account, no tracking. Progress is stored only on this phone.',
    'ಖಾತೆ ಇಲ್ಲ, ಟ್ರ್ಯಾಕಿಂಗ್ ಇಲ್ಲ. ಪ್ರಗತಿ ಈ ಫೋನಿನಲ್ಲಿ ಮಾತ್ರ.',
  );
}
