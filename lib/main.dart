import 'package:flutter/material.dart';
import 'configuracion_juego_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Papelillos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Título en grande
          Center(
            child: Text(
              'Papelillos',
              style: TextStyle(
                fontSize: 50, // Tamaño grande para el título
                fontWeight: FontWeight.bold, // Negrita
                color: Colors.blue, // Color azul
              ),
            ),
          ),
          SizedBox(height: 100), // Espacio entre el título y los botones

          // Botón para iniciar en modo normal
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfiguracionJuegoScreen(
                      modoAleatorio: false,
                      modoTodasPalabrasAleatorias: false, // Modo normal
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Tamaño del botón
                textStyle: TextStyle(fontSize: 24, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightBlueAccent, // Azul
              ),
              child: Text('Modo Normal'),
            ),
          ),

          SizedBox(height: 20), // Espacio entre los botones

          // Botón para iniciar en modo palabras aleatorias
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfiguracionJuegoScreen(
                      modoAleatorio: true,
                      modoTodasPalabrasAleatorias: false, // Modo palabras online
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Tamaño del botón
                textStyle: TextStyle(fontSize: 24, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightBlueAccent, // Azul
              ),
              child: Text('Con Palabras Online'),
            ),
          ),

          SizedBox(height: 20), // Espacio entre los botones

          // Nuevo botón para iniciar en "Todas las Palabras Aleatorias"
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfiguracionJuegoScreen(
                      modoAleatorio: false,
                      modoTodasPalabrasAleatorias: true, // Modo todas las palabras aleatorias
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Tamaño del botón
                textStyle: TextStyle(fontSize: 24, color: Colors.white), // Tamaño y color del texto
                backgroundColor: Colors.lightBlueAccent, // Azul
              ),
              child: Text('Todas las Palabras Aleatorias'),
            ),
          ),
        ],
      ),
    );
  }
}
