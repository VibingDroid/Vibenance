import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño de Vibenance
/// sobre una base Material 3.
///
/// Paleta:
/// - Navy: color principal de texto y cabeceras.
/// - Coral: acento de marca (estado activo, énfasis).
/// - Azul: enlaces, acciones secundarias y chevrons.
/// - Superficies claras con tarjetas redondeadas y separadores suaves.
abstract final class FtColors {
  // Marca / primario
  static const Color primary = Color(0xFF4374F8);
  static const Color primaryCyan = Color(0xFF00CED8);
  static const Color primaryViolet = Color(0xFF8C38FF);
  static const List<Color> brandGradient = <Color>[
    primaryCyan,
    primary,
    primaryViolet,
  ];

  // Alias retrocompatibles para el azul de marca
  static const Color blue = primary;
  static const Color blueLight = Color(
    0xFF6AA6FF,
  ); // Azul luminoso para modo oscuro / énfasis

  // Neutros (modo claro)
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sectionHeader = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Neutros (modo oscuro)
  static const Color bgDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF151D2A);
  static const Color sectionHeaderDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF243044);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Semánticos para finanzas
  static const Color income = Color(
    0xFF047857,
  ); // Esmeralda profundo WCAG AA en Light
  static const Color incomeDark = Color(0xFF10B981); // Menta en Dark
  static const Color incomeLight = incomeDark; // Alias retrocompatible luminoso
  static const Color expense = Color(0xFFBE123C); // Rubí accesible en Light
  static const Color expenseDark = Color(0xFFF43F5E); // Carmín suave en Dark
  static const Color transfer = Color(0xFF475569); // Acero oscuro en Light
  static const Color transferDark = Color(0xFF64748B); // Azul acero en Dark

  // Alias retrocompatibles: coral -> expense
  static const Color coral = expense;
  static const Color coralDark = expense; // Alto contraste, alias del rubí
  static const Color coralLight = expenseDark; // Alias del carmín en Dark

  // Capas de producto
  static const Color aiLayer = Color(
    0xFF6D28D9,
  ); // IA / categorización en Light
  static const Color aiLayerDark = Color(
    0xFF8B5CF6,
  ); // IA / categorización en Dark
  static const Color syncLayer = Color(
    0xFF0E7490,
  ); // Sincronización / importador en Light
  static const Color syncLayerDark = Color(
    0xFF06B6D4,
  ); // Sincronización / importador en Dark

  // Advertencias
  static const Color warning = Color(
    0xFFD97706,
  ); // Ámbar dorado accesible en blanco
  static const Color warningLight = Color(
    0xFFFBBF24,
  ); // Ámbar luminoso para modo oscuro

  // Alias retrocompatibles de texto
  static const Color navy = textPrimary;
  static const Color navySoft = textMuted;

  /// Colores semánticos adaptativos según brillo del tema
  static Color primaryFor({required bool isDark}) =>
      isDark ? blueLight : primary;

  static Color incomeFor({required bool isDark}) =>
      isDark ? incomeDark : income;

  static Color expenseFor({required bool isDark}) =>
      isDark ? expenseDark : expense;

  static Color transferFor({required bool isDark}) =>
      isDark ? transferDark : transfer;

  static Color coralFor({required bool isDark}) => isDark ? coralLight : coral;

  static Color blueFor({required bool isDark}) => isDark ? blueLight : blue;

  static Color warningFor({required bool isDark}) =>
      isDark ? warningLight : warning;

  static Color primaryOf(BuildContext context) =>
      primaryFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color incomeOf(BuildContext context) =>
      incomeFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color expenseOf(BuildContext context) =>
      expenseFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color transferOf(BuildContext context) =>
      transferFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color coralOf(BuildContext context) =>
      coralFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color blueOf(BuildContext context) =>
      blueFor(isDark: Theme.of(context).brightness == Brightness.dark);

  static Color warningOf(BuildContext context) =>
      warningFor(isDark: Theme.of(context).brightness == Brightness.dark);

  /// Paleta de colores para modo claro: calibrada para contraste >= 3.5:1 en blanco
  static const List<Color> categoryPaletteLight = <Color>[
    Color(0xFFD32F2F), // rojo
    Color(0xFFE65100), // naranja profundo
    Color(0xFFC27803), // ámbar dorado
    Color(0xFF388E3C), // verde
    Color(0xFF00796B), // teal
    Color(0xFF1565C0), // azul
    Color(0xFF3949AB), // índigo
    Color(0xFF7B1FA2), // púrpura
    Color(0xFFC2185B), // rosa
    Color(0xFF5D4037), // marrón
    Color(0xFF00838F), // cian profundo
    Color(0xFF455A64), // azul pizarra
    Color(0xFFAD1457), // fucsia oscuro
    Color(0xFF00897B), // verde menta
    Color(0xFF283593), // azul medianoche
    Color(0xFF6A1B9A), // morado intenso
    Color(0xFF0277BD), // azul cielo profundo
    Color(0xFF33691E), // verde oliva
    Color(0xFFBF360C), // óxido / teja
    Color(0xFF00695C), // verde esmeralda
    Color(0xFF512DA8), // violeta oscuro
    Color(0xFF880E4F), // borgoña
    Color(0xFFF57F17), // oro oscuro
    Color(0xFF37474F), // carbón pizarra
  ];

  /// Paleta de colores para modo oscuro: luminosos y contrastados (>= 4.5:1 en fondo navy)
  static const List<Color> categoryPaletteDark = <Color>[
    Color(0xFFEF5350), // rojo claro
    Color(0xFFFFA726), // naranja claro
    Color(0xFFFFD54F), // ámbar claro
    Color(0xFF81C784), // verde claro
    Color(0xFF4DB6AC), // teal claro
    Color(0xFF64B5F6), // azul claro
    Color(0xFF9FA8DA), // índigo claro
    Color(0xFFBA68C8), // púrpura claro
    Color(0xFFF06292), // rosa claro
    Color(0xFFBCAAA4), // marrón claro / arena
    Color(0xFF4DD0E1), // cian claro
    Color(0xFF90A4AE), // gris azulado claro
    Color(0xFFFF80AB), // fucsia claro
    Color(0xFF80CBC4), // verde menta claro
    Color(0xFF7986CB), // azul suave
    Color(0xFFCE93D8), // morado suave
    Color(0xFF4FC3F7), // azul cielo claro
    Color(0xFFAED581), // verde lima claro
    Color(0xFFFF8A65), // naranja suave
    Color(0xFFA5D6A7), // esmeralda suave
    Color(0xFFB39DDB), // violeta suave
    Color(0xFFF48FB1), // borgoña claro
    Color(0xFFFFF176), // amarillo claro
    Color(0xFFCFD8DC), // gris perla
  ];

  static List<Color> get categoryPalette => categoryPaletteLight;

  /// Color determinista y bien distribuido para una categoría adaptado al modo de brillo.
  static Color categoryColor(
    String key, {
    bool? isDark,
    BuildContext? context,
  }) {
    final bool dark =
        isDark ??
        (context != null && Theme.of(context).brightness == Brightness.dark);
    final String norm = key.trim().toLowerCase();
    final CategoryStyle? style = CategoryIcon.findStyle(norm);
    if (style != null) {
      return dark ? style.darkColor : style.lightColor;
    }
    // Hash FNV-1a sencillo para repartir mejor que String.hashCode.
    int h = 2166136261;
    for (final int c in norm.codeUnits) {
      h = (h ^ c) * 16777619;
      h &= 0xFFFFFFFF;
    }
    final List<Color> palette = dark
        ? categoryPaletteDark
        : categoryPaletteLight;
    return palette[h % palette.length];
  }
}

