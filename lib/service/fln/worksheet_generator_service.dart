import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_translator/models/fln_models.dart';
import 'package:speech_translator/service/fln/fln_curriculum_data.dart';

class WorksheetGeneratorService {
  static final Random _rand = Random();

  /// Generates a customized bilingual worksheet based on Grade and Subject
  static BilingualWorksheet generateWorksheet({
    required FlnGrade grade,
    required FlnSubject subject,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;

    if (subject == FlnSubject.numeracy) {
      return _generateNumeracyWorksheet(grade, timestamp);
    } else {
      return _generateLiteracyWorksheet(grade, timestamp);
    }
  }

  static BilingualWorksheet _generateLiteracyWorksheet(FlnGrade grade, int seed) {
    List<BilingualWorksheetItem> items = [];

    // Shuffle flashcard pool for dynamic unique questions
    final cards = List<VisualFlashcard>.from(FlnCurriculumData.flashcards)..shuffle(_rand);

    // Question 1: Picture/Word Matching (Hindi to Ol Chiki)
    final q1Card = cards[0];
    final q1Distractors = [cards[1].santaliOlChiki, cards[2].santaliOlChiki, q1Card.santaliOlChiki]..shuffle(_rand);
    items.add(BilingualWorksheetItem(
      itemNumber: 1,
      type: WorksheetType.matching,
      promptHindi: "चित्र पहचानकर सही संथाली (ओल चिकी) शब्द चुनो:",
      promptSantali: "ᱪᱤᱛᱟᱹᱨ ᱧᱮᱞᱛᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱱᱛᱟᱲᱤ (ᱚᱞ ᱪᱤᱠᱤ) ᱥᱟᱵᱟᱫᱽ ᱵᱟᱪᱷᱟᱣᱢᱮ:",
      stimulusText: "${q1Card.hindi} (${q1Card.english})",
      stimulusIcon: q1Card.icon,
      options: q1Distractors,
      correctAnswer: q1Card.santaliOlChiki,
    ));

    // Question 2: Letter Recognition (First sound in Ol Chiki)
    final q2Card = cards[1];
    final firstChar = q2Card.santaliOlChiki.isNotEmpty ? q2Card.santaliOlChiki.substring(0, 1) : "ᱚ";
    final distractorLetters = ["ᱚ", "ᱛ", "ᱜ", "ᱞ", "ᱟ", "ᱥ"]..shuffle(_rand);
    final letterOptions = ({firstChar, distractorLetters[0], distractorLetters[1]}).toList()..shuffle(_rand);
    items.add(BilingualWorksheetItem(
      itemNumber: 2,
      type: WorksheetType.letterRecognition,
      promptHindi: "'${q2Card.hindi}' (${q2Card.santaliLatin}) शब्द का पहला अक्षर (पहला वर्ण) क्या है?",
      promptSantali: "'${q2Card.santaliLatin}' ᱥᱟᱵᱟᱫᱽ ᱨᱮᱭᱟᱜ ᱯᱩᱭᱞᱩ ᱟᱠᱷᱚᱨ ᱫᱚ ᱪᱮᱫ?",
      stimulusText: "${q2Card.santaliOlChiki} [${q2Card.santaliLatin}]",
      stimulusIcon: q2Card.icon,
      options: letterOptions,
      correctAnswer: firstChar,
    ));

    // Question 3: Vocabulary Translation Match
    final q3Card = cards[2];
    items.add(BilingualWorksheetItem(
      itemNumber: 3,
      type: WorksheetType.wordSelection,
      promptHindi: "'${q3Card.hindi}' का सही संथाली रूप कौन सा है?",
      promptSantali: "'${q3Card.hindi}' ᱨᱮᱭᱟᱜ ᱥᱟᱹᱨᱤ ᱥᱟᱱᱛᱟᱲᱤ ᱨᱩᱯ ᱚᱠᱟᱴᱟᱜ ᱠᱟᱱᱟ?",
      stimulusText: q3Card.hindi,
      stimulusIcon: q3Card.icon,
      options: [q3Card.santaliLatin, cards[3].santaliLatin, cards[4].santaliLatin]..shuffle(_rand),
      correctAnswer: q3Card.santaliLatin,
    ));

    // Question 4: Sentence Fill in the Blanks
    final q4Card = cards[3];
    items.add(BilingualWorksheetItem(
      itemNumber: 4,
      type: WorksheetType.fillBlanks,
      promptHindi: "खाली स्थान भरो: ${q4Card.exampleSentenceHindi.replaceAll(q4Card.hindi, '_____')}",
      promptSantali: "ᱠᱷᱟᱹᱞᱤ ᱴᱷᱟᱶ ᱯᱮᱨᱮᱡᱽᱢᱮ: ${q4Card.exampleSentenceSantali.replaceAll(q4Card.santaliOlChiki, '_____')}",
      stimulusText: q4Card.exampleSentenceHindi,
      stimulusIcon: q4Card.icon,
      options: [q4Card.santaliOlChiki, cards[0].santaliOlChiki, cards[1].santaliOlChiki]..shuffle(_rand),
      correctAnswer: q4Card.santaliOlChiki,
    ));

    return BilingualWorksheet(
      id: "WS-LIT-$seed",
      titleHindi: "निपुण भारत बुनियादी भाषा कार्यपत्रक (संथाली - हिन्दी)",
      titleSantali: "ᱱᱤᱯᱩᱱ ᱵᱷᱟᱨᱚᱛ ᱯᱩᱭᱞᱩ ᱯᱟᱹᱨᱥᱤ ᱠᱟᱹᱢᱤ ᱥᱟᱠᱟᱢ (ᱥᱟᱱᱛᱟᱲᱤ - ᱦᱤᱱᱫᱤ)",
      grade: grade,
      subject: FlnSubject.literacy,
      competencyCode: grade == FlnGrade.balvatika ? "FL-BV-01" : "FL-G1-01",
      instructionsHindi: "सभी प्रश्नों को ध्यानपूर्वक पढ़ें। चित्रों को देखकर सही संथाली (ओल चिकी) उत्तर पर घेरा (O) लगाएं।",
      instructionsSantali: "ᱥᱟᱱᱟᱢ ᱠᱩᱠᱞᱤ ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱯᱟᱲᱦᱟᱣᱯᱮ᱾ ᱪᱤᱛᱟᱹᱨ ᱧᱮᱞᱛᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱱᱛᱟᱲᱤ (ᱚᱞ ᱪᱤᱠᱤ) ᱛᱮᱞᱟ ᱨᱮ ᱜᱩᱞᱟᱹᱭ (O) ᱪᱤᱱᱦᱟᱹ ᱞᱟᱜᱟᱣᱯᱮ᱾",
      items: items,
    );
  }

  static BilingualWorksheet _generateNumeracyWorksheet(FlnGrade grade, int seed) {
    List<BilingualWorksheetItem> items = [];

    final numberPairs = [
      {'num': 1, 'hi': 'एक (1)', 'olDigit': '᱑', 'olWord': 'ᱢᱤᱫ', 'latin': 'Mit'},
      {'num': 2, 'hi': 'दो (2)', 'olDigit': '᱒', 'olWord': 'ᱵᱟᱨ', 'latin': 'Bar'},
      {'num': 3, 'hi': 'तीन (3)', 'olDigit': '᱓', 'olWord': 'ᱯᱮ', 'latin': 'Pe'},
      {'num': 4, 'hi': 'चार (4)', 'olDigit': '᱔', 'olWord': 'ᱯᱩᱱ', 'latin': 'Pun'},
      {'num': 5, 'hi': 'पाँच (5)', 'olDigit': '᱕', 'olWord': 'ᱢᱚᱬᱮ', 'latin': 'More'},
      {'num': 6, 'hi': 'छह (6)', 'olDigit': '᱖', 'olWord': 'ᱛᱩᱨᱩᱭ', 'latin': 'Turui'},
      {'num': 7, 'hi': 'सात (7)', 'olDigit': '᱗', 'olWord': 'ᱮᱭᱟᱭ', 'latin': 'Eyay'},
      {'num': 8, 'hi': 'आठ (8)', 'olDigit': '᱘', 'olWord': 'ᱤᱨᱟᱹᱞ', 'latin': 'Iral'},
      {'num': 9, 'hi': 'नौ (9)', 'olDigit': '᱙', 'olWord': 'ᱟᱨᱮ', 'latin': 'Are'},
      {'num': 10, 'hi': 'दस (10)', 'olDigit': '᱑᱐', 'olWord': 'ᱜᱮᱞ', 'latin': 'Gel'},
    ]..shuffle(_rand);

    final iconsPool = [
      Icons.star,
      Icons.favorite,
      Icons.circle,
      Icons.eco,
      Icons.pets,
      Icons.auto_stories,
    ];

    // Question 1: Count & Write (1-5)
    final q1 = numberPairs[0];
    final q1Qty = (q1['num'] as int) <= 5 ? (q1['num'] as int) : 3;
    items.add(BilingualWorksheetItem(
      itemNumber: 1,
      type: WorksheetType.countAndWrite,
      promptHindi: "वस्तुओं को गिनो और सही ओल चिकी संख्या चुनो:",
      promptSantali: "ᱡᱤᱱᱤᱥ ᱞᱮᱠᱷᱟᱭᱯᱮ ᱟᱨ ᱥᱟᱹᱨᱤ ᱚᱞ ᱪᱤᱠᱤ ᱮᱞ ᱵᱟᱪᱷᱟᱣᱯᱮ:",
      countQuantity: q1Qty,
      stimulusIcon: iconsPool[_rand.nextInt(iconsPool.length)],
      options: ['᱑', '᱒', '᱓', '᱔', '᱕']..shuffle(_rand),
      correctAnswer: _getOlDigit(q1Qty),
    ));

    // Question 2: Numeral to Word Match
    final q2 = numberPairs[1];
    final q2Distractors = [
      q2['olWord'] as String,
      numberPairs[2]['olWord'] as String,
      numberPairs[3]['olWord'] as String,
    ]..shuffle(_rand);
    items.add(BilingualWorksheetItem(
      itemNumber: 2,
      type: WorksheetType.matching,
      promptHindi: "ओल चिकी अंक '${q2['olDigit']}' को संथाली शब्द में क्या कहते हैं?",
      promptSantali: "ᱚᱞ ᱪᱤᱠᱤ ᱮᱞ '${q2['olDigit']}' ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮ ᱪᱮᱫ ᱵᱚ ᱢᱮᱛᱟᱜ-ᱟ?",
      stimulusText: "${q2['olDigit']} (${q2['hi']})",
      options: q2Distractors,
      correctAnswer: q2['olWord'] as String,
    ));

    // Question 3: Simple Visual Addition / Joining
    items.add(BilingualWorksheetItem(
      itemNumber: 3,
      type: WorksheetType.countAndWrite,
      promptHindi: "जोड़ो (मिलाओ): ᱒ (ᱵᱟᱨ) + ᱑ (ᱢᱤᱫ) = कितना?",
      promptSantali: "ᱢᱮᱥᱟᱭᱯᱮ: ᱒ (ᱵᱟᱨ) + ᱑ (ᱢᱤᱫ) = ᱛᱤᱱᱟᱹᱜ?",
      stimulusText: "᱒ (दो) + ᱑ (एक) = ?",
      stimulusIcon: Icons.add_circle_outline,
      options: ['᱑', '᱒', '᱓', '᱔']..shuffle(_rand),
      correctAnswer: '᱓',
    ));

    // Question 4: Number Name Recognition in Latin
    final q4 = numberPairs[4];
    items.add(BilingualWorksheetItem(
      itemNumber: 4,
      type: WorksheetType.wordSelection,
      promptHindi: "संख्या '${q4['hi']}' का संथाली उच्चारण (Latin) क्या है?",
      promptSantali: "ᱮᱞ '${q4['hi']}' ᱨᱮᱭᱟᱜ ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ (Latin) ᱫᱚ ᱪᱮᱫ?",
      stimulusText: "${q4['olDigit']} (${q4['hi']})",
      options: [q4['latin'] as String, numberPairs[5]['latin'] as String, numberPairs[6]['latin'] as String]..shuffle(_rand),
      correctAnswer: q4['latin'] as String,
    ));

    return BilingualWorksheet(
      id: "WS-NUM-$seed",
      titleHindi: "निपुण भारत बुनियादी संख्या ज्ञान कार्यपत्रक (गिनती एवं संथाली अंक)",
      titleSantali: "ᱱᱤᱯᱩᱱ ᱵᱷᱟᱨᱚᱛ ᱯᱩᱭᱞᱩ ᱞᱮᱠᱷᱟ ᱠᱟᱹᱢᱤ ᱥᱟᱠᱟᱢ (ᱞᱮᱠᱷᱟ ᱟᱨ ᱚᱞ ᱪᱤᱠᱤ ᱮᱞ)",
      grade: grade,
      subject: FlnSubject.numeracy,
      competencyCode: grade == FlnGrade.balvatika ? "FN-BV-01" : "FN-G1-01",
      instructionsHindi: "वस्तुओं को संथाली में गिनें और सही उत्तर के सामने घेरा लगाएं या लिखें।",
      instructionsSantali: "ᱡᱤᱱᱤᱥ ᱠᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮ ᱞᱮᱠᱷᱟᱭᱯᱮ ᱟᱨ ᱥᱟᱹᱨᱤ ᱛᱮᱞᱟ ᱴᱷᱮᱱ ᱜᱩᱞᱟᱹᱭ (O) ᱪᱤᱱᱦᱟᱹ ᱞᱟᱜᱟᱣᱯᱮ᱾",
      items: items,
    );
  }

  static String _getOlDigit(int n) {
    const digits = ['᱐', '᱑', '᱒', '᱓', '᱔', '᱕', '᱖', '᱗', '᱘', '᱙'];
    if (n >= 0 && n <= 9) return digits[n];
    return n.toString();
  }

  /// Formats the worksheet as a clean plain-text printable sheet with optional answer key
  static String formatWorksheetAsText(BilingualWorksheet ws, {bool includeAnswerKey = false}) {
    final buf = StringBuffer();
    buf.writeln("==================================================================");
    buf.writeln("          JHARKHAND PALASH MTB-MLE / NIPUN BHARAT                 ");
    buf.writeln("             द्विभाषी बुनियादी कार्यपत्रक (Bilingual Worksheet)      ");
    buf.writeln("==================================================================");
    buf.writeln("विषय / Subject : ${ws.subject == FlnSubject.literacy ? 'बुनियादी भाषा (Literacy)' : 'बुनियादी संख्या ज्ञान (Numeracy)'}");
    buf.writeln("कक्षा / Grade  : ${ws.grade.label}");
    buf.writeln("दक्षता कोड     : ${ws.competencyCode}");
    buf.writeln("विद्यार्थी का नाम: _____________________  रोल नं: _________  दिनांक: _________");
    buf.writeln("------------------------------------------------------------------");
    buf.writeln("शीर्षक: ${ws.titleHindi}");
    buf.writeln("ᱢᱩᱬ ᱠᱟᱛᱷᱟ: ${ws.titleSantali}");
    buf.writeln("");
    buf.writeln("निर्देश (Hindi): ${ws.instructionsHindi}");
    buf.writeln("ᱫᱤᱥᱟᱹ (Santali): ${ws.instructionsSantali}");
    buf.writeln("------------------------------------------------------------------");
    buf.writeln("");

    for (var item in ws.items) {
      buf.writeln("प्र. ${item.itemNumber}. ${item.promptHindi}");
      buf.writeln("    ${item.promptSantali}");
      if (item.stimulusText.isNotEmpty) {
        buf.writeln("    [ ${item.stimulusText} ]");
      }
      if (item.countQuantity != null) {
        buf.writeln("    गिनें: ${'★ ' * item.countQuantity!}");
      }
      buf.writeln("    विकल्प:");
      for (int i = 0; i < item.options.length; i++) {
        final optLetter = String.fromCharCode(65 + i); // A, B, C, D
        buf.writeln("      ($optLetter) ${item.options[i]}");
      }
      buf.writeln("    उत्तर: [       ]");
      buf.writeln("");
    }

    if (includeAnswerKey) {
      buf.writeln("==================================================================");
      buf.writeln("                   TEACHER ANSWER KEY (शिक्षक उत्तर कुंजी)        ");
      buf.writeln("==================================================================");
      for (var item in ws.items) {
        buf.writeln("प्र. ${item.itemNumber}: ${item.correctAnswer}");
      }
      buf.writeln("==================================================================");
    }

    return buf.toString();
  }
}
