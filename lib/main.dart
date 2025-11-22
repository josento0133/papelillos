import 'package:flutter/material.dart';
import 'configuracion_juego_screen.dart';

void main() {
  // ensureInitialized() no es necesario a menos que uses plugins que requieran inicialización nativa *antes* de runApp.
  // Como no hay plugins async aquí, lo omitimos para mayor limpieza, o lo mantenemos si lo necesitas para otras partes del app.
  // WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papelillos',
      theme: ThemeData(
        // Tema primario en azul
        primarySwatch: Colors.blue,
        // Configuración de elevación para botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Color por defecto para todos los botones
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Espacio inicial flexible
          const Spacer(flex: 2),

          // Título en grande
          const Text(
            'Papelillos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              color: Colors.blue,
            ),
          ),

          const Spacer(flex: 1),

          // --- Botones de Modo de Juego ---

          // Modo Normal (Manual)
          _BotonModo(
            texto: 'Modo Normal (Manual)',
            modoAleatorio: false,
            modoTodasPalabrasAleatorias: false,
            color: Colors.blue,
          ),

          const SizedBox(height: 15),

          // Con Palabras Online (Mezclando manual y aleatorio)
          _BotonModo(
            texto: 'Con Palabras Online (Mixto)',
            modoAleatorio: true,
            modoTodasPalabrasAleatorias: false,
            color: Colors.lightBlue,
          ),

          const SizedBox(height: 15),

          // Todas las Palabras Aleatorias (Solo API)
          _BotonModo(
            texto: 'Todas las Palabras Aleatorias',
            modoAleatorio: false,
            modoTodasPalabrasAleatorias: true,
            color: Colors.cyan, // Un tono diferente para destacar
          ),

          const Spacer(flex: 2), // Espacio final flexible
        ],
      ),
    );
  }
}

// Widget auxiliar para crear botones de modo de juego de forma DRY
class _BotonModo extends StatelessWidget {
  final String texto;
  final bool modoAleatorio;
  final bool modoTodasPalabrasAleatorias;
  final Color color;

  const _BotonModo({
    required this.texto,
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracionJuegoScreen(
                modoAleatorio: modoAleatorio,
                modoTodasPalabrasAleatorias: modoTodasPalabrasAleatorias,
              ),
            ),
          );
        },
        // Sobrescribimos el color de fondo solo para esta instancia
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        child: Text(texto),
      ),
    );
  }
}