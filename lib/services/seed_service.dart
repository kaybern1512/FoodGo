import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/core/enums/order_status.dart';
import 'package:foodgo/core/enums/payment_enum.dart';
import 'package:foodgo/core/enums/user_role.dart';
import 'package:foodgo/models/app_user.dart';

/// Service tạo dữ liệu mẫu (Fake Data) phong phú cho toàn bộ ứng dụng.
class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo tài liệu Admin trong Firestore
  Future<void> seedAdminUser(String adminUid) async {
    final user = AppUser(
      id: adminUid,
      fullName: 'Quản trị viên',
      email: 'admin@foodgo.com',
      phone: '0900000000',
      address: 'Hà Nội, Việt Nam',
      avatarUrl: '',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(adminUid)
        .set(user.toMap());
  }

  /// Tạo nhà hàng mẫu và sản phẩm cho nhà hàng hiện tại
  Future<void> seedRestaurantAndProducts(String restaurantOwnerUid) async {
    final restaurantRef =
        await _firestore.collection(FirestoreCollections.restaurants).add({
      'ownerId': restaurantOwnerUid,
      'name': 'Cơm Tấm Sài Gòn 137',
      'description': 'Cơm tấm đặc sản Sài Gòn với sườn nướng thảo mộc gia truyền',
      'address': '123 Nguyễn Huệ, Quận 1, TP.HCM',
      'phone': '0901234567',
      'imageUrl':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
      'rating': 4.8,
      'isApproved': true,
      'isOpen': true,
      'createdAt': Timestamp.now(),
    });

    final restaurantId = restaurantRef.id;

    final products = [
      {
        'restaurantId': restaurantId,
        'name': 'Cơm tấm sườn bì chả trạc đặc biệt',
        'description': 'Cơm tấm thơm mềm với sườn nướng mộc, bì heo giòn và chả trứng hấp',
        'category': 'Cơm tấm',
        'price': 55000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop',
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      },
      {
        'restaurantId': restaurantId,
        'name': 'Cơm tấm sườn ốp la',
        'description': 'Cơm tấm sườn nướng đậm vị kèm trứng ốp la lòng đào',
        'category': 'Cơm tấm',
        'price': 45000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&auto=format&fit=crop',
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      },
      {
        'restaurantId': restaurantId,
        'name': 'Bún thịt nướng chả giò',
        'description': 'Bún tươi với thịt heo nướng, chả giò giòn rụm và nước mắm chua ngọt',
        'category': 'Bún',
        'price': 40000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      },
      {
        'restaurantId': restaurantId,
        'name': 'Canh khổ qua dồn thịt',
        'description': 'Canh khổ qua thanh mát dồn thịt nạc băm',
        'category': 'Món phụ',
        'price': 20000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&auto=format&fit=crop',
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      },
      {
        'restaurantId': restaurantId,
        'name': 'Trà đá mứt tắc',
        'description': 'Trà tắc mát lạnh giải nhiệt',
        'category': 'Đồ uống',
        'price': 12000.0,
        'imageUrl':
            'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=600&auto=format&fit=crop',
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      },
    ];

    final batch = _firestore.batch();
    for (final product in products) {
      final ref = _firestore.collection(FirestoreCollections.products).doc();
      batch.set(ref, product);
    }
    await batch.commit();
  }

  /// Tạo toàn bộ dữ liệu ảo (Toàn bộ Cửa hàng, Sản phẩm, Đơn hàng & Shipper)
  Future<void> seedFullSystemDemoData(String currentUserId) async {
    // 1. Tạo thêm các Nhà hàng ảo
    final resList = [
      {
        'ownerId': 'demo_owner_1',
        'name': 'Phở Thìn Hà Nội 1979',
        'description': 'Phở tái lăn đậm đà chuẩn vị phố cổ Hà Nội',
        'address': '88 Lê Lợi, Quận 1, TP.HCM',
        'phone': '0988776655',
        'imageUrl':
            'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop',
        'rating': 4.9,
        'isApproved': true,
        'isOpen': true,
        'createdAt': Timestamp.now(),
      },
      {
        'ownerId': 'demo_owner_2',
        'name': 'Bánh Mì Huỳnh Hoa',
        'description': 'Bánh mì kẹp pa tê bơ béo ngậy đầy đặn nhất Sài Gòn',
        'address': '26 Lê Thị Riêng, Quận 1, TP.HCM',
        'phone': '0911223344',
        'imageUrl':
            'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=600&auto=format&fit=crop',
        'rating': 4.7,
        'isApproved': true,
        'isOpen': true,
        'createdAt': Timestamp.now(),
      },
      {
        'ownerId': 'demo_owner_3',
        'name': 'Trà Sữa Gong Cha',
        'description': 'Trà sữa Đài Loan chính hiệu trân châu đen dai ngon',
        'address': '79 Trần Hưng Đạo, Quận 5, TP.HCM',
        'phone': '0933445566',
        'imageUrl':
            'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600&auto=format&fit=crop',
        'rating': 4.6,
        'isApproved': true,
        'isOpen': true,
        'createdAt': Timestamp.now(),
      },
    ];

    for (final res in resList) {
      final resRef = await _firestore
          .collection(FirestoreCollections.restaurants)
          .add(res);

      final rId = resRef.id;

      // Thêm sản phẩm tương ứng
      if (res['name'].toString().contains('Phở')) {
        await _addProducts(rId, [
          {
            'name': 'Phở bò tái lăn đặc biệt',
            'description': 'Bò tái xào thơm với hành lá tươi nồng',
            'category': 'Phở',
            'price': 65000.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop',
          },
          {
            'name': 'Phở gà chặt lá chanh',
            'description': 'Thịt gà ta giòn da nêm lá chanh thơm lừng',
            'category': 'Phở',
            'price': 55000.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&auto=format&fit=crop',
          },
          {
            'name': 'Quẩy nóng giòn (3 cái)',
            'description': 'Quẩy rán vàng ruộm ăn kèm phở',
            'category': 'Món thêm',
            'price': 10000.0,
            'imageUrl': '',
          },
        ]);
      } else if (res['name'].toString().contains('Bánh Mì')) {
        await _addProducts(rId, [
          {
            'name': 'Bánh mì thập cẩm thịt chả',
            'description': 'Ổ bánh mì giòn kẹp 5 loại thịt chả pate ngon',
            'category': 'Bánh mì',
            'price': 58000.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=600&auto=format&fit=crop',
          },
          {
            'name': 'Bánh mì xíu mại sốt cà',
            'description': 'Xíu mại viên mềm thơm béo sốt cà đậm đà',
            'category': 'Bánh mì',
            'price': 35000.0,
            'imageUrl': '',
          },
        ]);
      } else {
        await _addProducts(rId, [
          {
            'name': 'Trà sữa ô long sương sáo',
            'description': 'Trà ô long thơm đậm kết hợp sương sáo thanh mát',
            'category': 'Trà sữa',
            'price': 48000.0,
            'imageUrl':
                'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600&auto=format&fit=crop',
          },
          {
            'name': 'Trà xoài kem tuyết',
            'description': 'Trà xoài tươi kem Cheese sánh mịn',
            'category': 'Trà trái cây',
            'price': 52000.0,
            'imageUrl': '',
          },
        ]);
      }
    }

    // 2. Tạo danh sách Đơn hàng ảo ở đủ các trạng thái
    final sampleOrders = [
      {
        'customerId': currentUserId,
        'restaurantId': 'demo_res_1',
        'shipperId': null,
        'customerName': 'Nguyễn Văn An',
        'customerPhone': '0909123456',
        'deliveryAddress': '45 Nguyễn Thị Minh Khai, Q.3, TP.HCM',
        'items': [
          {
            'productId': 'p1',
            'productName': 'Phở bò tái lăn đặc biệt',
            'imageUrl':
                'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop',
            'price': 65000.0,
            'quantity': 2,
            'totalPrice': 130000.0,
          },
          {
            'productId': 'p2',
            'productName': 'Quẩy nóng giòn (3 cái)',
            'imageUrl': '',
            'price': 10000.0,
            'quantity': 1,
            'totalPrice': 10000.0,
          }
        ],
        'subtotal': 140000.0,
        'shippingFee': 15000.0,
        'totalAmount': 155000.0,
        'paymentMethod': PaymentMethod.mockWallet.toFirestoreString(),
        'paymentStatus': PaymentStatus.paid.toFirestoreString(),
        'orderStatus': OrderStatus.waitingForShipper.toFirestoreString(),
        'note': 'Giao gấp giúp em, không bỏ hành tây',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'customerId': currentUserId,
        'restaurantId': 'demo_res_2',
        'shipperId': currentUserId,
        'customerName': 'Trần Thị Mai',
        'customerPhone': '0918222333',
        'deliveryAddress': '12 Đinh Tiên Hoàng, Quận 1, TP.HCM',
        'items': [
          {
            'productId': 'p3',
            'productName': 'Bánh mì thập cẩm thịt chả',
            'imageUrl':
                'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=600&auto=format&fit=crop',
            'price': 58000.0,
            'quantity': 1,
            'totalPrice': 58000.0,
          }
        ],
        'subtotal': 58000.0,
        'shippingFee': 15000.0,
        'totalAmount': 73000.0,
        'paymentMethod': PaymentMethod.cash.toFirestoreString(),
        'paymentStatus': PaymentStatus.unpaid.toFirestoreString(),
        'orderStatus': OrderStatus.delivering.toFirestoreString(),
        'note': 'Cho nhiều ớt cay',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
      {
        'customerId': currentUserId,
        'restaurantId': 'demo_res_3',
        'shipperId': 'demo_shipper_99',
        'customerName': 'Lê Hoàng Nam',
        'customerPhone': '0938444555',
        'deliveryAddress': '88 Nam Kỳ Khởi Nghĩa, Q.1, TP.HCM',
        'items': [
          {
            'productId': 'p4',
            'productName': 'Trà sữa ô long sương sáo',
            'imageUrl':
                'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600&auto=format&fit=crop',
            'price': 48000.0,
            'quantity': 2,
            'totalPrice': 96000.0,
          }
        ],
        'subtotal': 96000.0,
        'shippingFee': 15000.0,
        'totalAmount': 111000.0,
        'paymentMethod': PaymentMethod.cash.toFirestoreString(),
        'paymentStatus': PaymentStatus.paid.toFirestoreString(),
        'orderStatus': OrderStatus.completed.toFirestoreString(),
        'note': '50% đường 50% đá',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      },
    ];

    for (final orderMap in sampleOrders) {
      await _firestore
          .collection(FirestoreCollections.orders)
          .add(orderMap);
    }
  }

  Future<void> _addProducts(
      String restaurantId, List<Map<String, dynamic>> items) async {
    final batch = _firestore.batch();
    for (final item in items) {
      final ref = _firestore.collection(FirestoreCollections.products).doc();
      batch.set(ref, {
        'restaurantId': restaurantId,
        'name': item['name'],
        'description': item['description'],
        'category': item['category'],
        'price': item['price'],
        'imageUrl': item['imageUrl'],
        'isAvailable': true,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}
