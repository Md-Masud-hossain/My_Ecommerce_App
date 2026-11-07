import 'package:ecommerce_app/bloc/cart/cart_cubit.dart';
import 'package:ecommerce_app/bloc/product/product_bloc.dart';
import 'package:ecommerce_app/bloc/product/product_event.dart';
import 'package:ecommerce_app/bloc/product/product_state.dart';
import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/repositories/product_repository.dart';
import 'package:ecommerce_app/screens/auth_screen.dart';
import 'package:ecommerce_app/screens/auth_service.dart';
import 'package:ecommerce_app/screens/cart_page.dart';
import 'package:ecommerce_app/screens/product_details_page.dart';
import 'package:firebase_core/firebase_core.dart'; // নতুন
import 'firebase_options.dart'; // নতুন
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  // async হলো
  WidgetsFlutterBinding.ensureInitialized(); // নতুন
  await Firebase.initializeApp(
    // নতুন
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ProductBloc(ProductRepository())),
        BlocProvider(create: (context) => CartCubit()),
      ],
      child: MaterialApp(
        // লগইন না থাকলে AuthScreen, থাকলে HomePage
        home: const AuthGate(child: HomePage()),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProduct());
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        title: Text("Zeynep", style: TextStyle(color: Colors.black87)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
            icon: Icon(Icons.shopping_cart),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => confirmAndLogout(context),
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return CircularProgressIndicator();
          }
          if (state is ProductSuccess) {
            return GridView.builder(
              itemCount: state.products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final product = state.products[index];

                return Card(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text("Image not found"),
                              );
                            },
                          ),
                        ),

                        Text(product.name, style: TextStyle(fontSize: 18)),
                        Text(
                          "${product.price}",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(product.category),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailsPage(product: product),
                                  ),
                                );
                              },
                              child: Text("View Details"),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                context.read<CartCubit>().addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Product added")),
                                );
                              },
                              child: Text("Add to Cart"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          if (state is ProductError) {
            return Text(state.message, style: TextStyle(fontSize: 20));
          }
          return SizedBox();
        },
      ),
    );
  }
}
