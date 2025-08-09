class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    'ko': {
      // Common
      'appTitle': '물 마시기 리마인더',
      'ml': 'ml',
      'liter': 'L',
      'cancel': '취소',
      'save': '저장',
      'delete': '삭제',
      'edit': '편집',
      'confirm': '확인',
      
      // Navigation
      'home': '홈',
      'stats': '통계',
      'settings': '설정',
      
      // Main Screen
      'drink': '마시기',
      'drinkAmount': '%s ml 마시기',
      'history': '기록',
      'viewAll': '전체 보기 →',
      'noDrinksToday': '오늘 마신 물이 없습니다',
      'ofDailyGoal': '일일 목표의',
      'entries': '개 기록',
      'startHydrating': '지금 시작하세요!',
      
      // Drink Types
      'water': '물',
      'tea': '차',
      'coffee': '커피',
      'juice': '주스',
      'milk': '우유',
      
      // Settings Screen
      'dailyGoal': '일일 목표량',
      'darkMode': '다크 모드',
      'notifications': '알림 설정',
      'language': '언어',
      'setDailyGoal': '일일 목표량 설정',
      'enterDailyGoal': '하루 목표 물 섭취량을 입력하세요',
      'goalAmount': '목표량 (ml)',
      'recommendedAmount': '권장량: 2000ml',
      'goalChanged': '목표량이 %sml로 변경되었습니다',
      
      // Stats Screen
      'report': '리포트',
      'weekly': '주간',
      'monthly': '월간',
      'yearly': '연간',
      'drinkCompletion': '목표 달성률',
      'hydrate': '수분 섭취량',
      'today': '오늘',
      'yesterday': '어제',
      'noData': '데이터 없음',
      
      // History
      'noRecordsYet': '아직 기록이 없습니다',
      'totalAmount': '총 %s mL',
      'deleteEntry': '기록 삭제',
      'deleteConfirm': '이 기록을 삭제하시겠습니까?',
      
      // Dialogs
      'drinkSettings': '음료 설정',
      'selectDrink': '음료 선택',
      'selectAmount': '용량 선택',
      'customAmount': '직접 입력 (ml)',
      'editDrink': '음료 수정',
      'drinkType': '음료 종류',
      'amount': '용량',
      
      // Date formats
      'dateToday': '오늘',
      'dateYesterday': '어제',
      'week': '주',
      'month': '월',
      'year': '년',
    },
    'en': {
      // Common
      'appTitle': 'Water Reminder',
      'ml': 'ml',
      'liter': 'L',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      
      // Navigation
      'home': 'Home',
      'stats': 'Stats',
      'settings': 'Settings',
      
      // Main Screen
      'drink': 'Drink',
      'drinkAmount': 'Drink %s ml',
      'history': 'History',
      'viewAll': 'View All →',
      'noDrinksToday': 'No drinks yet today',
      'ofDailyGoal': 'of daily goal',
      'entries': 'entries',
      'startHydrating': 'Start hydrating!',
      
      // Drink Types
      'water': 'Water',
      'tea': 'Tea',
      'coffee': 'Coffee',
      'juice': 'Juice',
      'milk': 'Milk',
      
      // Settings Screen
      'dailyGoal': 'Daily Goal',
      'darkMode': 'Dark Mode',
      'notifications': 'Notifications',
      'language': 'Language',
      'setDailyGoal': 'Set Daily Goal',
      'enterDailyGoal': 'Enter your daily water intake goal',
      'goalAmount': 'Goal Amount (ml)',
      'recommendedAmount': 'Recommended: 2000ml',
      'goalChanged': 'Goal changed to %sml',
      
      // Stats Screen
      'report': 'Report',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'drinkCompletion': 'Drink Completion',
      'hydrate': 'Hydrate',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'noData': 'No data',
      
      // History
      'noRecordsYet': 'No drinks recorded yet',
      'totalAmount': 'Total %s mL',
      'deleteEntry': 'Delete Entry',
      'deleteConfirm': 'Are you sure you want to delete this entry?',
      
      // Dialogs
      'drinkSettings': 'Drink Settings',
      'selectDrink': 'Select Drink',
      'selectAmount': 'Select Amount',
      'customAmount': 'Custom Amount (ml)',
      'editDrink': 'Edit Drink',
      'drinkType': 'Drink Type',
      'amount': 'Amount',
      
      // Date formats
      'dateToday': 'Today',
      'dateYesterday': 'Yesterday',
      'week': 'Week',
      'month': 'Month',
      'year': 'Year',
    },
  };
  
  static String _currentLanguage = 'ko';
  
  static void setLanguage(String languageCode) {
    if (_localizedValues.containsKey(languageCode)) {
      _currentLanguage = languageCode;
    }
  }
  
  static String get currentLanguage => _currentLanguage;
  
  static String get(String key, [String? param]) {
    String value = _localizedValues[_currentLanguage]?[key] ?? key;
    if (param != null) {
      value = value.replaceAll('%s', param);
    }
    return value;
  }
  
  static String getDrinkName(String drinkType) {
    switch (drinkType.toLowerCase()) {
      case 'water':
        return get('water');
      case 'tea':
        return get('tea');
      case 'coffee':
        return get('coffee');
      case 'juice':
        return get('juice');
      case 'milk':
        return get('milk');
      default:
        return drinkType;
    }
  }
  
  static String getMonthName(int month) {
    if (_currentLanguage == 'ko') {
      return '${month}월';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return months[month - 1];
    }
  }
  
  static String getWeekdayName(int weekday) {
    if (_currentLanguage == 'ko') {
      const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return weekdays[weekday - 1];
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[weekday - 1];
    }
  }
}