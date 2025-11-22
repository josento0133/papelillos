import 'package:flutter/material.dart';
import 'nombres_jugadores_screen.dart';

class ConfiguracionJuegoScreen extends StatefulWidget {
  final bool modoAleatorio;
  final bool modoTodasPalabrasAleatorias;

  ConfiguracionJuegoScreen({
    required this.modoAleatorio,
    required this.modoTodasPalabrasAleatorias,
  });

  @override
  _ConfiguracionJuegoScreenState createState() =>
      _ConfiguracionJuegoScreenState();
}

class _ConfiguracionJuegoScreenState extends State<ConfiguracionJuegoScreen> {
  // Valores por defecto y rangos
  int _numeroJugadores = 4; // Mínimo 4, debe ser par
  double _tiempoPorRonda = 30; // Usamos double para el Slider, luego lo convertimos a int
  int _palabrasPorJugador = 2; // Mínimo 2

  // Solo necesitamos el controlador para las palabras, ya que es un TextField
  final TextEditingController _palabrasController = TextEditingController(text: '2');
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


  // Método para validar solo el campo de Palabras (si es visible)
  bool _validarCampos() {
    // Si el modo aleatorio total está desactivado, debemos validar el campo de palabras.
    if (!widget.modoTodasPalabrasAleatorias && _palabrasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa el número de palabras por jugador.', style: TextStyle(fontSize: 18))),
      );
      return false;
    }
    return true;
  }

  // Método para guardar la configuración
  void _guardarConfiguracion() {
    if (_validarCampos()) {
      // Asegurar que el valor del TextField se parsee si el modo no es aleatorio total
      if (!widget.modoTodasPalabrasAleatorias) {
        int? parsedValue = int.tryParse(_palabrasController.text);
        if (parsedValue == null || parsedValue < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Palabras por jugador debe ser un número válido (min. 2).', style: TextStyle(fontSize: 18))),
          );
          return;
        }
        _palabrasPorJugador = parsedValue;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NombresJugadoresScreen(
            modoAleatorio: widget.modoAleatorio,
            numeroJugadores: _numeroJugadores,
            palabras: [], // La lista de palabras se llenará en NombresJugadoresScreen
            palabrasPorJugador: _palabrasPorJugador,
            tiempoPorRonda: _tiempoPorRonda.round(), // Convertimos el double a int
            modoTodasPalabrasAleatorias: widget.modoTodasPalabrasAleatorias,
          ),
        ),
      );
    }
  }

  // Limpieza del controlador al salir del widget
  @override
  void dispose() {
    _palabrasController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Usamos el color de tema para consistencia


    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración del Juego'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // --- 1. Número de Jugadores (Stepper) ---
            Text('Número de Jugadores (min. 4, par):', style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_numeroJugadores', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, size: 40, color: _numeroJugadores > 4 ? Colors.redAccent : Colors.grey),
                      onPressed: _numeroJugadores > 4
                          ? () => setState(() => _numeroJugadores -= 2)
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, size: 40, color: Colors.blue),
                      onPressed: () => setState(() => _numeroJugadores += 2),
                    ),
                  ],
                ),
              ],
            ),

            Divider(height: 30),

            // --- 2. Tiempo por Ronda (Slider) ---
            Text('Tiempo por Ronda (segundos):', style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    activeColor: Colors.blue,
                    value: _tiempoPorRonda,
                    min: 15,
                    max: 60,
                    divisions: 9, // Saltos de 5 en 5 (15, 20, 25... 60)
                    label: '${_tiempoPorRonda.round()} s',
                    onChanged: (double value) {
                      setState(() {
                        _tiempoPorRonda = value;
                      });
                    },
                  ),
                ),
                Text('${_tiempoPorRonda.round()} s', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
              ],
            ),

            Divider(height: 30),

            // --- 3. Palabras por Jugador (Condicional) ---
            // Solo se muestra si NO está activado el modo aleatorio de palabras totales

              Text('Palabras por Jugador (min. 2):', style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
              TextField(
                controller: _palabrasController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Min: 2 palabras',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                ),
                style: TextStyle(fontSize: 24),
              ),

              Divider(height: 30),


            // Espacio flexible
            Spacer(),

            // --- 4. Botón de Continuar ---
            // --- 4. Botón de Continuar ---
            ElevatedButton(
              onPressed: _guardarConfiguracion,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: TextStyle(fontSize: 24, color: Colors.white),

                // CAMBIO AQUÍ: Usamos Colors.blue directamente
                backgroundColor: Colors.blue,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Guardar y Continuar'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}