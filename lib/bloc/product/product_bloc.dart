import 'package:ecommerce_app/bloc/product/product_event.dart';
import 'package:ecommerce_app/bloc/product/product_state.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  ProductBloc(this.repository) : super(ProductLoading()) {
    on<LoadProduct>((event, emit) async {
      try {
        emit(ProductLoading());
    List<Product> products = await repository.getProducts();

        emit(ProductSuccess(products));
      } catch (e) {
        emit(ProductError("Something Went Wrong"));
      }
    });
  }
}
