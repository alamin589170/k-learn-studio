import 'package:flutter/material.dart';
import 'vocab.dart' as v;
import 'flashcards.dart';
import 'quiz.dart';

export 'vocab.dart' hide vocabPageFor;

Widget? vocabPageFor(int i) {
  if (i == 0) return const FlashcardPage();
  if (i == 8) return const QuizPage();
  return v.vocabPageFor(i);
}
