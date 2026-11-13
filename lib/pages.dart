import 'package:flutter/material.dart';
import 'vocab.dart' as v;
import 'flashcards.dart';

export 'vocab.dart' hide vocabPageFor;

Widget? vocabPageFor(int i) {
  if (i == 0) return const FlashcardPage();
  return v.vocabPageFor(i);
}
