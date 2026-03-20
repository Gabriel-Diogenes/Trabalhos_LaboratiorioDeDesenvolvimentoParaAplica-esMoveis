import 'dart:io';

void main(){
  //Imprimir a mensagem
  print('Hello,Dart!');

  stdout.write('Digite seu nome: ');

  String? nome = stdin.readLineSync();
  print('Hello, $nome!');

}