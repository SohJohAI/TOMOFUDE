import 'package:flutter/material.dart';

class RubyTextWidget extends StatelessWidget {
  final String text;
  final String ruby;
  final TextStyle textStyle;
  final TextStyle rubyStyle;

  const RubyTextWidget({
    Key? key,
    required this.text,
    required this.ruby,
    this.textStyle = const TextStyle(fontSize: 18),
    this.rubyStyle = const TextStyle(fontSize: 10, color: Colors.grey),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ruby,
          style: rubyStyle,
        ),
        Text(
          text,
          style: textStyle,
        ),
      ],
    );
  }
}
