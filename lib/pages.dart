import 'package:flutter/material.dart';
import 'vocab.dart' as v;
import 'flashcards.dart';
import 'quiz.dart';
import 'revision.dart';
import 'progress.dart';
import 'planner.dart';
import 'hub.dart';
import 'settings.dart';
import 'grammar.dart';
import 'exam.dart';
import 'reading.dart';
import 'connected.dart';
import 'search.dart';
import 'sentence.dart';
import 'sync.dart';
import 'image_manager.dart';

export 'vocab.dart' hide vocabPageFor;

Widget? vocabPageFor(int i) {
  SyncService.autoOnce();
  if (i == 1) return const ImageManagerPage();
  if (i == 6) return const ReadingPage();
  if (i == 0) return const FlashcardPage();
  if (i == 7) return const GrammarPage();
  if (i == 8) return const QuizPage();
  if (i == 11) return const RevisionPage();
  if (i == 12) return const SentencePage();
  if (i == 14) return const ExamPage();
  if (i == 15) return const ProgressPage();
  if (i == 16) return const PlannerPage();
  if (i == 17) return const HubPage();
  if (i == 18) return const ConnectedPage();
  if (i == 20) return const SearchPage();
  if (i == 21) return const SettingsPage();
  return v.vocabPageFor(i);
}
