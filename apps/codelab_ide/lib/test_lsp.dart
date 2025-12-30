import 'dart:io';

// Класс с намеренными ошибками для проверки LSP
class TestLspFeatures {
  // Неинициализированная переменная (должна быть подчеркнута)
  String uninitializedVar;

  // Неиспользуемая переменная (должно быть предупреждение)
  final int unusedVar = 42;

  // Метод с неправильным типом возвращаемого значения (должна быть ошибка)
  String returnWrongType() {
    return 42;
  }

  // Метод для проверки автодополнения
  void testAutocompletion() {
    final testString = 'Hello';
    // Попробуйте ввести testString. - должны появиться методы строки
    
    final testList = <String>[];
    // Попробуйте ввести testList. - должны появиться методы списка
  }

  // Метод с неправильным использованием API (должна быть ошибка)
  Future<void> testAsyncFeatures() {
    // Отсутствует await
    Future.delayed(Duration(seconds: 1));
    
    // Неправильное использование Future
    return null;
  }

  // Проверка импортов
  void testImports() {
    // Попробуйте ввести File. - должно предложить импорт dart:io
    // Попробуйте ввести JsonEnc - должно предложить импорт dart:convert
  }
}

// Функция с типом, которого нет (должна быть ошибка)
void testUndefinedType(UndefinedType param) {
}

// TODO: Добавьте /// перед методом и нажмите Enter - должна создаться документация
void testDocumentation() {
}
