import 'package:flutter/material.dart';
import 'nombres_jugadores_screen.dart';

class ConfiguracionJuegoScreen extends StatefulWidget {
  final bool modoAleatorio; // Para elegir el modo
  final bool modoTodasPalabrasAleatorias; // Agregar este parámetro

  ConfiguracionJuegoScreen({
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias, // Asegúrate de pasarlo también aquí
  });

  @override
  _ConfiguracionJuegoScreenState createState() =>
      _ConfiguracionJuegoScreenState();
}

class _ConfiguracionJuegoScreenState extends State<ConfiguracionJuegoScreen> {
  int _numeroJugadores = 4; // Valor por defecto
  int _tiempoPorRonda = 30; // Valor por defecto
  int _palabrasPorJugador = 2; // Valor por defecto

  List<String> palabras = [];

  // Controladores para los campos de texto
  final TextEditingController _jugadoresController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();
  final TextEditingController _palabrasController = TextEditingController();

  // Método para validar los campos
  bool _validarCampos() {
    if (_jugadoresController.text.isEmpty ||
        _tiempoController.text.isEmpty ||
          // Validar si el total de palabras es válido
        (!widget.modoTodasPalabrasAleatorias && _palabrasController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, completa todos los campos.', style: TextStyle(fontSize: 24))),
      );
      return false;
    }
    return true;
  }

  // Método para guardar la configuración en Firestore
  void _guardarConfiguracion() {
    if (_validarCampos()) {
      // Navegar directamente a la pantalla de NombresJugadores
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NombresJugadoresScreen(
            modoAleatorio: widget.modoAleatorio,
            numeroJugadores: _numeroJugadores,
            palabras: palabras,
            palabrasPorJugador: _palabrasPorJugador, // Usar el total de palabras si está activado el modo
            tiempoPorRonda: _tiempoPorRonda,
            modoTodasPalabrasAleatorias: widget.modoTodasPalabrasAleatorias, // Pasa este parámetro aquí
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración del Juego'),
        automaticallyImplyLeading: false, // Esto oculta la flecha de retroceso
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Número de Jugadores
            TextField(
              controller: _jugadoresController,
              decoration: InputDecoration(
                labelText: 'Número de Jugadores (min. 4):',
                labelStyle: TextStyle(fontSize: 24, color: Colors.lightBlue), // Cambia el tamaño de la etiqueta
                contentPadding: EdgeInsets.symmetric(vertical: 16.0),
              ),
              style: TextStyle(fontSize: 24),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                int? parsedValue = int.tryParse(value);
                if (parsedValue != null && parsedValue >= 4 && parsedValue % 2 == 0) {
                  setState(() {
                    _numeroJugadores = parsedValue;
                  });
                }
              },
            ),

            // Tiempo por ronda
            TextField(
              controller: _tiempoController,
              decoration: InputDecoration(
                labelText: 'Tiempo por Ronda (por defecto 30 seg.):',
                labelStyle: TextStyle(fontSize: 24, color: Colors.lightBlue),
                contentPadding: EdgeInsets.symmetric(vertical: 16.0),
              ),
              style: TextStyle(fontSize: 24),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                int? parsedValue = int.tryParse(value);
                if (parsedValue != null && parsedValue <= 60) {
                  setState(() {
                    _tiempoPorRonda = parsedValue;
                  });
                }
              },
            ),


              TextField(
                controller: _palabrasController,
                decoration: InputDecoration(
                  labelText: 'Palabras por Jugador (min. 2):',
                  labelStyle: TextStyle(fontSize: 24, color: Colors.lightBlue),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                style: TextStyle(fontSize: 24),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  int? parsedValue = int.tryParse(value);
                  if (parsedValue != null && parsedValue >= 2) {
                    setState(() {
                      _palabrasPorJugador = parsedValue;
                    });
                  }
                },
              ),

            SizedBox(height: 70),
            ElevatedButton(
              onPressed: _guardarConfiguracion,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: TextStyle(fontSize: 24, color: Colors.white),
                backgroundColor: Colors.lightBlue, // Azul eterno
              ),
              child: Text('Guardar y Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
