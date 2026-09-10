import 'package:flutter/material.dart';

enum FlnSubject { literacy, numeracy }

enum FlnGrade { balvatika, grade1, grade2, grade3 }

extension FlnGradeExt on FlnGrade {
  String get label {
    switch (this) {
      case FlnGrade.balvatika:
        return "बालवाटिका (Balvatika)";
      case FlnGrade.grade1:
        return "कक्षा 1 (Grade 1)";
      case FlnGrade.grade2:
        return "कक्षा 2 (Grade 2)";
      case FlnGrade.grade3:
        return "कक्षा 3 (Grade 3)";
    }
  }

  String get shortLabel {
    switch (this) {
      case FlnGrade.balvatika:
        return "Balvatika";
      case FlnGrade.grade1:
        return "Grade 1";
      case FlnGrade.grade2:
        return "Grade 2";
      case FlnGrade.grade3:
        return "Grade 3";
    }
  }
}

class NipunCompetency {
  final String code; // e.g. "FL-L1-01"
  final FlnSubject subject;
  final FlnGrade grade;
  final String titleHindi;
  final String titleSantali;
  final String learningOutcome;

  const NipunCompetency({
    required this.code,
    required this.subject,
    required this.grade,
    required this.titleHindi,
    required this.titleSantali,
    required this.learningOutcome,
  });
}

class LessonPhase {
  final String phaseNameHindi;
  final String phaseNameSantali;
  final int durationMinutes;
  final String teacherDialogueHindi;
  final String santaliOlChiki;
  final String santaliLatin;
  final String santaliDevanagari;
  final String activityInstructionsHindi;
  final String studentAction;

  const LessonPhase({
    required this.phaseNameHindi,
    required this.phaseNameSantali,
    required this.durationMinutes,
    required this.teacherDialogueHindi,
    required this.santaliOlChiki,
    required this.santaliLatin,
    required this.santaliDevanagari,
    required this.activityInstructionsHindi,
    required this.studentAction,
  });
}

class LessonScript {
  final String id;
  final String titleHindi;
  final String titleSantali;
  final String competencyCode;
  final FlnGrade grade;
  final FlnSubject subject;
  final int totalDurationMinutes;
  final String learningOutcome;
  final List<String> materialsNeeded;
  final List<LessonPhase> phases;

  const LessonScript({
    required this.id,
    required this.titleHindi,
    required this.titleSantali,
    required this.competencyCode,
    required this.grade,
    required this.subject,
    required this.totalDurationMinutes,
    required this.learningOutcome,
    required this.materialsNeeded,
    required this.phases,
  });
}

class ClassroomInstruction {
  final String id;
  final String category; // 'Management', 'Praise', 'Focus', 'Movement', 'Question'
  final String hindi;
  final String santaliOlChiki;
  final String santaliLatin;
  final String santaliDevanagari;
  final String pedagogicalTip;

  const ClassroomInstruction({
    required this.id,
    required this.category,
    required this.hindi,
    required this.santaliOlChiki,
    required this.santaliLatin,
    required this.santaliDevanagari,
    required this.pedagogicalTip,
  });
}

class AssessmentPrompt {
  final String id;
  final String competencyCode;
  final FlnGrade grade;
  final FlnSubject subject;
  final String promptHindi;
  final String promptSantaliOlChiki;
  final String promptSantaliLatin;
  final String promptSantaliDevanagari;
  final String expectedResponseHindi;
  final String expectedResponseSantali;
  final String rubricBeginning; // Level 1
  final String rubricProgressing; // Level 2
  final String rubricProficient; // Level 3

  const AssessmentPrompt({
    required this.id,
    required this.competencyCode,
    required this.grade,
    required this.subject,
    required this.promptHindi,
    required this.promptSantaliOlChiki,
    required this.promptSantaliLatin,
    required this.promptSantaliDevanagari,
    required this.expectedResponseHindi,
    required this.expectedResponseSantali,
    required this.rubricBeginning,
    required this.rubricProgressing,
    required this.rubricProficient,
  });
}

class VisualFlashcard {
  final String id;
  final String category; // 'Animals', 'Body Parts', 'Numbers', 'Colors', 'Classroom', 'Actions', 'Nature'
  final FlnGrade nipunLevel;
  final String hindi;
  final String santaliOlChiki;
  final String santaliLatin;
  final String santaliDevanagari;
  final String english;
  final IconData icon;
  final Color cardColor;
  final String exampleSentenceHindi;
  final String exampleSentenceSantali;

  const VisualFlashcard({
    required this.id,
    required this.category,
    required this.nipunLevel,
    required this.hindi,
    required this.santaliOlChiki,
    required this.santaliLatin,
    required this.santaliDevanagari,
    required this.english,
    required this.icon,
    required this.cardColor,
    required this.exampleSentenceHindi,
    required this.exampleSentenceSantali,
  });
}

enum WorksheetType { matching, countAndWrite, letterRecognition, fillBlanks, wordSelection }

class BilingualWorksheetItem {
  final int itemNumber;
  final WorksheetType type;
  final String promptHindi;
  final String promptSantali;
  final String stimulusText;
  final IconData? stimulusIcon;
  final int? countQuantity;
  final List<String> options;
  final String correctAnswer;

  const BilingualWorksheetItem({
    required this.itemNumber,
    required this.type,
    required this.promptHindi,
    required this.promptSantali,
    this.stimulusText = '',
    this.stimulusIcon,
    this.countQuantity,
    this.options = const [],
    required this.correctAnswer,
  });
}

class BilingualWorksheet {
  final String id;
  final String titleHindi;
  final String titleSantali;
  final FlnGrade grade;
  final FlnSubject subject;
  final String competencyCode;
  final String instructionsHindi;
  final String instructionsSantali;
  final List<BilingualWorksheetItem> items;

  const BilingualWorksheet({
    required this.id,
    required this.titleHindi,
    required this.titleSantali,
    required this.grade,
    required this.subject,
    required this.competencyCode,
    required this.instructionsHindi,
    required this.instructionsSantali,
    required this.items,
  });
}
