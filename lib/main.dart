import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculadora',
      theme: ThemeData.dark(),
      home: Calculadora(),
    );
  }
}

class Calculadora extends StatefulWidget{
  const Calculadora({super.key});

  @override
  State<Calculadora> createState() => _CalculadoraState();
}

class _CalculadoraState extends State<Calculadora> {

  //guardar todo la operacion en un string
  String expresion = '';

  //onButtonPress maneja la logica de la calculadora
  void onButtonPress(String texto){
    setState(() {
      if("0123456789".contains(texto)){
        
        //si la expresion termina en un parentesis cerrado, no permitir agregar numero
        if (expresion.endsWith(')')) return;
        expresion += texto;

      }
      else if ("+-×÷".contains(texto)) {
        if (expresion.isEmpty) return;
        // no permitir dos operadores seguidos
        if ("+-×÷(".contains(expresion[expresion.length - 1])) return;
        expresion += " $texto ";
      }
      else if(texto == '( )'){
        int abiertos = '('.allMatches(expresion).length;
        int cerrados = ')'.allMatches(expresion).length;

        //verficiar si se debe abrir o cerrar parentesis
        if (expresion.isEmpty || "+-×÷(".contains(expresion.trim().characters.last)) {
          expresion += "( ";
        } else if (abiertos > cerrados) {
          expresion += " )";
        }
      }else if (texto == '%') {
        if (expresion.isEmpty) return;
        // no permitir % despues de un operador
        if ("+-×÷(".contains(expresion.trim().characters.last)) return;
        expresion += " %";
      } else if (texto == '+÷-') {
        // cambiar el signo del último número ingresado
        List<String> partes = expresion.split(' ');
        if (partes.isEmpty) return;

        String ultimo = partes.last;
        if (esNumero(ultimo)) {
          double num = double.parse(ultimo) * -1;
          partes[partes.length - 1] = num.toString();
          expresion = partes.join(' ');
        }
      }
      else if (texto == ".") {
        if (expresion.endsWith(")")) return;

        // obtener el último número que se está escribiendo
        List<String> partes = expresion.split(' ');
        String ultimo = partes.isNotEmpty ? partes.last : "";

        if (ultimo.contains(".")) return; // ya tiene punto

        if (expresion.isEmpty || "+-×÷(".contains(expresion.characters.last)) {
          expresion += "0.";
        } else {
          expresion += ".";
        }
      }
      else if(texto == 'C'){
        expresion = '';      
      }
      else if (texto == '=') {
        String normalizada = expresion
            .replaceAll('(', ' ( ')
            .replaceAll(')', ' ) ')
            .replaceAll('+', ' + ')
            .replaceAll('-', ' - ')
            .replaceAll('×', ' × ')
            .replaceAll('÷', ' ÷ ');

        List<String> tokens = normalizada.split(' ').where((e) => e.isNotEmpty).toList();

        CalcError? error = validarExpresion(tokens);

        if (error != null) {
          expresion = error.mensaje();
          return;
        }

        try {
          double res = evaluar(tokens);
          if (res.isInfinite) {
            expresion = "MathError";
          } else if (res.isNaN) {
            expresion = "MathError";
          } else {
            expresion = res.toString();
          }
        } catch (e) {
          expresion = MathError().mensaje();
        }
      }
    });
  }


  //boolean para verificar si un string es un numero
  bool esNumero(String s) => double.tryParse(s) != null;

  //funcion para validar la expresion
  CalcError? validarExpresion(List<String> tokens) {
    int balance = 0;
    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];

      if (token == '(') balance++;
      else if (token == ')') {
        balance--;
        if (balance < 0) return SyntaxError();
      }

      if (i == 0 && "+×÷".contains(token)) return SyntaxError();
      if (i == tokens.length - 1 && "+-×÷(".contains(token)) return SyntaxError();

