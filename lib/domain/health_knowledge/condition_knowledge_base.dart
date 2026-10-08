import '../profile/chronic_condition.dart';
import '../profile/diabetes_type.dart';
import 'condition_guidance.dart';

/// Base de conocimiento estática con pautas dietéticas generales por
/// condición crónica, para uso del motor de menús (Fase 5) y futuras
/// funciones de la app. No reemplaza indicación médica ni nutricional
/// individual (ver MedicalDisclaimerBanner). Todo el contenido cita su
/// fuente; no se inventa información nutricional ni clínica.
///
/// Fuentes principales consultadas (julio 2026):
/// - American Diabetes Association, Standards of Care in Diabetes 2026.
/// - ADA, guía sobre carbohidratos y fibra (Dietary Guidelines 2025-2030).
/// - MedlinePlus (NIH), "DASH Eating Plan".
/// - Mayo Clinic, "DASH diet" y "Lactose intolerance".
/// - MINSAL Chile, Guía Clínica Diabetes Mellitus Tipo 2 (DIPRECE).
/// - Literatura clínica sobre subtipos de diabetes (MODY, LADA, tipo 3c).
class ConditionKnowledgeBase {
  ConditionKnowledgeBase._();

  static const _adaSource = KnowledgeSource(
    name: 'American Diabetes Association — Standards of Care in Diabetes 2026',
    url: 'https://diabetesjournals.org/care/article/49/Supplement_1/S6/163930',
  );

  static const _adaFiberSource = KnowledgeSource(
    name:
        'American Diabetes Association — 2025-2030 Dietary Guidelines: '
        'Protein and Dietary Fiber',
    url:
        'https://professional.diabetes.org/event/2025-2030-dietary-'
        'guidelines-and-modern-diabetes-care-spotlight-protein-and-'
        'dietary-fiber',
  );

  static const _minsalSource = KnowledgeSource(
    name: 'MINSAL Chile — Guía Clínica Diabetes Mellitus Tipo 2 (DIPRECE)',
    url:
        'https://diprece.minsal.cl/wrdprss_minsal/wp-content/uploads/2018/'
        '01/DIABETES-MELLITUS-TIPO-2-1.pdf',
  );

  static const _medlinePlusDashSource = KnowledgeSource(
    name: 'MedlinePlus (NIH) — DASH Eating Plan',
    url: 'https://medlineplus.gov/dasheatingplan.html',
  );

  static const _mayoDashSource = KnowledgeSource(
    name:
        'Mayo Clinic — DASH diet: Healthy eating to lower your blood '
        'pressure',
    url:
        'https://www.mayoclinic.org/healthy-lifestyle/nutrition-and-'
        'healthy-eating/in-depth/dash-diet/art-20048456',
  );

  static const _mayoLactoseSource = KnowledgeSource(
    name: 'Mayo Clinic — Lactose intolerance: Diagnosis & treatment',
    url:
        'https://www.mayoclinic.org/diseases-conditions/lactose-'
        'intolerance/diagnosis-treatment/drc-20374238',
  );

  static const _mody3Source = KnowledgeSource(
    name: 'NCBI PMC — Maturity-Onset Diabetes of the Young Type 3 (MODY 3)',
    url: 'https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11271687/',
  );

  static const _type3cSource = KnowledgeSource(
    name:
        'DiabetesOnTheNet — Recognition and management of pancreatogenic '
        '(type 3c) diabetes',
    url:
        'https://diabetesonthenet.com/cpd-module/pancreatogenic-type-3c-'
        'diabetes/',
  );

  static final ConditionGuidance _diabetesGeneral = ConditionGuidance(
    title: 'Diabetes',
    summary:
        'No existe una única distribución de macronutrientes válida para '
        'todas las personas con diabetes; la ADA prioriza fuentes de '
        'carbohidratos de calidad, altas en fibra y mínimamente '
        'procesadas por sobre solo controlar la cantidad total.',
    foodsToPrioritize: const [
      'Verduras variadas',
      'Legumbres',
      'Frutas enteras (no en jugo)',
      'Granos integrales',
      'Proteínas magras',
      'Grasas saludables (paltas, frutos secos, aceite de oliva)',
    ],
    foodsToLimit: const [
      'Carbohidratos refinados (harinas blancas, azúcar)',
      'Bebidas y alimentos con azúcares añadidos',
      'Alimentos ultraprocesados',
      'Exceso de sodio y grasas saturadas',
    ],
    nutrientNotes: const [
      NutrientNote(
        nutrientKey: 'fiber',
        guidance: 'Al menos 14 g de fibra por cada 1000 kcal consumidas.',
        minPerDay: null,
      ),
      NutrientNote(
        nutrientKey: 'sugar',
        guidance:
            'Minimizar azúcares añadidos; priorizar azúcares '
            'naturales de fruta entera.',
      ),
    ],
    sources: const [_adaSource, _adaFiberSource, _minsalSource],
  );