/// Estilo visual específico para una categoría (icono y colores con contraste garantizado).
class CategoryStyle {
  final IconData icon;
  final Color lightColor;
  final Color darkColor;

  const CategoryStyle({
    required this.icon,
    required this.lightColor,
    required this.darkColor,
  });
}

/// Asigna un icono representativo a una categoría a partir de su nombre,
/// con iconos circulares.
abstract final class CategoryIcon {
  /// Mapeo exhaustivo y específico para categorías conocidas con sus colores e iconos característicos.
  static const Map<String, CategoryStyle> _categoryStyles =
      <String, CategoryStyle>{
        // Suministros y servicios
        'agua': CategoryStyle(
          icon: Icons.water_drop,
          lightColor: Color(0xFF0288D1),
          darkColor: Color(0xFF4FC3F7),
        ),
        'electricidad': CategoryStyle(
          icon: Icons.bolt,
          lightColor: Color(0xFFFF8F00),
          darkColor: Color(0xFFFFE082),
        ),
        'gas': CategoryStyle(
          icon: Icons.local_fire_department,
          lightColor: Color(0xFFE64A19),
          darkColor: Color(0xFFFF8A65),
        ),
        'internet': CategoryStyle(
          icon: Icons.wifi,
          lightColor: Color(0xFF0097A7),
          darkColor: Color(0xFF80DEEA),
        ),
        'móvil': CategoryStyle(
          icon: Icons.smartphone,
          lightColor: Color(0xFF1976D2),
          darkColor: Color(0xFF64B5F6),
        ),
        'movil': CategoryStyle(
          icon: Icons.smartphone,
          lightColor: Color(0xFF1976D2),
          darkColor: Color(0xFF64B5F6),
        ),
        'televisión': CategoryStyle(
          icon: Icons.tv,
          lightColor: Color(0xFF283593),
          darkColor: Color(0xFF9FA8DA),
        ),
        'television': CategoryStyle(
          icon: Icons.tv,
          lightColor: Color(0xFF283593),
          darkColor: Color(0xFF9FA8DA),
        ),

        // Vivienda e inmuebles
        'hogar': CategoryStyle(
          icon: Icons.home,
          lightColor: Color(0xFF6D4C41),
          darkColor: Color(0xFFA1887F),
        ),
        'hipoteca': CategoryStyle(
          icon: Icons.real_estate_agent,
          lightColor: Color(0xFF1A237E),
          darkColor: Color(0xFF7986CB),
        ),
        'comunidad': CategoryStyle(
          icon: Icons.location_city,
          lightColor: Color(0xFFD84315),
          darkColor: Color(0xFFFF7043),
        ),
        'alquiler y compra': CategoryStyle(
          icon: Icons.apartment,
          lightColor: Color(0xFF4527A0),
          darkColor: Color(0xFFB39DDB),
        ),
        'mantenimiento hogar': CategoryStyle(
          icon: Icons.home_repair_service,
          lightColor: Color(0xFF546E7A),
          darkColor: Color(0xFFB0BEC5),
        ),
        'seguro hogar': CategoryStyle(
          icon: Icons.security,
          lightColor: Color(0xFF5D4037),
          darkColor: Color(0xFFBCAAA4),
        ),

        // Vehículos y transporte
        'gasolina': CategoryStyle(
          icon: Icons.local_gas_station,
          lightColor: Color(0xFFEF6C00),
          darkColor: Color(0xFFFFB74D),
        ),
        'alquiler vehículos': CategoryStyle(
          icon: Icons.car_rental,
          lightColor: Color(0xFFE65100),
          darkColor: Color(0xFFFFB74D),
        ),
        'alquiler vehiculos': CategoryStyle(
          icon: Icons.car_rental,
          lightColor: Color(0xFFE65100),
          darkColor: Color(0xFFFFB74D),
        ),
        'mantenimiento vehículo': CategoryStyle(
          icon: Icons.build,
          lightColor: Color(0xFFBF360C),
          darkColor: Color(0xFFFF8A65),
        ),
        'mantenimiento vehiculo': CategoryStyle(
          icon: Icons.build,
          lightColor: Color(0xFFBF360C),
          darkColor: Color(0xFFFF8A65),
        ),
        'seguro auto': CategoryStyle(
          icon: Icons.directions_car,
          lightColor: Color(0xFF0D47A1),
          darkColor: Color(0xFF64B5F6),
        ),
        'parking y peaje': CategoryStyle(
          icon: Icons.local_parking,
          lightColor: Color(0xFF006064),
          darkColor: Color(0xFF4DD0E1),
        ),
        'transportes': CategoryStyle(
          icon: Icons.directions_bus,
          lightColor: Color(0xFFF57C00),
          darkColor: Color(0xFFFFB74D),
        ),

        // Alimentación
        'supermercado': CategoryStyle(
          icon: Icons.shopping_cart,
          lightColor: Color(0xFF388E3C),
          darkColor: Color(0xFF81C784),
        ),
        'restaurante': CategoryStyle(
          icon: Icons.restaurant,
          lightColor: Color(0xFFD32F2F),
          darkColor: Color(0xFFE57373),
        ),

        // Salud y bienestar
        'farmacia': CategoryStyle(
          icon: Icons.local_pharmacy,
          lightColor: Color(0xFFB71C1C),
          darkColor: Color(0xFFE57373),
        ),
        'médico': CategoryStyle(
          icon: Icons.local_hospital,
          lightColor: Color(0xFF00897B),
          darkColor: Color(0xFF80CBC4),
        ),
        'medico': CategoryStyle(
          icon: Icons.local_hospital,
          lightColor: Color(0xFF00897B),
          darkColor: Color(0xFF80CBC4),
        ),
        'óptica y dentista': CategoryStyle(
          icon: Icons.visibility,
          lightColor: Color(0xFF00ACC1),
          darkColor: Color(0xFF4DD0E1),
        ),
        'optica y dentista': CategoryStyle(
          icon: Icons.visibility,
          lightColor: Color(0xFF00ACC1),
          darkColor: Color(0xFF4DD0E1),
        ),
        'belleza': CategoryStyle(
          icon: Icons.spa,
          lightColor: Color(0xFFD81B60),
          darkColor: Color(0xFFF06292),
        ),
        'seguro vida': CategoryStyle(
          icon: Icons.favorite,
          lightColor: Color(0xFF880E4F),
          darkColor: Color(0xFFEF9A9A),
        ),

        // Ocio, cultura y entretenimiento
        'deporte': CategoryStyle(
          icon: Icons.fitness_center,
          lightColor: Color(0xFF558B2F),
          darkColor: Color(0xFFAED581),
        ),
        'material deportivo': CategoryStyle(
          icon: Icons.sports_soccer,
          lightColor: Color(0xFF33691E),
          darkColor: Color(0xFFAED581),
        ),
        'espectáculos': CategoryStyle(
          icon: Icons.theater_comedy,
          lightColor: Color(0xFF6A1B9A),
          darkColor: Color(0xFFCE93D8),
        ),
        'espectaculos': CategoryStyle(
          icon: Icons.theater_comedy,
          lightColor: Color(0xFF6A1B9A),
          darkColor: Color(0xFFCE93D8),
        ),
        'juegos': CategoryStyle(
          icon: Icons.sports_esports,
          lightColor: Color(0xFF4A148C),
          darkColor: Color(0xFFCE93D8),
        ),
        'suscripciones': CategoryStyle(
          icon: Icons.subscriptions,
          lightColor: Color(0xFF512DA8),
          darkColor: Color(0xFF9575CD),
        ),
        'hotel': CategoryStyle(
          icon: Icons.hotel,
          lightColor: Color(0xFF311B92),
          darkColor: Color(0xFF9575CD),
        ),
        'librería': CategoryStyle(
          icon: Icons.menu_book,
          lightColor: Color(0xFF4E342E),
          darkColor: Color(0xFF8D6E63),
        ),
        'libreria': CategoryStyle(
          icon: Icons.menu_book,
          lightColor: Color(0xFF4E342E),
          darkColor: Color(0xFF8D6E63),
        ),
        'loterías': CategoryStyle(
          icon: Icons.casino,
          lightColor: Color(0xFFF9A825),
          darkColor: Color(0xFFFFEE58),
        ),
        'loterias': CategoryStyle(
          icon: Icons.casino,
          lightColor: Color(0xFFF9A825),
          darkColor: Color(0xFFFFEE58),
        ),
        'otros ocio': CategoryStyle(
          icon: Icons.celebration,
          lightColor: Color(0xFF8E24AA),
          darkColor: Color(0xFFCE93D8),
        ),

        // Compras y estilo
        'ropa': CategoryStyle(
          icon: Icons.checkroom,
          lightColor: Color(0xFF7B1FA2),
          darkColor: Color(0xFFE1BEE7),
        ),
        'electrónica': CategoryStyle(
          icon: Icons.devices,
          lightColor: Color(0xFF0097A7),
          darkColor: Color(0xFF80DEEA),
        ),
        'electronica': CategoryStyle(
          icon: Icons.devices,
          lightColor: Color(0xFF0097A7),
          darkColor: Color(0xFF80DEEA),
        ),
        'regalos': CategoryStyle(
          icon: Icons.card_giftcard,
          lightColor: Color(0xFFE91E63),
          darkColor: Color(0xFFF48FB1),
        ),
        'regalos recibidos': CategoryStyle(
          icon: Icons.redeem,
          lightColor: Color(0xFFAD1457),
          darkColor: Color(0xFFFF4081),
        ),
        'promos': CategoryStyle(
          icon: Icons.local_offer,
          lightColor: Color(0xFFFF8F00),
          darkColor: Color(0xFFFFE082),
        ),
        'servicios y productos online': CategoryStyle(
          icon: Icons.cloud,
          lightColor: Color(0xFF0277BD),
          darkColor: Color(0xFF4FC3F7),
        ),
        'otras compras': CategoryStyle(
          icon: Icons.shopping_bag,
          lightColor: Color(0xFF3949AB),
          darkColor: Color(0xFF7986CB),
        ),
        'niños y mascotas': CategoryStyle(
          icon: Icons.pets,
          lightColor: Color(0xFFC2185B),
          darkColor: Color(0xFFFF80AB),
        ),
        'ninos y mascotas': CategoryStyle(
          icon: Icons.pets,
          lightColor: Color(0xFFC2185B),
          darkColor: Color(0xFFFF80AB),
        ),

        // Finanzas, banca y flujos de dinero
        'nómina': CategoryStyle(
          icon: Icons.paid,
          lightColor: Color(0xFF2E7D32),
          darkColor: Color(0xFFA5D6A7),
        ),
        'nomina': CategoryStyle(
          icon: Icons.paid,
          lightColor: Color(0xFF2E7D32),
          darkColor: Color(0xFFA5D6A7),
        ),
        'ahorros': CategoryStyle(
          icon: Icons.savings,
          lightColor: Color(0xFF1B5E20),
          darkColor: Color(0xFF81C784),
        ),
        'inversiones': CategoryStyle(
          icon: Icons.trending_up,
          lightColor: Color(0xFF00796B),
          darkColor: Color(0xFF4DB6AC),
        ),
        'rendimientos': CategoryStyle(
          icon: Icons.insights,
          lightColor: Color(0xFF00897B),
          darkColor: Color(0xFF80CBC4),
        ),
        'cripto': CategoryStyle(
          icon: Icons.currency_bitcoin,
          lightColor: Color(0xFFF57F17),
          darkColor: Color(0xFFFFD54F),
        ),
        'efectivo': CategoryStyle(
          icon: Icons.payments,
          lightColor: Color(0xFF388E3C),
          darkColor: Color(0xFF81C784),
        ),
        'cargos bancarios': CategoryStyle(
          icon: Icons.price_check,
          lightColor: Color(0xFFC62828),
          darkColor: Color(0xFFEF5350),
        ),
        'tarjeta a débito': CategoryStyle(
          icon: Icons.credit_card,
          lightColor: Color(0xFF1565C0),
          darkColor: Color(0xFF90CAF9),
        ),
        'tarjeta a debito': CategoryStyle(
          icon: Icons.credit_card,
          lightColor: Color(0xFF1565C0),
          darkColor: Color(0xFF90CAF9),
        ),
        'tarjeta crédito': CategoryStyle(
          icon: Icons.credit_score,
          lightColor: Color(0xFFBF360C),
          darkColor: Color(0xFFFFAB91),
        ),
        'tarjeta credito': CategoryStyle(
          icon: Icons.credit_score,
          lightColor: Color(0xFFBF360C),
          darkColor: Color(0xFFFFAB91),
        ),
        'préstamos': CategoryStyle(
          icon: Icons.request_quote,
          lightColor: Color(0xFF880E4F),
          darkColor: Color(0xFFF48FB1),
        ),
        'prestamos': CategoryStyle(
          icon: Icons.request_quote,
          lightColor: Color(0xFF880E4F),
          darkColor: Color(0xFFF48FB1),
        ),
        'transferencias': CategoryStyle(
          icon: Icons.swap_horiz,
          lightColor: Color(0xFF00796B),
          darkColor: Color(0xFF80CBC4),
        ),
        'traspasos y transferencias': CategoryStyle(
          icon: Icons.compare_arrows,
          lightColor: Color(0xFF00838F),
          darkColor: Color(0xFF4DD0E1),
        ),
        'otros cargos y abonos': CategoryStyle(
          icon: Icons.sync_alt,
          lightColor: Color(0xFF607D8B),
          darkColor: Color(0xFFCFD8DC),
        ),
        'otros ingresos': CategoryStyle(
          icon: Icons.arrow_downward,
          lightColor: Color(0xFF43A047),
          darkColor: Color(0xFF81C784),
        ),

        // Instituciones y público
        'impuestos': CategoryStyle(
          icon: Icons.gavel,
          lightColor: Color(0xFF37474F),
          darkColor: Color(0xFF78909C),
        ),
        'devolución impuestos': CategoryStyle(
          icon: Icons.assignment_returned,
          lightColor: Color(0xFF00695C),
          darkColor: Color(0xFF4DB6AC),
        ),
        'devolucion impuestos': CategoryStyle(
          icon: Icons.assignment_returned,
          lightColor: Color(0xFF00695C),
          darkColor: Color(0xFF4DB6AC),
        ),
        'ayuntamiento': CategoryStyle(
          icon: Icons.account_balance,
          lightColor: Color(0xFF455A64),
          darkColor: Color(0xFF90A4AE),
        ),
        'otros organismos': CategoryStyle(
          icon: Icons.corporate_fare,
          lightColor: Color(0xFF546E7A),
          darkColor: Color(0xFFB0BEC5),
        ),
        'asociaciones': CategoryStyle(
          icon: Icons.groups,
          lightColor: Color(0xFF00838F),
          darkColor: Color(0xFF4DD0E1),
        ),
        'solidaridad': CategoryStyle(
          icon: Icons.volunteer_activism,
          lightColor: Color(0xFF2E7D32),
          darkColor: Color(0xFF81C784),
        ),
      };

