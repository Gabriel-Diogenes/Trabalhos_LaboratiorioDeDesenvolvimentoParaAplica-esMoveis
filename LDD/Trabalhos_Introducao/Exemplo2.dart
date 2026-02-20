void main(){
  
  List<int> numeros = [10,5,3,8,2];

  print('Lista original: $numeros');

  numeros.add(7);

  print('Lista atualizada com o valor 7: $numeros');


  numeros.remove(5);

  print('Lista com o valor 5 removido: $numeros');

  numeros.sort();

  print('Lista ordenada: $numeros');
}