class AppSyllabus {
  AppSyllabus._();

  static String normalizeClass(dynamic value) {
    final match = RegExp(r'\d+').firstMatch(value?.toString() ?? '');
    return match?.group(0) ?? '12';
  }

  static String normalizeBoard(dynamic value) {
    final board = (value ?? '').toString().trim().toUpperCase();

    if (board.contains('CBSE')) return 'CBSE';
    if (board.contains('ICSE')) return 'ICSE';
    if (board.contains('ISC') || board.contains('CISCE')) return 'ISC';

    return 'STATE_BOARD';
  }

  static Map<String, String> chapters({
    required String subjectName,
    dynamic className,
    dynamic board,
  }) {
    final classKey = normalizeClass(className);
    final boardKey = normalizeBoard(board);
    final subject = subjectName.trim().toLowerCase();

    // ============================================================
    // CLASS 10
    // ============================================================

    if (classKey == '10') {
      if (subject == 'mathematics' || subject == 'maths') {
        return _maths10[boardKey] ?? _maths10['ICSE']!;
      }

      return const {};
    }

    // ============================================================
    // CLASS 12
    // ============================================================

    if (classKey == '12') {
      if (subject == 'mathematics' || subject == 'maths') {
        return _maths[boardKey] ?? _maths['STATE_BOARD']!;
      }

      if (subject == 'physics') {
        return _physics[boardKey] ?? _physics['STATE_BOARD']!;
      }
    }

    return const {};
  }

  // ==============================================================
  // CLASS 10 MATHEMATICS
  // ==============================================================

  static const Map<String, Map<String, String>> _maths10 = {
    'ICSE': {
      'C1': 'Commercial Mathematics',
      'C2': 'Algebra',
      'C3': 'Coordinate Geometry',
      'C4': 'Geometry',
      'C5': 'Mensuration',
      'C6': 'Trigonometry',
      'C7': 'Statistics',
      'C8': 'Probability',
    },
  };

  // ==============================================================
  // CLASS 12 MATHEMATICS
  // ==============================================================

  static const Map<String, Map<String, String>> _maths = {
    'STATE_BOARD': {
      'C1': 'Applications of Matrices and Determinants',
      'C2': 'Complex Numbers',
      'C3': 'Theory of Equations',
      'C4': 'Inverse Trigonometric Functions',
      'C5': 'Two Dimensional Analytical Geometry-II',
      'C6': 'Applications of Vector Algebra',
      'C7': 'Applications of Differential Calculus',
      'C8': 'Differentials and Partial Derivatives',
      'C9': 'Applications of Integration',
      'C10': 'Ordinary Differential Equations',
      'C11': 'Probability Distributions',
      'C12': 'Discrete Mathematics',
    },

    'CBSE': {
      'C1': 'Relations and Functions',
      'C2': 'Inverse Trigonometric Functions',
      'C3': 'Matrices',
      'C4': 'Determinants',
      'C5': 'Continuity and Differentiability',
      'C6': 'Applications of Derivatives',
      'C7': 'Integrals',
      'C8': 'Applications of Integrals',
      'C9': 'Differential Equations',
      'C10': 'Vectors',
      'C11': 'Three Dimensional Geometry',
      'C12': 'Linear Programming',
      'C13': 'Probability',
    },

    'ISC': {
      'C1': 'Relations and Functions',
      'C2': 'Algebra (Matrices & Determinants)',
      'C3': 'Calculus (Continuity, Differentiation, Integration, DEs)',
      'C4': 'Probability',
      'C5': 'Vectors',
      'C6': 'Three Dimensional Geometry',
      'C7': 'Applications of Integrals',
      'C8': 'Applications of Calculus (Commerce/Economics)',
      'C9': 'Linear Regression',
      'C10': 'Linear Programming',
    },
  };

  // ==============================================================
  // CLASS 12 PHYSICS
  // ==============================================================

  static const Map<String, Map<String, String>> _physics = {
    // ------------------------------------------------------------
    // TAMIL NADU STATE BOARD
    // Volume 1: Units 1-5
    // Volume 2: Units 6-11
    // ------------------------------------------------------------

    'STATE_BOARD': {
      'C1': 'Electrostatics',
      'C2': 'Current Electricity',
      'C3': 'Magnetism and Magnetic Effects of Electric Current',
      'C4': 'Electromagnetic Induction and Alternating Current',
      'C5': 'Electromagnetic Waves',
      'C6': 'Ray Optics',
      'C7': 'Wave Optics',
      'C8': 'Dual Nature of Radiation and Matter',
      'C9': 'Atomic and Nuclear Physics',
      'C10': 'Electronics and Communication',
      'C11': 'Recent Developments in Physics',
    },

    // ------------------------------------------------------------
    // CBSE
    // ------------------------------------------------------------

    'CBSE': {
      'C1':
      'Electric Charges and Fields / Electrostatic Potential & Capacitance',
      'C2': 'Current Electricity',
      'C3': 'Moving Charges and Magnetism / Magnetism and Matter',
      'C4': 'Electromagnetic Induction / Alternating Current',
      'C5': 'Electromagnetic Waves',
      'C6': 'Ray Optics / Wave Optics',
      'C7': 'Dual Nature of Radiation and Matter',
      'C8': 'Atoms / Nuclei',
      'C9': 'Semiconductor Electronics / Communication Systems',
    },

    // ------------------------------------------------------------
    // ISC
    // ------------------------------------------------------------

    'ISC': {
      'C1': 'Electrostatics',
      'C2': 'Current Electricity',
      'C3': 'Magnetism and Magnetic Effects of Current',
      'C4': 'Electromagnetic Induction and Alternating Currents',
      'C5': 'Electromagnetic Waves',
      'C6': 'Optics (Ray and Wave)',
      'C7': 'Dual Nature of Radiation and Matter',
      'C8': 'Atoms and Nuclei',
      'C9': 'Electronic Devices and Communication',
    },
  };
}