  static CategoryStyle? findStyle(String normalizedName) =>
      _categoryStyles[normalizedName];

  static const Map<String, IconData> _keywords = <String, IconData>{
    // Frases compuestas específicas (prioritarias sobre palabras individuales)
    'alquiler vehículos': Icons.car_rental,
    'alquiler vehiculos': Icons.car_rental,
    'alquiler y compra': Icons.apartment,
    'mantenimiento vehículo': Icons.build,
    'mantenimiento vehiculo': Icons.build,
    'mantenimiento hogar': Icons.home_repair_service,
    'seguro auto': Icons.directions_car,
    'seguro coche': Icons.directions_car,
    'seguro hogar': Icons.security,
    'seguro vida': Icons.favorite,
    'parking y peaje': Icons.local_parking,
    'óptica y dentista': Icons.visibility,
    'optica y dentista': Icons.visibility,
    'tarjeta a débito': Icons.credit_card,
    'tarjeta a debito': Icons.credit_card,
    'tarjeta crédito': Icons.credit_score,
    'tarjeta credito': Icons.credit_score,
    'devolución impuestos': Icons.assignment_returned,
    'devolucion impuestos': Icons.assignment_returned,
    'traspasos y transferencias': Icons.compare_arrows,
    'otros cargos y abonos': Icons.sync_alt,
    'otros organismos': Icons.corporate_fare,
    'otros ingresos': Icons.arrow_downward,
    'otros ocio': Icons.celebration,
    'otras compras': Icons.shopping_bag,
    'niños y mascotas': Icons.pets,
    'material deportivo': Icons.sports_soccer,
    'servicios y productos online': Icons.cloud,
    'uber eats': Icons.delivery_dining,
    'just eat': Icons.delivery_dining,

    // Supermercado y alimentación
    'super': Icons.shopping_cart,
    'mercado': Icons.shopping_cart,
    'mercadona': Icons.shopping_cart,
    'carrefour': Icons.shopping_cart,
    'lidl': Icons.shopping_cart,
    'aldi': Icons.shopping_cart,
    'dia': Icons.shopping_cart,
    'compra': Icons.shopping_bag,
    'amazon': Icons.shopping_bag,
    // Restauración
    'restaur': Icons.restaurant,
    'comida': Icons.restaurant,
    'café': Icons.local_cafe,
    'cafe': Icons.local_cafe,
    'bar': Icons.local_bar,
    'glovo': Icons.delivery_dining,
    // Transporte y vehículos
    'gasolina': Icons.local_gas_station,
    'combust': Icons.local_gas_station,
    'coche': Icons.directions_car,
    'auto': Icons.directions_car,
    'taller': Icons.build,
    'parking': Icons.local_parking,
    'peaje': Icons.toll,
    'aparcamient': Icons.local_parking,
    'transport': Icons.directions_bus,
    'bus': Icons.directions_bus,
    'tren': Icons.train,
    'renfe': Icons.train,
    'metro': Icons.subway,
    'taxi': Icons.local_taxi,
    'uber': Icons.local_taxi,
    'cabify': Icons.local_taxi,
    'bici': Icons.pedal_bike,
    'moto': Icons.two_wheeler,
    'viaje': Icons.flight,
    'vuelo': Icons.flight,
    'avion': Icons.flight,
    'hotel': Icons.hotel,
    // Suministros y hogar
    'móvil': Icons.smartphone,
    'movil': Icons.smartphone,
    'teléfono': Icons.smartphone,
    'internet': Icons.wifi,
    'fibra': Icons.wifi,
    'luz': Icons.bolt,
    'electric': Icons.bolt,
    'iberdrola': Icons.bolt,
    'endesa': Icons.bolt,
    'agua': Icons.water_drop,
    'gas': Icons.local_fire_department,
    'hogar': Icons.home,
    'alquiler': Icons.home,
    'casa': Icons.home,
    'hipoteca': Icons.real_estate_agent,
    'comunidad': Icons.location_city,
    'limpieza': Icons.cleaning_services,
    'tv': Icons.tv,
    'televis': Icons.tv,
    // Salud y belleza
    'salud': Icons.local_hospital,
    'farmac': Icons.local_pharmacy,
    'médic': Icons.local_hospital,
    'medic': Icons.local_hospital,
    'dentist': Icons.health_and_safety,
    'óptic': Icons.visibility,
    'optic': Icons.visibility,
    'peluquería': Icons.content_cut,
    'peluqueria': Icons.content_cut,
    'belleza': Icons.spa,
    'cosmétic': Icons.face,
    'spa': Icons.spa,
    // Ocio y suscripciones
    'deporte': Icons.fitness_center,
    'gimnas': Icons.fitness_center,
    'ocio': Icons.celebration,
    'cine': Icons.movie,
    'teatro': Icons.theater_comedy,
    'espectacul': Icons.theater_comedy,
    'espectácul': Icons.theater_comedy,
    'música': Icons.music_note,
    'musica': Icons.music_note,
    'suscrip': Icons.subscriptions,
    'netflix': Icons.subscriptions,
    'spotify': Icons.subscriptions,
    'hbo': Icons.subscriptions,
    'disney': Icons.subscriptions,
    'prime': Icons.subscriptions,
    'juego': Icons.sports_esports,
    'videojuego': Icons.sports_esports,
    'steam': Icons.sports_esports,
    'playstation': Icons.sports_esports,
    'xbox': Icons.sports_esports,
    'casino': Icons.casino,
    'loteria': Icons.casino,
    'lotería': Icons.casino,
    // Compras
    'regalo': Icons.card_giftcard,
    'ropa': Icons.checkroom,
    'moda': Icons.checkroom,
    'zapato': Icons.snowshoeing,
    'zapatilla': Icons.snowshoeing,
    'electrón': Icons.devices,
    'electron': Icons.devices,
    'tecnolog': Icons.devices,
    'promo': Icons.local_offer,
    'oferta': Icons.local_offer,
    // Educación y lectura
    'educa': Icons.school,
    'colegio': Icons.school,
    'universidad': Icons.school,
    'curso': Icons.school,
    'libro': Icons.menu_book,
    'librer': Icons.menu_book,
    'mascota': Icons.pets,
    'veterinari': Icons.pets,
    'niñ': Icons.child_care,
    // Finanzas e impuestos
    'impuesto': Icons.gavel,
    'ayuntam': Icons.account_balance,
    'hacienda': Icons.account_balance,
    'ibi': Icons.account_balance,
    'organism': Icons.corporate_fare,
    'asociaci': Icons.groups,
    'solidarid': Icons.volunteer_activism,
    'ong': Icons.volunteer_activism,
    'banco': Icons.account_balance,
    'comisi': Icons.price_check,
    'seguro': Icons.shield,
    'nómina': Icons.paid,
    'nomina': Icons.paid,
    'salario': Icons.paid,
    'sueldo': Icons.paid,
    'ingreso': Icons.arrow_downward,
    'rendimiento': Icons.insights,
    'bizum': Icons.send,
    'transferencia': Icons.swap_horiz,
    'reintegro': Icons.money,
    'cajero': Icons.local_atm,
    'efectivo': Icons.payments,
    'ahorro': Icons.savings,
    'inversión': Icons.trending_up,
    'inversion': Icons.trending_up,
    'cripto': Icons.currency_bitcoin,
    'bitcoin': Icons.currency_bitcoin,
    'dividendo': Icons.percent,
    'préstamo': Icons.request_quote,
    'prestamo': Icons.request_quote,
    'tarjeta': Icons.credit_card,
    'multa': Icons.gavel,
  };