  static const Map<DiabetesType, String> _diabetesSubtypeNotes = {
    DiabetesType.type1:
        'En diabetes tipo 1, el conteo de carbohidratos suele coordinarse '
        'con el ajuste de insulina definido por el equipo de salud; esta '
        'app no calcula dosis de insulina.',
    DiabetesType.type2:
        'En diabetes tipo 2, además de la calidad de los carbohidratos, '
        'la guía MINSAL destaca el beneficio de actividad física regular '
        'y, si hay sobrepeso, una baja de peso moderada y sostenida.',
    DiabetesType.gestational:
        'En diabetes gestacional suele recomendarse distribuir los '
        'carbohidratos en varias comidas pequeñas durante el día, bajo '
        'control de matrona/nutricionista especializado en embarazo.',
    DiabetesType.lada:
        'LADA se comporta clínicamente como una diabetes tipo 1 de '
        'progresión lenta; aplican las mismas consideraciones generales, '
        'con vigilancia de una eventual necesidad progresiva de insulina.',
    DiabetesType.mody:
        'MODY agrupa varios subtipos genéticos distintos. Para el '
        'subtipo más frecuente (MODY 3), la literatura describe buena '
        'respuesta a una dieta baja en carbohidratos combinada con '
        'tratamiento específico; dado que el manejo varía mucho según el '
        'subtipo exacto, esta guía general de diabetes es un punto de '
        'partida, no un reemplazo del ajuste con tu equipo tratante.',
    DiabetesType.type3c:
        'La diabetes tipo 3c (pancreatogénica) suele coexistir con '
        'dificultad para digerir grasas por insuficiencia del páncreas '
        'exocrino. La literatura describe beneficio de asegurar proteína '
        'adecuada y ajustar (a veces restringir) las grasas, además del '
        'control habitual de carbohidratos, frecuentemente junto con '
        'enzimas pancreáticas indicadas por el equipo tratante.',
    DiabetesType.prediabetes:
        'En prediabetes aplican las mismas prioridades que en diabetes '
        'tipo 2, con foco en prevención mediante actividad física '
        'regular y control de peso.',
  };

  static final ConditionGuidance _hypertension = ConditionGuidance(
    title: 'Hipertensión',
    summary:
        'El patrón alimentario con más evidencia para bajar la presión '
        'arterial es DASH: rico en frutas, verduras y lácteos bajos en '
        'grasa, bajo en sodio.',
    foodsToPrioritize: const [
      'Frutas y verduras variadas',
      'Lácteos bajos en grasa',
      'Legumbres, frutos secos y semillas',
      'Granos integrales',
      'Pescado y aves',
      'Alimentos ricos en potasio, calcio y magnesio',
    ],
    foodsToLimit: const [
      'Sal y alimentos altos en sodio',
      'Carnes rojas y procesadas',
      'Dulces y bebidas azucaradas',
      'Grasas saturadas',
    ],
    nutrientNotes: const [
      NutrientNote(
        nutrientKey: 'sodium',
        guidance:
            'Limitar a menos de 2300 mg/día; bajar a 1500 mg/día '
            'reduce la presión aún más, según DASH.',
        maxPerDay: 2300,
      ),
    ],
    sources: const [_medlinePlusDashSource, _mayoDashSource],
  );

  static final ConditionGuidance _lactoseIntolerance = ConditionGuidance(
    title: 'Intolerancia a la lactosa',
    summary:
        'No es una alergia: es dificultad para digerir la lactosa. El '
        'manejo suele ser individual, probando tolerancia, no '
        'necesariamente evitando todo lácteo.',
    foodsToPrioritize: const [
      'Porciones pequeñas de lácteos (hasta ~120 ml de una vez)',
      'Yogur y quesos madurados (naturalmente más bajos en lactosa)',
      'Leches vegetales o lácteos sin lactosa',
      'Consumir lácteos junto con otros alimentos, no solos',
    ],
    foodsToLimit: const ['Porciones grandes de leche líquida de una sola vez'],
    nutrientNotes: const [
      NutrientNote(
        nutrientKey: 'calcium',
        guidance:
            'Asegurar unas 3 porciones/día de fuentes de calcio '
            '(lácteas o no) para compensar el menor consumo de lácteos '
            'regulares.',
      ),
    ],
    sources: const [_mayoLactoseSource],
  );

  static ConditionGuidance guidanceFor(
    ChronicCondition condition, {
    DiabetesType? diabetesType,
  }) {
    switch (condition) {
      case ChronicCondition.diabetes:
        if (diabetesType == null) {
          return _diabetesGeneral;
        }
        final subtypeNote = _diabetesSubtypeNotes[diabetesType];
        return ConditionGuidance(
          title: '${_diabetesGeneral.title} (${diabetesType.label})',
          summary: _diabetesGeneral.summary,
          foodsToPrioritize: _diabetesGeneral.foodsToPrioritize,
          foodsToLimit: _diabetesGeneral.foodsToLimit,
          nutrientNotes: _diabetesGeneral.nutrientNotes,
          sources: [
            ..._diabetesGeneral.sources,
            if (diabetesType == DiabetesType.mody) _mody3Source,
            if (diabetesType == DiabetesType.type3c) _type3cSource,
          ],
          additionalNote: subtypeNote,
        );
      case ChronicCondition.hypertension:
        return _hypertension;
      case ChronicCondition.lactoseIntolerance:
        return _lactoseIntolerance;
      case ChronicCondition.other:
        return const ConditionGuidance(
          title: 'Otra condición',
          summary:
              'No hay pautas específicas cargadas para esta condición; '
              'usa las notas que registraste en tu perfil como '
              'referencia.',
          foodsToPrioritize: [],
          foodsToLimit: [],
          nutrientNotes: [],
          sources: [],
        );
    }
  }
}
