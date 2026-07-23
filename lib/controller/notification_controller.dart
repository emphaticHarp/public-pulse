import 'package:get/get.dart';
import 'package:public_pulse/model/notification_model.dart';

class NotificationController extends GetxController {
  /// Selected notification tab
  final RxInt tabIndex = 0.obs;

  /// New notifications
  final RxList<NotificationModel> newNotifications = <NotificationModel>[].obs;

  /// Earlier notifications
  final RxList<NotificationModel> earlierNotifications =
      <NotificationModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    newNotifications.assignAll([
      NotificationModel(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDoxQ-xb10EfZcbxV3tlBo_MFaC-W-3IQzhpLa2nhhxOADtJwc6PQLVzTd9nDp4XuZvg-K_AO2H6m3SI9ViSMZttjLAwCZOcd9d4NPF6g3qaG-Xdu14GrdRK8FJcOg3c_MKWy_MOtWrkGJCA5XOgVbyov5XKa08K6fpSvCZaLrc9fNvC2RbGAx-bB03gvpNljJ1xW-Tu3cv-afcjWmqV9Vo6gfROyh9Oc4PlyuS2e6H2cEhCMaxX97lhNVIyf_E_BHqcPIfdv_kBgRr',
        name: 'Ananya Sharma',
        action: 'liked your post.',
        timeAgo: '2m ago',
        postImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBOYrJkC732ED2bXPLVsi82qIO_0yvMubha3VOR4ORPCuDCjV1-vsbCXrQ8woKkclJAEZ501TLtGAtC-ClYrV5wToATxv6PFTafJasIUSRIZJ8Yk5fLENimz17YcYzR2HEmT6W3UtKQilngtzWsis8revtcsKKgXl2xsJkVCW4-uGehXA8zPm2LH9FLSt4wCvTUTQ70v2fjp06Cc5xGH5Jys6raTOBpS3oHUlQbzys6NSbMyVNpHyxfZQzPEoiQq_awa32-8QQbsJL1',
      ),
      NotificationModel(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAKPedLQkJtbpQXgRkojUuRCrMcgM76mbFjOelhr9QQ2du8lDvw0HHtWGITCNBBX9FlcbRSTt3i1ZCQHgtP4ygXPm_4ijVcQwJXqVUoNNNhRe_DbPlXoybwEQNpKPli98RrapkBQ0bW5nFyQCok4yjJXLZXc9A5Amsva7I-m-z3a_ZMf_YCgYVsPG3iS9J8pf2wKHD7dlK3VTUmx7B9NxZjRIm4cwHNnxh4ITBdrZ55Nu_mXFFljP4fvQTMHivhRltd4o5hK_6wo50U',
        name: 'Priya Singh',
        action: 'started following you.',
        timeAgo: '10m ago',
        postImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBOYrJkC732ED2bXPLVsi82qIO_0yvMubha3VOR4ORPCuDCjV1-vsbCXrQ8woKkclJAEZ501TLtGAtC-ClYrV5wToATxv6PFTafJasIUSRIZJ8Yk5fLENimz17YcYzR2HEmT6W3UtKQilngtzWsis8revtcsKKgXl2xsJkVCW4-uGehXA8zPm2LH9FLSt4wCvTUTQ70v2fjp06Cc5xGH5Jys6raTOBpS3oHUlQbzys6NSbMyVNpHyxfZQzPEoiQq_awa32-8QQbsJL1',
      ),
    ]);

    earlierNotifications.assignAll([
      NotificationModel(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDx5tgKWpfEvhlth_ATNDGPiqQ2aV-qav5mcq0M70yrYhRjJ9YOltNcY_DF-cA7URCjI1bqddLxlTP7QVAkTyF8M6u9K1QubWvq_QYKR-DFhJlNmvNat9goR1FhoNiZw5HHFzoj8hWrQ3FZjxOlvEcNzD7uUdPw6bd_GoWfcl9K-cbB5YDi-zx85rvRCc2h_SKXP0oKTT4sTl08svzL4GJUEoFMny59OMGmuG2tHvCPWEBZCBKAa4_MTSgMwdHZK8C20mxjmMasmZ8E',
        name: 'Rohit Das',
        action: 'started following you.',
        timeAgo: '2h ago',
        postImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBOYrJkC732ED2bXPLVsi82qIO_0yvMubha3VOR4ORPCuDCjV1-vsbCXrQ8woKkclJAEZ501TLtGAtC-ClYrV5wToATxv6PFTafJasIUSRIZJ8Yk5fLENimz17YcYzR2HEmT6W3UtKQilngtzWsis8revtcsKKgXl2xsJkVCW4-uGehXA8zPm2LH9FLSt4wCvTUTQ70v2fjp06Cc5xGH5Jys6raTOBpS3oHUlQbzys6NSbMyVNpHyxfZQzPEoiQq_awa32-8QQbsJL1',
      ),
      NotificationModel(
        avatarUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCAsmaIO9pB3q4w23vpIg9dAODtsw5-_pHXjha_QkWKntX-21or4Y8-4tfMz57LtE8jCC1R8NKXJT7aeXjqovzpAibpQKNPIrmwyeQCqVaBA26FX7K4yupBJ2dZEOhjDqBQiOJ1zUkAmYpvsH5Yt0gnOflBkBuk0yU-K-uexOVEO-MpG0PDZlb0_E3tAgrPBckVKKAfyhHRx3XMGI9xhnkVlvAk9-tC7RQ-pXIyqmxd0AfX8EZT4UTZM1BvTkICgTyzCW645KQv7F_b',
        name: 'Neha Patel',
        action: 'liked your post.',
        timeAgo: '1h ago',
        postImageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBOYrJkC732ED2bXPLVsi82qIO_0yvMubha3VOR4ORPCuDCjV1-vsbCXrQ8woKkclJAEZ501TLtGAtC-ClYrV5wToATxv6PFTafJasIUSRIZJ8Yk5fLENimz17YcYzR2HEmT6W3UtKQilngtzWsis8revtcsKKgXl2xsJkVCW4-uGehXA8zPm2LH9FLSt4wCvTUTQ70v2fjp06Cc5xGH5Jys6raTOBpS3oHUlQbzys6NSbMyVNpHyxfZQzPEoiQq_awa32-8QQbsJL1',
      ),
    ]);
  }
}
