import 'package:flutter/material.dart';
import '../../../../questions/domain/entities/question.dart';

class BankAlHazQuestionDialog extends StatefulWidget {
  final Question question;
  final void Function(bool correct) onResult;

  const BankAlHazQuestionDialog({
    super.key,
    required this.question,
    required this.onResult,
  });

  @override
  State<BankAlHazQuestionDialog> createState() => _BankAlHazQuestionDialogState();
}

class _BankAlHazQuestionDialogState extends State<BankAlHazQuestionDialog> {
  int? selectedIdx;
  bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.blue.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'سؤال التحدي',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Question text
              Text(
                widget.question.text,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Options
              if (widget.question.options != null)
                ...widget.question.options!.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final isCorrectOpt = widget.question.correctOptionIndices?.contains(idx) ?? false;
                  
                  final bool isSelected = selectedIdx == idx;
                  final bool revealed = isCorrect != null;

                  Color btnColor = Colors.grey.shade50;
                  Color textColor = Colors.black87;
                  Color borderColor = Colors.grey.shade200;

                  if (revealed) {
                     if (isCorrectOpt) {
                       btnColor = Colors.green.shade50;
                       textColor = Colors.green.shade700;
                       borderColor = Colors.green;
                     } else if (isSelected) {
                       btnColor = Colors.red.shade50;
                       textColor = Colors.red.shade700;
                       borderColor = Colors.red;
                     }
                  } else if (isSelected) {
                     btnColor = Colors.blue.shade50;
                     textColor = Colors.blue;
                     borderColor = Colors.blue;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: revealed ? null : () => _handleSelection(idx, isCorrectOpt),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: btnColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              if (isSelected && !revealed)
                                BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: Text(
                            opt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected || (revealed && isCorrectOpt) ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              
              // True/False
              if (widget.question.type == QuestionType.trueFalse)
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     _buildTFButton(true, "صح", Colors.blue, widget.question.tfValue == true),
                     const SizedBox(width: 16),
                     _buildTFButton(false, "خطأ", Colors.red, widget.question.tfValue == false),
                   ],
                 ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTFButton(bool value, String text, Color color, bool isActuallyCorrect) {
    final bool revealed = isCorrect != null;
    final bool isSelected = selectedIdx == (value ? 1 : 0);

    Color btnColor = Colors.grey.shade50;
    Color textColor = Colors.black87;
    Color borderColor = Colors.grey.shade200;

    if (revealed) {
      if (isActuallyCorrect) {
         btnColor = Colors.green.shade50;
         textColor = Colors.green.shade700;
         borderColor = Colors.green;
      } else if (isSelected) {
         btnColor = Colors.red.shade50;
         textColor = Colors.red.shade700;
         borderColor = borderColor; // red
      }
    } else if (isSelected) {
        btnColor = Colors.blue.shade50;
        textColor = Colors.blue;
        borderColor = Colors.blue;
    }

    return Expanded(
      child: InkWell(
        onTap: revealed ? null : () {
          setState(() => selectedIdx = value ? 1 : 0);
          _handleSelection(value ? 1 : 0, value == widget.question.tfValue);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: revealed && isSelected && !isActuallyCorrect ? Colors.red : (revealed && isActuallyCorrect ? Colors.green : borderColor), width: 2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSelection(int idx, bool correct) {
    setState(() {
      selectedIdx = idx;
      isCorrect = correct;
    });
    
    Future.delayed(const Duration(seconds: 1), () {
       if (mounted) widget.onResult(correct);
    });
  }
}