  static IconData forName(String name) {
    final String n = name.trim().toLowerCase();
    final CategoryStyle? style = _categoryStyles[n];
    if (style != null) {
      return style.icon;
    }
    for (final MapEntry<String, IconData> e in _keywords.entries) {
      if (n.contains(e.key)) {
        return e.value;
      }
    }
    return Icons.category_outlined;
  }
}

abstract final class FtTheme {
  static const double radius = 16;
  static const double radiusSmall = 12;

  static final ColorScheme lightScheme =
      ColorScheme.fromSeed(
        seedColor: FtColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: FtColors.primary,
        onPrimary: Colors.white,
        primaryContainer: FtColors.primary.withValues(alpha: 0.12),
        onPrimaryContainer: FtColors.primary,
        secondary: FtColors.transfer,
        onSecondary: Colors.white,
        surface: FtColors.surface,
        onSurface: FtColors.textPrimary,
        onSurfaceVariant: FtColors.textMuted,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: FtColors.surface,
        surfaceContainer: FtColors.bg,
        surfaceContainerHigh: FtColors.sectionHeader,
        surfaceContainerHighest: FtColors.sectionHeader,
        outline: FtColors.border,
        outlineVariant: FtColors.border,
        error: FtColors.expense,
        onError: Colors.white,
      );

