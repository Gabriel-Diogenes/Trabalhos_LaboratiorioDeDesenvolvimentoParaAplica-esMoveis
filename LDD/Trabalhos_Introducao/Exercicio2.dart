import 'dart:io';

void main(){

  List<String> amigos = ['Fernando', 'Rafael', 'Davi'];
  print('Está e uma lista de amigos: $amigos');
  stdout.write('Digite o nome do seu amigo para adicionar a lista: ');
  String? amigo = stdin.readLineSync();

  amigos.add(amigo!);

  print('O ${amigos[0]} foi excluido da lista');
  amigos.removeAt(0);

  print('Lista de amigos: $amigos');

}