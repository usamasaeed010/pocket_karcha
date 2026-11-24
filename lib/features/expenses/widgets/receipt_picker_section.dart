// Image attachments (receipts) are disabled for now.
// The whole receipt picker is commented out until images are used again.
//
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:pocket_karcha/core/constants/app_colors.dart';
// import 'package:pocket_karcha/core/constants/app_spacing.dart';
// import 'package:pocket_karcha/core/l10n/app_strings.dart';
// import 'package:pocket_karcha/features/expenses/providers/add_expense_form_provider.dart';
// import 'package:pocket_karcha/providers/auth_provider.dart';
// import 'package:pocket_karcha/providers/locale_provider.dart';
//
// class ReceiptPickerSection extends ConsumerWidget {
//   const ReceiptPickerSection({super.key});
//
//   Future<void> _pick(WidgetRef ref, ImageSource source) async {
//     final picker = ImagePicker();
//     final file = await picker.pickImage(
//       source: source,
//       maxWidth: 1600,
//       imageQuality: 85,
//     );
//     if (file != null) {
//       ref.read(addExpenseFormProvider.notifier).setReceipt(File(file.path));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final urdu = ref.watch(localeUrduProvider);
//     final s = AppStrings(urdu);
//     final form = ref.watch(addExpenseFormProvider);
//     final canUpload = !ref.watch(guestModeProvider);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(s.receipt, style: Theme.of(context).textTheme.labelLarge),
//         const SizedBox(height: AppSpacing.sm),
//         if (!canUpload)
//           Text(
//             s.loginToSync,
//             style: const TextStyle(
//               fontSize: 12,
//               color: AppColors.textSecondary,
//             ),
//           ),
//         if (form.receiptFile != null) ...[
//           const SizedBox(height: AppSpacing.sm),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
//             child: Image.file(
//               form.receiptFile!,
//               height: 140,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//           ),
//           TextButton.icon(
//             onPressed: () =>
//                 ref.read(addExpenseFormProvider.notifier).setReceipt(null),
//             icon: const Icon(Icons.close, size: 18),
//             label: Text(s.removeReceipt),
//           ),
//         ] else ...[
//           const SizedBox(height: AppSpacing.sm),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => _pick(ref, ImageSource.camera),
//                   icon: const Icon(Icons.camera_alt_outlined),
//                   label: Text(s.takePhoto),
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.sm),
//               Expanded(
//                 child: OutlinedButton.icon(
//                   onPressed: () => _pick(ref, ImageSource.gallery),
//                   icon: const Icon(Icons.photo_library_outlined),
//                   label: Text(s.chooseGallery),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }
// }
