/// Vehicle brand metadata model.
class VehicleBrand {
  const VehicleBrand({
    required this.id,
    required this.name,
    required this.logoAsset,
    required this.type,
  });

  final String id;
  final String name;
  final String logoAsset;
  /// 'car', 'bike', or 'all'
  final String type;

  bool get isOther => id == 'other';
}

/// Central registry of popular Car & Bike brands with logo asset paths and search helpers.
class VehicleBrandRegistry {
  const VehicleBrandRegistry._();

  static const VehicleBrand other = VehicleBrand(
    id: 'other',
    name: 'Other',
    logoAsset: '',
    type: 'all',
  );

  static const List<VehicleBrand> popularCars = [
    VehicleBrand(
      id: 'toyota',
      name: 'Toyota',
      logoAsset: 'assets/brands/cars/toyota.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'honda',
      name: 'Honda',
      logoAsset: 'assets/brands/cars/honda.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'nissan',
      name: 'Nissan',
      logoAsset: 'assets/brands/cars/nissan.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'hyundai',
      name: 'Hyundai',
      logoAsset: 'assets/brands/cars/hyundai.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'ford',
      name: 'Ford',
      logoAsset: 'assets/brands/cars/ford.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'bmw',
      name: 'BMW',
      logoAsset: 'assets/brands/cars/bmw.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'mercedes',
      name: 'Mercedes-Benz',
      logoAsset: 'assets/brands/cars/mercedes.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'audi',
      name: 'Audi',
      logoAsset: 'assets/brands/cars/audi.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'tesla',
      name: 'Tesla',
      logoAsset: 'assets/brands/cars/tesla.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'mitsubishi',
      name: 'Mitsubishi',
      logoAsset: 'assets/brands/cars/mitsubishi.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'kia',
      name: 'Kia',
      logoAsset: 'assets/brands/cars/kia.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'suzuki',
      name: 'Suzuki',
      logoAsset: 'assets/brands/cars/suzuki.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'tata',
      name: 'Tata',
      logoAsset: 'assets/brands/cars/tata.svg',
      type: 'car',
    ),
    VehicleBrand(
      id: 'mahindra',
      name: 'Mahindra',
      logoAsset: 'assets/brands/cars/mahindra.svg',
      type: 'car',
    ),
    other,
  ];

  static const List<VehicleBrand> popularBikes = [
    VehicleBrand(
      id: 'yamaha',
      name: 'Yamaha',
      logoAsset: 'assets/brands/bikes/yamaha.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'honda_bike',
      name: 'Honda',
      logoAsset: 'assets/brands/bikes/honda_bike.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'suzuki_bike',
      name: 'Suzuki',
      logoAsset: 'assets/brands/bikes/suzuki_bike.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'bajaj',
      name: 'Bajaj',
      logoAsset: 'assets/brands/bikes/bajaj.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'tvs',
      name: 'TVS',
      logoAsset: 'assets/brands/bikes/tvs.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'hero',
      name: 'Hero',
      logoAsset: 'assets/brands/bikes/hero.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'royal_enfield',
      name: 'Royal Enfield',
      logoAsset: 'assets/brands/bikes/royal_enfield.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'ktm',
      name: 'KTM',
      logoAsset: 'assets/brands/bikes/ktm.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'kawasaki',
      name: 'Kawasaki',
      logoAsset: 'assets/brands/bikes/kawasaki.svg',
      type: 'bike',
    ),
    VehicleBrand(
      id: 'runner',
      name: 'Runner',
      logoAsset: 'assets/brands/bikes/runner.svg',
      type: 'bike',
    ),
    other,
  ];

  /// Returns brand list matching vehicle type ('Car' or 'Bike').
  static List<VehicleBrand> getBrandsForType(String type) {
    if (type.toLowerCase() == 'bike' || type.toLowerCase() == 'motorcycle') {
      return popularBikes;
    }
    return popularCars;
  }

  /// Finds brand by ID or name (case-insensitive).
  static VehicleBrand? findBrand(String? brandIdOrName) {
    if (brandIdOrName == null || brandIdOrName.trim().isEmpty) return null;
    final clean = brandIdOrName.trim().toLowerCase();

    for (final b in [...popularCars, ...popularBikes]) {
      if (b.id.toLowerCase() == clean || b.name.toLowerCase() == clean) {
        return b;
      }
    }
    return null;
  }
}
