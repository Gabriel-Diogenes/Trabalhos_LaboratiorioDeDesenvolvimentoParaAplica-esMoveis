import 'dart:io';

void main(){

print('Calculando a soma e a media de dois numeros');
stdout.write('Digite o primeiro numero: ');
int? num1 = int.parse(stdin.readLineSync() ?? '0');

stdout.write('Digite o segundo numero: ');
int? num2 = int.parse(stdin.readLineSync() ?? '0');

int soma = num1 + num2;
double media = (num1 + num2) / 2;

print('A soma dos dois numeros é = $soma e a média é = $media');
}