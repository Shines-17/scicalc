import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scientific Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.black,
        // 💥 FIX 1: Changed ElevatedButtonData to ElevatedButtonThemeData 💥
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            minimumSize: const Size(60, 60),
          ),
        ),
      ),
      home: const ScientificCalculator(),
    );
  }
}

class ScientificCalculator extends StatefulWidget {
  const ScientificCalculator({super.key});
  @override
  _ScientificCalculatorState createState() => _ScientificCalculatorState();
}

class _ScientificCalculatorState extends State<ScientificCalculator> {
  String input = "";
  String output = "";
  bool degreesMode = true;

  void _append(String s) {
    setState(() => input += s);
  }

  void _clearAll() {
    setState(() {
      input = "";
      output = "";
    });
  }

  void _deleteLast() {
    if (input.isNotEmpty) {
      setState(() => input = input.substring(0, input.length - 1));
    }
  }

  String _fixPower(String expr) {
    while (expr.contains("^")) {
      int i = expr.indexOf("^");

      // Find the Base (left side of ^)
      int l = i - 1;
      if (expr[l] == ')') {
        int count = 1;
        l--;
        while (l >= 0 && count > 0) {
          if (expr[l] == ')') count++;
          if (expr[l] == '(') count--;
          l--;
        }
        l++;
      } else {
        while (l >= 0 && RegExp(r"[0-9a-zA-Z\._]").hasMatch(expr[l])) {
          l--;
        }
        l++;
      }
      String base = expr.substring(l, i);

      int r = i + 1;
      if (expr[r] == '(') {
        int count = 1;
        r++;
        while (r < expr.length && count > 0) {
          if (expr[r] == '(') count++;
          if (expr[r] == ')') count--;
          r++;
        }
      } else {
        // FIX: Ensure r correctly captures the exponent until a non-match or end of string.
        int end = expr.length;
        while (r < end && RegExp(r"[0-9a-zA-Z\._]").hasMatch(expr[r])) {
          r++;
        }
      }
      String exp = expr.substring(i + 1, r);

      // Replace with pow(base, exp)
      expr = expr.substring(0, l) + "pow($base,$exp)" + expr.substring(r);
    }

    return expr;
  }

  String _preprocessForParser(String s) {
    String res = s.replaceAll(' ', '');
    res = res.replaceAll('√', 'sqrt');
    res = res.replaceAllMapped(RegExp(r'ln\('), (m) => 'log(');

    res = _transformLog10(res);
    res = _fixPower(res); // All power logic is handled here

    if (degreesMode) {
      res = res.replaceAllMapped(RegExp(r'(sin|cos|tan)\(([^)]+)\)'), (m) {
        return '${m[1]!}((pi/180)*(${m[2]!}))';
      });

      res = res.replaceAllMapped(RegExp(r'a(sin|cos|tan)\(([^)]+)\)'), (m) {
        return '(180/pi)*arc${m[1]!}(${m[2]!})';
      });
    } else {
      res = res.replaceAll('asin', 'arcsin');
      res = res.replaceAll('acos', 'arccos');
      res = res.replaceAll('atan', 'arctan');
    }

    return res;
  }

  String _transformLog10(String s) {
    String res = s;
    const pattern = 'log10(';
    int idx = res.indexOf(pattern);

    while (idx != -1) {
      int start = idx + pattern.length;
      int end = start;
      int parenCount = 0;
      int depth = 1;

      while (end < res.length) {
        if (res[end] == '(') parenCount++;
        else if (res[end] == ')') {
          if (parenCount == 0) {
            depth--;
            break;
          }
          parenCount--;
        }
        end++;
      }

      if (depth != 0) break;

      String inside = res.substring(start, end);
      String replace = '(log($inside)/log(10))';

      res = res.substring(0, idx) + replace + res.substring(end + 1);
      idx = res.indexOf(pattern);
    }

    return res;
  }

  void calculateResult() {
    if (input.isEmpty) {
      setState(() => output = "");
      return;
    }

    try {
      String expr = _preprocessForParser(input);
      Parser p = Parser();
      Expression parsed = p.parse(expr);

      ContextModel cm = ContextModel();
      cm.bindVariable(Variable('pi'), Number(math.pi));
      cm.bindVariable(Variable('e'), Number(math.e));

      double eval = parsed.evaluate(EvaluationType.REAL, cm).toDouble();

      setState(() => output = eval.toStringAsPrecision(10));
    } catch (e) {
      setState(() => output = "Error: Invalid Expression");
    }
  }