  static final ColorScheme darkScheme =
      ColorScheme.fromSeed(
        seedColor: FtColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: FtColors.primary,
        onPrimary: FtColors.textPrimaryDark,
        primaryContainer: FtColors.primary.withValues(alpha: 0.18),
        onPrimaryContainer: FtColors.textPrimaryDark,
        secondary: FtColors.transferDark,
        onSecondary: FtColors.textPrimaryDark,
        surface: FtColors.surfaceDark,
        onSurface: FtColors.textPrimaryDark,
        onSurfaceVariant: FtColors.textMutedDark,
        surfaceContainerLowest: FtColors.bgDark,
        surfaceContainerLow: FtColors.surfaceDark,
        surfaceContainer: FtColors.surfaceDark,
        surfaceContainerHigh: FtColors.sectionHeaderDark,
        surfaceContainerHighest: FtColors.sectionHeaderDark,
        outline: FtColors.borderDark,
        outlineVariant: FtColors.borderDark,
        error: FtColors.expenseDark,
        onError: FtColors.textPrimaryDark,
      );

  static ThemeData light() => _base(lightScheme, FtColors.bg);
  static ThemeData dark() => _base(darkScheme, FtColors.bgDark);

  static ThemeData _base(ColorScheme scheme, Color scaffold) {
    final bool isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData(brightness: scheme.brightness).textTheme,
      ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        shape: const RoundedRectangleBorder(),
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: 3,
        height: 68,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? FtColors.sectionHeaderDark
            : FtColors.sectionHeader,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
