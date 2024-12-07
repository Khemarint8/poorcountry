import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// Product Model
class Product {
  final int id;
  final String title;
  final String description;
  final String image;
  final double price;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      image: json['image'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

// Controller for managing products and cart
class ProductController extends GetxController {
  var isLoading = true.obs;
  var products = <Product>[].obs;
  var cartItems = <Product>[].obs;

  @override
  void onInit() {
    fetchProducts();
    super.onInit();
  }

  void fetchProducts() async {
    try {
      isLoading(true);
      final response =
          await http.get(Uri.parse('https://fakestoreapi.com/products'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body) as List;
        products.value = data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch products");
    } finally {
      isLoading(false);
    }
  }

  void addToCart(Product product) {
    cartItems.add(product);
  }

  void removeFromCart(Product product) {
    cartItems.remove(product);
  }
}

// HomeScreen Widget
class HomeScreen extends StatelessWidget {
  final ProductController productController = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () {
              Get.to(CartPage());
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(Icons.shopping_cart),
                ),
                Obx(() => Positioned(
                      right: 6,
                      top: 6,
                      child: productController.cartItems.isEmpty
                          ? SizedBox.shrink()
                          : Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${productController.cartItems.length}',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                    )),
              ],
            ),
          ),
        ],
      ),
      body: HomeComponent(),
    );
  }
}

// HomeComponent Widget
class HomeComponent extends StatelessWidget {
  final ProductController productController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (productController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate number of columns dynamically based on screen width
            int crossAxisCount =
                constraints.maxWidth ~/ 120; // Adjust item width here

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio:
                    0.6, // Adjust height-to-width ratio for each item
              ),
              itemCount: productController.products.length,
              itemBuilder: (context, index) {
                final product = productController.products[index];
                return Card(
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              Get.to(ProductDetailPage(product: product)),
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(
                              product.image,
                              fit: BoxFit
                                  .cover, // Ensures the image covers the container completely
                              width: double
                                  .infinity, // Makes the image take full width
                              height: double
                                  .infinity, // Makes the image take full height
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add, size: 18),
                            onPressed: () =>
                                productController.addToCart(product),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove, size: 18),
                            onPressed: () =>
                                productController.removeFromCart(product),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
}

// ProductDetailPage Widget
class ProductDetailPage extends StatelessWidget {
  final Product product;

  ProductDetailPage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(product.image, height: 200),
            ),
            SizedBox(height: 16),
            Text(product.title,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('\$${product.price.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, color: Colors.green)),
            SizedBox(height: 16),
            Text(product.description, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// CartPage Widget
class CartPage extends StatelessWidget {
  final ProductController productController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cart"),
      ),
      body: Obx(() {
        if (productController.cartItems.isEmpty) {
          return Center(child: Text("Your cart is empty."));
        }
        return ListView.builder(
          itemCount: productController.cartItems.length,
          itemBuilder: (context, index) {
            final product = productController.cartItems[index];
            return ListTile(
              leading: Image.network(product.image, width: 50, height: 50),
              title: Text(product.title),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            );
          },
        );
      }),
    );
  }
}