      if (i < tokens.length - 1) {
        String a = tokens[i];
        String b = tokens[i + 1];

        if ((double.tryParse(a) != null && double.tryParse(b) != null) ||
            (a == ')' && double.tryParse(b) != null) ||
            (double.tryParse(a) != null && b == '(') ||
            (a == ')' && b == '(')) {
          return SyntaxError();
        }

       if ("+-×÷".contains(a) && "+-×÷".contains(b)) return SyntaxError();

      }
    }

    if (balance != 0) return SyntaxError();
    return null;

  }

  double evaluar(List<String> tokens) {
    while (tokens.contains('(')) {
      int i = tokens.lastIndexOf('(');
      int j = tokens.indexOf(')', i);
      double sub = evaluar(tokens.sublist(i + 1, j));
      tokens.replaceRange(i, j + 1, [sub.toString()]);
    }

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '×' || tokens[i] == '÷') {
        double a = double.parse(tokens[i - 1]);
        double b = double.parse(tokens[i + 1]);
        double r = tokens[i] == '×' ? a * b : a / b;
        tokens.replaceRange(i - 1, i + 2, [r.toString()]);
        i--;
      }
    }

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == '+' || tokens[i] == '-') {
        double a = double.parse(tokens[i - 1]);
        double b = double.parse(tokens[i + 1]);
        double r = tokens[i] == '+' ? a + b : a - b;
        tokens.replaceRange(i - 1, i + 2, [r.toString()]);
        i--;
      }
    }

    return double.parse(tokens.first);
  }

  //funcion para evaluar parentesis
  double evaluarSinParentesis(List<String> tokens){
    //Prioridad a parentesis
    while(tokens.contains('(')){
      //encontrar la primera apertura de parentesis
      int inicio = tokens.lastIndexOf('(');
      //encontrar el cierre correspondiente
      int fin = tokens.indexOf(')', inicio);
      //tomamos la sublista dentro del parentesis
      List<String> subLista = tokens.sublist(inicio + 1, fin);
      //calcular el resultado de la sublista
      double res = resultado(subLista);

      tokens.removeRange(inicio, fin + 1);
      tokens.insert(inicio, res.toString());

    }

    return resultado(tokens);
  }

  //funcion para devolver el resultado de la operacion
  double resultado(List<String> tokens){

    //Prioridad a multiplicacion y division
    for(int i=0; i< tokens.length; i++){
      if(tokens[i] == '×' || tokens[i] == '÷'){
        //tomar los numeros para hacer la operacion
        double num1 = double.parse(tokens[i-1]);
        double num2 = double.parse(tokens[i+1]);

        //realizar la operacion con operador ternario
        double res = tokens[i] == '×' ? num1 * num2 : num1 / num2;
        
        //quitar los elementos de la lista
        tokens.removeAt(i + 1);
        tokens.removeAt(i);
        tokens[i - 1] = res.toString();

        i --; 

      }
    }

    //segunda pasada para suma y resta
    for(int i=0; i< tokens.length; i++){
      if(tokens[i] == '+' || tokens[i] == '-'){
        double num1 = double.parse(tokens[i-1]);
        double num2 = double.parse(tokens[i+1]);
        double res = tokens[i] == '+' ? num1 + num2 : num1 - num2;
        tokens.removeAt(i + 1);
        tokens.removeAt(i);
        tokens[i - 1] = res.toString();
        i --;
      }
    }
    return double.parse(tokens[0]);

    
  }
 
  //funcion por simplicidad
  Widget boton(String texto) {
    Color colorBoton;

    if ("+-%×÷.( )".contains(texto)) {
      colorBoton = Colors.black87;        // operadores
    }
    else if (texto == "=") {
      colorBoton = const Color.fromARGB(255, 78, 190, 82);         // igual
    } else if (texto == "C") {
      colorBoton = Colors.red;           // borrar
    } else {
      colorBoton = const Color.fromARGB(255, 30, 31, 32); // números
    }

    return ElevatedButton(
      onPressed: () => onButtonPress(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorBoton,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(60),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 28,
          color: Colors.white,
        ),
      ),
    );
  }


  Widget displayWidget(double size) {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(30),
      child: Text(
        expresion.isEmpty ? '0' : expresion,
        style: TextStyle(fontSize: size, color: Colors.white),
      ),
    );
  }
  
  Widget gridBotones(Orientation orientation) {
    int columnas = orientation == Orientation.portrait ? 4 : 4;
    double aspectRatio = orientation == Orientation.portrait ? 1 : 2.4;

    // Aquí puedes reorganizar los botones solo si estás en horizontal
    List<String> botones = orientation == Orientation.portrait
        ? ["C","( )","%","÷","7","8","9","×","4","5","6","-","1","2","3","+","+/-","0",".","="]
        : ["C","( )","%","÷","7","8","9","×","4","5","6","-","1","2","3","+","0","+/-",".","="];

    return GridView.count(
      crossAxisCount: columnas,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      padding: const EdgeInsets.all(5),
      childAspectRatio: aspectRatio,
      children: botones.map((b) => boton(b)).toList(),
    );
  }


  Widget layoutVertical() {
    return Column(
      children: [
        //ajustamos el flex para que el display ocupe mas espacio
        Expanded(flex: 2, child: displayWidget(70)),
        Expanded(flex: 4, child: gridBotones(Orientation.portrait)),
      ],
    );
  }

  Widget layoutHorizontal() {
    return Row(
      children: [
        Expanded(flex: 2, child: displayWidget(40)),
        Expanded(flex: 4, child: gridBotones(Orientation.landscape)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora")),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
              ? layoutVertical()
              : layoutHorizontal();
        },
      ),
    );
  }
}

//Manejo de posibles errores matematicos y de sintaxis
abstract class CalcError {
String mensaje();
}

class SyntaxError extends CalcError {
  @override
  String mensaje() => "SyntaxError";
}

class MathError extends CalcError {
  @override
  String mensaje() => "MathError";
}
