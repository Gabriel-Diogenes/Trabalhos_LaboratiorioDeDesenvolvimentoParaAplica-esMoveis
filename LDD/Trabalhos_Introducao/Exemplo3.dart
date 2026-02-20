class Carro{
   String marca;
   String modelo;
   int ano;

   Carro(this.marca,this.modelo,this.ano);

   void detalhes(){
    print('Marca: $marca, Modelo: $modelo, ano: $ano');
   }

   bool isNovo(){
    return ano == DateTime.now().year;
   }
  
}

void main(){
  Carro carro1 = Carro('Toyota', 'Corolla', 2026);
  Carro carro2 = Carro('Honda', 'Civic', 2022);

  carro1.detalhes();
  carro2.detalhes();

  // Verificar se os carros são novos
  print('O carro ${carro1.modelo} é novo? ${carro1.isNovo()}');
  print('O carro ${carro2.modelo} é novo? ${carro2.isNovo()}');
}