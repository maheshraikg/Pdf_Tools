/// The kinds of sum the generator can make. Every kind has a non-negative
/// whole-number answer (division with remainder also has a remainder).
enum Op {
  add,
  sub,
  mul,
  div,
  divRem,
  square,
  cube,
  percent,
  fracOf,
  fracAdd,
  after,
  before,
  tenMore,
  tenLess,
  addMul, // a + b × c
  mulSub, // a × b − c
}

/// An answer: a whole number, plus a remainder for [Op.divRem].
class Answer {
  const Answer(this.value, [this.remainder]);

  final int value;
  final int? remainder;

  bool get isNegative => value < 0 || (remainder ?? 0) < 0;

  @override
  bool operator ==(Object other) => other is Answer && other.value == value && other.remainder == remainder;

  @override
  int get hashCode => Object.hash(value, remainder);

  @override
  String toString() => remainder == null ? '$value' : '$value r$remainder';
}

/// One generated sum. [a], [b] and [c] are the operands; their meaning
/// depends on [op] (see [Question.fromParts]).
class Question {
  Question._(this.topicId, this.op, this.a, this.b, this.c, this.answer);

  /// Builds a question and computes its answer.
  ///
  /// * add/sub/mul: a ∘ b
  /// * div/divRem: a ÷ b
  /// * square/cube: aⁿ
  /// * percent: a % of b
  /// * fracOf: a/b of c
  /// * fracAdd: a/c + b/c (answer is the numerator over c)
  /// * after/before/tenMore/tenLess: about a
  /// * addMul: a + b × c; mulSub: a × b − c
  factory Question.fromParts(String topicId, Op op, int a, [int b = 0, int c = 0]) {
    final Answer ans;
    switch (op) {
      case Op.add:
        ans = Answer(a + b);
      case Op.sub:
        ans = Answer(a - b);
      case Op.mul:
        ans = Answer(a * b);
      case Op.div:
        ans = Answer(a ~/ b);
      case Op.divRem:
        ans = Answer(a ~/ b, a % b);
      case Op.square:
        ans = Answer(a * a);
      case Op.cube:
        ans = Answer(a * a * a);
      case Op.percent:
        ans = Answer(a * b ~/ 100);
      case Op.fracOf:
        ans = Answer(c ~/ b * a);
      case Op.fracAdd:
        ans = Answer(a + b);
      case Op.after:
        ans = Answer(a + 1);
      case Op.before:
        ans = Answer(a - 1);
      case Op.tenMore:
        ans = Answer(a + 10);
      case Op.tenLess:
        ans = Answer(a - 10);
      case Op.addMul:
        ans = Answer(a + b * c);
      case Op.mulSub:
        ans = Answer(a * b - c);
    }
    return Question._(topicId, op, a, b, c, ans);
  }

  /// Rebuilds a question from a [factKey] such as `mul:7:8:0`.
  static Question? fromKey(String topicId, String key) {
    final p = key.split(':');
    if (p.length != 4) return null;
    final op = Op.values.where((o) => o.name == p[0]).firstOrNull;
    final a = int.tryParse(p[1]), b = int.tryParse(p[2]), c = int.tryParse(p[3]);
    if (op == null || a == null || b == null || c == null) return null;
    return Question.fromParts(topicId, op, a, b, c);
  }

  final String topicId;
  final Op op;
  final int a;
  final int b;
  final int c;
  final Answer answer;

  /// Identifies the maths fact, e.g. `mul:7:8:0` for 7 × 8.
  String get factKey => '${op.name}:$a:$b:$c';

  bool get needsRemainder => op == Op.divRem;

  /// Whether this question uses a sentence (localised) rather than symbols.
  bool get isWordQuestion =>
      op == Op.after || op == Op.before || op == Op.tenMore || op == Op.tenLess || op == Op.percent || op == Op.fracOf;

  /// Language-neutral symbolic form, e.g. `7 × 8`. Word questions return a
  /// compact symbolic form too (used in lists); screens localise them.
  String get expression {
    switch (op) {
      case Op.add:
        return '$a + $b';
      case Op.sub:
        return '$a − $b';
      case Op.mul:
        return '$a × $b';
      case Op.div:
      case Op.divRem:
        return '$a ÷ $b';
      case Op.square:
        return '$a²';
      case Op.cube:
        return '$a³';
      case Op.percent:
        return '$a% × $b';
      case Op.fracOf:
        return '$a/$b × $c';
      case Op.fracAdd:
        return '$a/$c + $b/$c';
      case Op.after:
        return '$a + 1';
      case Op.before:
        return '$a − 1';
      case Op.tenMore:
        return '$a + 10';
      case Op.tenLess:
        return '$a − 10';
      case Op.addMul:
        return '$a + $b × $c';
      case Op.mulSub:
        return '$a × $b − $c';
    }
  }

  @override
  String toString() => '$expression = $answer';
}