  void buttonPressed(String value) async {
    if (value == 'AC') return _clearAll();
    if (value == 'DEL') return _deleteLast();

    if (value == 'sin') return _append('sin(');
    if (value == 'cos') return _append('cos(');
    if (value == 'tan') return _append('tan(');
    if (value == 'asin') return _append('asin(');
    if (value == 'acos') return _append('acos(');
    if (value == 'atan') return _append('atan(');
    if (value == 'ln') return _append('ln(');
    if (value == 'log') return _append('log10(');
    if (value == '√') return _append('√(');

    // x² (appends ^2)
    if (value == 'x²') return _append('^2');

    // x³ (appends ^3)
    if (value == 'x³') return _append('^3');

    // y^x (appends ^)
    if (value == 'y^x') return _append("^");

    if (value == 'π') return _append('pi');
    if (value == 'e') return _append('e');

    if (value == 'ANS') return _append(output);
    if (value == 'Rad/Deg') return setState(() => degreesMode = !degreesMode);

    if (value == '=') return calculateResult();

    _append(value);
  }

  Widget buildGridButton(String label, String value, Color buttonColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SizedBox(
        width: 60,
        height: 60,
        child: ElevatedButton(
          onPressed: () => buttonPressed(value),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: textColor,
            padding: EdgeInsets.zero,
          ),
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF9500);
    const darkGrey = Color(0xFF505050);
    const black = Color(0xFF333333);

    final List<Map<String, String>> simplifiedLabels = [
      {'label': '(', 'value': '('}, {'label': ')', 'value': ')'},
      {'label': 'mc', 'value': 'mc'}, {'label': 'm+', 'value': 'm+'},
      {'label': 'm-', 'value': 'm-'}, {'label': 'mr', 'value': 'mr'},
      {'label': '2ⁿᵈ', 'value': '2nd'},
      {'label': 'x²', 'value': 'x²'}, {'label': 'x³', 'value': 'x³'},
      {'label': 'yˣ', 'value': 'y^x'},
      {'label': 'log', 'value': 'log'}, {'label': 'ln', 'value': 'ln'},
      {'label': '√', 'value': '√'},
      {'label': 'sin', 'value': 'sin'}, {'label': 'cos', 'value': 'cos'},
      {'label': 'tan', 'value': 'tan'},
      {'label': 'π', 'value': 'π'}, {'label': 'e', 'value': 'e'},
      {'label': 'Rad/Deg', 'value': 'Rad/Deg'},
      {'label': 'asin', 'value': 'asin'}, {'label': 'acos', 'value': 'acos'},
      {'label': 'atan', 'value': 'atan'},
      {'label': 'DEL', 'value': 'DEL'}, {'label': 'AC', 'value': 'AC'},
      {'label': '7', 'value': '7'}, {'label': '8', 'value': '8'},
      {'label': '9', 'value': '9'}, {'label': '÷', 'value': '/'},
      {'label': '+/-', 'value': '+/-'}, {'label': '%', 'value': '%'},
      {'label': '4', 'value': '4'}, {'label': '5', 'value': '5'},
      {'label': '6', 'value': '6'}, {'label': '×', 'value': '*'},
      {'label': 'ANS', 'value': 'ANS'}, {'label': '0', 'value': '0'},
      {'label': '1', 'value': '1'}, {'label': '2', 'value': '2'},
      {'label': '3', 'value': '3'}, {'label': '-', 'value': '-'},
      {'label': '+', 'value': '+'}, {'label': '.', 'value': '.'},
      {'label': '=','value': '='},
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Scientific Calculator', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(degreesMode ? 'Deg' : 'Rad',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 8),
              child: SingleChildScrollView(
                reverse: true,
                scrollDirection: Axis.horizontal,
                child: Text(
                  input,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 28, color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SelectableText(
                output,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: simplifiedLabels.length,
                  itemBuilder: (context, index) {
                    final item = simplifiedLabels[index];
                    Color buttonColor;
                    Color textColor = Colors.white;

                    if (['AC', 'DEL', '+/-', '%', 'Rad/Deg', '2ⁿᵈ', 'mc', 'm+', 'm-', 'mr']
                        .contains(item['value'])) {
                      buttonColor = darkGrey;
                    } else if (['/', '*', '-', '+', '='].contains(item['value'])) {
                      buttonColor = orange;
                    } else if ([
                      '7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '.'
                    ].contains(item['value'])) {
                      buttonColor = black;
                    } else {
                      buttonColor = darkGrey;
                    }

                    if (item['label'] == 'AC' ||
                        item['value'] == 'DEL' ||
                        item['value'] == '+/-' ||
                        item['value'] == '%') {
                      textColor = Colors.black;
                    }

                    return buildGridButton(
                        item['label']!, item['value']!, buttonColor, textColor);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}