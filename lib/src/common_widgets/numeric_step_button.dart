import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumericStepButton extends StatefulWidget {
  const NumericStepButton({
    super.key,
    required this.onValueChanged,
    required this.currentValue,
    this.minValue = 0,
    this.maxValue = 256,
  });
  
  final double currentValue;
  final void Function(double) onValueChanged;

  final int minValue;
  final int maxValue;

  static const double buttonSize = 24.0;

  @override
  State<NumericStepButton> createState() => _NumericStepButtonState();
}

class _NumericStepButtonState extends State<NumericStepButton> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = '${widget.currentValue}';
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.text = '${widget.currentValue}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 128,
          child: TextField(
            onChanged: (String newVal) {

            },
            textAlign: TextAlign.center,
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: false,
            ),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: InputDecoration(
              prefixIcon: _Button(
                iconData: Icons.remove_circle,
                onPressed: () {
                  if (widget.currentValue == widget.minValue) return;

                  widget.onValueChanged(widget.currentValue - 1);
                },
              ),
              suffixIcon: _Button(
                iconData: Icons.add_circle,
                onPressed: () {
                  if (widget.currentValue == widget.maxValue) return;

                  widget.onValueChanged(widget.currentValue + 1);
                },
              ),
              border: const OutlineInputBorder(),

            ),
          ),
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    super.key,
    required this.iconData,
    required this.onPressed,
  });
  final IconData iconData;
  final void Function() onPressed;

  static const double buttonSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        iconData,
      ),
      iconSize: buttonSize,
      onPressed: onPressed
    );
  }
}
