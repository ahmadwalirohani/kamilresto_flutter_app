import 'package:flutter/material.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text('؋${value.toStringAsFixed(2)}', style: style);
  }
}
