import 'package:ecommerce_app/models/cart_item_model.dart';
import 'package:ecommerce_app/models/product_model.dart';
//import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartCubit extends Cubit<List<CartItem>>{
    CartCubit():super([]);
    void addToCart(Product product){


int index=state.indexWhere(
 (item)=>item.product.name ==product.name,
);
List<CartItem>updatedCard =[...state];

if(index == -1){
updatedCard.add(CartItem(product, 1));
}else{
    updatedCard[index].quantity+=1;
}
emit(updatedCard);
    }

    void increaseQuantity(String productName){
int index = state.indexWhere(
  (item)=>item.product.name == productName,
);
List<CartItem>updatedCard=[...state];
if(index !=-1){
updatedCard[index].quantity+=1;

}emit(updatedCard);
    }

      void decreaseQuantity(String productName){
int index = state.indexWhere(
  (item)=>item.product.name == productName,
);
List<CartItem>updatedCard=[...state];
if(index !=-1){
if(updatedCard[index].quantity >1){

  updatedCard[index].quantity-=1;
}else{updatedCard.removeAt(index);}


}emit(updatedCard);
    }

   void removeFromCart(String productName){
  List<CartItem>updatedCard=[...state];
  int index = state.indexWhere(
  (item)=>item.product.name == productName,
  );
  if(index !=-1){
  updatedCard.removeAt(index);
  emit(updatedCard);
  }
   }


int getTotalPrice(){
  int total = 0;
  for (var item in state){
    total += item.product.price * item.quantity;
  }return total;
}
void clearCart(){
  emit([]);
}
}
