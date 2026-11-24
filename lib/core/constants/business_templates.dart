import 'package:pocket_karcha/data/models/product_model.dart';

class TemplateItem {
  const TemplateItem(this.name, this.price, {this.variants = const []});

  final String name;
  final double price;
  final List<ProductVariant> variants;

  ProductModel toProduct({String category = ''}) => ProductModel(
        id: '',
        name: name,
        price: variants.isEmpty ? price : 0,
        category: category,
        variants: variants,
      );
}

/// Kinds of shop with ready starter items (PKR prices, edited during setup).
class BusinessTemplate {
  const BusinessTemplate({
    required this.key,
    required this.emoji,
    required this.en,
    required this.ur,
    this.items = const [],
  });

  final String key;
  final String emoji;
  final String en;
  final String ur;
  final List<TemplateItem> items;

  String label(bool urdu) => urdu ? ur : en;
}

abstract final class BusinessTemplates {
  static const List<BusinessTemplate> all = [
    BusinessTemplate(
      key: 'juice',
      emoji: '🥤',
      en: 'Juice & shakes',
      ur: 'جوس اور شیک',
      items: [
        TemplateItem('Mango Shake', 250),
        TemplateItem('Banana Shake', 200),
        TemplateItem('Strawberry Shake', 250),
        TemplateItem('Fresh Orange Juice', 200),
        TemplateItem('Apple Juice', 220),
        TemplateItem('Anaar Juice', 300),
        TemplateItem('Fresh Lime', 120),
        TemplateItem('Mint Margarita', 180),
      ],
    ),
    BusinessTemplate(
      key: 'chaat',
      emoji: '🍓',
      en: 'Fruit chaat & snacks',
      ur: 'فروٹ چاٹ اور سنیکس',
      items: [
        TemplateItem(
          'Fruit Chaat',
          150,
          variants: [
            ProductVariant(name: 'Small', price: 150),
            ProductVariant(name: 'Large', price: 250),
          ],
        ),
        TemplateItem('Dahi Bhallay', 150),
        TemplateItem('Chana Chaat', 120),
        TemplateItem('Papri Chaat', 150),
        TemplateItem('Samosa (2 pcs)', 80),
        TemplateItem('Gol Gappay (8 pcs)', 100),
      ],
    ),
    BusinessTemplate(
      key: 'fastfood',
      emoji: '🍔',
      en: 'Burgers & fast food',
      ur: 'برگر اور فاسٹ فوڈ',
      items: [
        TemplateItem('Zinger Burger', 450),
        TemplateItem('Chicken Burger', 350),
        TemplateItem('Beef Burger', 550),
        TemplateItem(
          'Fries',
          150,
          variants: [
            ProductVariant(name: 'Regular', price: 150),
            ProductVariant(name: 'Large', price: 250),
          ],
        ),
        TemplateItem('Loaded Fries', 380),
        TemplateItem('Chicken Shawarma', 250),
        TemplateItem('Club Sandwich', 420),
        TemplateItem('Soft Drink', 100),
      ],
    ),
    BusinessTemplate(
      key: 'bakery',
      emoji: '🎂',
      en: 'Bakery & cakes',
      ur: 'بیکری اور کیک',
      items: [
        TemplateItem(
          'Chocolate Cake',
          1200,
          variants: [
            ProductVariant(name: '1 lb', price: 1200),
            ProductVariant(name: '2 lb', price: 2200),
          ],
        ),
        TemplateItem(
          'Black Forest Cake',
          1100,
          variants: [
            ProductVariant(name: '1 lb', price: 1100),
            ProductVariant(name: '2 lb', price: 2000),
          ],
        ),
        TemplateItem('Cupcakes (6 pcs)', 600),
        TemplateItem('Brownies (box of 6)', 750),
        TemplateItem('Cookies (12 pcs)', 500),
        TemplateItem('Bread', 150),
      ],
    ),
    BusinessTemplate(
      key: 'restaurant',
      emoji: '🍛',
      en: 'Restaurant & home kitchen',
      ur: 'ریسٹورنٹ اور گھر کا کھانا',
      items: [
        TemplateItem(
          'Chicken Biryani',
          350,
          variants: [
            ProductVariant(name: 'Single', price: 350),
            ProductVariant(name: 'Full', price: 650),
          ],
        ),
        TemplateItem(
          'Chicken Karahi',
          1100,
          variants: [
            ProductVariant(name: 'Half', price: 1100),
            ProductVariant(name: 'Full', price: 2000),
          ],
        ),
        TemplateItem('Daal Mash', 300),
        TemplateItem('Chicken Tikka', 420),
        TemplateItem('Roti', 25),
        TemplateItem('Naan', 40),
        TemplateItem('Raita', 80),
      ],
    ),
    BusinessTemplate(
      key: 'grocery',
      emoji: '🛒',
      en: 'Grocery / kiryana',
      ur: 'کریانہ اسٹور',
      items: [
        TemplateItem('Atta (10 kg)', 1300),
        TemplateItem('Sugar (1 kg)', 160),
        TemplateItem('Cooking Oil (1 L)', 560),
        TemplateItem('Basmati Rice (1 kg)', 380),
        TemplateItem('Milk (1 L)', 220),
        TemplateItem('Eggs (dozen)', 360),
        TemplateItem('Tea (950 g)', 1600),
      ],
    ),
    BusinessTemplate(
      key: 'clothing',
      emoji: '👗',
      en: 'Boutique & clothing',
      ur: 'بوتیک اور کپڑے',
      items: [
        TemplateItem('Lawn Suit (3 pc)', 3500),
        TemplateItem('Kurti', 1800),
        TemplateItem('Shalwar Kameez (stitched)', 2800),
        TemplateItem('Dupatta', 900),
        TemplateItem('Kids Frock', 1500),
      ],
    ),
    BusinessTemplate(
      key: 'other',
      emoji: '🏪',
      en: 'Something else',
      ur: 'کچھ اور',
    ),
  ];

  static BusinessTemplate byKey(String? key) =>
      all.firstWhere((t) => t.key == key, orElse: () => all.last);
}
